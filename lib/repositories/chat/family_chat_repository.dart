import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';

class FamilyChatRepository {
  FamilyChatRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _messageCollection(String familyId) {
    return _db.collection('families').doc(familyId).collection('messages');
  }

  Stream<List<FamilyChatMessage>> watchMessages(String familyId, {int limit = 200}) {
    return _messageCollection(familyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => FamilyChatMessage.fromDoc(doc, familyId: familyId))
          .toList(),
    );
  }

  Stream<List<FamilyChatMember>> watchMembers(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .snapshots()
        .asyncMap((membersSnapshot) async {
      if (membersSnapshot.docs.isEmpty) {
        return <FamilyChatMember>[];
      }

      final userReads = await Future.wait(
        membersSnapshot.docs.map((memberDoc) {
          return _db.collection('users').doc(memberDoc.id).get();
        }),
      );

      final members = <FamilyChatMember>[];
      for (var i = 0; i < membersSnapshot.docs.length; i++) {
        final memberDoc = membersSnapshot.docs[i];
        final memberData = memberDoc.data();
        final userData = userReads[i].data() ?? <String, dynamic>{};

        final displayNameRaw =
            userData['displayName'] ?? userData['email'] ?? memberDoc.id;

        members.add(
          FamilyChatMember(
            uid: memberDoc.id,
            role: (memberData['role'] ?? 'member').toString(),
            displayName: displayNameRaw.toString(),
            avatarUrl: (userData['avatarUrl'] ?? '').toString(),
          ),
        );
      }

      members.sort((a, b) {
        final roleScoreA = a.role == 'parent' ? 0 : 1;
        final roleScoreB = b.role == 'parent' ? 0 : 1;
        final roleCompare = roleScoreA.compareTo(roleScoreB);
        if (roleCompare != 0) return roleCompare;
        return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
      });

      return members;
    });
  }

  Future<void> sendTextMessage({
    required String familyId,
    required String senderUid,
    required String senderName,
    required String senderRole,
    required String text,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    if (normalized.length > 1000) {
      throw ArgumentError.value(normalized.length, 'text', 'Message too long (>1000 chars)');
    }

    try {
      await _functions.httpsCallable('sendFamilyMessage').call({'text': normalized});
      return;
    } on FirebaseFunctionsException catch (e) {
      final fallbackCodes = {'not-found', 'unimplemented'};
      if (!fallbackCodes.contains(e.code)) {
        rethrow;
      }
    }

    final messageRef = _messageCollection(familyId).doc();
    final now = FieldValue.serverTimestamp();

    final batch = _db.batch();
    batch.set(messageRef, {
      'id': messageRef.id,
      'familyId': familyId,
      'senderUid': senderUid,
      'senderRole': senderRole,
      'senderName': senderName,
      'text': normalized,
      'type': 'text',
      'createdAt': now,
    });

    batch.set(
      _db.collection('families').doc(familyId),
      {
        'lastMessageAt': now,
        'lastMessageBy': senderUid,
        'lastMessageText': normalized,
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
}
