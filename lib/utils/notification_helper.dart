import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/notification_type.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/notification_modal.dart';

class Notify {
  /// Dialog 1 nút "Tiếp tục" (success/info/error)
  static Future<void> show(
    BuildContext context, {
    required DialogType type,
    required String title,
    required String message,
    bool barrierDismissible = false,
    VoidCallback? onConfirm,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => NotificationModal(
        // chặn tap nền nếu barrierDismissible = false
        onBackgroundTap: barrierDismissible ? null : () {},
        child: NotificationDialog(
          type: type,
          title: title,
          message: message,
          onConfirm: onConfirm,
        ),
      ),
    );
  }

  /// Confirm warning (Xác nhận / Hủy) trả bool
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    bool barrierDismissible = false,
  }) async {
    final completer = Completer<bool>();

    await showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => NotificationModal(
        // bấm nền => coi như Hủy
        onBackgroundTap: () {
          if (!completer.isCompleted) completer.complete(false);
          Navigator.of(context, rootNavigator: true).pop();
        },
        child: NotificationDialog(
          type: DialogType.warning,
          title: title,
          message: message,
          onConfirm: () {
            if (!completer.isCompleted) completer.complete(true);
          },
          onCancel: () {
            if (!completer.isCompleted) completer.complete(false);
          },
        ),
      ),
    );

    if (!completer.isCompleted) completer.complete(false);
    return completer.future;
  }
}
