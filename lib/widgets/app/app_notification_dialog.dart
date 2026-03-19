// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/widgets/common/notification_modal.dart';

class NotificationDialog extends StatelessWidget {
  final DialogType type;
  final String title;
  final String message;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const NotificationDialog({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.onConfirm,
    this.onCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required DialogType type,
    required String title,
    required String message,
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

    return Padding(
      padding: const EdgeInsets.all(24),
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
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          /// MESSAGE
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? colorScheme.onSurface.withOpacity(0.9)
                  : colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 24),

          _ActionSection(
            type: type,
            primaryColor: config.primary,
            onConfirm: onConfirm,
            onCancel: onCancel,
          ),
        ],
      ),
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
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const _ActionSection({
    required this.type,
    required this.primaryColor,
    this.onConfirm,
    this.onCancel,
  });

  void _close(BuildContext context, VoidCallback? callback) {
    Navigator.pop(context);
    callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isWarning = type == DialogType.warning;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    if (isWarning) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 56,
            child: ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStatePropertyAll(
                  isDark ? colorScheme.primary : const Color(0xFF2563EB),
                ),
                elevation: const MaterialStatePropertyAll(0),
                overlayColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                shadowColor: const MaterialStatePropertyAll(Colors.transparent),
                surfaceTintColor: const MaterialStatePropertyAll(
                  Colors.transparent,
                ),
                splashFactory: NoSplash.splashFactory,
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              onPressed: () => _close(context, onConfirm),
              child: Text(
                "Xác nhận",
                style: textTheme.labelLarge?.copyWith(
                  color: isDark ? colorScheme.onPrimary : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 56,
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
                splashFactory: NoSplash.splashFactory,
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
              onPressed: () => _close(context, onCancel),
              child: Text(
                "Hủy",
                style: textTheme.labelLarge?.copyWith(
                  color: isDark ? colorScheme.primary : const Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
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
          backgroundColor: MaterialStatePropertyAll(
            isDark ? colorScheme.primary : const Color(0xFFF1F5F9),
          ),
          elevation: const MaterialStatePropertyAll(0),
          overlayColor: const MaterialStatePropertyAll(Colors.transparent),
          shadowColor: const MaterialStatePropertyAll(Colors.transparent),
          surfaceTintColor: const MaterialStatePropertyAll(Colors.transparent),
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
          "Tiếp tục",
          style: textTheme.labelLarge?.copyWith(
            color: isDark ? colorScheme.onPrimary : const Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}