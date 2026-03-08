import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';

Future<void> showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onConfirm,
}) async {
  final rootCtx = Navigator.of(context, rootNavigator: true).context;
  await NotificationDialog.show(
    rootCtx,
    type: DialogType.success,
    title: title,
    message: message,
    onConfirm: onConfirm,
  );
}

Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  VoidCallback? onConfirm,
}) async {
  final rootCtx = Navigator.of(context, rootNavigator: true).context;
  await NotificationDialog.show(
    rootCtx,
    type: DialogType.error,
    title: title,
    message: message,
    onConfirm: onConfirm,
  );
}