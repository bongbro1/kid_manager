import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';

class AccessibilityPermissionScreen extends StatelessWidget {
  const AccessibilityPermissionScreen({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.busy,
    required this.onOpenAccessibility,
    required this.onOpenSettings,
    required this.onSkip,
    this.statusMessage,
    this.media,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool busy;
  final VoidCallback onOpenAccessibility;
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
      title: 'Bật Accessibility',
      description:
          'Cần cho một số tính năng giám sát và bảo vệ hoạt động ổn định trên Android.',
      helper:
          'Đây là quyền hệ thống nhạy cảm. Chỉ bật khi bạn dùng các tính năng thực sự cần nó, và có thể quay lại thiết lập sau trong app.',
      primaryLabel: 'Mở Accessibility',
      settingsLabel: 'Mở cài đặt chung',
      icon: Icons.accessibility_new_rounded,
      color: const Color(0xFFF79009),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onOpenAccessibility,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
