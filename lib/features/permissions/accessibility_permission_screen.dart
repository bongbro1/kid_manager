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
      title: 'Bật trợ năng',
      description: 'Cần cho một số tính năng bảo vệ trên Android.',
      primaryLabel: 'Đến cài đặt',
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
