import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/features/permissions/permission_onboarding_flow.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class SessionPermissionGate extends StatefulWidget {
  const SessionPermissionGate({
    super.key,
    required this.role,
    required this.child,
    this.copyModeOverride,
  });

  final UserRole role;
  final Widget child;
  final PermissionOnboardingCopyMode? copyModeOverride;

  @override
  State<SessionPermissionGate> createState() => _SessionPermissionGateState();
}

class _SessionPermissionGateState extends State<SessionPermissionGate> {
  bool _loading = true;
  bool _showPermission = false;
  late List<PermissionOnboardingStepType> _steps;

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps(widget.role);
    unawaited(_evaluate());
  }

  @override
  void didUpdateWidget(covariant SessionPermissionGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role) {
      setState(() {
        _loading = true;
        _showPermission = false;
      });
      _steps = _buildSteps(widget.role);
      unawaited(_evaluate());
    }
  }

  List<PermissionOnboardingStepType> _buildSteps(UserRole role) {
    if (role.isAdultManager) {
      final steps = <PermissionOnboardingStepType>[
        PermissionOnboardingStepType.notifications,
        PermissionOnboardingStepType.location,
        PermissionOnboardingStepType.backgroundLocation,
        PermissionOnboardingStepType.media,
      ];
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        steps.addAll(const <PermissionOnboardingStepType>[
          PermissionOnboardingStepType.usage,
          PermissionOnboardingStepType.battery,
        ]);
      }
      return steps;
    }

    if (role != UserRole.child) {
      return const <PermissionOnboardingStepType>[];
    }

    final steps = <PermissionOnboardingStepType>[
      PermissionOnboardingStepType.notifications,
      PermissionOnboardingStepType.location,
      PermissionOnboardingStepType.backgroundLocation,
      PermissionOnboardingStepType.media,
    ];

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      steps.addAll(const <PermissionOnboardingStepType>[
        PermissionOnboardingStepType.usage,
        PermissionOnboardingStepType.battery,
      ]);
    }

    return steps;
  }

  Future<void> _evaluate() async {
    final storage = context.read<StorageService>();
    final hasSeenPermissionFlow =
        storage.getBool(StorageKeys.permissionOnboardingSeenV1) ?? false;

    if (_steps.isEmpty) {
      if (!mounted) return;
      setState(() {
        _showPermission = false;
        _loading = false;
      });
      return;
    }

    var hasMissingPermissions = false;
    for (final step in _steps) {
      if (!await _isGranted(step)) {
        hasMissingPermissions = true;
        break;
      }
    }

    if (!mounted) return;
    setState(() {
      _showPermission = !hasSeenPermissionFlow || hasMissingPermissions;
      _loading = false;
    });
  }

  Future<bool> _isGranted(PermissionOnboardingStepType type) {
    final permissionService = context.read<PermissionService>();
    switch (type) {
      case PermissionOnboardingStepType.notifications:
        return permissionService.hasNotificationPermission();
      case PermissionOnboardingStepType.location:
        return permissionService.hasForegroundLocationPermission();
      case PermissionOnboardingStepType.backgroundLocation:
        return permissionService.hasBackgroundLocationPermission();
      case PermissionOnboardingStepType.media:
        return permissionService.hasPhotosOrStoragePermission();
      case PermissionOnboardingStepType.usage:
        return permissionService.hasUsagePermission();
      case PermissionOnboardingStepType.battery:
        return permissionService.hasBatteryOptimizationDisabled();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const LoadingOverlay();
    }

    if (_showPermission) {
      final copyMode =
          widget.copyModeOverride ??
          (widget.role.isAdultManager
              ? PermissionOnboardingCopyMode.adultDevice
              : PermissionOnboardingCopyMode.childDevice);
      return PermissionOnboardingFlow(
        steps: _steps,
        copyMode: copyMode,
        onFinished: (_) async {
          final storage = context.read<StorageService>();
          await storage.setBool(
            StorageKeys.permissionOnboardingSeenV1,
            true,
          );
          if (widget.role == UserRole.child) {
            await storage.setBool(
              StorageKeys.childSupervisionSetupSeenV1,
              true,
            );
          }

          if (!mounted) return;
          setState(() {
            _showPermission = false;
          });
        },
      );
    }

    return widget.child;
  }
}
