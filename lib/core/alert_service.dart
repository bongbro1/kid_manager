import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_navigator.dart';

class AlertService {
  AlertService._();

  /// Snackbar nhanh (info / error)
  static void showSnack(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = AppNavigator.messengerKey.currentState;

    if (messenger == null) return;

    messenger.clearSnackBars();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  /// Dialog xác nhận (OK/Cancel)
  static Future<bool> confirm({
    required String title,
    required String message,
    String okText = 'OK',
    String cancelText = 'Huỷ',
  }) async {
    final ctx = AppNavigator.navigatorKey.currentContext;

    if (ctx == null) return false;

    final res = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(okText),
          ),
        ],
      ),
    );

    return res ?? false;
  }

  /// Dialog báo lỗi (1 nút)
  static Future<void> error({
    String title = 'Có lỗi xảy ra',
    required String message,
    String okText = 'Đóng',
  }) async {
    final ctx = AppNavigator.navigatorKey.currentContext;

    if (ctx == null) return;

    await showDialog<void>(
      context: ctx,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(okText),
          ),
        ],
      ),
    );
  }
}