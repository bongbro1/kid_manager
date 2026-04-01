import 'dart:ui';

class BackgroundTrackingStatusSnapshot {
  const BackgroundTrackingStatusSnapshot({
    required this.requireBackground,
    required this.serviceRunning,
    required this.isSharing,
    required this.publishingHandledByService,
    required this.hasBackgroundPermission,
    required this.backgroundModeEnabled,
    this.appLifecycleState,
  });

  final bool requireBackground;
  final bool serviceRunning;
  final bool isSharing;
  final bool publishingHandledByService;
  final bool hasBackgroundPermission;
  final bool backgroundModeEnabled;
  final AppLifecycleState? appLifecycleState;
}

bool isBackgroundTrackingSatisfiedForStatus(
  BackgroundTrackingStatusSnapshot snapshot,
) {
  if (!snapshot.requireBackground) {
    return true;
  }

  if (snapshot.serviceRunning) {
    return true;
  }

  final isForegroundSession =
      snapshot.appLifecycleState == AppLifecycleState.resumed;
  if (isForegroundSession && snapshot.isSharing) {
    return true;
  }

  if (!snapshot.hasBackgroundPermission) {
    return false;
  }

  // Once publishing is handed off to the foreground service, background
  // tracking is only healthy if that service is actually alive.
  if (snapshot.publishingHandledByService) {
    return false;
  }

  return snapshot.backgroundModeEnabled;
}
