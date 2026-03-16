import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/core/zones/zone_monitor.dart';
import 'package:kid_manager/features/pipeline/tracking_pipeline.dart';
import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/location/transport_mode.dart';
import 'package:kid_manager/models/zones/geo_zone.dart';
import 'package:kid_manager/repositories/location/location_repository.dart';
import 'package:kid_manager/repositories/zones/zone_repository.dart';
import 'package:kid_manager/services/location/location_service.dart';
import 'package:kid_manager/services/location/tracking_status_service.dart';
import 'package:kid_manager/widgets/app/app_mode.dart';

import 'package:flutter_activity_recognition/models/activity.dart';

class ChildLocationViewModel extends ChangeNotifier {
  ChildLocationViewModel(
    this._locationRepository,
    this._locationService, {
    FirebaseAuth? auth,
    TrackingStatusService? trackingStatusService,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _trackingStatusService =
           trackingStatusService ?? TrackingStatusService();

  final LocationRepository _locationRepository;
  final LocationServiceInterface _locationService;
  final FirebaseAuth _auth;
  final TrackingStatusService _trackingStatusService;

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
  int _lastBadAccCurrentSentAtMs = 0;
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

  late final ZoneMonitor _zoneMonitor;
  StreamSubscription<List<GeoZone>>? _zonesSub;
  bool _zonesInited = false;

  TransportMode _transport = TransportMode.unknown;
  TransportMode get transport => _transport;

  final List<LocationData> _trail = [];
  List<LocationData> get locationTrail => List.unmodifiable(_trail);
  bool _isSharing = false;
  bool get isSharing => _isSharing;

  bool _requireBackground = false;
  bool get requireBackground => _requireBackground;

  String? _error;
  String? get error => _error;

  // ===== INTERNAL =====
  late final TrackingPipeline _engine = TrackingPipeline(
    motionDetector: MotionDetector(),
    sendPolicy: SendPolicy(),
  );

  StreamSubscription<LocationData>? _gpsSub;

  bool _restarting = false;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception("Chua dang nhap -> khong the chia se vi tri");
    }
    return uid;
  }

  void _setError(Object? e) {
    _error = e?.toString();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // used on LOGOUT (clear state)
  Future<void> stopSharingOnLogout() async {
    await stopSharing(clearData: true);
    await _activitySub?.cancel();
    await _zonesSub?.cancel();
    _zonesSub = null;
    _zonesInited = false;
    _activitySub = null;
    _lastActivity = null;
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

  Future<void> _ensureZoneMonitor() async {
    if (_zonesInited) return;

    final uid = _requireUid();
    final repo = ZoneRepository();

    _zoneMonitor = ZoneMonitor(repo: repo, childUid: uid);

    await _zonesSub?.cancel();
    _zonesSub = repo
        .watchZones(uid)
        .listen(
          (zones) => _zoneMonitor.updateZones(zones),
          onError: (e) => debugPrint("zones watch error: $e"),
        );

    _zonesInited = true;
  }

  Future<void> _reportTrackingStatusIfChanged(
    String status, {
    String? message,
    bool force = false,
  }) async {
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
    _healthTimer?.cancel();

    _healthTimer = Timer.periodic(const Duration(seconds: 20), (_) async {
      try {
        final serviceEnabled = await _locationService.isServiceEnabled();
        final permissionGranted = await _locationService.hasLocationPermission(
          requireBackground: _requireBackground,
        );
        final preciseGranted = await _locationService
            .hasPreciseLocationPermission();

        _locationServiceEnabled = serviceEnabled;
        _locationPermissionGranted = permissionGranted && preciseGranted;

        if (!serviceEnabled) {
          await _reportTrackingStatusIfChanged(
            'location_service_off',
            message: 'Thiết bị đã tắt GPS/vị trí',
          );
          notifyListeners();
          return;
        }

        if (!permissionGranted || !preciseGranted) {
          await _reportTrackingStatusIfChanged(
            'location_permission_denied',
            message: preciseGranted
                ? 'Thiet bi da tat quyen vi tri'
                : 'Thiet bi chua cap vi tri chinh xac (Precise location)',
          );
          notifyListeners();
          return;
        }

        if (_requireBackground) {
          final bgEnabled = await _locationService.isBackgroundModeEnabled();
          if (!bgEnabled) {
            await _reportTrackingStatusIfChanged(
              'background_disabled',
              message: 'Da tat chia se vi tri nen',
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
            message: 'Dinh vi hoat dong binh thuong',
            force: true,
          );
        }

        notifyListeners();
      } catch (e) {
        debugPrint('health monitor error: $e');
      }
    });
  }

  /// Stop sharing (clearData=false if paused, true on logout)
  Future<void> stopSharing({bool clearData = false}) async {
    await _gpsSub?.cancel();
    _gpsSub = null;
    _engine.reset();

    _isSharing = false;
    _restarting = false;
    _lastTrackingStatus = null;
    _lastStatusHeartbeatAtMs = 0;
    _lastCurrentSentAtMs = 0;
    _lastBadAccCurrentSentAtMs = 0;
    _sentInitialCurrent = false;

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

    notifyListeners();
  }

  /// Start sharing with background mode by default so tracking keeps running.
  Future<void> startLocationSharing({bool background = true}) async {
    if (_isSharing) return;

    try {
      _requireUid(); // validate
    } catch (e) {
      _setError(e);
      return;
    }

    _error = null;

    // allow caller override requireBackground
    _requireBackground = background;
    notifyListeners();

    var ok = false;
    try {
      ok = await _locationService.ensureServiceAndPermission(
        requireBackground: _requireBackground,
      );
    } catch (e, st) {
      debugPrint('ensureServiceAndPermission error: $e');
      debugPrint('$st');
      ok = false;
    }

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

    if (!ok) {
      final serviceEnabled = await _locationService.isServiceEnabled();
      _locationServiceEnabled = serviceEnabled;
      if (!serviceEnabled) {
        await _reportTrackingStatusIfChanged(
          'location_service_off',
          message: 'Thiet bi da tat GPS/vi tri',
        );
        _error = 'Vui long bat GPS/vi tri tren thiet bi.';
      } else {
        final preciseGranted = await _locationService
            .hasPreciseLocationPermission();
        if (!preciseGranted) {
          await _reportTrackingStatusIfChanged(
            'location_permission_denied',
            message: 'Thiet bi chua cap vi tri chinh xac (Precise location)',
          );
          _error = 'Vui long bat vi tri chinh xac (Precise location).';
        } else if (_requireBackground) {
          final bgEnabled = await _locationService.isBackgroundModeEnabled();
          if (!bgEnabled) {
            await _reportTrackingStatusIfChanged(
              'background_disabled',
              message: 'Da tat chia se vi tri nen',
            );
            _error = 'Vui long bat chia se vi tri nen (Allow all the time).';
          }
        }
      }
      _locationPermissionGranted = false;
      _isSharing = false;
      notifyListeners();
      return;
    }

    _sentInitialCurrent = false;
    _isSharing = true;
    _motionState = MotionState.moving;
    await _startHealthMonitor();

    notifyListeners();

    // listen GPS stream
    await _startActivityRecognition();
    await _ensureZoneMonitor();
    _gpsSub = _locationService.getLocationStream().listen((raw) async {
      debugPrint('GPS RAW: acc=${raw.accuracy}');

      final result = _engine.process(raw, _lastActivity);
      final filtered = result.filteredLocation;
      final acc = filtered.accuracy;

      if (acc <= 30) {
        _lastGoodFixAt = DateTime.now();
      }
      final shouldGuardJump = _sentInitialCurrent && _currentLocation != null;
      if (shouldGuardJump &&
          _isJumpTooLarge(_currentLocation, filtered) &&
          filtered.accuracy > 20) {
        debugPrint('Skip jump point: acc=${filtered.accuracy}');
        return;
      }

      _transport = result.transport;
      if (_currentLocation == null || acc <= 50) {
        _currentLocation = filtered;
      }

      try {
        if (_zonesInited) {
          debugPrint(
            "Checking zones for location: lat=${filtered.latitude} lng=${filtered.longitude}",
          );
          await _zoneMonitor.onLocation(filtered);
        }
      } catch (e) {
        debugPrint("zoneMonitor error: $e");
      }

      _motionState = result.motion;

      // build payload once
      final uid = _requireUid();
      final payload = TrackingPayload(
        deviceId: uid,
        location: filtered,
        motion: result.motion.name,
        transport: _transport.name,
      );

      // =========================
      // 1) Update CURRENT when moving, and allow one initial current fix.
      // =========================
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final rejectVeryBadAcc = acc > 100;
      final isMoving = result.motion == MotionState.moving;
      final goodHistoryAcc = acc <= 30; // adjust threshold as needed
      final shouldSendInitialCurrent =
          !_sentInitialCurrent && !rejectVeryBadAcc;

      try {
        bool sentCurrentToServer = false;

        if ((isMoving || shouldSendInitialCurrent) && !rejectVeryBadAcc) {
          if (acc <= 20) {
            if (nowMs - _lastCurrentSentAtMs >= 3000) {
              _lastCurrentSentAtMs = nowMs;
              await _locationRepository.updateMyCurrent(payload);
              sentCurrentToServer = true;
            }
          } else if (acc <= 50) {
            if (nowMs - _lastCurrentSentAtMs >= 8000) {
              _lastCurrentSentAtMs = nowMs;
              await _locationRepository.updateMyCurrent(payload);
              sentCurrentToServer = true;
            }
          } else {
            if (nowMs - _lastBadAccCurrentSentAtMs >= 30000) {
              _lastBadAccCurrentSentAtMs = nowMs;
              await _locationRepository.updateMyCurrent(payload);
              sentCurrentToServer = true;
            }
          }
        }

        if (sentCurrentToServer) {
          _sentInitialCurrent = true;
        }

        // =========================
        // 2) Append HISTORY only when policy allows and moving
        // =========================
        if (isMoving && result.shouldSend && goodHistoryAcc) {
          await _locationRepository.appendMyHistory(payload);
        }

        // Keep status reporting separate from health monitor.
        // Only report "ok" when current was sent successfully.
        if (sentCurrentToServer) {
          await _reportTrackingStatusIfChanged(
            'ok',
            message: 'Dinh vi hoat dong binh thuong',
          );
        }

        debugPrint(
          'OK -> lat=${result.filteredLocation.latitude}, '
          'lng=${result.filteredLocation.longitude}, '
          'motion=${result.motion}, '
          'transport=${_transport.name}, '
          'acc=${acc.toStringAsFixed(1)}',
        );
      } catch (e) {
        debugPrint("ERROR LOCATIONS: $e");
        _setError(e);
      }

      if (acc <= 30) {
        _appendTrail(result.filteredLocation);
      }
      notifyListeners();
    });
  }

  /// Android 11+: request background permission (usually opens Settings)
  Future<void> enableBackgroundSharing() async {
    _requireBackground = true;
    notifyListeners();

    final ok = await _locationService.ensureServiceAndPermission(
      requireBackground: true,
    );

    if (!ok) return;

    // If already sharing, restart once to bind new permission state.
    if (_isSharing) {
      await _restartSharing(delay: const Duration(milliseconds: 300));
    }
  }

  // SOS

  Future<void> _restartSharing({
    Duration delay = const Duration(seconds: 1),
  }) async {
    if (_restarting) return;
    _restarting = true;

    // If user logs out during restart flow, abort.
    if (_auth.currentUser?.uid == null) {
      _restarting = false;
      return;
    }

    try {
      await _gpsSub?.cancel();
      _gpsSub = null;
      _engine.reset();
      _sentInitialCurrent = false;

      _isSharing = false;
      notifyListeners();

      await Future.delayed(delay);

      // Start again with current mode.
      await startLocationSharing(background: _requireBackground);
    } finally {
      _restarting = false;
    }
  }

  Future<void> _startActivityRecognition() async {
    ActivityPermission permission = await FlutterActivityRecognition.instance
        .checkPermission();

    if (permission == ActivityPermission.DENIED) {
      permission = await FlutterActivityRecognition.instance
          .requestPermission();
    }

    if (permission != ActivityPermission.GRANTED) {
      debugPrint(" Activity permission not granted");
      return;
    }

    await _activitySub?.cancel();
    _activitySub = FlutterActivityRecognition.instance.activityStream.listen((
      activity,
    ) {
      _lastActivity = activity;
      // Activity stream is used internally; no continuous UI notify needed.
      debugPrint(" activity=${activity.type} conf=${activity.confidence}");
    }, onError: (e) => debugPrint("Activity stream error: $e"));
  }

  Future<void> replayHistory({
    Duration step = const Duration(milliseconds: 800),
  }) async {
    if (_trail.length < 2) return;
    _mode = LocationPlayMode.replay;
    notifyListeners();
    for (final loc in _trail) {
      if (_mode != LocationPlayMode.replay) break;

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
  }
  ) async {
    try {
      // If repo interface does not include this, call impl directly.
      final history = await _locationRepository.getLocationHistoryByDay(
        childId,
        day,
        fromTs: fromTs,
        toTs: toTs,
      );

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
    if (_mode == LocationPlayMode.replay) {
      _mode = LocationPlayMode.live;
      notifyListeners();
    }
  }

  int _lastTrailTs = 0;
  double _lastTrailHeading = 0;

  double _turnDelta(double a, double b) {
    var d = (a - b).abs();
    if (d > 180) d = 360 - d;
    return d;
  }

  void _appendTrail(LocationData loc) {
    if (_trail.isEmpty) {
      _trail.add(loc);
      _lastTrailTs = loc.timestamp;
      _lastTrailHeading = loc.heading;
      return;
    }

    final prev = _trail.last;
    final dtMs = loc.timestamp - prev.timestamp;
    final dKm = prev.distanceTo(loc);
    final turn = _turnDelta(loc.heading, prev.heading);

    final shouldAdd =
        dtMs >= 10000 || dKm >= 0.012 || turn >= 25; // 10s / 12m / cua
    if (shouldAdd) {
      _trail.add(loc);
    }
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _activitySub?.cancel();
    _zonesSub?.cancel();
    _healthTimer?.cancel();
    _activitySub = null;
    _lastActivity = null;
    super.dispose();
  }
}
