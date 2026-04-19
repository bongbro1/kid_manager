import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/location/current_publish_policy.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/core/location/tracking_tuning.dart';
import 'package:kid_manager/core/zones/zone_monitor.dart';
import 'package:kid_manager/features/pipeline/tracking_pipeline.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/background/tracking_runtime_config.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/services/location/background_tracking_status_policy.dart';
import 'package:kid_manager/services/device_power_service.dart';
import 'package:kid_manager/services/location/location_day_key_resolver.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/services/location/tracking_status_service.dart';
import 'package:kid_manager/utils/app_localizations_loader.dart';
import 'package:kid_manager/widgets/app/app_mode.dart';
import 'package:kid_manager/background/tracking_background_service.dart';

class ChildLocationViewModel extends ChangeNotifier {
  static const Duration _uiNotifyThrottle = Duration(milliseconds: 250);
  static const Duration _historyFlushInterval = Duration(seconds: 10);
  static const int _historyFlushBatchSize = 5;
  static const Duration _zoneLaneThrottle = Duration(seconds: 5);
  static const double _zoneLaneMinDistanceMeters = 15;

  ChildLocationViewModel(
    this._locationRepository,
    this._locationService, {
    FirebaseAuth? auth,
    DevicePowerService? devicePowerService,
    TrackingStatusService? trackingStatusService,
    LocationDayKeyResolver? dayKeyResolver,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _devicePowerService = devicePowerService ?? DevicePowerService(),
       _dayKeyResolver = dayKeyResolver ?? LocationDayKeyResolver(),
       _trackingStatusService =
           trackingStatusService ?? TrackingStatusService() {
    _authStateSub = _auth.authStateChanges().listen(_handleAuthStateChanged);
  }

  final LocationRepository _locationRepository;
  final LocationServiceInterface _locationService;
  final FirebaseAuth _auth;
  final DevicePowerService _devicePowerService;
  final LocationDayKeyResolver _dayKeyResolver;
  final TrackingStatusService _trackingStatusService;
  StreamSubscription<User?>? _authStateSub;
  bool _disposed = false;

  Timer? _healthTimer;

  bool _locationServiceEnabled = true;
  bool get locationServiceEnabled => _locationServiceEnabled;

  bool _locationPermissionGranted = true;
  bool get locationPermissionGranted => _locationPermissionGranted;

  DateTime? _lastGoodFixAt;
  DateTime? get lastGoodFixAt => _lastGoodFixAt;

  String? _lastTrackingStatus;
  int _lastStatusHeartbeatAtMs = 0;
  int _lastCurrentSentAtMs = 0;
  int _lastCurrentFailureAtMs = 0;
  int _lastHistoryFailureAtMs = 0;
  bool _sentInitialCurrent = false;
  // ===== STATE =====
  LocationData? _currentLocation;
  LocationData? get currentLocation => _currentLocation;

  LocationPlayMode _mode = LocationPlayMode.live;
  LocationPlayMode get mode => _mode;

  MotionState _motionState = MotionState.moving;
  MotionState get motionState => _motionState;

  StreamSubscription<Activity>? _activitySub;
  Activity? _lastActivity;

  ZoneMonitor? _zoneMonitor;
  StreamSubscription<List<GeoZone>>? _zonesSub;
  bool _zonesInited = false;
  String? _zoneMonitorUid;

  TransportMode _transport = TransportMode.unknown;
  TransportMode get transport => _transport;

  final List<LocationData> _trail = [];
  List<LocationData> get locationTrail => List.unmodifiable(_trail);
  bool _isSharing = false;
  bool get isSharing => _isSharing;

  bool _requireBackground = false;
  bool get requireBackground => _requireBackground;

  bool _publishingHandledByService = false;
  bool get publishingHandledByService => _publishingHandledByService;

  String? _error;
  String? get error => _error;

  // ===== INTERNAL =====
  late final TrackingPipeline _engine = TrackingPipeline(
    motionDetector: MotionDetector(),
    sendPolicy: SendPolicy(),
  );

  StreamSubscription<LocationData>? _gpsSub;
  LocationData? _pendingGpsLocation;
  bool _gpsDrainInFlight = false;

  _QueuedCurrentUpload? _pendingCurrentUpload;
  bool _currentUploadInFlight = false;
  int _lastCurrentQueuedAtMs = 0;

  final List<_QueuedHistoryUpload> _historyUploadQueue = <_QueuedHistoryUpload>[];
  bool _historyUploadInFlight = false;
  Timer? _historyFlushTimer;

  LocationData? _pendingZoneLocation;
  LocationData? _lastZoneCheckLocation;
  bool _zoneCheckInFlight = false;
  int _lastZoneCheckAtMs = 0;
  Timer? _zoneFlushTimer;

  Timer? _notifyThrottleTimer;
  DateTime? _lastUiNotifyAt;
  String _trackingStatusOkMessage = "";

  bool _restarting = false;
  String? _activeSharingUid;
  Future<AppLocalizations>? _l10nFuture;
  String? _l10nUid;

  AppLocalizations _fallbackL10n() {
    final lang = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return lookupAppLocalizations(Locale(lang == 'en' ? 'en' : 'vi'));
  }

  Future<AppLocalizations> _getL10n() {
    final uid = _auth.currentUser?.uid;
    if (_l10nFuture != null && _l10nUid == uid) {
      return _l10nFuture!;
    }

    final fallbackLang =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase() == 'en'
        ? 'en'
        : 'vi';
    _l10nUid = uid;
    _l10nFuture = AppLocalizationsLoader.loadForUser(
      userRepository: UserRepository.background(FirebaseFirestore.instance),
      uid: uid,
      fallbackLang: fallbackLang,
    );
    return _l10nFuture!;
  }

  Future<TrackingRoutingContext?> _loadTrackingRoutingContext() async {
    final uid = _currentUidOrNull();
    if (uid == null) {
      return null;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = snapshot.data();
      if (data == null) {
        return null;
      }

      final parentUid = data['parentUid']?.toString().trim();
      final familyId = data['familyId']?.toString().trim();
      final timeZone = await _dayKeyResolver.resolvePreferredTimeZone(
        data['timezone']?.toString(),
      );
      return TrackingRoutingContext(
        userId: uid,
        parentUid: parentUid?.isEmpty == true ? null : parentUid,
        familyId: familyId?.isEmpty == true ? null : familyId,
        timeZone: timeZone,
      );
    } catch (e, st) {
      debugPrint('ChildLocationViewModel load routing context error: $e');
      debugPrint('$st');
      return null;
    }
  }

  String? _currentUidOrNull() {
    final uid = _auth.currentUser?.uid.trim();
    if (uid == null || uid.isEmpty) {
      return null;
    }
    return uid;
  }

  void _handleAuthStateChanged(User? user) {
    if (_disposed) return;
    final nextUid = user?.uid.trim();
    final activeSharingUid = _activeSharingUid;
    if (activeSharingUid == null || nextUid == activeSharingUid) {
      return;
    }

    if (kDebugMode) {
      debugPrint(
        'Child location sharing stopped because auth session changed.',
      );
    }
    unawaited(stopSharingOnLogout());
  }

  String _requireUid() {
    final uid = _currentUidOrNull();
    if (uid == null || uid.isEmpty) {
      throw Exception(_fallbackL10n().authLoginRequired);
    }
    return uid;
  }

  void _setError(Object? e) {
    if (_disposed) return;
    _error = e?.toString();
    notifyListeners();
  }

  void clearError() {
    if (_disposed) return;
    _error = null;
    notifyListeners();
  }

  // used on LOGOUT (clear state)
  Future<void> stopSharingOnLogout() async {
    if (_disposed) return;
    await stopSharing(clearData: true);
    await _activitySub?.cancel();
    await _zonesSub?.cancel();
    _zonesSub = null;
    _zonesInited = false;
    _zoneMonitorUid = null;
    _activeSharingUid = null;
    _activitySub = null;
    _lastActivity = null;
    _l10nFuture = null;
    _l10nUid = null;
  }

  bool _isJumpTooLarge(LocationData? prev, LocationData next) {
    if (prev == null) return false;

    final dtSec = (next.timestamp - prev.timestamp) / 1000.0;
    if (dtSec <= 0) return true;

    final distanceMeters = prev.distanceTo(next) * 1000.0;
    final speedMps = distanceMeters / dtSec;

    // > 45 m/s ~ 162 km/h, unusually high for a child.
    return speedMps > 45;
  }

  Future<void> _ensureZoneMonitor(String uid) async {
    if (_disposed) return;
    if (_zonesInited && _zoneMonitorUid == uid) return;

    final repo = ZoneRepository();

    await _zonesSub?.cancel();
    if (_disposed) return;
    _zoneMonitor = ZoneMonitor(repo: repo, childUid: uid);
    _zoneMonitorUid = uid;
    _zonesSub = repo
        .watchZones(uid)
        .listen(
          (zones) => _zoneMonitor?.updateZones(zones),
          onError: (e) => debugPrint("zones watch error: $e"),
        );

    _zonesInited = true;
  }

  Future<void> _reportTrackingStatusIfChanged(
    String status, {
    String? message,
    bool force = false,
  }) async {
    if (_publishingHandledByService) return;
    if (!force && _lastTrackingStatus == status) return;
    _lastTrackingStatus = status;

    try {
      await _trackingStatusService.reportStatus(
        status: status,
        message: message,
      );
    } catch (e) {
      debugPrint('reportTrackingStatus error: $e');
    }
  }

  Future<void> _startHealthMonitor() async {
    if (_disposed) return;
    _healthTimer?.cancel();

    _healthTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      if (_disposed) return;
      try {
        final l10n = await _getL10n();
        if (_disposed) return;
        final serviceEnabled = await _locationService.isServiceEnabled();
        final permissionGranted = await _locationService.hasLocationPermission(
          requireBackground: _requireBackground,
        );
        final preciseGranted = await _locationService
            .hasPreciseLocationPermission();
        if (_disposed) return;

        _locationServiceEnabled = serviceEnabled;
        _locationPermissionGranted = permissionGranted && preciseGranted;

        if (!serviceEnabled) {
          await _reportTrackingStatusIfChanged(
            'location_service_off',
            message: l10n.trackingStatusLocationServiceOffMessage,
          );
          notifyListeners();
          return;
        }

        if (!permissionGranted || !preciseGranted) {
          await _reportTrackingStatusIfChanged(
            'location_permission_denied',
            message: preciseGranted
                ? l10n.trackingStatusLocationPermissionDeniedMessage
                : l10n.trackingStatusPreciseLocationDeniedMessage,
          );
          notifyListeners();
          return;
        }

        if (_requireBackground) {
          final backgroundSatisfied =
              await _isBackgroundTrackingSatisfiedForStatus();
          if (!backgroundSatisfied) {
            await _reportTrackingStatusIfChanged(
              'background_disabled',
              message: l10n.trackingStatusBackgroundDisabledMessage,
            );
            notifyListeners();
            return;
          }
        }

        final nowMs = DateTime.now().millisecondsSinceEpoch;
        final shouldHeartbeatOk =
            _lastTrackingStatus != 'ok' ||
            nowMs - _lastStatusHeartbeatAtMs >= 60000;
        if (shouldHeartbeatOk) {
          _lastStatusHeartbeatAtMs = nowMs;
          await _reportTrackingStatusIfChanged(
            'ok',
            message: l10n.trackingStatusOkMessage,
            force: true,
          );
        }

        notifyListeners();
      } catch (e) {
        debugPrint('health monitor error: $e');
      }
    });
  }

  bool _canAttemptSend({
    required int nowMs,
    required int lastSuccessAtMs,
    required int lastFailureAtMs,
    required Duration minSuccessInterval,
    Duration failureBackoff = const Duration(seconds: 5),
  }) {
    final nextAfterSuccess =
        lastSuccessAtMs + minSuccessInterval.inMilliseconds;
    final nextAfterFailure = lastFailureAtMs + failureBackoff.inMilliseconds;
    return nowMs >= nextAfterSuccess && nowMs >= nextAfterFailure;
  }

  void _scheduleUiNotify({bool immediate = false}) {
    if (_disposed) return;

    final now = DateTime.now();
    final lastUiNotifyAt = _lastUiNotifyAt;
    final elapsed = lastUiNotifyAt == null
        ? _uiNotifyThrottle
        : now.difference(lastUiNotifyAt);

    if (immediate || elapsed >= _uiNotifyThrottle) {
      _notifyThrottleTimer?.cancel();
      _notifyThrottleTimer = null;
      _lastUiNotifyAt = now;
      super.notifyListeners();
      return;
    }

    if (_notifyThrottleTimer?.isActive == true) {
      return;
    }

    _notifyThrottleTimer = Timer(_uiNotifyThrottle - elapsed, () {
      _notifyThrottleTimer = null;
      if (_disposed) return;
      _lastUiNotifyAt = DateTime.now();
      super.notifyListeners();
    });
  }

  void _resetAsyncPipelines() {
    _pendingGpsLocation = null;
    _gpsDrainInFlight = false;
    _pendingCurrentUpload = null;
    _currentUploadInFlight = false;
    _lastCurrentQueuedAtMs = 0;
    _historyUploadQueue.clear();
    _historyUploadInFlight = false;
    _historyFlushTimer?.cancel();
    _historyFlushTimer = null;
    _pendingZoneLocation = null;
    _lastZoneCheckLocation = null;
    _zoneCheckInFlight = false;
    _lastZoneCheckAtMs = 0;
    _zoneFlushTimer?.cancel();
    _zoneFlushTimer = null;
    _notifyThrottleTimer?.cancel();
    _notifyThrottleTimer = null;
  }

  void _enqueueGpsLocation(LocationData raw) {
    if (_disposed) return;
    _pendingGpsLocation = raw;
    if (_gpsDrainInFlight) return;
    _gpsDrainInFlight = true;
    unawaited(_drainGpsLocations());
  }

  Future<void> _drainGpsLocations() async {
    try {
      while (!_disposed) {
        final raw = _pendingGpsLocation;
        if (raw == null) {
          break;
        }
        _pendingGpsLocation = null;
        await _handleGpsLocation(raw);
      }
    } finally {
      _gpsDrainInFlight = false;
      if (!_disposed && _pendingGpsLocation != null) {
        _gpsDrainInFlight = true;
        unawaited(_drainGpsLocations());
      }
    }
  }

  void _enqueueCurrentUpload({
    required TrackingPayload payload,
    required int nowMs,
  }) {
    if (_disposed || _publishingHandledByService) return;
    _pendingCurrentUpload = _QueuedCurrentUpload(
      payload: payload,
      queuedAtMs: nowMs,
      okStatusMessage: _trackingStatusOkMessage,
    );
    _lastCurrentQueuedAtMs = nowMs;
    if (_currentUploadInFlight) return;
    _currentUploadInFlight = true;
    unawaited(_drainCurrentUploads());
  }

  Future<void> _drainCurrentUploads() async {
    try {
      while (!_disposed) {
        final upload = _pendingCurrentUpload;
        if (upload == null) {
          break;
        }
        _pendingCurrentUpload = null;

        try {
          await _locationRepository.updateMyCurrent(upload.payload);
          _lastCurrentSentAtMs = upload.queuedAtMs;
          _lastCurrentFailureAtMs = 0;
          _sentInitialCurrent = true;
          await _reportTrackingStatusIfChanged(
            'ok',
            message: upload.okStatusMessage,
          );
          if (_error != null) {
            _error = null;
            _scheduleUiNotify();
          }
        } catch (e) {
          _lastCurrentFailureAtMs = DateTime.now().millisecondsSinceEpoch;
          debugPrint('ERROR CURRENT LOCATION: $e');
          _setError(e);
        }
      }
    } finally {
      _currentUploadInFlight = false;
      if (!_disposed && _pendingCurrentUpload != null) {
        _currentUploadInFlight = true;
        unawaited(_drainCurrentUploads());
      }
    }
  }

  void _enqueueHistoryUpload({
    required TrackingPayload payload,
    required LocationData filteredLocation,
    required MotionState motionState,
  }) {
    if (_disposed || _publishingHandledByService) return;
    _historyUploadQueue.add(
      _QueuedHistoryUpload(
        payload: payload,
        filteredLocation: filteredLocation,
        motionState: motionState,
      ),
    );

    if (_historyUploadQueue.length >= _historyFlushBatchSize) {
      _historyFlushTimer?.cancel();
      _historyFlushTimer = null;
      if (!_historyUploadInFlight) {
        unawaited(_flushHistoryUploads());
      }
      return;
    }

    _historyFlushTimer ??= Timer(_historyFlushInterval, () {
      _historyFlushTimer = null;
      unawaited(_flushHistoryUploads());
    });
  }

  Future<void> _flushHistoryUploads() async {
    if (
      _disposed ||
      _publishingHandledByService ||
      _historyUploadInFlight ||
      _historyUploadQueue.isEmpty
    ) {
      return;
    }

    _historyFlushTimer?.cancel();
    _historyFlushTimer = null;
    _historyUploadInFlight = true;

    try {
      while (!_disposed && _historyUploadQueue.isNotEmpty) {
        final batchSize = _historyUploadQueue.length >= _historyFlushBatchSize
            ? _historyFlushBatchSize
            : _historyUploadQueue.length;
        final batch = _historyUploadQueue.sublist(0, batchSize).toList();
        _historyUploadQueue.removeRange(0, batchSize);

        for (var index = 0; index < batch.length; index++) {
          final upload = batch[index];
          try {
            await _locationRepository.appendMyHistory(upload.payload);
            _lastHistoryFailureAtMs = 0;
            _engine.acknowledgeHistorySent(
              upload.filteredLocation,
              upload.motionState,
            );
          } catch (e) {
            _lastHistoryFailureAtMs = DateTime.now().millisecondsSinceEpoch;
            debugPrint('ERROR HISTORY LOCATION: $e');
            _setError(e);
            _historyUploadQueue.insertAll(0, batch.skip(index));
            return;
          }
        }
      }
    } finally {
      _historyUploadInFlight = false;
      if (!_disposed && _historyUploadQueue.isNotEmpty) {
        _historyFlushTimer ??= Timer(_historyFlushInterval, () {
          _historyFlushTimer = null;
          unawaited(_flushHistoryUploads());
        });
      }
    }
  }

  void _enqueueZoneCheck(LocationData location) {
    if (_disposed || _publishingHandledByService || !_zonesInited) {
      return;
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastZoneCheckLocation = _lastZoneCheckLocation;
    final movedEnough =
        lastZoneCheckLocation == null ||
        lastZoneCheckLocation.distanceTo(location) * 1000 >=
            _zoneLaneMinDistanceMeters;
    final intervalElapsed =
        nowMs - _lastZoneCheckAtMs >= _zoneLaneThrottle.inMilliseconds;

    _pendingZoneLocation = location;
    if (_zoneCheckInFlight) {
      return;
    }

    if (movedEnough || intervalElapsed) {
      _zoneFlushTimer?.cancel();
      _zoneFlushTimer = null;
      unawaited(_drainZoneChecks());
      return;
    }

    final remainingMs =
        _zoneLaneThrottle.inMilliseconds - (nowMs - _lastZoneCheckAtMs);
    _zoneFlushTimer ??= Timer(
      Duration(
        milliseconds: (remainingMs.clamp(
          0,
          _zoneLaneThrottle.inMilliseconds,
        ) as num).toInt(),
      ),
      () {
        _zoneFlushTimer = null;
        unawaited(_drainZoneChecks());
      },
    );
  }

  Future<void> _drainZoneChecks() async {
    if (
      _disposed ||
      _publishingHandledByService ||
      !_zonesInited ||
      _zoneCheckInFlight
    ) {
      return;
    }

    final location = _pendingZoneLocation;
    if (location == null) {
      return;
    }

    _pendingZoneLocation = null;
    _zoneFlushTimer?.cancel();
    _zoneFlushTimer = null;
    _zoneCheckInFlight = true;

    try {
      debugPrint(
        "Checking zones for location: lat=${location.latitude} lng=${location.longitude}",
      );
      await _zoneMonitor?.onLocation(location);
      _lastZoneCheckLocation = location;
      _lastZoneCheckAtMs = DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      debugPrint("zoneMonitor error: $e");
    } finally {
      _zoneCheckInFlight = false;
      if (!_disposed && _pendingZoneLocation != null) {
        _enqueueZoneCheck(_pendingZoneLocation!);
      }
    }
  }

  Future<void> _handleGpsLocation(LocationData raw) async {
    if (_disposed) return;
    final activeSharingUid = _activeSharingUid;
    final currentUid = _currentUidOrNull();
    if (
      !_isSharing ||
      activeSharingUid == null ||
      currentUid == null ||
      currentUid != activeSharingUid
    ) {
      if (kDebugMode) {
        debugPrint(
          'Drop child location update because auth session is no longer valid.',
        );
      }
      unawaited(stopSharingOnLogout());
      return;
    }

    debugPrint('GPS RAW: acc=${raw.accuracy}');

    final result = _engine.process(
      raw,
      _lastActivity,
      previousReference: _currentLocation,
    );
    if (_disposed) return;
    final filtered = result.filteredLocation;
    final acc = filtered.accuracy;

    if (acc <= TrackingTuning.historyGoodAccuracyMaxM) {
      _lastGoodFixAt = DateTime.now();
    }
    final shouldGuardJump = _sentInitialCurrent && _currentLocation != null;
    if (
      shouldGuardJump &&
      _isJumpTooLarge(_currentLocation, filtered) &&
      filtered.accuracy > TrackingTuning.jumpGuardBadAccuracyMinM
    ) {
      debugPrint('Skip jump point: acc=${filtered.accuracy}');
      return;
    }

    _transport = result.transport;
    final shouldUpdateCurrentLocation =
        _currentLocation == null || acc <= TrackingTuning.weakAccuracyMaxM;
    _motionState = result.motion;

    if (!_publishingHandledByService) {
      _enqueueZoneCheck(filtered);
    }

    final currentLocation = await _attachCurrentBattery(filtered);
    if (_disposed) return;
    if (shouldUpdateCurrentLocation) {
      _currentLocation = currentLocation;
    }

    final currentPayload = TrackingPayload(
      deviceId: activeSharingUid,
      location: currentLocation,
      motion: result.motion.name,
      transport: _transport.name,
    );
    final historyPayload = TrackingPayload(
      deviceId: activeSharingUid,
      location: filtered,
      motion: result.motion.name,
      transport: _transport.name,
    );

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final rejectVeryBadAcc = acc > TrackingTuning.currentRejectAccuracyMaxM;
    final isMoving = result.motion == MotionState.moving;
    final goodHistoryAcc = acc <= TrackingTuning.historyGoodAccuracyMaxM;
    final shouldSendInitialCurrent = !_sentInitialCurrent && !rejectVeryBadAcc;

    final currentInterval = currentPublishInterval(
      motion: result.motion,
      accuracy: acc,
      shouldSendInitialCurrent: shouldSendInitialCurrent,
      indoorSuppressed: result.indoorSuppressed,
    );
    final shouldAttemptCurrentSend =
        !_publishingHandledByService &&
        currentInterval != null &&
        _canAttemptSend(
          nowMs: nowMs,
          lastSuccessAtMs: _lastCurrentSentAtMs > _lastCurrentQueuedAtMs
              ? _lastCurrentSentAtMs
              : _lastCurrentQueuedAtMs,
          lastFailureAtMs: _lastCurrentFailureAtMs,
          minSuccessInterval: currentInterval,
        );

    if (shouldAttemptCurrentSend) {
      final resolvedCurrentInterval = currentInterval;
      if (result.indoorSuppressed && kDebugMode) {
        debugPrint(
          'ChildLocationViewModel current update anchored due to weak GPS '
          'acc=${acc.toStringAsFixed(1)} '
          'interval=${resolvedCurrentInterval.inSeconds}s',
        );
      }
      _enqueueCurrentUpload(payload: currentPayload, nowMs: nowMs);
    }

    final historySendWindowOpen = _canAttemptSend(
      nowMs: nowMs,
      lastSuccessAtMs: 0,
      lastFailureAtMs: _lastHistoryFailureAtMs,
      minSuccessInterval: Duration.zero,
    );
    if (
      !_publishingHandledByService &&
      isMoving &&
      goodHistoryAcc &&
      result.indoorSuppressed &&
      historySendWindowOpen &&
      kDebugMode
    ) {
      debugPrint(
        'ChildLocationViewModel history send skipped due to indoor '
        'suppression acc=${acc.toStringAsFixed(1)}',
      );
    }
    if (
      !_publishingHandledByService &&
      isMoving &&
      !result.indoorSuppressed &&
      result.shouldSend &&
      goodHistoryAcc &&
      historySendWindowOpen
    ) {
      _enqueueHistoryUpload(
        payload: historyPayload,
        filteredLocation: filtered,
        motionState: result.motion,
      );
    }

    if (
      _publishingHandledByService &&
      isMoving &&
      result.shouldSend &&
      goodHistoryAcc
    ) {
      _engine.acknowledgeHistorySent(filtered, result.motion);
    }

    if (acc <= TrackingTuning.historyGoodAccuracyMaxM) {
      _appendTrail(result.filteredLocation);
    }
    _scheduleUiNotify();
  }

  /// Stop sharing (clearData=false if paused, true on logout)
  Future<void> stopSharing({bool clearData = false}) async {
    final serviceBacked =
        _publishingHandledByService ||
        await TrackingBackgroundService.isRunning();
    _publishingHandledByService = false;

    if (serviceBacked) {
      await TrackingBackgroundService.stop();
    }

    await _gpsSub?.cancel();
    _gpsSub = null;
    _engine.reset();
    _resetAsyncPipelines();
    _activeSharingUid = null;

    _isSharing = false;
    _restarting = false;
    _lastTrackingStatus = null;
    _lastStatusHeartbeatAtMs = 0;
    _lastCurrentSentAtMs = 0;
    _lastCurrentFailureAtMs = 0;
    _lastHistoryFailureAtMs = 0;
    _sentInitialCurrent = false;
    _trackingStatusOkMessage = "";

    _isSharing = false;
    _restarting = false;

    _healthTimer?.cancel();
    _healthTimer = null;

    if (clearData) {
      _currentLocation = null;
      _trail.clear();
      _requireBackground = false;
      _error = null;
    }

    if (_disposed) return;
    notifyListeners();
  }

  /// Start sharing with background mode by default so tracking keeps running.
  Future<void> startLocationSharing({bool background = true}) async {
    if (_disposed) return;
    if (_isSharing) return;

    final l10n = await _getL10n();
    if (_disposed) return;
    late final String sharingUid;

    try {
      sharingUid = _requireUid();
    } catch (e) {
      _setError(e);
      return;
    }

    _error = null;

    // allow caller override requireBackground
    _requireBackground = background;
    debugPrint(
      '[SelfTracking] start requested uid=$sharingUid '
      'requireBackground=$_requireBackground',
    );
    notifyListeners();

    var ok = false;
    try {
      ok = await _locationService.ensureServiceAndPermission(
        requireBackground: _requireBackground,
        enablePluginBackgroundMode: false,
        notificationTitle: l10n.locationForegroundServiceTitle,
        notificationSubtitle: l10n.locationForegroundServiceSubtitle,
      );
    } catch (e, st) {
      debugPrint('ensureServiceAndPermission error: $e');
      debugPrint('$st');
      ok = false;
    }
    if (_disposed) return;

    // Background permission is often denied on first run.
    // Fall back to foreground tracking so location can still be sent.
    if (!ok && _requireBackground) {
      bool fgOk = false;
      try {
        fgOk = await _locationService.ensureServiceAndPermission(
          requireBackground: false,
        );
      } catch (e, st) {
        debugPrint('ensureServiceAndPermission fallback error: $e');
        debugPrint('$st');
        fgOk = false;
      }
      if (fgOk) {
        debugPrint(
          'Background location unavailable, fallback to foreground tracking',
        );
        _requireBackground = false;
        ok = true;
      }
    }
    if (_disposed) return;

    if (!ok) {
      final serviceEnabled = await _locationService.isServiceEnabled();
      if (_disposed) return;
      _locationServiceEnabled = serviceEnabled;
      if (!serviceEnabled) {
        await _reportTrackingStatusIfChanged(
          'location_service_off',
          message: l10n.trackingStatusLocationServiceOffMessage,
        );
        _error = l10n.trackingErrorEnableLocationService;
      } else {
        final preciseGranted = await _locationService
            .hasPreciseLocationPermission();
        if (!preciseGranted) {
          await _reportTrackingStatusIfChanged(
            'location_permission_denied',
            message: l10n.trackingStatusPreciseLocationDeniedMessage,
          );
          _error = l10n.trackingErrorEnablePreciseLocation;
        } else if (_requireBackground) {
          final backgroundSatisfied =
              await _isBackgroundTrackingSatisfiedForStatus();
          if (!backgroundSatisfied) {
            await _reportTrackingStatusIfChanged(
              'background_disabled',
              message: l10n.trackingStatusBackgroundDisabledMessage,
            );
            _error = l10n.trackingErrorEnableBackgroundLocation;
          }
        }
      }
      _locationPermissionGranted = false;
      _isSharing = false;
      debugPrint(
        '[SelfTracking] start blocked uid=$sharingUid '
        'serviceEnabled=$serviceEnabled '
        'requireBackground=$_requireBackground '
        'error=$_error',
      );
      notifyListeners();
      return;
    }

    final currentUid = _currentUidOrNull();
    if (currentUid == null || currentUid != sharingUid) {
      _setError(_fallbackL10n().authLoginRequired);
      return;
    }

    var serviceStarted = false;
    final shouldUseBackgroundService = _requireBackground && !_isAppResumed();
    if (shouldUseBackgroundService) {
      final routingContext = await _loadTrackingRoutingContext();
      serviceStarted = await TrackingBackgroundService.startForCurrentUser(
        requireBackground: _requireBackground,
        parentUid: routingContext?.parentUid,
        familyId: routingContext?.familyId,
        timeZone: routingContext?.timeZone,
      );
      if (serviceStarted) {
        final runtimeReady = await TrackingBackgroundService.waitUntilReady();
        _publishingHandledByService = runtimeReady;
        if (!runtimeReady) {
          debugPrint(
            'Tracking foreground service started but background runtime is not ready yet; keep local publisher active.',
          );
        }
      } else {
        _publishingHandledByService = false;
      }
      debugPrint(
        '[SelfTracking] background bootstrap uid=$sharingUid '
        'serviceStarted=$serviceStarted '
        'runtimeReady=$_publishingHandledByService '
        'shouldUseBackgroundService=$shouldUseBackgroundService '
        'parentUid=${routingContext?.parentUid} '
        'familyId=${routingContext?.familyId}',
      );
    }

    if (!_publishingHandledByService && _requireBackground && !_isAppResumed()) {
      try {
        await _locationService.ensureServiceAndPermission(
          requireBackground: true,
          requestIfNeeded: false,
          enablePluginBackgroundMode: true,
          notificationTitle: l10n.locationForegroundServiceTitle,
          notificationSubtitle: l10n.locationForegroundServiceSubtitle,
        );
      } catch (e, st) {
        debugPrint('enable native plugin background mode fallback error: $e');
        debugPrint('$st');
      }
    }

    _sentInitialCurrent = false;
    _activeSharingUid = sharingUid;
    _isSharing = true;
    _motionState = MotionState.moving;
    _trackingStatusOkMessage = l10n.trackingStatusOkMessage;
    debugPrint(
      '[SelfTracking] publisher active uid=$sharingUid '
      'handledByService=$_publishingHandledByService '
      'requireBackground=$_requireBackground',
    );
    await _startHealthMonitor();
    if (_disposed) return;

    notifyListeners();

    // listen GPS stream
    await _startActivityRecognition();
    if (_disposed) return;
    if (!_publishingHandledByService) {
      await _ensureZoneMonitor(sharingUid);
    }
    if (_disposed) return;
    _gpsSub = _locationService.getLocationStream().listen((raw) {
      _enqueueGpsLocation(raw);
    });
  }

  /// Android 11+: request background permission (usually opens Settings)
  Future<void> enableBackgroundSharing() async {
    if (_disposed) return;
    _requireBackground = true;
    notifyListeners();

    final l10n = await _getL10n();
    if (_disposed) return;
    final ok = await _locationService.ensureServiceAndPermission(
      requireBackground: true,
      enablePluginBackgroundMode: !_publishingHandledByService,
      notificationTitle: l10n.locationForegroundServiceTitle,
      notificationSubtitle: l10n.locationForegroundServiceSubtitle,
    );

    if (_disposed) return;
    if (!ok) return;

    // If already sharing, restart once to bind new permission state.
    if (_isSharing) {
      await _restartSharing(delay: const Duration(milliseconds: 300));
    }
  }

  bool _isAppResumed() {
    return SchedulerBinding.instance.lifecycleState ==
        AppLifecycleState.resumed;
  }

  Future<bool> _isBackgroundTrackingSatisfiedForStatus() async {
    if (!_requireBackground) {
      return true;
    }

    final serviceRunning = await TrackingBackgroundService.isRunning();
    final hasBackgroundPermission = await _locationService
        .hasBackgroundLocationPermission();

    var backgroundModeEnabled = false;
    final shouldProbePluginBackgroundMode =
        _requireBackground &&
        !serviceRunning &&
        !_publishingHandledByService &&
        !(_isAppResumed() && _isSharing) &&
        hasBackgroundPermission;
    if (shouldProbePluginBackgroundMode) {
      backgroundModeEnabled = await _locationService.isBackgroundModeEnabled();
    }

    return isBackgroundTrackingSatisfiedForStatus(
      BackgroundTrackingStatusSnapshot(
        requireBackground: _requireBackground,
        serviceRunning: serviceRunning,
        isSharing: _isSharing,
        publishingHandledByService: _publishingHandledByService,
        hasBackgroundPermission: hasBackgroundPermission,
        backgroundModeEnabled: backgroundModeEnabled,
        appLifecycleState: SchedulerBinding.instance.lifecycleState,
      ),
    );
  }

  Future<void> refreshLifecycleRouting() async {
    if (_disposed || !_isSharing) return;

    final appResumed = _isAppResumed();
    final serviceRunning = await TrackingBackgroundService.isRunning();

    if (appResumed) {
      if (serviceRunning || _publishingHandledByService) {
        await TrackingBackgroundService.stop();
        _publishingHandledByService = false;
        await _restartSharing(delay: Duration.zero);
      }
      return;
    }

    if (!_requireBackground) {
      return;
    }

    if (_publishingHandledByService && serviceRunning) {
      return;
    }

    await _restartSharing(delay: Duration.zero);
  }

  // SOS

  Future<void> _restartSharing({
    Duration delay = const Duration(seconds: 1),
  }) async {
    if (_disposed) return;
    if (_restarting) return;
    _restarting = true;

    // If user logs out during restart flow, abort.
    if (_auth.currentUser?.uid == null) {
      _restarting = false;
      return;
    }

    try {
      final serviceRunning = await TrackingBackgroundService.isRunning();
      if (serviceRunning || _publishingHandledByService) {
        await TrackingBackgroundService.stop();
      }
      _publishingHandledByService = false;
      await _gpsSub?.cancel();
      _gpsSub = null;
      _engine.reset();
      _lastCurrentSentAtMs = 0;
      _lastCurrentFailureAtMs = 0;
      _lastHistoryFailureAtMs = 0;
      _sentInitialCurrent = false;

      _isSharing = false;
      notifyListeners();

      await Future.delayed(delay);
      if (_disposed) return;

      // Start again with current mode.
      await startLocationSharing(background: _requireBackground);
    } finally {
      _restarting = false;
    }
  }

  Future<void> _startActivityRecognition() async {
    if (_disposed) return;
    try {
      ActivityPermission permission = await FlutterActivityRecognition.instance
          .checkPermission();

      if (permission == ActivityPermission.DENIED) {
        permission = await FlutterActivityRecognition.instance
            .requestPermission();
      }

      if (permission != ActivityPermission.GRANTED) {
        debugPrint("Activity permission not granted");
        _lastActivity = null;
        return;
      }
    } on PlatformException catch (e, st) {
      final code = e.code.toUpperCase();
      if (code == 'ACTIVITY_PERMISSION_REQUEST_CANCELLED') {
        debugPrint(
          'Activity permission request cancelled; continue without motion recognition.',
        );
        _lastActivity = null;
        return;
      }
      debugPrint('Activity permission error: ${e.code} ${e.message}');
      debugPrint('$st');
      _lastActivity = null;
      return;
    } catch (e, st) {
      debugPrint('Unexpected activity permission error: $e');
      debugPrint('$st');
      _lastActivity = null;
      return;
    }

    await _activitySub?.cancel();
    if (_disposed) return;
    _activitySub = FlutterActivityRecognition.instance.activityStream.listen((
      activity,
    ) {
      if (_disposed) return;
      _lastActivity = activity;
      // Activity stream is used internally; no continuous UI notify needed.
    }, onError: (e) => debugPrint("Activity stream error: $e"));
  }

  Future<void> replayHistory({
    Duration step = const Duration(milliseconds: 800),
  }) async {
    if (_disposed) return;
    if (_trail.length < 2) return;
    _mode = LocationPlayMode.replay;
    notifyListeners();
    for (final loc in _trail) {
      if (_disposed || _mode != LocationPlayMode.replay) break;

      _currentLocation = loc;
      notifyListeners();
      await Future.delayed(step);
    }

    _mode = LocationPlayMode.live;
    notifyListeners();
  }

  /// Load history (used by History tab)
  Future<List<LocationData>> loadLocationHistory(String childId) async {
    try {
      final history = await _locationRepository.getLocationHistoryByDay(
        childId,
        DateTime.now(),
      );
      if (_disposed) return history;

      _trail
        ..clear()
        ..addAll(history);

      if (history.isNotEmpty) {
        _currentLocation = history.last;
      }

      notifyListeners();
      return history;
    } catch (e) {
      _setError(e);
      return [];
    }
  }

  Future<List<LocationData>> loadLocationHistoryByDay(
    String childId,
    DateTime day, {
    int? fromTs,
    int? toTs,
    int? startMinuteOfDay,
    int? endMinuteOfDay,
  }) async {
    try {
      final history = await _locationRepository.getLocationHistoryByDay(
        childId,
        day,
        fromTs: fromTs,
        toTs: toTs,
        startMinuteOfDay: startMinuteOfDay,
        endMinuteOfDay: endMinuteOfDay,
      );
      if (_disposed) return history;

      _trail
        ..clear()
        ..addAll(history);

      if (history.isNotEmpty) {
        _currentLocation = history.last;
      }

      notifyListeners();
      return history;
    } catch (e) {
      _setError(e);
      return [];
    }
  }

  void stopReplay() {
    if (_disposed) return;
    if (_mode == LocationPlayMode.replay) {
      _mode = LocationPlayMode.live;
      notifyListeners();
    }
  }

  double _turnDelta(double a, double b) {
    var d = (a - b).abs();
    if (d > 180) d = 360 - d;
    return d;
  }

  void _appendTrail(LocationData loc) {
    if (_trail.isEmpty) {
      _trail.add(loc);
      return;
    }

    final prev = _trail.last;
    final dtMs = loc.timestamp - prev.timestamp;
    final dKm = prev.distanceTo(loc);
    final turn = _turnDelta(loc.heading, prev.heading);
    final movedEnough = dKm >= 0.006;

    final shouldAdd =
        dKm >= 0.012 ||
        (movedEnough && dtMs >= 20000) ||
        (movedEnough && turn >= 25); // 12m / 20s+6m / cua khi co di chuyen
    if (shouldAdd) {
      _trail.add(loc);
    }
  }

  Future<LocationData> _attachCurrentBattery(LocationData location) async {
    final snapshot = await _devicePowerService.getSnapshot();
    return location.copyWith(
      batteryLevel: snapshot.batteryLevel,
      isCharging: snapshot.isCharging,
    );
  }

  @override
  void addListener(VoidCallback listener) {
    if (_disposed) return;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (_disposed) return;
    super.removeListener(listener);
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _authStateSub?.cancel();
    _gpsSub?.cancel();
    _activitySub?.cancel();
    _zonesSub?.cancel();
    _healthTimer?.cancel();
    _resetAsyncPipelines();
    _authStateSub = null;
    _activitySub = null;
    _lastActivity = null;
    super.dispose();
  }
}

class _QueuedCurrentUpload {
  const _QueuedCurrentUpload({
    required this.payload,
    required this.queuedAtMs,
    required this.okStatusMessage,
  });

  final TrackingPayload payload;
  final int queuedAtMs;
  final String okStatusMessage;
}

class _QueuedHistoryUpload {
  const _QueuedHistoryUpload({
    required this.payload,
    required this.filteredLocation,
    required this.motionState,
  });

  final TrackingPayload payload;
  final LocationData filteredLocation;
  final MotionState motionState;
}
