import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';

class BackgroundLocationPermissionScreen extends StatelessWidget {
  const BackgroundLocationPermissionScreen({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.busy,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onSkip,
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

  @override
  Widget build(BuildContext context) {
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: 'Bat vi tri luon luon',
      description:
          'Cho phep vi tri "Allow all the time" de tracking, Safe Route va canh bao van hoat dong khi app chay nen.',
      helper:
          'Neu he thong khong hien popup, hay mo cai dat ung dung va chon quyen vi tri la "Allow all the time" de theo doi lien tuc.',
      primaryLabel: 'Cho phep luon luon',
      settingsLabel: 'Mo cai dat vi tri',
      icon: Icons.my_location_rounded,
      color: const Color(0xFF155EEF),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onAllow,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
