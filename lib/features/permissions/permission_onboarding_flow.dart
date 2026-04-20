import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kid_manager/features/permissions/background_location_guide_video_card.dart';
import 'package:kid_manager/features/permissions/background_location_permission_screen.dart';
import 'package:kid_manager/features/permissions/battery_optimization_permission_screen.dart';
import 'package:kid_manager/features/permissions/location_permission_screen.dart';
import 'package:kid_manager/features/permissions/media_permission_screen.dart';
import 'package:kid_manager/features/permissions/notification_permission_screen.dart';
import 'package:kid_manager/features/permissions/usage_access_permission_screen.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class PermissionOnboardingCompletion {
  const PermissionOnboardingCompletion({required this.allPermissionsGranted});

  final bool allPermissionsGranted;
}

class PermissionOnboardingFlow extends StatefulWidget {
  const PermissionOnboardingFlow({
    super.key,
    required this.onFinished,
    this.mediaBuilder,
    this.steps,
    this.copyMode = PermissionOnboardingCopyMode.childDevice,
  });

  final Future<void> Function(PermissionOnboardingCompletion completion)
  onFinished;
  final Widget Function(
    BuildContext context,
    PermissionOnboardingStepType step,
  )?
  mediaBuilder;
  final List<PermissionOnboardingStepType>? steps;
  final PermissionOnboardingCopyMode copyMode;

  @override
  State<PermissionOnboardingFlow> createState() =>
      _PermissionOnboardingFlowState();
}

enum PermissionOnboardingStepType {
  notifications,
  location,
  backgroundLocation,
  media,
  usage,
  battery,
}

enum PermissionOnboardingCopyMode { adultDevice, childDevice, sharedDevice }

class PermissionOnboardingStepCopy {
  const PermissionOnboardingStepCopy({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;
}

class _PermissionOnboardingFlowState extends State<PermissionOnboardingFlow>
    with WidgetsBindingObserver {
  late final PermissionService _permissionService;
  late final List<PermissionOnboardingStepType> _steps;

  int _stepIndex = 0;
  bool _busy = false;
  bool _openedSettings = false;
  String? _statusMessage;

  PermissionOnboardingStepType get _currentStep => _steps[_stepIndex];
  List<String> get _stepLabels => _steps.map(_labelForStep).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _permissionService = context.read<PermissionService>();
    _steps = widget.steps ?? _buildDefaultSteps();
    Future.microtask(_syncCurrentStep);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_openedSettings || state != AppLifecycleState.resumed) return;
    _openedSettings = false;
    Future.delayed(const Duration(milliseconds: 350), _syncCurrentStep);
  }

  List<PermissionOnboardingStepType> _buildDefaultSteps() {
    final steps = <PermissionOnboardingStepType>[
      PermissionOnboardingStepType.notifications,
      PermissionOnboardingStepType.location,
      PermissionOnboardingStepType.backgroundLocation,
      PermissionOnboardingStepType.media,
    ];

    if (Platform.isAndroid) {
      steps.addAll(const [
        PermissionOnboardingStepType.usage,
        PermissionOnboardingStepType.battery,
      ]);
    }

    return steps;
  }

  String _labelForStep(PermissionOnboardingStepType step) {
    final l10n = AppLocalizations.of(context);
    switch (step) {
      case PermissionOnboardingStepType.notifications:
        return l10n.permissionOnboardingStepNotificationsLabel;
      case PermissionOnboardingStepType.location:
        return l10n.permissionOnboardingStepLocationLabel;
      case PermissionOnboardingStepType.backgroundLocation:
        return l10n.permissionOnboardingStepBackgroundLocationLabel;
      case PermissionOnboardingStepType.media:
        return l10n.permissionOnboardingStepMediaLabel;
      case PermissionOnboardingStepType.usage:
        return l10n.permissionOnboardingStepUsageLabel;
      case PermissionOnboardingStepType.battery:
        return l10n.permissionOnboardingStepBatteryLabel;
    }
  }

  Future<void> _syncCurrentStep() async {
    if (!mounted) return;

    if (_steps.isEmpty) {
      await _finishFlow();
      return;
    }

    for (var i = 0; i < _steps.length; i++) {
      final granted = await _isGranted(_steps[i]);
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _stepIndex = i;
          _statusMessage = null;
        });
        return;
      }
    }

    await _finishFlow();
  }

  Future<bool> _isGranted(PermissionOnboardingStepType type) {
    switch (type) {
      case PermissionOnboardingStepType.notifications:
        return _permissionService.hasNotificationPermission();
      case PermissionOnboardingStepType.location:
        return _permissionService.hasForegroundLocationPermission();
      case PermissionOnboardingStepType.backgroundLocation:
        return _permissionService.hasBackgroundLocationPermission();
      case PermissionOnboardingStepType.media:
        return _permissionService.hasPhotosOrStoragePermission();
      case PermissionOnboardingStepType.usage:
        return _permissionService.hasUsagePermission();
      case PermissionOnboardingStepType.battery:
        return _permissionService.hasBatteryOptimizationDisabled();
    }
  }

  Future<void> _handlePrimary() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _statusMessage = null;
    });

    try {
      if (_isSettingsOnlyStep(_currentStep)) {
        await _openSettings(_currentStep);
        return;
      }

      final status = await _requestPermission(_currentStep);
      if (!mounted) return;

      if (_isRequestGranted(status, _currentStep)) {
        await _moveToNextStep();
        return;
      }

      final l10n = AppLocalizations.of(context);
      if (status.isPermanentlyDenied || status.isRestricted) {
        setState(() {
          _statusMessage = l10n.permissionOnboardingSystemDeniedMessage;
        });
        return;
      }

      setState(() {
        _statusMessage = l10n.permissionOnboardingNotGrantedMessage;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _handleOpenSettings() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _statusMessage = null;
    });

    try {
      await _openSettings(_currentStep);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _handleSkip() async {
    if (_busy) return;
    await _moveToNextStep();
  }

  Future<void> _moveToNextStep() async {
    for (var i = _stepIndex + 1; i < _steps.length; i++) {
      final granted = await _isGranted(_steps[i]);
      if (!granted) {
        if (!mounted) return;
        setState(() {
          _stepIndex = i;
          _statusMessage = null;
        });
        return;
      }
    }

    await _finishFlow();
  }

  Future<void> _finishFlow() async {
    var allPermissionsGranted = true;
    for (final step in _steps) {
      if (!await _isGranted(step)) {
        allPermissionsGranted = false;
        break;
      }
    }

    await widget.onFinished(
      PermissionOnboardingCompletion(
        allPermissionsGranted: allPermissionsGranted,
      ),
    );
  }

  bool _isSettingsOnlyStep(PermissionOnboardingStepType step) {
    switch (step) {
      case PermissionOnboardingStepType.usage:
      case PermissionOnboardingStepType.battery:
        return true;
      case PermissionOnboardingStepType.notifications:
      case PermissionOnboardingStepType.location:
      case PermissionOnboardingStepType.backgroundLocation:
      case PermissionOnboardingStepType.media:
        return false;
    }
  }

  Future<void> _openSettings(PermissionOnboardingStepType type) async {
    _openedSettings = true;
    switch (type) {
      case PermissionOnboardingStepType.notifications:
        if (Platform.isAndroid) {
          await _permissionService.openAndroidSosAlertSettings();
        } else {
          await _permissionService.openNotificationSettings();
        }
        break;
      case PermissionOnboardingStepType.location:
      case PermissionOnboardingStepType.backgroundLocation:
      case PermissionOnboardingStepType.media:
        if (type == PermissionOnboardingStepType.backgroundLocation) {
          await _permissionService.openLocationSettings();
        } else {
          await _permissionService.openAppSettingsPage();
        }
        break;
      case PermissionOnboardingStepType.usage:
        await _permissionService.openUsageAccessSettings();
        break;
      case PermissionOnboardingStepType.battery:
        await _permissionService.openBatteryOptimizationSettings();
        break;
    }
  }

  Future<PermissionStatus> _requestPermission(
    PermissionOnboardingStepType type,
  ) {
    switch (type) {
      case PermissionOnboardingStepType.notifications:
        return _permissionService.requestNotificationPermission();
      case PermissionOnboardingStepType.location:
        return _permissionService.requestForegroundLocationPermission();
      case PermissionOnboardingStepType.backgroundLocation:
        return _permissionService.requestBackgroundLocationPermission();
      case PermissionOnboardingStepType.media:
        return _requestMediaPermission();
      case PermissionOnboardingStepType.usage:
      case PermissionOnboardingStepType.battery:
        return Future.value(PermissionStatus.denied);
    }
  }

  Future<PermissionStatus> _requestMediaPermission() async {
    final granted = await _permissionService.requestPhotosOrStoragePermission();
    return granted ? PermissionStatus.granted : PermissionStatus.denied;
  }

  bool _isRequestGranted(
    PermissionStatus status,
    PermissionOnboardingStepType type,
  ) {
    if (status.isGranted) return true;
    if (type == PermissionOnboardingStepType.notifications &&
        status == PermissionStatus.provisional) {
      return true;
    }
    if (type == PermissionOnboardingStepType.media &&
        status == PermissionStatus.limited) {
      return true;
    }
    return false;
  }

  PermissionOnboardingStepCopy _copyForStep(PermissionOnboardingStepType step) {
    final l10n = AppLocalizations.of(context);
    final isAdult = widget.copyMode == PermissionOnboardingCopyMode.adultDevice;
    final isShared =
        widget.copyMode == PermissionOnboardingCopyMode.sharedDevice;

    switch (step) {
      case PermissionOnboardingStepType.notifications:
        if (isShared) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Bật thông báo',
              en: 'Turn on notifications',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để nhận SOS, chat, cảnh báo vùng an toàn và các cảnh báo an toàn ngay khi chúng xảy ra.',
              en: 'To receive SOS, chat, safe zone, and safety alerts as soon as they happen.',
            ),
          );
        }
        if (isAdult) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Bật thông báo trên máy phụ huynh',
              en: 'Turn on notifications on the parent device',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để nhận SOS, cảnh báo vùng an toàn và các cảnh báo an toàn từ thiết bị trẻ ngay khi chúng xảy ra.',
              en: 'To receive SOS, safe zone, and safety alerts from the child device as soon as they happen.',
            ),
          );
        }
        return PermissionOnboardingStepCopy(
          title: l10n.permissionOnboardingNotificationTitle,
          description: l10n.permissionOnboardingNotificationSubtitle,
        );
      case PermissionOnboardingStepType.location:
        if (isShared) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Bật vị trí',
              en: 'Turn on location',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để app dùng bản đồ, chia sẻ vị trí và các tính năng an toàn khi cần.',
              en: 'So the app can use maps, location sharing, and safety features when needed.',
            ),
          );
        }
        if (isAdult) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Bật vị trí trên máy phụ huynh',
              en: 'Turn on location on the parent device',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để bản đồ gia đình và các tính năng an toàn có thể dùng vị trí của chính thiết bị phụ huynh khi cần.',
              en: 'So family maps and safety features can use the parent device location when needed.',
            ),
          );
        }
        return PermissionOnboardingStepCopy(
          title: l10n.permissionOnboardingLocationTitle,
          description: l10n.permissionOnboardingLocationSubtitle,
        );
      case PermissionOnboardingStepType.backgroundLocation:
        if (isShared) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Cho phép vị trí nền',
              en: 'Allow background location',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để app vẫn có thể cập nhật vị trí và duy trì các tính năng an toàn khi chạy nền.',
              en: 'So the app can still update location and keep safety features working in the background.',
            ),
          );
        }
        if (isAdult) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Cho phép vị trí nền trên máy phụ huynh',
              en: 'Allow background location on the parent device',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để app vẫn có thể cập nhật vị trí của thiết bị phụ huynh khi bạn đang dùng các tính năng chia sẻ vị trí hoặc an toàn.',
              en: 'So the app can still update the parent device location while using live location sharing or safety features.',
            ),
          );
        }
        return PermissionOnboardingStepCopy(
          title: l10n.permissionOnboardingBackgroundLocationTitle,
          description: l10n.permissionOnboardingBackgroundLocationSubtitle,
        );
      case PermissionOnboardingStepType.media:
        if (isShared) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Cho phép ảnh và media',
              en: 'Allow photos and media',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để đổi ảnh đại diện, chọn ảnh trong chat và dùng các tính năng cần media.',
              en: 'To change profile photos, choose images in chat, and use media features.',
            ),
          );
        }
        if (isAdult) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Cho phép ảnh và media trên máy phụ huynh',
              en: 'Allow photos and media on the parent device',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để đổi ảnh đại diện, chọn ảnh trong chat và dùng các tính năng cần media trên máy phụ huynh.',
              en: 'To change profile photos, choose images in chat, and use media-related features on the parent device.',
            ),
          );
        }
        return PermissionOnboardingStepCopy(
          title: l10n.permissionOnboardingMediaTitle,
          description: l10n.permissionOnboardingMediaSubtitle,
        );
      case PermissionOnboardingStepType.usage:
        if (isShared) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Bật quyền sử dụng ứng dụng',
              en: 'Enable app usage access',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để app hỗ trợ các tính năng theo dõi, thống kê và quản lý liên quan đến việc sử dụng ứng dụng.',
              en: 'So the app can support tracking, statistics, and management features related to app usage.',
            ),
          );
        }
        if (isAdult) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Bật quyền sử dụng ứng dụng trên máy phụ huynh',
              en: 'Enable app usage access on the parent device',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để app có thể theo dõi thời gian sử dụng và hỗ trợ các tính năng quản lý, giám sát trên chính thiết bị phụ huynh khi cần.',
              en: 'So the app can read app usage and support management or supervision features on the parent device when needed.',
            ),
          );
        }
        return PermissionOnboardingStepCopy(
          title: l10n.permissionOnboardingUsageTitle,
          description: l10n.permissionOnboardingUsageSubtitle,
        );
      case PermissionOnboardingStepType.battery:
        if (isShared) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Tắt giới hạn pin',
              en: 'Turn off battery restrictions',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để app vẫn hoạt động ổn định trên nền và không bỏ lỡ cập nhật hoặc cảnh báo quan trọng.',
              en: 'So the app can keep running reliably in the background and not miss important updates or alerts.',
            ),
          );
        }
        if (isAdult) {
          return PermissionOnboardingStepCopy(
            title: _localizedCopy(
              context,
              vi: 'Tắt giới hạn pin trên máy phụ huynh',
              en: 'Turn off battery restrictions on the parent device',
            ),
            description: _localizedCopy(
              context,
              vi: 'Để app vẫn tiếp tục hoạt động ổn định trên nền và không bỏ lỡ các cảnh báo an toàn hay cập nhật quan trọng.',
              en: 'So the app can keep running reliably in the background and not miss safety alerts or important updates.',
            ),
          );
        }
        return PermissionOnboardingStepCopy(
          title: l10n.permissionOnboardingBatteryTitle,
          description: l10n.permissionOnboardingBatterySubtitle,
        );
    }
  }

  Widget _buildStepScreen() {
    final l10n = AppLocalizations.of(context);
    final currentStep = _stepIndex + 1;
    final totalSteps = _steps.length;
    final media = _buildStepMedia();
    final copy = _copyForStep(_currentStep);
    final notificationHelperText =
        Platform.isAndroid &&
            _currentStep == PermissionOnboardingStepType.notifications
        ? _localizedCopy(
            context,
            vi: 'Trên Android, bạn có thể bật thêm quyền truy cập SOS khẩn cấp để cảnh báo mạnh hơn khi máy ở chế độ Không làm phiền. Hệ điều hành vẫn không đảm bảo sẽ phát tiếng trong mọi chế độ im lặng.',
            en: 'On Android, you can also enable emergency SOS access so the app can use stronger alerts, bypass Do Not Disturb when the device allows it, and temporarily raise some alert-related volume streams. Android still does not guarantee sound in every silent-mode scenario.',
          )
        : null;
    final notificationSettingsLabel =
        Platform.isAndroid &&
            _currentStep == PermissionOnboardingStepType.notifications
        ? _localizedCopy(
            context,
            vi: 'Mở cài đặt SOS khẩn cấp',
            en: 'Open SOS alert settings',
          )
        : null;

    final resolvedNotificationHelperText =
        notificationHelperText == null
        ? null
        : _localizedCopy(
            context,
            vi: 'Trên Android, bạn có thể bật thêm cài đặt SOS khẩn cấp để app dùng cảnh báo mạnh hơn, bỏ qua Không làm phiền nếu máy cho phép, và tạm thời tăng một số mức âm lượng cảnh báo. Android vẫn không đảm bảo phát tiếng trong mọi chế độ im lặng.',
            en: 'On Android, you can also enable emergency SOS access so the app can use stronger alerts, bypass Do Not Disturb when the device allows it, and temporarily raise some alert-related volume streams. Android still does not guarantee sound in every silent-mode scenario.',
          );

    switch (_currentStep) {
      case PermissionOnboardingStepType.notifications:
        return NotificationPermissionScreen(
          key: const ValueKey('notifications'),
          currentStep: currentStep,
          totalSteps: totalSteps,
          stepLabels: _stepLabels,
          busy: _busy,
          statusMessage: _statusMessage,
          media: media,
          title: copy.title,
          description: copy.description,
          helperText:
              resolvedNotificationHelperText ??
              l10n.permissionOnboardingNotificationHelperText,
          settingsLabel: notificationSettingsLabel,
          onAllow: () => unawaited(_handlePrimary()),
          onOpenSettings: () => unawaited(_handleOpenSettings()),
          onSkip: () => unawaited(_handleSkip()),
        );
      case PermissionOnboardingStepType.location:
        return LocationPermissionScreen(
          key: const ValueKey('location'),
          currentStep: currentStep,
          totalSteps: totalSteps,
          stepLabels: _stepLabels,
          busy: _busy,
          statusMessage: _statusMessage,
          media: media,
          title: copy.title,
          description: copy.description,
          onAllow: () => unawaited(_handlePrimary()),
          onOpenSettings: () => unawaited(_handleOpenSettings()),
          onSkip: () => unawaited(_handleSkip()),
        );
      case PermissionOnboardingStepType.backgroundLocation:
        return BackgroundLocationPermissionScreen(
          key: const ValueKey('background-location'),
          currentStep: currentStep,
          totalSteps: totalSteps,
          stepLabels: _stepLabels,
          busy: _busy,
          statusMessage: _statusMessage,
          media: media,
          title: copy.title,
          description: copy.description,
          onAllow: () => unawaited(_handlePrimary()),
          onOpenSettings: () => unawaited(_handleOpenSettings()),
          onSkip: () => unawaited(_handleSkip()),
        );
      case PermissionOnboardingStepType.media:
        return MediaPermissionScreen(
          key: const ValueKey('media'),
          currentStep: currentStep,
          totalSteps: totalSteps,
          stepLabels: _stepLabels,
          busy: _busy,
          statusMessage: _statusMessage,
          media: media,
          title: copy.title,
          description: copy.description,
          onAllow: () => unawaited(_handlePrimary()),
          onOpenSettings: () => unawaited(_handleOpenSettings()),
          onSkip: () => unawaited(_handleSkip()),
        );
      case PermissionOnboardingStepType.usage:
        return UsageAccessPermissionScreen(
          key: const ValueKey('usage'),
          currentStep: currentStep,
          totalSteps: totalSteps,
          stepLabels: _stepLabels,
          busy: _busy,
          statusMessage: _statusMessage,
          media: media,
          title: copy.title,
          description: copy.description,
          onOpenUsageAccess: () => unawaited(_handlePrimary()),
          onOpenSettings: () => unawaited(_handleOpenSettings()),
          onSkip: () => unawaited(_handleSkip()),
        );
      case PermissionOnboardingStepType.battery:
        return BatteryOptimizationPermissionScreen(
          key: const ValueKey('battery'),
          currentStep: currentStep,
          totalSteps: totalSteps,
          stepLabels: _stepLabels,
          busy: _busy,
          statusMessage: _statusMessage,
          media: media,
          title: copy.title,
          description: copy.description,
          onOpenBatterySettings: () => unawaited(_handlePrimary()),
          onOpenSettings: () => unawaited(_handleOpenSettings()),
          onSkip: () => unawaited(_handleSkip()),
        );
    }
  }

  Widget? _buildStepMedia() {
    final override = widget.mediaBuilder?.call(context, _currentStep);
    if (override != null) return override;

    if (_currentStep == PermissionOnboardingStepType.backgroundLocation) {
      return const BackgroundLocationGuideVideoCard();
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: _buildStepScreen(),
    );
  }
}

String _localizedCopy(
  BuildContext context, {
  required String vi,
  required String en,
}) {
  return Localizations.localeOf(context).languageCode.toLowerCase() == 'vi'
      ? vi
      : en;
}
