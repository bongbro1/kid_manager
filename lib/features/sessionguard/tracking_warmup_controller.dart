import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/background/tracking_background_service.dart';
import 'package:kid_manager/features/sessionguard/tracking_warmup_snapshot.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/viewmodels/location/child_location_view_model.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:provider/provider.dart';

class TrackingWarmupController extends StatefulWidget {
  const TrackingWarmupController({
    super.key,
    required this.snapshot,
    required this.child,
  });

  final TrackingWarmupSnapshot snapshot;
  final Widget child;

  @override
  State<TrackingWarmupController> createState() =>
      _TrackingWarmupControllerState();
}

@visibleForTesting
bool shouldSyncTrackingState({
  required bool force,
  required String? lastAppliedTrackingKey,
  required String selfTrackingKey,
  required bool shouldShare,
  required bool isParent,
  required bool selfTrackingActive,
  required bool backgroundCurrentSharingActive,
}) {
  if (force) {
    return true;
  }

  if (lastAppliedTrackingKey != selfTrackingKey) {
    return true;
  }

  if (isParent) {
    return shouldShare != backgroundCurrentSharingActive;
  }

  return shouldShare != selfTrackingActive;
}

class _TrackingWarmupControllerState extends State<TrackingWarmupController>
    with WidgetsBindingObserver {
  bool _ready = false;
  bool _syncInFlight = false;
  bool _resyncRequested = false;
  bool _forceTrackingRequested = false;
  bool _postFrameSyncScheduled = false;
  bool _postFrameForceTracking = false;
  TrackingWarmupSnapshot? _pendingSnapshotToStop;
  bool _backgroundCurrentSharingActive = false;
  bool _selfTrackingActive = false;

  String? _startedMyLocationUid;
  String? _lastFamilyScopeKey;
  String? _lastLocationSyncKey;
  String? _lastAppliedTrackingKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _schedulePostFrameSync(forceTracking: true);
  }

  @override
  void didUpdateWidget(covariant TrackingWarmupController oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot.uid != widget.snapshot.uid ||
        oldWidget.snapshot.role != widget.snapshot.role) {
      _schedulePostFrameSync(
        forceTracking: true,
        snapshotToStop: oldWidget.snapshot,
      );
      return;
    }

    if (oldWidget.snapshot != widget.snapshot) {
      _schedulePostFrameSync();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _schedulePostFrameSync(forceTracking: true);
  }

  bool _isAppResumed() {
    return WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  void _schedulePostFrameSync({
    bool forceTracking = false,
    TrackingWarmupSnapshot? snapshotToStop,
  }) {
    _postFrameForceTracking = _postFrameForceTracking || forceTracking;
    if (snapshotToStop != null) {
      _pendingSnapshotToStop = snapshotToStop;
    }
    if (_postFrameSyncScheduled) {
      return;
    }

    _postFrameSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameSyncScheduled = false;
      final shouldForceTracking = _postFrameForceTracking;
      final pendingSnapshotToStop = _pendingSnapshotToStop;
      _postFrameForceTracking = false;
      _pendingSnapshotToStop = null;

      if (!mounted) return;
      unawaited(() async {
        if (pendingSnapshotToStop != null) {
          await _stopPreviousRoleState(pendingSnapshotToStop);
          _resetWarmupKeys();
        }
        await _queueSync(forceTracking: shouldForceTracking);
      }());
    });
  }

  Future<void> _queueSync({bool forceTracking = false}) async {
    if (_syncInFlight) {
      _resyncRequested = true;
      _forceTrackingRequested = _forceTrackingRequested || forceTracking;
      return;
    }

    _syncInFlight = true;
    try {
      var shouldForceTracking = forceTracking;
      do {
        _resyncRequested = false;
        _forceTrackingRequested = false;
        await _syncFromSnapshot(forceTracking: shouldForceTracking);
        shouldForceTracking = _forceTrackingRequested;
      } while (_resyncRequested && mounted);
    } finally {
      _syncInFlight = false;
      if (mounted && !_ready) {
        setState(() {
          _ready = true;
        });
      }
    }
  }

  Future<void> _syncFromSnapshot({bool forceTracking = false}) async {
    if (!mounted) return;
    final snapshot = widget.snapshot;
    if (snapshot.uid.isEmpty) {
      return;
    }

    if (snapshot.isLocationViewer) {
      await _ensureViewerWatches(snapshot);
      _ensureMyLocationStarted(snapshot.uid);
    }

    await _syncRoleTracking(snapshot, force: forceTracking);
  }

  Future<void> _ensureViewerWatches(TrackingWarmupSnapshot snapshot) async {
    if (snapshot.familyId.isEmpty) {
      return;
    }

    final userVm = context.read<UserVm>();

    if (_lastFamilyScopeKey != snapshot.familyScopeKey) {
      userVm.watchFamilyMembers(snapshot.familyId);
      userVm.watchLocationMembers(snapshot.familyId, excludeUid: snapshot.uid);
      if (snapshot.isParent) {
        userVm.watchChildren(snapshot.uid);
      }
      _lastFamilyScopeKey = snapshot.familyScopeKey;
    }

    if (_lastLocationSyncKey != snapshot.locationSyncKey) {
      await context.read<ParentLocationVm>().syncWatching(
        userVm.locationMembers,
      );
      _lastLocationSyncKey = snapshot.locationSyncKey;
    }
  }

  void _ensureMyLocationStarted(String uid) {
    if (_startedMyLocationUid == uid) {
      return;
    }
    _startedMyLocationUid = uid;
    unawaited(context.read<ParentLocationVm>().startMyLocation());
  }

  Future<void> _syncRoleTracking(
    TrackingWarmupSnapshot snapshot, {
    required bool force,
  }) async {
    if (!shouldSyncTrackingState(
      force: force,
      lastAppliedTrackingKey: _lastAppliedTrackingKey,
      selfTrackingKey: snapshot.selfTrackingKey,
      shouldShare: snapshot.allowTracking,
      isParent: snapshot.isParent,
      selfTrackingActive: _selfTrackingActive,
      backgroundCurrentSharingActive: _backgroundCurrentSharingActive,
    )) {
      return;
    }

    if (snapshot.isParent) {
      await _syncParentTracking(snapshot);
    } else if (snapshot.isGuardian || snapshot.isChild) {
      await _syncSelfTracking(snapshot, force: force);
    }
  }

  Future<void> _syncParentTracking(TrackingWarmupSnapshot snapshot) async {
    final locationVm = context.read<ParentLocationVm>();
    final locationService = context.read<LocationServiceInterface>();
    final shouldShareCurrent = snapshot.allowTracking;

    if (!shouldShareCurrent) {
      await locationVm.setCurrentSharingEnabled(false);
      if (_backgroundCurrentSharingActive ||
          await TrackingBackgroundService.isRunning()) {
        await TrackingBackgroundService.stop();
        _backgroundCurrentSharingActive = false;
      }
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    if (_isAppResumed()) {
      if (_backgroundCurrentSharingActive ||
          await TrackingBackgroundService.isRunning()) {
        await TrackingBackgroundService.stop();
        _backgroundCurrentSharingActive = false;
      }
      await locationVm.setCurrentSharingEnabled(true);
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    if (_backgroundCurrentSharingActive) {
      await locationVm.setCurrentSharingEnabled(false);
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    final hasForegroundPermission = await locationService.hasLocationPermission(
      requireBackground: false,
    );
    final serviceEnabled = await locationService.isServiceEnabled();
    if (!hasForegroundPermission || !serviceEnabled) {
      await locationVm.setCurrentSharingEnabled(true);
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    final started = await TrackingBackgroundService.startForCurrentUser(
      requireBackground: true,
      currentOnly: true,
      parentUid: snapshot.uid,
      familyId: snapshot.familyId,
      displayName: snapshot.displayName,
      timeZone: snapshot.timeZone,
    );

    if (!started) {
      _backgroundCurrentSharingActive = false;
      await locationVm.setCurrentSharingEnabled(true);
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    final ready = await TrackingBackgroundService.waitUntilReady();
    _backgroundCurrentSharingActive = ready;
    await locationVm.setCurrentSharingEnabled(!ready);
    _lastAppliedTrackingKey = snapshot.selfTrackingKey;
  }

  Future<void> _syncSelfTracking(
    TrackingWarmupSnapshot snapshot, {
    required bool force,
  }) async {
    final childLocationVm = _readOptional<ChildLocationViewModel>();
    if (childLocationVm == null) {
      return;
    }

    final locationService = context.read<LocationServiceInterface>();
    final shouldShare = snapshot.allowTracking;

    if (shouldShare && !_selfTrackingActive) {
      final hasForegroundPermission = await locationService
          .hasLocationPermission(requireBackground: false);
      final serviceEnabled = await locationService.isServiceEnabled();
      if (!hasForegroundPermission || !serviceEnabled) {
        _lastAppliedTrackingKey = snapshot.selfTrackingKey;
        return;
      }

      await childLocationVm.startLocationSharing(background: true);
      _selfTrackingActive = childLocationVm.isSharing;
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    if (shouldShare && _selfTrackingActive) {
      if (force) {
        await childLocationVm.refreshLifecycleRouting();
        _selfTrackingActive = childLocationVm.isSharing;
      }
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    if (!shouldShare && _selfTrackingActive) {
      await childLocationVm.stopSharing(clearData: false);
      _selfTrackingActive = false;
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
      return;
    }

    if (!shouldShare && !_selfTrackingActive) {
      _lastAppliedTrackingKey = snapshot.selfTrackingKey;
    }
  }

  Future<void> _stopPreviousRoleState(TrackingWarmupSnapshot snapshot) async {
    if (!mounted || snapshot.uid.isEmpty) {
      return;
    }

    if (snapshot.isParent) {
      await context.read<ParentLocationVm>().setCurrentSharingEnabled(false);
      if (_backgroundCurrentSharingActive ||
          await TrackingBackgroundService.isRunning()) {
        await TrackingBackgroundService.stop();
        _backgroundCurrentSharingActive = false;
      }
      return;
    }

    final childLocationVm = _readOptional<ChildLocationViewModel>();
    if (childLocationVm != null && _selfTrackingActive) {
      await childLocationVm.stopSharing(clearData: false);
      _selfTrackingActive = false;
    }
  }

  T? _readOptional<T>() {
    try {
      return context.read<T>();
    } catch (_) {
      return null;
    }
  }

  void _resetWarmupKeys() {
    _startedMyLocationUid = null;
    _lastFamilyScopeKey = null;
    _lastLocationSyncKey = null;
    _lastAppliedTrackingKey = null;
    _backgroundCurrentSharingActive = false;
    _selfTrackingActive = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.snapshot.isChild && !_ready) {
      return const _WarmupLoadingView();
    }
    return widget.child;
  }
}

class _WarmupLoadingView extends StatelessWidget {
  const _WarmupLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
