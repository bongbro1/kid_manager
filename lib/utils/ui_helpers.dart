import 'package:flutter/material.dart';

Future<T> runWithLoading<T>(
  BuildContext context,
  Future<T> Function() action,
) async {
  final rootNav = Navigator.of(context, rootNavigator: true);

  bool dialogOpen = true;

  // show loading bằng context của root navigator để chắc chắn cùng stack
  showDialog<void>(
    context: rootNav.context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (_) => const Center(
      child: SizedBox(
        width: 60,
        height: 60,
        child: CircularProgressIndicator(strokeWidth: 4),
      ),
    ),
  ).then((_) {
    dialogOpen = false;
  });

  // đảm bảo route đã push xong
  await Future.delayed(Duration.zero);

  try {
    return await action();
  } finally {
    // chỉ pop nếu loading dialog vẫn còn mở
    if (dialogOpen && rootNav.canPop()) {
      rootNav.pop();
    }
  }
}