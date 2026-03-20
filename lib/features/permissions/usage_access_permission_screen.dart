import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';

class UsageAccessPermissionScreen extends StatelessWidget {
  const UsageAccessPermissionScreen({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.busy,
    required this.onOpenUsageAccess,
    required this.onOpenSettings,
    required this.onSkip,
    this.statusMessage,
    this.media,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool busy;
  final VoidCallback onOpenUsageAccess;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;
  final String? statusMessage;
  final Widget? media;

  @override
  Widget build(BuildContext context) {
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: 'Bật Usage Access',
      description:
          'Cần để giám sát thời gian dùng app và kích hoạt các tính năng quản lý thiết bị trên Android.',
      helper:
          'Android không hiện popup trực tiếp cho quyền này. App sẽ đưa bạn tới đúng màn cài đặt để bật thủ công.',
      primaryLabel: 'Mở Usage Access',
      settingsLabel: 'Mở cài đặt chung',
      icon: Icons.query_stats_rounded,
      color: const Color(0xFF7A5AF8),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onOpenUsageAccess,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
