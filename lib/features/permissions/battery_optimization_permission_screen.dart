import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';

class BatteryOptimizationPermissionScreen extends StatelessWidget {
  const BatteryOptimizationPermissionScreen({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.busy,
    required this.onOpenBatterySettings,
    required this.onOpenSettings,
    required this.onSkip,
    this.statusMessage,
    this.media,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final bool busy;
  final VoidCallback onOpenBatterySettings;
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
      title: 'Tắt giới hạn pin',
      description: 'Để app không bị dừng khi chạy nền.',
      primaryLabel: 'Đến cài đặt',
      settingsLabel: 'Mở cài đặt chung',
      icon: Icons.battery_charging_full_rounded,
      color: const Color(0xFF12B76A),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onOpenBatterySettings,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
