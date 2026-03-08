import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';

Future<bool> confirmExitUnsavedChanges(BuildContext context) async {
  final completer = Completer<bool>();

  // dùng root context để chắc chắn dialog nằm trên cùng stack (đặc biệt khi đang ở bottom sheet)
  final rootCtx = Navigator.of(context, rootNavigator: true).context;

  await NotificationDialog.show(
    rootCtx,
    type: DialogType.warning,
    title: 'Cảnh báo',
    message: 'Bạn chưa lưu, bạn có chắc muốn thoát?',
    onConfirm: () {
      if (!completer.isCompleted) completer.complete(true); // thoát
    },
    onCancel: () {
      if (!completer.isCompleted) completer.complete(false); // ở lại
    },
  );

  // NotificationDialog tự pop khi bấm nút, nhưng user có thể back dialog (nếu hệ thống cho phép).
  // Nếu dialog bị đóng mà chưa complete thì mặc định ở lại.
  if (!completer.isCompleted) completer.complete(false);

  return completer.future;
}
