import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';

/// Trả true nếu user xác nhận xoá, false nếu huỷ/đóng dialog.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final completer = Completer<bool>();

  // Luôn dùng root context để tránh lệch navigator (đặc biệt khi gọi trong bottom sheet)
  final rootCtx = Navigator.of(context, rootNavigator: true).context;

  await NotificationDialog.show(
    rootCtx,
    type: DialogType.warning,
    title: title,
    message: message,
    onConfirm: () {
      if (!completer.isCompleted) completer.complete(true);
    },
    onCancel: () {
      if (!completer.isCompleted) completer.complete(false);
    },
  );

  // Nếu dialog bị đóng kiểu khác (tap ngoài/back) thì mặc định là không xoá
  if (!completer.isCompleted) completer.complete(false);

  return completer.future;
}