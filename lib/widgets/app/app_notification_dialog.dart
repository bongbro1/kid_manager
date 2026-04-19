// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/widgets/common/notification_modal.dart';

class NotificationDialog extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const NotificationDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required DialogType type,
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => NotificationModal(
        child: NotificationDialog(
          type: type,
          title: title,
          message: message,
          confirmText: confirmText,
          cancelText: cancelText,
          onConfirm: onConfirm,
          onCancel: onCancel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = DialogConfig.from(type);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final messageColor = theme.brightness == Brightness.dark
        ? colorScheme.onSurface.withValues(alpha: 0.9)
        : colorScheme.onSurfaceVariant;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dialogPadding = context.adaptiveHorizontalPadding(
          compact: 16,
          regular: 24,
        );
        return Padding(
          padding: EdgeInsets.all(dialogPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: constraints.maxHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _IconSection(config: config),
                const SizedBox(height: 10),

                /// TITLE
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                /// MESSAGE
                Flexible(
                  fit: FlexFit.loose,
                  child: SingleChildScrollView(
                    child: Text(
                      message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: messageColor,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                _ActionSection(
                  type: type,
                  primaryColor: config.primary,
                  confirmText: confirmText,
                  cancelText: cancelText,
                  onConfirm: onConfirm,
                  onCancel: onCancel,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IconSection extends StatelessWidget {
  final DialogConfig config;

  const _IconSection({required this.config});

  @override
  Widget build(BuildContext context) {
    return Center(child: config.iconBuilder());
  }
}

class _ActionSection extends StatelessWidget {
  final DialogType type;
  final Color primaryColor;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _ActionSection({
    required this.type,
    required this.primaryColor,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  void _close(BuildContext context, VoidCallback? callback) {
    Navigator.pop(context);
    callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWarning = type == DialogType.warning;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final buttonTextStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

    if (isWarning) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(colorScheme.primary),
                elevation: const MaterialStatePropertyAll(0),
                overlayColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                shadowColor: const MaterialStatePropertyAll(Colors.transparent),
                surfaceTintColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                textStyle: MaterialStatePropertyAll(buttonTextStyle),
                splashFactory: NoSplash.splashFactory,
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              onPressed: () => _close(context, onConfirm),
              child: Text(
                l10n.confirmButton,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colorScheme.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(
                  isDark ? colorScheme.onSurface : const Color(0xFFF3F4F6),
                ),
                elevation: const MaterialStatePropertyAll(0),
                overlayColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                shadowColor: const MaterialStatePropertyAll(Colors.transparent),
                surfaceTintColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                textStyle: MaterialStatePropertyAll(buttonTextStyle),
                splashFactory: NoSplash.splashFactory,
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              onPressed: () => _close(context, onCancel),
              child: Text(
                l10n.cancelButton,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF111827)),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ButtonStyle(
          backgroundColor: MaterialStatePropertyAll(colorScheme.primary),
          elevation: const MaterialStatePropertyAll(0),
          overlayColor: const MaterialStatePropertyAll(Colors.transparent),
          shadowColor: const MaterialStatePropertyAll(Colors.transparent),
          surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
          textStyle: MaterialStatePropertyAll(buttonTextStyle),
          splashFactory: NoSplash.splashFactory,
          padding: const MaterialStatePropertyAll(
            EdgeInsets.symmetric(vertical: 14),
          ),
          shape: MaterialStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        onPressed: () => _close(context, onConfirm),
        child: Text(
          l10n.continueButton,
          style: TextStyle(color: colorScheme.onPrimary),
        ),
      ),
    );
  }
}
