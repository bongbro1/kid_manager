import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FamilyChatSkeletonScaffold extends StatelessWidget {
  const FamilyChatSkeletonScaffold({
    super.key,
    required this.title,
    required this.chatBackground,
    required this.chatSurface,
  });

  final String title;
  final Color chatBackground;
  final Color chatSurface;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Skeletonizer(
      enabled: true,
      child: Scaffold(
        backgroundColor: chatBackground,
        appBar: AppBar(
          backgroundColor: chatSurface,
          foregroundColor: scheme.onSurface,
          elevation: 0.5,
          titleSpacing: 12,
          title: const _FamilyChatHeaderSkeleton(),
        ),
        body: const Column(
          children: [
            _FamilyChatMembersBarSkeleton(),
            Expanded(
              child: _FamilyChatMessagesSkeleton(),
            ),
            _FamilyChatComposerSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _FamilyChatHeaderSkeleton extends StatelessWidget {
  const _FamilyChatHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const CircleAvatar(radius: 20, child: Icon(Icons.person)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Family chat',
                style: textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '3 members online',
                style: textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FamilyChatMembersBarSkeleton extends StatelessWidget {
  const _FamilyChatMembersBarSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const SizedBox(
          width: 60,
          child: Column(
            children: [
              CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
              SizedBox(height: 8),
              Text(
                'Nguyen',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyChatMessagesSkeleton extends StatelessWidget {
  const _FamilyChatMessagesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      children: const [
        _MessageBubbleSkeleton(
          isMine: false,
          sender: 'Mom',
          lines: ['Hello family', 'How is everyone today?'],
        ),
        SizedBox(height: 12),
        _MessageBubbleSkeleton(
          isMine: true,
          sender: 'Me',
          lines: ['I am studying now'],
        ),
        SizedBox(height: 12),
        _MessageBubbleSkeleton(
          isMine: false,
          sender: 'Dad',
          lines: ['Remember dinner', 'And finish homework'],
        ),
        SizedBox(height: 12),
        _MessageBubbleSkeleton(
          isMine: true,
          sender: 'Me',
          lines: ['Okay'],
        ),
      ],
    );
  }
}

class _MessageBubbleSkeleton extends StatelessWidget {
  const _MessageBubbleSkeleton({
    required this.isMine,
    required this.sender,
    required this.lines,
  });

  final bool isMine;
  final String sender;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment:
          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMine) ...[
          const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 14)),
          const SizedBox(width: 8),
        ],
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine) ...[
                  Text(
                    sender,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                ],
                for (final line in lines) ...[
                  Text(line),
                  const SizedBox(height: 4),
                ],
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '18:40',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FamilyChatComposerSkeleton extends StatelessWidget {
  const _FamilyChatComposerSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(color: scheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 18, child: Icon(Icons.add)),
            const SizedBox(width: 8),
            const CircleAvatar(radius: 18, child: Icon(Icons.image)),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text('Type a message...'),
              ),
            ),
            const SizedBox(width: 8),
            const CircleAvatar(radius: 20, child: Icon(Icons.send)),
          ],
        ),
      ),
    );
  }
}