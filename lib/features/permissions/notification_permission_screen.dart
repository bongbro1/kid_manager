import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.busy,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onSkip,
    this.helperText,
    this.statusMessage,
    this.media,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool busy;
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;
  final String? statusMessage;
  final Widget? media;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: 'Bật thông báo',
      description:
          'Nhận SOS, cảnh báo lệch tuyến và cập nhật an toàn ngay cả khi bạn không mở app.',
      helper:
          helperText ??
          'Nên bật từ đầu để không bỏ lỡ thông báo khẩn cấp. Sau khi cấp quyền, bạn vẫn có thể tinh chỉnh âm thanh trong cài đặt hệ thống.',
      primaryLabel: 'Cho phép thông báo',
      settingsLabel: 'Mở cài đặt thông báo',
      icon: Icons.notifications_active_rounded,
      color: const Color(0xFFE35D47),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onAllow,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
