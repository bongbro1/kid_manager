import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'location_permission_screen.dart';
import 'notification_permission_screen.dart';

class PermissionOnboardingFlow extends StatefulWidget {
  final VoidCallback onFinished;

  const PermissionOnboardingFlow({
    super.key,
    required this.onFinished,
  });

  @override
  State<PermissionOnboardingFlow> createState() =>
      _PermissionOnboardingFlowState();
}

class _PermissionOnboardingFlowState extends State<PermissionOnboardingFlow>
    with WidgetsBindingObserver {
  int _step = 0; // 0 = notification, 1 = location
  bool _openedSettings = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _checkInitialPermissions() async {
    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.locationWhenInUse.status;

    if (!mounted) return;

    if (notificationStatus.isGranted && locationStatus.isGranted) {
      widget.onFinished();
      return;
    }

    if (notificationStatus.isGranted) {
      setState(() => _step = 1);
      return;
    }

    setState(() => _step = 0);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (!_openedSettings || state != AppLifecycleState.resumed) return;

    final notificationStatus = await Permission.notification.status;
    final locationStatus = await Permission.locationWhenInUse.status;

    if (!mounted) return;

    setState(() => _openedSettings = false);

    if (_step == 0) {
      if (notificationStatus.isGranted) {
        setState(() => _step = 1);
      }
      return;
    }

    if (_step == 1) {
      if (locationStatus.isGranted) {
        widget.onFinished();
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final status = await Permission.notification.request();

      if (!mounted) return;

      if (status.isGranted) {
        setState(() => _step = 1);
        return;
      }

      if (status.isPermanentlyDenied || status.isRestricted || status.isDenied) {
        _openNotificationSettings();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _requestLocationPermission() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      final status = await Permission.locationWhenInUse.request();

      if (!mounted) return;

      if (status.isGranted) {
        widget.onFinished();
        return;
      }

      if (status.isPermanentlyDenied || status.isRestricted || status.isDenied) {
        _openAppSettings();
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _skipLocation() {
    widget.onFinished();
  }

  void _openNotificationSettings() {
    setState(() => _openedSettings = true);
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  void _openAppSettings() {
    setState(() => _openedSettings = true);
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _PermissionProgressHeader(step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: slide,
                      child: child,
                    ),
                  );
                },
                child: _step == 0
                    ? NotificationPermissionScreen(
                  key: const ValueKey('notification-step'),
                  onAllow: _requestNotificationPermission,
                  onOpenSettings: _openNotificationSettings,
                  busy: _busy,
                )
                    : LocationPermissionScreen(
                  key: const ValueKey('location-step'),
                  onAllow: _requestLocationPermission,
                  onOpenSettings: _openAppSettings,
                  onSkip: _skipLocation,
                  busy: _busy,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionProgressHeader extends StatelessWidget {
  final int step;

  const _PermissionProgressHeader({required this.step});

  @override
  Widget build(BuildContext context) {
    final currentStep = step + 1;
    final progress = currentStep / 2;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bước $currentStep/2',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D2B2E),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEAEAEA),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2D2B2E)),
            ),
          ),
        ],
      ),
    );
  }
}