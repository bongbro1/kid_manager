import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/models/chat/family_chat_state.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/chat/family_chat_storage_path.dart';

class FamilyChatRepository {
  FamilyChatRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  static const int _maxClientMessageIdLength = 120;
  static final RegExp _safeClientMessageIdPattern = RegExp(
    r'^[A-Za-z0-9_-]{1,120}$',
  );

  CollectionReference<Map<String, dynamic>> _messageCollection(String familyId) {
    return _db.collection('families').doc(familyId).collection('messages');
  }

  DocumentReference<Map<String, dynamic>> _chatStateDoc(String familyId, String uid) {
    return _db.collection('families').doc(familyId).collection('chatStates').doc(uid);
  }

  String _resolveSenderName(AppUser sender) {
    return sender.displayName?.trim().isNotEmpty == true
        ? sender.displayName!.trim()
        : sender.email?.trim().isNotEmpty == true
            ? sender.email!.trim()
            : 'Family member';
  }

  String _resolveMessageId(String familyId, String? clientMessageId) {
    final normalizedClientMessageId = clientMessageId?.trim() ?? '';
    final messageId = normalizedClientMessageId.isNotEmpty
        ? normalizedClientMessageId
        : _messageCollection(familyId).doc().id;

    if (messageId.length > _maxClientMessageIdLength ||
        !_safeClientMessageIdPattern.hasMatch(messageId)) {
      throw ArgumentError.value(
        messageId,
        'clientMessageId',
        'clientMessageId must match [A-Za-z0-9_-] and be <= $_maxClientMessageIdLength chars',
      );
    }

    return messageId;
  }

  Future<Map<String, dynamic>> _createPendingMessage({
    required String familyId,
    required AppUser sender,
    required String type,
    required String text,
    required String messageId,
    String? stickerId,
    String? imageUrl,
    String? imagePath,
    int? imageWidth,
    int? imageHeight,
  }) async {
    final resolvedFamilyId = familyId.trim();
    if (resolvedFamilyId.isEmpty) {
      throw ArgumentError.value(familyId, 'familyId', 'familyId is required');
    }

    final clientCreatedAt = Timestamp.now();

    await _messageCollection(resolvedFamilyId).doc(messageId).set({
      'id': messageId,
      'familyId': resolvedFamilyId,
      'senderUid': sender.uid,
      'senderRole': roleToString(sender.role),
      'senderName': _resolveSenderName(sender),
      'clientMessageId': messageId,
      'text': text,
      'type': type,
      'stickerId': stickerId,
      'imageUrl': imageUrl,
      'imagePath': imagePath,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight,
      'verifyState': 'pending',
      'clientCreatedAt': clientCreatedAt,
      'createdAt': clientCreatedAt,
    }..removeWhere((key, value) => value == null));

    return <String, dynamic>{
      'ok': true,
      'familyId': resolvedFamilyId,
      'messageId': messageId,
      'clientMessageId': messageId,
    };
  }

  Stream<List<FamilyChatMessage>> watchMessages(String familyId, {int limit = 200}) {
    return _messageCollection(familyId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
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

      final members = <FamilyChatMember>[];
      for (final memberDoc in membersSnapshot.docs) {
        final memberData = memberDoc.data();
        final displayName = (memberData['displayName'] ?? '').toString().trim();
        final email = (memberData['email'] ?? '').toString().trim();
        final displayNameRaw = displayName.isNotEmpty
            ? displayName
            : email;

        members.add(
          FamilyChatMember(
            uid: memberDoc.id,
            role: UserRole.fromValue(memberData['role']),
            displayName: displayNameRaw.toString(),
            avatarUrl: (memberData['avatarUrl'] ?? '').toString(),
          ),
        );
      }

      members.sort((a, b) {
        final roleScoreA = switch (a.role) {
          UserRole.parent => 0,
          UserRole.guardian => 1,
          UserRole.child => 2,
        };
        final roleScoreB = switch (b.role) {
          UserRole.parent => 0,
          UserRole.guardian => 1,
          UserRole.child => 2,
        };
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
    required String familyId,
    required AppUser sender,
    required String text,
    String? clientMessageId,
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

    final resolvedFamilyId = familyId.trim();
    final messageId = _resolveMessageId(resolvedFamilyId, clientMessageId);

    debugPrint(
      '[FamilyChatRepository] sendTextMessage direct '
      'familyId=$resolvedFamilyId messageId=$messageId text="$normalized"',
    );

    try {
      return _createPendingMessage(
        familyId: resolvedFamilyId,
        sender: sender,
        type: 'text',
        text: normalized,
        messageId: messageId,
      );
    } catch (e, st) {
      debugPrint('[FamilyChatRepository] direct sendTextMessage error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendImageMessage({
    required String familyId,
    required AppUser sender,
    required String imageUrl,
    required String imagePath,
    required int imageWidth,
    required int imageHeight,
    String? clientMessageId,
    String text = '',
  }) async {
    final resolvedFamilyId = familyId.trim();
    if (resolvedFamilyId.isEmpty) {
      throw ArgumentError.value(familyId, 'familyId', 'familyId is required');
    }

    final normalizedImageUrl = imageUrl.trim();
    if (normalizedImageUrl.isEmpty) {
      throw ArgumentError.value(imageUrl, 'imageUrl', 'imageUrl is required');
    }

    final normalizedText = text.trim();
    if (normalizedText.length > 140) {
      throw ArgumentError.value(
        normalizedText.length,
        'text',
        'Image caption too long (>140 chars)',
      );
    }
    final normalizedImagePath = imagePath.trim();
    if (normalizedImagePath.isEmpty) {
      throw ArgumentError.value(imagePath, 'imagePath', 'imagePath is required');
    }

    final messageId = _resolveMessageId(resolvedFamilyId, clientMessageId);
    if (!matchesFamilyChatImageStoragePath(
      imagePath: normalizedImagePath,
      familyId: resolvedFamilyId,
      senderUid: sender.uid,
      messageId: messageId,
    )) {
      throw ArgumentError.value(
        normalizedImagePath,
        'imagePath',
        'imagePath must belong to the same family, sender, and messageId',
      );
    }

    debugPrint(
      '[FamilyChatRepository] sendImageMessage direct '
      'familyId=$resolvedFamilyId messageId=$messageId imageWidth=$imageWidth imageHeight=$imageHeight',
    );

    return _createPendingMessage(
      familyId: resolvedFamilyId,
      sender: sender,
      type: 'image',
      text: normalizedText,
      messageId: messageId,
      imageUrl: normalizedImageUrl,
      imagePath: normalizedImagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  Future<Map<String, dynamic>> sendStickerMessage({
    required String familyId,
    required AppUser sender,
    required String stickerId,
    String? clientMessageId,
  }) async {
    final normalized = stickerId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        stickerId,
        'stickerId',
        'stickerId is required',
      );
    }

    if (normalized.length > 64) {
      throw ArgumentError.value(
        normalized.length,
        'stickerId',
        'Sticker id too long (>64 chars)',
      );
    }

    final resolvedFamilyId = familyId.trim();
    if (resolvedFamilyId.isEmpty) {
      throw ArgumentError.value(familyId, 'familyId', 'familyId is required');
    }

    final messageId = _resolveMessageId(resolvedFamilyId, clientMessageId);

    debugPrint(
      '[FamilyChatRepository] sendStickerMessage direct '
      'familyId=$resolvedFamilyId messageId=$messageId stickerId="$normalized"',
    );

    return _createPendingMessage(
      familyId: resolvedFamilyId,
      sender: sender,
      type: 'sticker',
      text: '',
      messageId: messageId,
      stickerId: normalized,
    );
  }

  Future<Map<String, dynamic>> sendLegacyStickerMessage({
    required String familyId,
    required AppUser sender,
    required String legacyText,
    String? clientMessageId,
  }) async {
    final normalized = legacyText.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        legacyText,
        'legacyText',
        'legacyText is required',
      );
    }

    if (normalized.length > 32) {
      throw ArgumentError.value(
        normalized.length,
        'legacyText',
        'Legacy sticker payload too long (>32 chars)',
      );
    }

    final resolvedFamilyId = familyId.trim();
    if (resolvedFamilyId.isEmpty) {
      throw ArgumentError.value(familyId, 'familyId', 'familyId is required');
    }

    final messageId = _resolveMessageId(resolvedFamilyId, clientMessageId);

    return _createPendingMessage(
      familyId: resolvedFamilyId,
      sender: sender,
      type: 'sticker',
      text: normalized,
      messageId: messageId,
    );
  }

  Future<void> markAsRead() async {
    await _functions.httpsCallable('markFamilyChatRead').call();
  }
}
