import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/repositories/chat/family_chat_repository.dart';
import 'package:kid_manager/repositories/notification_repository.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

class LocalPendingChatMessage {
  final String localId;
  final String text;
  final DateTime createdAt;
  final bool failed;

  const LocalPendingChatMessage({
    required this.localId,
    required this.text,
    required this.createdAt,
    this.failed = false,
  });

  LocalPendingChatMessage copyWith({bool? failed}) {
    return LocalPendingChatMessage(
      localId: localId,
      text: text,
      createdAt: createdAt,
      failed: failed ?? this.failed,
    );
  }
}

class FamilyGroupChatScreen extends StatefulWidget {
  final String? initialFamilyId;
  final String? initialMessageId;

  const FamilyGroupChatScreen({
    super.key,
    this.initialFamilyId,
    this.initialMessageId,
  });

  @override
  State<FamilyGroupChatScreen> createState() => _FamilyGroupChatScreenState();
}

class _FamilyGroupChatScreenState extends State<FamilyGroupChatScreen> {
  final FamilyChatRepository _repo = FamilyChatRepository();
  final NotificationRepository _notificationRepo = NotificationRepository();
  final TextEditingController _textController = TextEditingController();
  final List<LocalPendingChatMessage> _pendingMessages = [];

  bool _clearedChatNotification = false;
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
    _pendingMessages.clear();
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

      await _notificationRepo.markFamilyChatRead(
        familyId: familyId,
        uid: uid,
      );

      _clearedChatNotification = true;
      debugPrint('[FamilyGroupChatScreen] cleared chat notifications for familyId=$familyId');
    } catch (e, st) {
      debugPrint('[FamilyGroupChatScreen] clear chat notifications error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();

    final pending = LocalPendingChatMessage(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      text: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _pendingMessages.insert(0, pending);
    });

    _repo.sendTextMessage(text: text).then((_) {
      if (!mounted) return;
      setState(() {
        _pendingMessages.removeWhere((m) => m.localId == pending.localId);
      });
    }).catchError((e) {
      if (!mounted) return;

      setState(() {
        final index =
            _pendingMessages.indexWhere((m) => m.localId == pending.localId);
        if (index != -1) {
          _pendingMessages[index] =
              _pendingMessages[index].copyWith(failed: true);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    });
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
          title: const Text('Family group chat'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    _ensureChatStreams(familyId);

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
                  pendingMessages: _pendingMessages,
                  memberNamesByUid: memberNamesByUid,
                ),
              ),
              _Composer(
                controller: _textController,
                onSend: _sendMessage,
              ),
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

  String _safeDisplayName(FamilyChatMember member) {
    if (member.uid == myUid) return 'You';
    final text = member.displayName.trim();
    return text.isEmpty ? 'Member' : text;
  }

  String _memberSummary() {
    if (isLoading) return 'Loading members...';
    if (members.isEmpty) return 'No members found';

    final names = members.map(_safeDisplayName).toList(growable: false);

    const maxVisible = 3;
    if (names.length <= maxVisible) {
      return names.join(', ');
    }

    final visible = names.take(maxVisible).join(', ');
    return '$visible +${names.length - maxVisible}';
  }

  String _memberCountLabel() {
    if (members.isEmpty) return '';
    if (members.length == 1) return '1 member';
    return '${members.length} members';
  }

  @override
  Widget build(BuildContext context) {
    final countLabel = _memberCountLabel();

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
              const Text(
                'Family Group Chat',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _memberSummary(),
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

  String _safeDisplayName(String rawName) {
    final text = rawName.trim();
    return text.isEmpty ? 'Member' : text;
  }

  String _initialOf(String rawName) {
    final text = rawName.trim();
    if (text.isEmpty) return '?';
    return text.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
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
        separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                    _initialOf(member.displayName),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isMe ? 'You' : _safeDisplayName(member.displayName),
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
    required this.pendingMessages,
    required this.memberNamesByUid,
  });

  final Stream<List<FamilyChatMessage>> messagesStream;
  final String myUid;
  final List<LocalPendingChatMessage> pendingMessages;
  final Map<String, String> memberNamesByUid;

  String _resolveSenderName(FamilyChatMessage message) {
    final currentName = memberNamesByUid[message.senderUid]?.trim();
    if (currentName != null && currentName.isNotEmpty) {
      return currentName;
    }

    final fallback = message.senderName.trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'Member';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyChatMessage>>(
      stream: messagesStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Cannot load messages',
              style: TextStyle(color: Color(0xFFDC2626)),
            ),
          );
        }

        final messages = snapshot.data ?? const <FamilyChatMessage>[];
        final hasAny = messages.isNotEmpty || pendingMessages.isNotEmpty;

        if (!hasAny) {
          return const Center(
            child: Text(
              'No messages yet. Start the conversation.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          );
        }

        final pendingCount = pendingMessages.length;
        final totalCount = pendingCount + messages.length;

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            if (index < pendingCount) {
              final localMessage = pendingMessages[index];
              return Padding(
                key: ValueKey('local-${localMessage.localId}'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _LocalPendingBubble(message: localMessage),
                ),
              );
            }

            final message = messages[index - pendingCount];
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
                  displaySenderName: _resolveSenderName(message),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LocalPendingBubble extends StatelessWidget {
  const _LocalPendingBubble({
    required this.message,
  });

  final LocalPendingChatMessage message;

  @override
  Widget build(BuildContext context) {
    final statusText = message.failed ? 'failed' : 'sending...';

    final statusColor =
        message.failed ? const Color(0xFFDC2626) : const Color(0xFF64748B);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
          border: Border.all(color: const Color(0xFFBAE6FD)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.displaySenderName,
  });

  final FamilyChatMessage message;
  final bool isMine;
  final String displaySenderName;

  @override
  Widget build(BuildContext context) {
    final createdAtText = message.createdAt == null
        ? '--:--'
        : DateFormat('HH:mm').format(message.createdAt!.toLocal());

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFFDCFCE7) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: isMine ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
            Text(
              createdAtText,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(color: Color(0xFF0F172A)),
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF60A5FA)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: FilledButton(
                onPressed: onSend,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

