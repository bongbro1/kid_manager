import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/chat/family_chat_message.dart';
import 'package:kid_manager/views/chat/family_chat_assets.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_ui_utils.dart';
import 'package:kid_manager/widgets/app/app_image_modal.dart';

class FamilyChatMessagesView extends StatelessWidget {
  const FamilyChatMessagesView({
    super.key,
    required this.messagesStream,
    required this.myUid,
    required this.memberNamesByUid,
    required this.stickerCatalog,
    required this.onRetryMessage,
  });

  final Stream<List<FamilyChatMessage>> messagesStream;
  final String myUid;
  final Map<String, String> memberNamesByUid;
  final List<FamilyChatSticker> stickerCatalog;
  final Future<void> Function(FamilyChatMessage message) onRetryMessage;

  bool _shouldDisplayMessage(FamilyChatMessage message) {
    final hasVisiblePayload =
        message.text.trim().isNotEmpty ||
        (message.imageUrl?.trim().isNotEmpty ?? false) ||
        (message.stickerId?.trim().isNotEmpty ?? false);
    if (!hasVisiblePayload) {
      return false;
    }

    final verifyState = message.verifyState.trim();
    if (verifyState == 'failed' || verifyState == 'pending') {
      return message.senderUid == myUid;
    }

    return true;
  }

  String _resolveSenderName(FamilyChatMessage message, AppLocalizations l10n) {
    final currentName = memberNamesByUid[message.senderUid]?.trim();
    if (currentName != null && currentName.isNotEmpty) {
      return sanitizeMemberLabel(currentName, l10n);
    }

    final fallback = message.senderName.trim();
    if (fallback.isNotEmpty) {
      return sanitizeMemberLabel(fallback, l10n);
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

        if (messages.isEmpty) {
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
                alignment:
                    isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: FamilyChatMessageBubble(
                  message: message,
                  isMine: isMine,
                  stickerCatalog: stickerCatalog,
                  displaySenderName: _resolveSenderName(message, l10n),
                  onRetry: isMine && message.verifyState == 'failed'
                      ? () => unawaited(onRetryMessage(message))
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

class FamilyChatMessageBubble extends StatelessWidget {
  const FamilyChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    required this.stickerCatalog,
    required this.displaySenderName,
    required this.onRetry,
  });

  final FamilyChatMessage message;
  final bool isMine;
  final List<FamilyChatSticker> stickerCatalog;
  final String displaySenderName;
  final VoidCallback? onRetry;

  bool get _isImage =>
      message.type == 'image' && (message.imageUrl?.trim().isNotEmpty ?? false);

  bool get _isSticker =>
      message.type == 'sticker' &&
      ((message.stickerId?.trim().isNotEmpty ?? false) ||
          message.text.trim().isNotEmpty);

  Future<void> _openImagePreview(BuildContext context) {
    final imageUrl = message.imageUrl;
    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return Future<void>.value();
    }

    return showImageModal(
      context,
      images: <ImageProvider>[CachedNetworkImageProvider(imageUrl)],
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (_isImage) {
      final imageUrl = message.imageUrl!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => _openImagePreview(context),
            borderRadius: BorderRadius.circular(14),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 240,
                  maxHeight: 280,
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180,
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180,
                    color: const Color(0xFFE2E8F0),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (message.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              message.text,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ],
        ],
      );
    }

    if (_isSticker) {
      return FamilyChatStickerMessageContent(
        message: message,
        stickerCatalog: stickerCatalog,
      );
    }

    return Text(
      message.text,
      style: const TextStyle(
        color: Color(0xFF0F172A),
        fontSize: 15,
        height: 1.35,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sticker = findFamilyChatStickerById(
      message.stickerId,
      catalog: stickerCatalog,
    );
    final isAssetSticker = message.type == 'sticker' && sticker != null;
    final createdAtText = message.createdAt == null
        ? '--:--'
        : DateFormat('HH:mm').format(message.createdAt!.toLocal());
    final isPending = isMine && message.hasPendingWrites;
    final isFailed = isMine && message.verifyState == 'failed';
    final bubbleColor = isAssetSticker
        ? Colors.transparent
        : isFailed
            ? const Color(0xFFFEF2F2)
            : isPending
                ? const Color(0xFFEFF6FF)
                : isMine
                    ? const Color(0xFFDCFCE7)
                    : Colors.white;
    final borderColor = isAssetSticker
        ? Colors.transparent
        : isFailed
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
    final statusColor =
        isFailed ? const Color(0xFFDC2626) : const Color(0xFF64748B);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isAssetSticker ? 0 : 12,
          vertical: isAssetSticker ? 0 : 10,
        ),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
          border: Border.all(
            color: borderColor,
            width: isAssetSticker ? 0 : 1,
          ),
          boxShadow: isAssetSticker
              ? const []
              : const [
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
            _buildMessageContent(context),
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

class FamilyChatStickerMessageContent extends StatelessWidget {
  const FamilyChatStickerMessageContent({
    super.key,
    required this.message,
    required this.stickerCatalog,
  });

  final FamilyChatMessage message;
  final List<FamilyChatSticker> stickerCatalog;

  @override
  Widget build(BuildContext context) {
    final sticker = findFamilyChatStickerById(
      message.stickerId,
      catalog: stickerCatalog,
    );
    if (sticker == null) {
      return Text(
        message.text.isEmpty ? '[Sticker]' : message.text,
        style: const TextStyle(
          fontSize: 32,
          height: 1,
        ),
      );
    }

    return FamilyChatStickerAssetPreview(
      assetPath: sticker.assetPath,
      semanticLabel: sticker.label,
      size: 120,
    );
  }
}

class FamilyChatStickerAssetPreview extends StatelessWidget {
  const FamilyChatStickerAssetPreview({
    super.key,
    required this.assetPath,
    required this.semanticLabel,
    required this.size,
  });

  final String assetPath;
  final String semanticLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(
                Icons.sticky_note_2_outlined,
                color: Color(0xFF94A3B8),
                size: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
