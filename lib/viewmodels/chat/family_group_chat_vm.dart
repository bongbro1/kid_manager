import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/repositories/chat/family_chat_repository.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/services/chat/chat_media_service.dart';
import 'package:kid_manager/services/chat/family_chat_storage_path.dart';

class FamilyGroupChatVm extends ChangeNotifier {
  FamilyGroupChatVm({
    FamilyChatRepository? chatRepository,
    NotificationRepository? notificationRepository,
  })  : _chatRepository = chatRepository ?? FamilyChatRepository(),
        _notificationRepository =
            notificationRepository ?? NotificationRepository();

  final FamilyChatRepository _chatRepository;
  final NotificationRepository _notificationRepository;

  String? _activeFamilyId;
  Stream<List<FamilyChatMember>>? _membersStream;
  Stream<List<FamilyChatMessage>>? _messagesStream;
  bool _clearedChatNotification = false;
  bool _isUploadingMedia = false;
  bool _disposed = false;
  int _familyGeneration = 0;

  String? get activeFamilyId => _activeFamilyId;
  Stream<List<FamilyChatMember>>? get membersStream => _membersStream;
  Stream<List<FamilyChatMessage>>? get messagesStream => _messagesStream;
  bool get isUploadingMedia => _isUploadingMedia;

  void bindFamily(String familyId) {
    final normalizedFamilyId = familyId.trim();
    if (normalizedFamilyId.isEmpty) {
      clearFamily();
      return;
    }

    final hasActiveStreams = _membersStream != null && _messagesStream != null;
    if (_activeFamilyId == normalizedFamilyId && hasActiveStreams) {
      return;
    }

    _familyGeneration++;
    _activeFamilyId = normalizedFamilyId;
    _membersStream = _chatRepository.watchMembers(normalizedFamilyId);
    _messagesStream = _chatRepository.watchMessages(normalizedFamilyId);
    _clearedChatNotification = false;
    _safeNotifyListeners();
  }

  void clearFamily() {
    final hadState =
        _activeFamilyId != null ||
        _membersStream != null ||
        _messagesStream != null ||
        _clearedChatNotification ||
        _isUploadingMedia;
    _familyGeneration++;
    _activeFamilyId = null;
    _membersStream = null;
    _messagesStream = null;
    _clearedChatNotification = false;
    _isUploadingMedia = false;
    if (hadState) {
      _safeNotifyListeners();
    }
  }

  Future<void> clearChatNotificationIfNeeded({required String uid}) async {
    final familyId = _activeFamilyId;
    final normalizedUid = uid.trim();
    if (_clearedChatNotification ||
        familyId == null ||
        familyId.isEmpty ||
        normalizedUid.isEmpty) {
      return;
    }

    try {
      await _notificationRepository.deleteChatNotificationsForFamily(
        uid: normalizedUid,
        familyId: familyId,
      );
      await _notificationRepository.markFamilyChatRead(
        familyId: familyId,
        uid: normalizedUid,
      );
      _clearedChatNotification = true;
      debugPrint(
        '[FamilyGroupChatVm] cleared chat notifications for familyId=$familyId',
      );
    } catch (e, st) {
      debugPrint('[FamilyGroupChatVm] clear chat notifications error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> sendTextMessage({
    required AppUser sender,
    required String text,
    String? clientMessageId,
  }) async {
    await _chatRepository.sendTextMessage(
      familyId: _requireFamilyId(),
      sender: sender,
      text: text,
      clientMessageId: clientMessageId,
    );
  }

  Future<void> sendQuickReaction({required AppUser sender}) {
    return sendTextMessage(sender: sender, text: '\u{1F44D}');
  }

  Future<void> sendStickerMessage({
    required AppUser sender,
    required String stickerId,
    String? clientMessageId,
  }) async {
    await _chatRepository.sendStickerMessage(
      familyId: _requireFamilyId(),
      sender: sender,
      stickerId: stickerId,
      clientMessageId: clientMessageId,
    );
  }

  Future<void> sendLegacyStickerMessage({
    required AppUser sender,
    required String legacyText,
    String? clientMessageId,
  }) async {
    await _chatRepository.sendLegacyStickerMessage(
      familyId: _requireFamilyId(),
      sender: sender,
      legacyText: legacyText,
      clientMessageId: clientMessageId,
    );
  }

  Future<void> sendRemoteImageMessage({
    required AppUser sender,
    required String imageUrl,
    required String imagePath,
    required int imageWidth,
    required int imageHeight,
    String text = '',
    String? clientMessageId,
  }) async {
    await _chatRepository.sendImageMessage(
      familyId: _requireFamilyId(),
      sender: sender,
      imageUrl: imageUrl,
      imagePath: imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      text: text,
      clientMessageId: clientMessageId,
    );
  }

  Future<void> retryMessage({
    required AppUser sender,
    required FamilyChatMessage message,
  }) async {
    if (message.type == 'image' &&
        message.imageUrl != null &&
        message.imageWidth != null &&
        message.imageHeight != null) {
      final resolvedImagePath = resolveFamilyChatImageStoragePath(
        familyId: _requireFamilyId(),
        senderUid: sender.uid,
        messageId: message.id,
        imagePath: message.imagePath,
        imageUrl: message.imageUrl,
      );
      if (resolvedImagePath == null) {
        throw StateError('missing_or_invalid_image_path');
      }

      await sendRemoteImageMessage(
        sender: sender,
        imageUrl: message.imageUrl!,
        imagePath: resolvedImagePath,
        imageWidth: message.imageWidth!,
        imageHeight: message.imageHeight!,
        text: message.text,
        clientMessageId: DateTime.now().microsecondsSinceEpoch.toString(),
      );
      return;
    }

    if (message.type == 'sticker') {
      final stickerId = message.stickerId?.trim() ?? '';
      if (stickerId.isNotEmpty) {
        await sendStickerMessage(
          sender: sender,
          stickerId: stickerId,
          clientMessageId: DateTime.now().microsecondsSinceEpoch.toString(),
        );
        return;
      }

      await sendLegacyStickerMessage(
        sender: sender,
        legacyText: message.text,
        clientMessageId: DateTime.now().microsecondsSinceEpoch.toString(),
      );
      return;
    }

    await sendTextMessage(
      sender: sender,
      text: message.text,
      clientMessageId: DateTime.now().microsecondsSinceEpoch.toString(),
    );
  }

  Future<void> pickAndSendImage({required AppUser sender}) async {
    if (_isUploadingMedia) {
      return;
    }

    final familyId = _requireFamilyId();
    final generation = _familyGeneration;
    PreparedChatImage? prepared;
    UploadedChatImage? uploaded;
    var messageSaved = false;
    _setUploadingMedia(true);

    try {
      prepared = await ChatMediaService.pickCompressedImage();
      if (prepared == null) {
        return;
      }
      if (prepared.width <= 0 || prepared.height <= 0) {
        throw Exception('invalid_image');
      }
      if (_isStaleFamilyOperation(generation, familyId)) {
        return;
      }

      final messageId = DateTime.now().microsecondsSinceEpoch.toString();
      uploaded = await ChatMediaService.uploadFamilyChatImage(
        image: prepared,
        familyId: familyId,
        senderUid: sender.uid,
        messageId: messageId,
      );
      if (_isStaleFamilyOperation(generation, familyId)) {
        await _deleteUploadedImage(uploaded.storagePath);
        return;
      }

      await _chatRepository.sendImageMessage(
        familyId: familyId,
        sender: sender,
        imageUrl: uploaded.downloadUrl,
        imagePath: uploaded.storagePath,
        imageWidth: prepared.width,
        imageHeight: prepared.height,
        clientMessageId: messageId,
      );
      messageSaved = true;
    } catch (e) {
      if (!messageSaved && uploaded != null) {
        unawaited(_deleteUploadedImage(uploaded.storagePath));
      }
      rethrow;
    } finally {
      _setUploadingMedia(false);
    }
  }

  Future<void> _deleteUploadedImage(String storagePath) async {
    await FirebaseStorage.instance.ref(storagePath).delete().catchError((_) {});
  }

  bool _isStaleFamilyOperation(int generation, String familyId) {
    return _disposed ||
        generation != _familyGeneration ||
        _activeFamilyId != familyId;
  }

  String _requireFamilyId() {
    final familyId = _activeFamilyId?.trim() ?? '';
    if (familyId.isEmpty) {
      throw StateError('familyId is required');
    }
    return familyId;
  }

  void _setUploadingMedia(bool value) {
    if (_isUploadingMedia == value) {
      return;
    }
    _isUploadingMedia = value;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
