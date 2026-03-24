import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/views/chat/family_chat_assets.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_messages_view.dart';
import 'package:kid_manager/views/chat/family_group_chat/family_chat_ui_utils.dart';

class FamilyChatComposer extends StatelessWidget {
  const FamilyChatComposer({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onQuickReaction,
    required this.onPickImage,
    required this.onPickEmoji,
    required this.onPickSticker,
    required this.isUploadingMedia,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onQuickReaction;
  final VoidCallback onPickImage;
  final VoidCallback onPickEmoji;
  final VoidCallback onPickSticker;
  final bool isUploadingMedia;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = scheme.primary;
    final inputBorderColor = familyChatBorderColor(scheme);
    final focusedInputBorderColor = Color.alphaBlend(
      accentColor.withAlpha(scheme.brightness == Brightness.dark ? 120 : 90),
      inputBorderColor,
    );

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: BoxDecoration(
          color: familyChatSurfaceColor(scheme),
          border: Border(top: BorderSide(color: familyChatBorderColor(scheme))),
        ),
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            final canSend = value.text.trim().isNotEmpty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isUploadingMedia)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    FamilyChatComposerActionButton(
                      onTap: isUploadingMedia ? null : onPickImage,
                      child: Image.asset(
                        'assets/icons/chat_image.webp',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        color: accentColor,
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    FamilyChatComposerActionButton(
                      onTap: onPickSticker,
                      child: SvgPicture.asset(
                        'assets/icons/chat_sticker.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          accentColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: familyChatInputFillColor(scheme),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => canSend ? onSend() : null,
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontSize: 14,
                              height: 1.25,
                            ),
                            minLines: 1,
                            maxLines: 4,
                            textAlignVertical: TextAlignVertical.center,
                            decoration: InputDecoration(
                              hintText: 'Aa',
                              hintStyle: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              isDense: true,
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.fromLTRB(
                                14,
                                11,
                                14,
                                11,
                              ),
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: IconButton(
                                  splashRadius: 18,
                                  iconSize: 20,
                                  onPressed: onPickEmoji,
                                  icon: Icon(
                                    Icons.emoji_emotions_rounded,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(color: inputBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(22),
                                borderSide: BorderSide(
                                  color: focusedInputBorderColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FamilyChatComposerActionButton(
                      onTap: canSend ? onSend : onQuickReaction,
                      child: SvgPicture.asset(
                        canSend
                            ? 'assets/icons/send-message.svg'
                            : 'assets/icons/chat_like.svg',
                        width: 20,
                        height: 20,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          accentColor,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FamilyChatComposerActionButton extends StatelessWidget {
  const FamilyChatComposerActionButton({
    super.key,
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Opacity(opacity: isDisabled ? 0.45 : 1, child: child),
          ),
        ),
      ),
    );
  }
}

class FamilyChatEmojiPickerSheet extends StatelessWidget {
  const FamilyChatEmojiPickerSheet({super.key, required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: items
              .map(
                (emoji) => InkWell(
                  onTap: () => Navigator.of(context).pop(emoji),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: familyChatBackgroundColor(scheme),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: familyChatBorderColor(scheme)),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class FamilyChatStickerPickerSheet extends StatelessWidget {
  const FamilyChatStickerPickerSheet({super.key, required this.items});

  final List<FamilyChatSticker> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SafeArea(
        child: SizedBox(
          height: 140,
          child: Center(child: Text('No sticker assets configured')),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: GridView.builder(
          shrinkWrap: true,
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final sticker = items[index];
            return InkWell(
              onTap: () => Navigator.of(context).pop(sticker),
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: FamilyChatStickerAssetPreview(
                    assetPath: sticker.assetPath,
                    semanticLabel: sticker.label,
                    size: 72,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
