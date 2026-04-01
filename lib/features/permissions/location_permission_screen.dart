import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: l10n.permissionOnboardingLocationTitle,
      description: l10n.permissionOnboardingLocationSubtitle,
      primaryLabel: l10n.permissionOnboardingLocationPrimaryButton,
      settingsLabel: l10n.permissionOnboardingLocationSettingsButton,
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
