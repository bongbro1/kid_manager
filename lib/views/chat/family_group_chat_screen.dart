import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/chat/family_chat_member.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/repositories/chat/family_chat_repository.dart';
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
  const FamilyGroupChatScreen({super.key});

  @override
  State<FamilyGroupChatScreen> createState() => _FamilyGroupChatScreenState();
}

class _FamilyGroupChatScreenState extends State<FamilyGroupChatScreen> {
  final FamilyChatRepository _repo = FamilyChatRepository();
  final TextEditingController _textController = TextEditingController();
  final List<LocalPendingChatMessage> _pendingMessages = [];
  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _resetLocalState() {
    _textController.clear();
    _pendingMessages.clear();
  }
  void _sendMessage({
    required AppUser me,
    required String familyId,
  }) {
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
    final familyId = context.select<UserVm, String?>((vm) => vm.familyId);

    if (me == null || familyId == null) {
      _resetLocalState();
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F172A),
          elevation: 0.5,
          title: const Text('Nhóm chat gia đình'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }



    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        titleSpacing: 16,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Realtime group chat',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _MembersBar(
            membersStream: _repo.watchMembers(familyId),
            myUid: me.uid,
          ),
          Expanded(
            child: _MessagesView(
              messagesStream: _repo.watchMessages(familyId),
              myUid: me.uid,
              pendingMessages: _pendingMessages,
            ),
          ),
          _Composer(
            controller: _textController,
            onSend: () => _sendMessage(me: me, familyId: familyId),
          ),
        ],
      ),
    );
  }
}

class _MembersBar extends StatelessWidget {
  const _MembersBar({
    required this.membersStream,
    required this.myUid,
  });

  final Stream<List<FamilyChatMember>> membersStream;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<List<FamilyChatMember>>(
        stream: membersStream,
        builder: (context, snapshot) {
          final members = snapshot.data ?? const <FamilyChatMember>[];
          if (members.isEmpty) {
            return const SizedBox.shrink();
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: members.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final member = members[index];
              final isMe = member.uid == myUid;
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: member.role == 'parent'
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF38BDF8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isMe ? 'You' : member.displayName,
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
  });

  final Stream<List<FamilyChatMessage>> messagesStream;
  final String myUid;
  final List<LocalPendingChatMessage> pendingMessages;

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

        return ListView(
          reverse: true,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          children: [
            ...pendingMessages.map(
                  (m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _LocalPendingBubble(message: m),
                ),
              ),
            ),
            ...messages.map(
                  (message) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: message.senderUid == myUid
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: _MessageBubble(
                    message: message,
                    isMine: message.senderUid == myUid,
                  ),
                ),
              ),
            ),
          ],
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

    final statusColor = message.failed
        ? const Color(0xFFDC2626)
        : const Color(0xFF64748B);

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
  });

  final FamilyChatMessage message;
  final bool isMine;

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
            color: isMine
                ? const Color(0xFFBBF7D0)
                : const Color(0xFFE2E8F0),
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
                message.senderName,
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