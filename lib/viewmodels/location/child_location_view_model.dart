  // lib/features/child/location/presentation/state/child_location_view_model.dart
  import 'dart:async';

  import 'package:firebase_auth/firebase_auth.dart';
  import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/location/motion_detector.dart';
import 'package:kid_manager/core/location/send_policy.dart';
import 'package:kid_manager/core/location/tracking_payload.dart';
import 'package:kid_manager/core/location/tracking_state.dart';
import 'package:kid_manager/features/pipeline/tracking_pipeline.dart';

  import 'package:kid_manager/models/location/location_data.dart';
  import 'package:kid_manager/repositories/location/location_repository.dart';
  import 'package:kid_manager/services/location/location_service.dart';
  import 'package:kid_manager/widgets/app/app_mode.dart';

  class ChildLocationViewModel extends ChangeNotifier {
    ChildLocationViewModel(
        this._locationRepository,
        this._locationService, {
          FirebaseAuth? auth,
        }) : _auth = auth ?? FirebaseAuth.instance;

    final LocationRepository _locationRepository;
    final LocationServiceInterface _locationService;
    final FirebaseAuth _auth;

    // ===== STATE =====
    LocationData? _currentLocation;
    LocationData? get currentLocation => _currentLocation;

    LocationPlayMode _mode =LocationPlayMode.live;
    LocationPlayMode get mode => _mode;

    MotionState _motionState =MotionState.moving;
    MotionState get motionState =>_motionState;

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
    Timer? _keepAliveTimer;

    bool _restarting = false;

    String _requireUid() {
      final uid = _auth.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception("Chưa đăng nhập -> không thể chia sẻ vị trí");
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

    //  dùng khi LOGOUT (clear sạch state)
    Future<void> stopSharingOnLogout() async {
      await stopSharing(clearData: true);
    }

    /// Stop sharing (clearData=false nếu chỉ muốn tạm dừng, true nếu logout)
    Future<void> stopSharing({bool clearData = false}) async {
      await _gpsSub?.cancel();
      _gpsSub = null;
      _engine.reset();


      _keepAliveTimer?.cancel();
      _keepAliveTimer = null;

      _isSharing = false;
      _restarting = false;

      if (clearData) {
        _currentLocation = null;
        _trail.clear();
        _requireBackground = false;
        _error = null;
      }

      notifyListeners();
    }

    ///  Start sharing (mặc định foreground để chắc chắn hiện permission popup)
    Future<void> startLocationSharing({bool background = false}) async {
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

      final ok = await _locationService.ensureServiceAndPermission(
        requireBackground: _requireBackground,
      );

      if (!ok) {
        _isSharing = false;
        notifyListeners();
        return;
      }

      _isSharing = true;
      _motionState = MotionState.moving;

      notifyListeners();

      // listen GPS stream


      _gpsSub = _locationService.getLocationStream().listen(
              (raw) async {
            debugPrint('📍 GPS RAW: acc=${raw.accuracy}');



            final result = _engine.process(raw);

            _currentLocation = result.filteredLocation;
            _motionState = result.motion;
            debugPrint("SHOULD SEND: ${result.shouldSend}");
            debugPrint("SPEED: ${result.filteredLocation.speedKmh}");
            debugPrint("MOTION: ${result.motion}");

            if (result.shouldSend) {
              try {
                final uid = _requireUid();
                final payload = TrackingPayload(
                  deviceId: uid,
                  location: result.filteredLocation,
                  motion: result.motion.name,
                );
                if (result.filteredLocation.speedKmh > 200) {
                  debugPrint("🚨 SPEED ANOMALY");
                  return;
                }

                await _locationRepository.updateMyLocation(
                  payload
                );

                debugPrint(
                  '✅ SENT → lat=${result.filteredLocation.latitude}, '
                      'lng=${result.filteredLocation.longitude}, '
                      'motion=${result.motion}',
                );
              } catch (e) {
                _setError(e);
              }
            }

            _appendTrail(result.filteredLocation);
            notifyListeners();
          },
      );
          }

    ///  Android 11+: bật background permission (thường sẽ mở Settings)
    Future<void> enableBackgroundSharing() async {
      _requireBackground = true;
      notifyListeners();

      final ok = await _locationService.ensureServiceAndPermission(
        requireBackground: true,
      );

      if (!ok) return;

      // Nếu đã share rồi thì restart 1 lần để chắc stream chạy theo permission mới
      if (_isSharing) {
        await _restartSharing(delay: const Duration(milliseconds: 300));
      }
    }

    Future<void> _restartSharing({Duration delay = const Duration(seconds: 1)}) async {
      if (_restarting) return;
      _restarting = true;

      // nếu user logout giữa chừng
      if (_auth.currentUser?.uid == null) {
        _restarting = false;
        return;
      }

      try {
        await _gpsSub?.cancel();
        _gpsSub = null;

        _isSharing = false;
        notifyListeners();

        await Future.delayed(delay);

        // start lại với mode hiện tại
        await startLocationSharing(background: _requireBackground);
      } finally {
        _restarting = false;
      }
    }

    Future<void> replayHistory({
      Duration step = const Duration(milliseconds: 800),
  })async{
      if(_trail.length < 2) return;
      _mode =LocationPlayMode.replay;
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
    /// Load lịch sử (dùng chung cho tab History)
    Future<List<LocationData>> loadLocationHistory(String childId) async {
      try {
        final history = await _locationRepository.getLocationHistory(childId);

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

    void _appendTrail(LocationData loc) {
      if (_trail.isEmpty ||
          _trail.last.distanceTo(loc) >= 0.03) {
        _trail.add(loc);
      }
    }

    @override
    void dispose() {
      _gpsSub?.cancel();
      _keepAliveTimer?.cancel();
      super.dispose();
    }
  }
