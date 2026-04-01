import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/chat/family_group_chat_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/chat/family_chat_assets.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_composer.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_header.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_messages_view.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_ui_utils.dart';
import 'package:provider/provider.dart';

class FamilyGroupChatScreen extends StatelessWidget {
  const FamilyGroupChatScreen({
    super.key,
    this.initialFamilyId,
    this.initialMessageId,
    this.initialComposerText,
  });

  final String? initialFamilyId;
  final String? initialMessageId;
  final String? initialComposerText;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FamilyGroupChatVm(),
      child: _FamilyGroupChatBody(
        initialFamilyId: initialFamilyId,
        initialMessageId: initialMessageId,
        initialComposerText: initialComposerText,
      ),
    );
  }
}

class _FamilyGroupChatBody extends StatefulWidget {
  const _FamilyGroupChatBody({
    required this.initialFamilyId,
    required this.initialMessageId,
    required this.initialComposerText,
  });

  final String? initialFamilyId;
  final String? initialMessageId;
  final String? initialComposerText;

  @override
  State<_FamilyGroupChatBody> createState() => _FamilyGroupChatBodyState();
}

class _FamilyGroupChatBodyState extends State<_FamilyGroupChatBody> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  bool _appliedInitialComposerText = false;
  bool _sessionSyncScheduled = false;
  String? _boundFamilyId;
  String? _boundUid;
  List<FamilyChatSticker> _stickerCatalog = kFamilyChatFallbackStickers;
  UserVm? _userVm;
  AuthVM? _authVm;

  @override
  void initState() {
    super.initState();
    unawaited(_loadStickerCatalog());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextUserVm = context.read<UserVm>();
    if (!identical(_userVm, nextUserVm)) {
      _userVm?.removeListener(_handleUserSessionChanged);
      _userVm = nextUserVm;
      _userVm?.addListener(_handleUserSessionChanged);
    }

    final nextAuthVm = context.read<AuthVM>();
    if (!identical(_authVm, nextAuthVm)) {
      _authVm?.removeListener(_handleAuthSessionChanged);
      _authVm = nextAuthVm;
      _authVm?.addListener(_handleAuthSessionChanged);
    }
    _scheduleSessionSync();
  }

  @override
  void didUpdateWidget(covariant _FamilyGroupChatBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFamilyId != widget.initialFamilyId ||
        oldWidget.initialComposerText != widget.initialComposerText) {
      _scheduleSessionSync();
    }
  }

  @override
  void dispose() {
    _userVm?.removeListener(_handleUserSessionChanged);
    _authVm?.removeListener(_handleAuthSessionChanged);
    _inputFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadStickerCatalog() async {
    final stickers = await loadFamilyChatStickers();
    debugPrint('stickers count = ${stickers.length}');
    for (final s in stickers) {
      debugPrint('sticker: id=${s.id}, path=${s.assetPath}');
    }

    if (!mounted) return;
    setState(() {
      _stickerCatalog = stickers;
    });
  }

  void _resetLocalState() {
    _textController.clear();
    _appliedInitialComposerText = false;
  }

  void _handleUserSessionChanged() {
    _scheduleSessionSync();
  }

  void _handleAuthSessionChanged() {
    _scheduleSessionSync();
  }

  void _scheduleSessionSync() {
    if (_sessionSyncScheduled) {
      return;
    }
    _sessionSyncScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionSyncScheduled = false;
      if (!mounted) {
        return;
      }
      _runSessionSync();
    });
  }

  void _runSessionSync() {
    final isLoggingOut = _authVm?.logoutInProgress ?? false;
    if (isLoggingOut) {
      _syncSession(null, null);
      return;
    }

    final me = _userVm?.me;
    final vmFamilyId = _userVm?.familyId;
    final familyId = widget.initialFamilyId ?? vmFamilyId;
    _syncSession(me, familyId);
  }

  void _applyInitialComposerTextIfNeeded() {
    if (_appliedInitialComposerText) {
      return;
    }

    final text = widget.initialComposerText?.trim() ?? '';
    if (text.isEmpty) {
      return;
    }

    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _appliedInitialComposerText = true;
  }

  void _syncSession(AppUser? me, String? familyId) {
    final normalizedUid = me?.uid.trim() ?? '';
    final normalizedFamilyId = familyId?.trim() ?? '';

    if (normalizedUid.isEmpty || normalizedFamilyId.isEmpty) {
      final hadSession = _boundUid != null || _boundFamilyId != null;
      _boundUid = null;
      _boundFamilyId = null;
      if (!hadSession) {
        return;
      }

      _resetLocalState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        context.read<FamilyGroupChatVm>().clearFamily();
      });
      return;
    }

    final sessionChanged =
        _boundUid != normalizedUid || _boundFamilyId != normalizedFamilyId;
    if (!sessionChanged) {
      _applyInitialComposerTextIfNeeded();
      return;
    }

    _boundUid = normalizedUid;
    _boundFamilyId = normalizedFamilyId;
    _resetLocalState();
    _applyInitialComposerTextIfNeeded();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final vm = context.read<FamilyGroupChatVm>();
      vm.bindFamily(normalizedFamilyId);
      unawaited(vm.clearChatNotificationIfNeeded(uid: normalizedUid));
    });
  }

  void _showSendError(Object error) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).familyChatSendFailed('$error'),
        ),
      ),
    );
  }

  Future<bool> _runChatAction(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } catch (error) {
      _showSendError(error);
      return false;
    }
  }

  void _insertEmoji(String emoji) {
    final value = _textController.value;
    final selection = value.selection;
    if (!selection.isValid) {
      final nextText = '${value.text}$emoji';
      _textController.value = TextEditingValue(
        text: nextText,
        selection: TextSelection.collapsed(offset: nextText.length),
      );
      return;
    }

    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(0, value.text.length);
    final nextText = value.text.replaceRange(start, end, emoji);
    final nextOffset = start + emoji.length;
    _textController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
    );
    _inputFocusNode.requestFocus();
  }

  Future<void> _showEmojiPicker() async {
    _inputFocusNode.unfocus();
    final emoji = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) =>
          const FamilyChatEmojiPickerSheet(items: kFamilyChatQuickEmojis),
    );
    if (emoji == null || emoji.isEmpty) {
      return;
    }
    _insertEmoji(emoji);
  }

  Future<void> _showStickerPicker(AppUser me) async {
    final sticker = await showModalBottomSheet<FamilyChatSticker>(
      context: context,
      showDragHandle: true,
      builder: (_) => FamilyChatStickerPickerSheet(items: _stickerCatalog),
    );
    if (sticker == null) {
      return;
    }

    await _runChatAction(
      () => context.read<FamilyGroupChatVm>().sendStickerMessage(
        sender: me,
        stickerId: sticker.id,
        clientMessageId: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    );
  }

  Future<bool> _sendMessageText(AppUser me, String text) {
    return _runChatAction(
      () => context.read<FamilyGroupChatVm>().sendTextMessage(
        sender: me,
        text: text,
        clientMessageId: DateTime.now().microsecondsSinceEpoch.toString(),
      ),
    );
  }

  Future<void> _retryMessage(AppUser me, FamilyChatMessage message) async {
    await _runChatAction(
      () => context.read<FamilyGroupChatVm>().retryMessage(
        sender: me,
        message: message,
      ),
    );
  }

  Future<void> _pickAndSendImage(AppUser me) async {
    _inputFocusNode.unfocus();
    await _runChatAction(
      () => context.read<FamilyGroupChatVm>().pickAndSendImage(sender: me),
    );
  }

  void _sendMessage(AppUser me) {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      return;
    }

    _textController.clear();
    unawaited(() async {
      final sent = await _sendMessageText(me, text);
      if (sent || !mounted || _textController.text.trim().isNotEmpty) {
        return;
      }

      _textController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }());
  }

  void _sendQuickReaction(AppUser me) {
    unawaited(
      _runChatAction(
        () => context.read<FamilyGroupChatVm>().sendQuickReaction(sender: me),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chatBackground = familyChatBackgroundColor(scheme);
    final chatSurface = familyChatSurfaceColor(scheme);

    final me = context.select<UserVm, AppUser?>((vm) => vm.me);
    final vmFamilyId = context.select<UserVm, String?>((vm) => vm.familyId);
    final familyId = widget.initialFamilyId ?? vmFamilyId;

    if (me == null || familyId == null || familyId.trim().isEmpty) {
      return _FamilyChatLoadingScaffold(
        title: AppLocalizations.of(context).familyChatLoadingTitle,
      );
    }

    final membersStream = context
        .select<FamilyGroupChatVm, Stream<List<FamilyChatMember>>?>(
          (vm) => vm.membersStream,
        );
    final messagesStream = context
        .select<FamilyGroupChatVm, Stream<List<FamilyChatMessage>>?>(
          (vm) => vm.messagesStream,
        );
    final isUploadingMedia = context.select<FamilyGroupChatVm, bool>(
      (vm) => vm.isUploadingMedia,
    );

    if (membersStream == null || messagesStream == null) {
      return _FamilyChatLoadingScaffold(
        title: AppLocalizations.of(context).familyChatLoadingTitle,
      );
    }

    return StreamBuilder<List<FamilyChatMember>>(
      stream: membersStream,
      builder: (context, membersSnapshot) {
        final members = membersSnapshot.data ?? const <FamilyChatMember>[];
        final isMembersLoading =
            membersSnapshot.connectionState == ConnectionState.waiting &&
            members.isEmpty;

        final memberNamesByUid = <String, String>{
          for (final member in members) member.uid: member.displayName,
        };

        return Scaffold(
          backgroundColor: chatBackground,
          appBar: AppBar(
            backgroundColor: chatSurface,
            foregroundColor: scheme.onSurface,
            elevation: 0.5,
            titleSpacing: 12,
            title: FamilyChatHeader(
              members: members,
              myUid: me.uid,
              isLoading: isMembersLoading,
            ),
          ),
          body: Column(
            children: [
              FamilyChatMembersBar(
                members: members,
                myUid: me.uid,
                isLoading: isMembersLoading,
              ),
              Expanded(
                child: FamilyChatMessagesView(
                  messagesStream: messagesStream,
                  myUid: me.uid,
                  memberNamesByUid: memberNamesByUid,
                  stickerCatalog: _stickerCatalog,
                  onRetryMessage: (message) => _retryMessage(me, message),
                ),
              ),
              FamilyChatComposer(
                controller: _textController,
                focusNode: _inputFocusNode,
                onSend: () => _sendMessage(me),
                onQuickReaction: () => _sendQuickReaction(me),
                onPickImage: () => _pickAndSendImage(me),
                onPickEmoji: _showEmojiPicker,
                onPickSticker: () => _showStickerPicker(me),
                isUploadingMedia: isUploadingMedia,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FamilyChatLoadingScaffold extends StatelessWidget {
  const _FamilyChatLoadingScaffold({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: familyChatBackgroundColor(scheme),
      appBar: AppBar(
        backgroundColor: familyChatSurfaceColor(scheme),
        foregroundColor: scheme.onSurface,
        elevation: 0.5,
        title: Text(title),
      ),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
