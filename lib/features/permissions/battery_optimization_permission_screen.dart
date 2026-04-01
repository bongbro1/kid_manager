import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: l10n.permissionOnboardingBatteryTitle,
      description: l10n.permissionOnboardingBatterySubtitle,
      primaryLabel: l10n.permissionOnboardingBatteryPrimaryButton,
      settingsLabel: l10n.permissionOnboardingBatterySettingsButton,
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
