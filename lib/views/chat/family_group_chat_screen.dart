import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/repositories/chat/family_chat_repository.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

bool _looksLikeOpaqueIdentifier(String raw) {
  final text = raw.trim();
  if (text.isEmpty || text.contains('@') || text.contains(' ')) {
    return false;
  }

  final normalized = text.replaceAll(RegExp(r'[-_]'), '');
  if (normalized.length < 16) {
    return false;
  }

  final hasLetter = RegExp(r'[A-Za-z]').hasMatch(normalized);
  final hasDigit = RegExp(r'\d').hasMatch(normalized);
  final onlyKeyChars = RegExp(r'^[A-Za-z0-9]+$').hasMatch(normalized);
  return hasLetter && hasDigit && onlyKeyChars;
}

String _sanitizeMemberLabel(String raw, AppLocalizations l10n) {
  final text = raw.trim();
  if (text.isEmpty || _looksLikeOpaqueIdentifier(text)) {
    return l10n.familyChatMemberFallback;
  }
  return text;
}

class FamilyGroupChatScreen extends StatefulWidget {
  final String? initialFamilyId;
  final String? initialMessageId;
  final String? initialComposerText;

  const FamilyGroupChatScreen({
    super.key,
    this.initialFamilyId,
    this.initialMessageId,
    this.initialComposerText,
  });

  @override
  State<FamilyGroupChatScreen> createState() => _FamilyGroupChatScreenState();
}

class _FamilyGroupChatScreenState extends State<FamilyGroupChatScreen> {
  final FamilyChatRepository _repo = FamilyChatRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final TextEditingController _textController = TextEditingController();

  bool _clearedChatNotification = false;
  bool _appliedInitialComposerText = false;
  String? _activeFamilyId;
  Stream<List<FamilyChatMember>>? _membersStream;
  Stream<List<FamilyChatMessage>>? _messagesStream;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _resetLocalState() {
    _textController.clear();
    _appliedInitialComposerText = false;
  }

  void _applyInitialComposerTextIfNeeded() {
    if (_appliedInitialComposerText) return;

    final text = widget.initialComposerText?.trim() ?? '';
    if (text.isEmpty) return;

    _textController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _appliedInitialComposerText = true;
  }

  void _ensureChatStreams(String familyId) {
    final hasActiveStreams = _membersStream != null && _messagesStream != null;
    if (_activeFamilyId == familyId && hasActiveStreams) {
      return;
    }

    _activeFamilyId = familyId;
    _membersStream = _repo.watchMembers(familyId);
    _messagesStream = _repo.watchMessages(familyId);
    _clearedChatNotification = false;
    _resetLocalState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearChatNotificationIfNeeded(familyId);
    });
  }

  Future<void> _clearChatNotificationIfNeeded(String familyId) async {
    if (_clearedChatNotification) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    try {
      await _notificationRepo.deleteChatNotificationsForFamily(
        uid: uid,
        familyId: familyId,
      );

      await _notificationRepo.markFamilyChatRead(familyId: familyId, uid: uid);

      _clearedChatNotification = true;
      debugPrint(
        '[FamilyGroupChatScreen] cleared chat notifications for familyId=$familyId',
      );
    } catch (e, st) {
      debugPrint('[FamilyGroupChatScreen] clear chat notifications error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<bool> _sendMessageText(String text) async {
    final me = context.read<UserVm>().me;
    final familyId = _activeFamilyId;
    if (me == null || familyId == null || familyId.isEmpty) {
      return false;
    }

    final clientMessageId =
        DateTime.now().microsecondsSinceEpoch.toString();

    try {
      await _repo.sendTextMessage(
        familyId: familyId,
        sender: me,
        text: text,
        clientMessageId: clientMessageId,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).familyChatSendFailed('$e'),
          ),
        ),
      );
      return false;
    }
  }

  Future<void> _retryMessage(FamilyChatMessage message) async {
    await _sendMessageText(message.text);
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    unawaited(() async {
      final sent = await _sendMessageText(text);
      if (sent || !mounted || _textController.text.trim().isNotEmpty) {
        return;
      }

      _textController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }());
  }

  @override
  Widget build(BuildContext context) {
    final me = context.select<UserVm, AppUser?>((vm) => vm.me);
    final vmFamilyId = context.select<UserVm, String?>((vm) => vm.familyId);
    final familyId = widget.initialFamilyId ?? vmFamilyId;

    if (me == null || familyId == null || familyId.isEmpty) {
      _resetLocalState();
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0.5,
          title: Text(AppLocalizations.of(context).familyChatLoadingTitle),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _ensureChatStreams(familyId);
    _applyInitialComposerTextIfNeeded();

    final membersStream = _membersStream!;
    final messagesStream = _messagesStream!;

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
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0.5,
            titleSpacing: 12,
            title: _ChatHeader(
              members: members,
              myUid: me.uid,
              isLoading: isMembersLoading,
            ),
          ),
          body: Column(
            children: [
              _MembersBar(
                members: members,
                myUid: me.uid,
                isLoading: isMembersLoading,
              ),
              Expanded(
                child: _MessagesView(
                  messagesStream: messagesStream,
                  myUid: me.uid,
                  memberNamesByUid: memberNamesByUid,
                  onRetryMessage: _retryMessage,
                ),
              ),
              _Composer(controller: _textController, onSend: _sendMessage),
            ],
          ),
        );
      },
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.members,
    required this.myUid,
    required this.isLoading,
  });

  final List<FamilyChatMember> members;
  final String myUid;
  final bool isLoading;

  String _safeDisplayName(FamilyChatMember member, AppLocalizations l10n) {
    if (member.uid == myUid) return l10n.familyChatYou;
    return _sanitizeMemberLabel(member.displayName, l10n);
  }

  String _memberSummary(AppLocalizations l10n) {
    if (isLoading) return l10n.familyChatLoadingMembers;
    if (members.isEmpty) return l10n.familyChatNoMembersFound;

    final names = members
        .map((member) => _safeDisplayName(member, l10n))
        .toList(growable: false);

    const maxVisible = 3;
    if (names.length <= maxVisible) {
      return names.join(', ');
    }

    final visible = names.take(maxVisible).join(', ');
    return l10n.familyChatMemberCountOverflow(
      visible,
      names.length - maxVisible,
    );
  }

  String _memberCountLabel(AppLocalizations l10n) {
    if (members.isEmpty) return '';
    if (members.length == 1) return l10n.familyChatOneMember;
    return l10n.familyChatManyMembers(members.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countLabel = _memberCountLabel(l10n);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.groups_rounded,
            color: Color(0xFF1D4ED8),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.familyChatTitleLarge,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _memberSummary(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (countLabel.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Text(
              countLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF1D4ED8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _MembersBar extends StatelessWidget {
  const _MembersBar({
    required this.members,
    required this.myUid,
    required this.isLoading,
  });

  final List<FamilyChatMember> members;
  final String myUid;
  final bool isLoading;

  String _safeDisplayName(String rawName, AppLocalizations l10n) {
    return _sanitizeMemberLabel(rawName, l10n);
  }

  String _initialOf(String rawName, AppLocalizations l10n) {
    final text = _sanitizeMemberLabel(rawName, l10n);
    if (text.isEmpty) return '?';
    return text.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (isLoading && members.isEmpty) {
      return const SizedBox(
        height: 52,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (members.isEmpty) {
      return const SizedBox(height: 8);
    }

    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: members.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final member = members[index];
          final isMe = member.uid == myUid;
          final roleColor = member.role == 'parent'
              ? const Color(0xFFF59E0B)
              : const Color(0xFF38BDF8);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFFDBEAFE) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: roleColor.withAlpha(30),
                  child: Text(
                    _initialOf(member.displayName, l10n),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isMe
                      ? l10n.familyChatYou
                      : _safeDisplayName(member.displayName, l10n),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessagesView extends StatelessWidget {
  const _MessagesView({
    required this.messagesStream,
    required this.myUid,
    required this.memberNamesByUid,
    required this.onRetryMessage,
  });

  final Stream<List<FamilyChatMessage>> messagesStream;
  final String myUid;
  final Map<String, String> memberNamesByUid;
  final ValueChanged<FamilyChatMessage> onRetryMessage;

  bool _shouldDisplayMessage(FamilyChatMessage message) {
    if (message.text.trim().isEmpty) {
      return false;
    }

    final verifyState = message.verifyState.trim();
    if (verifyState == 'failed') {
      return message.senderUid == myUid;
    }

    if (verifyState == 'pending') {
      return message.senderUid == myUid;
    }

    return true;
  }

  String _resolveSenderName(FamilyChatMessage message, AppLocalizations l10n) {
    final currentName = memberNamesByUid[message.senderUid]?.trim();
    if (currentName != null && currentName.isNotEmpty) {
      return _sanitizeMemberLabel(currentName, l10n);
    }

    final fallback = message.senderName.trim();
    if (fallback.isNotEmpty) {
      return _sanitizeMemberLabel(fallback, l10n);
    }

    return l10n.familyChatMemberFallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return StreamBuilder<List<FamilyChatMessage>>(
      stream: messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              l10n.familyChatCannotLoadMessages,
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          );
        }

        final messages = (snapshot.data ?? const <FamilyChatMessage>[])
            .where(_shouldDisplayMessage)
            .toList(growable: false);
        final hasAny = messages.isNotEmpty;

        if (!hasAny) {
          return Center(
            child: Text(
              l10n.familyChatNoMessagesYet,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMine = message.senderUid == myUid;

            return Padding(
              key: ValueKey('server-${message.id}'),
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: _MessageBubble(
                  message: message,
                  isMine: isMine,
                  displaySenderName: _resolveSenderName(message, l10n),
                  onRetry: isMine && message.verifyState == 'failed'
                      ? () => onRetryMessage(message)
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.displaySenderName,
    required this.onRetry,
  });

  final FamilyChatMessage message;
  final bool isMine;
  final String displaySenderName;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final createdAtText = message.createdAt == null
        ? '--:--'
        : DateFormat('HH:mm').format(message.createdAt!.toLocal());
    final isPending = isMine && message.hasPendingWrites;
    final isFailed = isMine && message.verifyState == 'failed';
    final bubbleColor = isFailed
        ? const Color(0xFFFEF2F2)
        : isPending
        ? const Color(0xFFEFF6FF)
        : isMine
        ? const Color(0xFFDCFCE7)
        : Colors.white;
    final borderColor = isFailed
        ? const Color(0xFFFECACA)
        : isPending
        ? const Color(0xFFBFDBFE)
        : isMine
        ? const Color(0xFFBBF7D0)
        : const Color(0xFFE2E8F0);
    final statusText = isFailed
        ? l10n.familyChatStatusFailed
        : isPending
        ? l10n.familyChatStatusSending
        : null;
    final statusColor = isFailed
        ? const Color(0xFFDC2626)
        : const Color(0xFF64748B);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine) ...[
              Text(
                displaySenderName,
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              message.text,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  createdAtText,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
                if (statusText != null) ...[
                  const SizedBox(width: 8),
                  if (isFailed)
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: Color(0xFFDC2626),
                    )
                  else
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (isFailed && onRetry != null) ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: onRetry,
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final canSend = value.text.trim().isNotEmpty;

            return Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => canSend ? onSend() : null,
                    style: const TextStyle(color: Color(0xFF0F172A)),
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: l10n.familyChatTypeMessageHint,
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF60A5FA)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: canSend
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: canSend
                        ? const [
                            BoxShadow(
                              color: Color(0x332563EB),
                              blurRadius: 14,
                              offset: Offset(0, 6),
                            ),
                          ]
                        : const [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSend ? onSend : null,
                      borderRadius: BorderRadius.circular(16),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
