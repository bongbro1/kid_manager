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
      title: 'Tat gioi han pin',
      description:
          'Giu tracking, vung an toan va cac canh bao hoat dong on dinh khi app chay nen tren Android.',
      helper:
          'Khuyen nghi bat de he thong khong dung app som khi man hinh tat hoac thiet bi o che do tiet kiem pin.',
      primaryLabel: 'Mo cai dat pin',
      settingsLabel: 'Mo cai dat chung',
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
