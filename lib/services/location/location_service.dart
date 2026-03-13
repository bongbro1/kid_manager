import 'dart:async';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:location/location.dart' as loc;

abstract class LocationServiceInterface {
  /// Bảo đảm GPS bật + quyền foreground/background (tuỳ requireBackground)
  Future<bool> ensureServiceAndPermission({required bool requireBackground});

  /// Stream vị trí liên tục
  Stream<LocationData> getLocationStream();

  /// GPS service đang bật hay không
  Future<bool> isServiceEnabled();

  /// App còn quyền vị trí hay không
  Future<bool> hasLocationPermission({required bool requireBackground});

  /// Background mode còn bật hay không
  Future<bool> isBackgroundModeEnabled();
}

class LocationServiceImpl implements LocationServiceInterface {
  final loc.Location _location = loc.Location();

  @override
  Future<bool> ensureServiceAndPermission({
    required bool requireBackground,
  }) async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }

    var permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }

    final fgGranted =
        permission == loc.PermissionStatus.granted ||
        permission == loc.PermissionStatus.grantedLimited;

    if (!fgGranted) return false;

    if (requireBackground) {
      final bgOk = await _location.enableBackgroundMode(enable: true);
      if (!bgOk) return false;

      await _location.changeNotificationOptions(
        title: "Đang chia sẻ vị trí",
        subtitle: "Ứng dụng chạy nền để bảo vệ con",
        onTapBringToFront: true,
      );
    } else {
      await _location.enableBackgroundMode(enable: false);
    }

    await _location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      distanceFilter: 5,
      interval: 3000,
    );

    return true;
  }

  @override
  Stream<LocationData> getLocationStream() {
    return _location.onLocationChanged.map((loc.LocationData l) {
      return LocationData(
        latitude: l.latitude ?? 0,
        longitude: l.longitude ?? 0,
        accuracy: (l.accuracy ?? 0).toDouble(),
        speed: (l.speed ?? 0).toDouble(),
        heading: (l.heading ?? 0).toDouble(),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<bool> isServiceEnabled() async {
    return _location.serviceEnabled();
  }

  @override
  Future<bool> hasLocationPermission({required bool requireBackground}) async {
    final permission = await _location.hasPermission();

    final fgGranted =
        permission == loc.PermissionStatus.granted ||
        permission == loc.PermissionStatus.grantedLimited;

    if (!fgGranted) return false;

    if (!requireBackground) return true;

    return _location.isBackgroundModeEnabled();
  }

  @override
  Future<bool> isBackgroundModeEnabled() async {
    return _location.isBackgroundModeEnabled();
  }
}
