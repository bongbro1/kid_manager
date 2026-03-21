import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: l10n.permissionOnboardingAccessibilityTitle,
      description: l10n.permissionOnboardingAccessibilitySubtitle,
      primaryLabel: l10n.permissionOnboardingAccessibilityPrimaryButton,
      settingsLabel: l10n.permissionOnboardingAccessibilitySettingsButton,
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
