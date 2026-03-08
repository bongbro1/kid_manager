import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/models/chat/family_chat_state.dart';

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

  DocumentReference<Map<String, dynamic>> _chatStateDoc(String familyId, String uid) {
    return _db.collection('families').doc(familyId).collection('chatStates').doc(uid);
  }

  Stream<List<FamilyChatMessage>> watchMessages(String familyId, {int limit = 200}) {
    return _messageCollection(familyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => FamilyChatMessage.fromDoc(doc, familyId: familyId))
        .toList());
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


  Stream<int> watchUnreadCount({
    required String familyId,
    required String uid,
  }) {
    return _chatStateDoc(familyId, uid).snapshots().map((doc) {
      final data = doc.data();
      debugPrint('[watchUnreadCount] familyId=$familyId uid=$uid exists=${doc.exists} data=$data');

      if (!doc.exists) return 0;
      return FamilyChatState.fromDoc(doc).unreadCount;
    });
  }

  Future<Map<String, dynamic>> sendTextMessage({
    required String text,
  }) async {
    final normalized = text.trim();
    if (normalized.isEmpty) {
      return <String, dynamic>{};
    }

    if (normalized.length > 1000) {
      throw ArgumentError.value(
        normalized.length,
        'text',
        'Message too long (>1000 chars)',
      );
    }

    debugPrint('[FamilyChatRepository] sendTextMessage start text="$normalized"');

    try {
      final result = await _functions.httpsCallable('sendFamilyMessage').call({
        'text': normalized,
      });

      debugPrint('[FamilyChatRepository] raw result.data=${result.data}');

      final map = result.data is Map
          ? Map<String, dynamic>.from(result.data as Map)
          : <String, dynamic>{};

      debugPrint('[FamilyChatRepository] parsed result=$map');
      return map;
    } on FirebaseFunctionsException catch (e, st) {
      debugPrint(
        '[FamilyChatRepository] FirebaseFunctionsException '
            'code=${e.code} message=${e.message} details=${e.details}',
      );
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('[FamilyChatRepository] sendTextMessage error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> markAsRead() async {
    await _functions.httpsCallable('markFamilyChatRead').call();
  }
}