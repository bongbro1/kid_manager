import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/features/permissions/permission_onboarding_flow.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:provider/provider.dart';

class ChildSupervisionSetupPrompt extends StatefulWidget {
  const ChildSupervisionSetupPrompt({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ChildSupervisionSetupPrompt> createState() =>
      _ChildSupervisionSetupPromptState();
}

class _ChildSupervisionSetupPromptState
    extends State<ChildSupervisionSetupPrompt>
    with WidgetsBindingObserver {
  static const List<PermissionOnboardingStepType> _supervisionSteps =
      <PermissionOnboardingStepType>[
        PermissionOnboardingStepType.usage,
        PermissionOnboardingStepType.battery,
        PermissionOnboardingStepType.accessibility,
      ];

  List<PermissionOnboardingStepType> _missingSteps =
      const <PermissionOnboardingStepType>[];
  bool _loading = true;
  bool _flowOpen = false;
  bool _bannerDismissedForSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_evaluateAndPrompt(autoOpenIfNeeded: true));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _flowOpen) {
      return;
    }
    unawaited(_evaluateAndPrompt());
  }

  Future<void> _evaluateAndPrompt({bool autoOpenIfNeeded = false}) async {
    if (!Platform.isAndroid) {
      if (!mounted) return;
      setState(() {
        _missingSteps = const <PermissionOnboardingStepType>[];
        _loading = false;
      });
      return;
    }

    final missingSteps = await _resolveMissingSteps();
    final hasSeenSetup =
        context.read<StorageService>().getBool(
          StorageKeys.childSupervisionSetupSeenV1,
        ) ??
        false;

    if (!mounted) return;

    setState(() {
      _missingSteps = missingSteps;
      _loading = false;
      if (missingSteps.isEmpty) {
        _bannerDismissedForSession = false;
      }
    });

    if (autoOpenIfNeeded && !hasSeenSetup && missingSteps.isNotEmpty) {
      await _openSetupFlow(missingSteps);
    }
  }

  Future<List<PermissionOnboardingStepType>> _resolveMissingSteps() async {
    final permissionService = context.read<PermissionService>();
    final supervisionPermissions =
        await permissionService.checkChildSupervisionPermissions();

    final missing = <PermissionOnboardingStepType>[];
    for (final step in _supervisionSteps) {
      switch (step) {
        case PermissionOnboardingStepType.usage:
          if (!(supervisionPermissions['usage'] ?? false)) {
            missing.add(step);
          }
          break;
        case PermissionOnboardingStepType.battery:
          if (!(supervisionPermissions['batteryOptimizationDisabled'] ??
              false)) {
            missing.add(step);
          }
          break;
        case PermissionOnboardingStepType.accessibility:
          if (!(supervisionPermissions['accessibility'] ?? false)) {
            missing.add(step);
          }
          break;
        case PermissionOnboardingStepType.notifications:
        case PermissionOnboardingStepType.location:
        case PermissionOnboardingStepType.backgroundLocation:
        case PermissionOnboardingStepType.media:
          break;
      }
    }

    return missing;
  }

  Future<void> _openSetupFlow(
    List<PermissionOnboardingStepType> steps,
  ) async {
    if (_flowOpen || steps.isEmpty || !mounted) {
      return;
    }

    _flowOpen = true;
    final storage = context.read<StorageService>();

    await Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (routeContext) {
          return Scaffold(
            body: SafeArea(
              child: PermissionOnboardingFlow(
                steps: steps,
                onFinished: (_) async {
                  await storage.setBool(
                    StorageKeys.childSupervisionSetupSeenV1,
                    true,
                  );
                  if (!routeContext.mounted) return;
                  Navigator.of(routeContext).pop();
                },
              ),
            ),
          );
        },
      ),
    );

    _flowOpen = false;
    if (!mounted) return;
    await _evaluateAndPrompt();
  }

  String _titleForStep(
    AppLocalizations l10n,
    PermissionOnboardingStepType step,
  ) {
    switch (step) {
      case PermissionOnboardingStepType.usage:
        return l10n.permissionOnboardingUsageTitle;
      case PermissionOnboardingStepType.battery:
        return l10n.permissionOnboardingBatteryTitle;
      case PermissionOnboardingStepType.accessibility:
        return l10n.permissionOnboardingAccessibilityTitle;
      case PermissionOnboardingStepType.notifications:
        return l10n.permissionOnboardingNotificationTitle;
      case PermissionOnboardingStepType.location:
        return l10n.permissionOnboardingLocationTitle;
      case PermissionOnboardingStepType.backgroundLocation:
        return l10n.permissionOnboardingBackgroundLocationTitle;
      case PermissionOnboardingStepType.media:
        return l10n.permissionOnboardingMediaTitle;
    }
  }

  String _subtitleForStep(
    AppLocalizations l10n,
    PermissionOnboardingStepType step,
  ) {
    switch (step) {
      case PermissionOnboardingStepType.usage:
        return l10n.permissionOnboardingUsageSubtitle;
      case PermissionOnboardingStepType.battery:
        return l10n.permissionOnboardingBatterySubtitle;
      case PermissionOnboardingStepType.accessibility:
        return l10n.permissionOnboardingAccessibilitySubtitle;
      case PermissionOnboardingStepType.notifications:
        return l10n.permissionOnboardingNotificationSubtitle;
      case PermissionOnboardingStepType.location:
        return l10n.permissionOnboardingLocationSubtitle;
      case PermissionOnboardingStepType.backgroundLocation:
        return l10n.permissionOnboardingBackgroundLocationSubtitle;
      case PermissionOnboardingStepType.media:
        return l10n.permissionOnboardingMediaSubtitle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowBanner =
        !_loading && _missingSteps.isNotEmpty && !_bannerDismissedForSession;

    if (!shouldShowBanner) {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context);
    final nextStep = _missingSteps.first;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: SafeArea(
            top: false,
            child: Material(
              elevation: 10,
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleForStep(l10n, nextStep),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitleForStep(l10n, nextStep),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _bannerDismissedForSession = true;
                            });
                          },
                          child: Text(l10n.permissionLaterButton),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _openSetupFlow(_missingSteps),
                          child: Text(l10n.continueButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
