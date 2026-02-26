
import 'package:flutter/material.dart';
import 'package:kid_manager/views/parent/schedule/schedule_success_sheet.dart';

Future<void> showScheduleSuccess(BuildContext context, String message) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Success',
    barrierColor: Colors.black.withOpacity(0.4),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, __, ___) => Center(child: ScheduleSuccessSheet(message: message)),
    transitionBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}
