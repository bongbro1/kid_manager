import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({
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
    this.helperText,
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
      title: 'Bat vi tri',
      description:
          'Can quyen vi tri de theo doi hanh trinh, vung an toan va lich su di chuyen cua thanh vien.',
      helper: helperText ??
          'Cap quyen khi dung app truoc. Ngay sau buoc nay app se huong dan bat them "Allow all the time" de tracking nen hoat dong on dinh.',
      primaryLabel: 'Cho phep vi tri',
      settingsLabel: 'Mo cai dat vi tri',
      icon: Icons.location_on_rounded,
      color: const Color(0xFF2D7FF9),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onAllow,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
