import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: l10n.permissionOnboardingBackgroundLocationTitle,
      description: l10n.permissionOnboardingBackgroundLocationSubtitle,
      primaryLabel: l10n.permissionOnboardingBackgroundLocationPrimaryButton,
      settingsLabel: l10n.permissionOnboardingBackgroundLocationSettingsButton,
      icon: Icons.my_location_rounded,
      color: const Color(0xFF1683F2),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onAllow,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
