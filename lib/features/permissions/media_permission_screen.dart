import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/permission_step_scaffold.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class MediaPermissionScreen extends StatelessWidget {
  const MediaPermissionScreen({
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
    this.title,
    this.description,
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
  final String? title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PermissionStepScaffold(
      currentStep: currentStep,
      totalSteps: totalSteps,
      stepLabels: stepLabels,
      title: title ?? l10n.permissionOnboardingMediaTitle,
      description: description ?? l10n.permissionOnboardingMediaSubtitle,
      primaryLabel: l10n.permissionOnboardingMediaPrimaryButton,
      settingsLabel: l10n.permissionOnboardingMediaSettingsButton,
      icon: Icons.photo_library_rounded,
      color: const Color(0xFF00A888),
      busy: busy,
      statusMessage: statusMessage,
      onPrimary: onAllow,
      onOpenSettings: onOpenSettings,
      onSkip: onSkip,
      media: media,
    );
  }
}
