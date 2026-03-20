import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:kid_manager/models/location/location_data.dart';
import 'package:location/location.dart' as loc;

abstract class LocationServiceInterface {
  /// Ensure GPS + foreground/background permission depending on requireBackground.
  Future<bool> ensureServiceAndPermission({
    required bool requireBackground,
    String? notificationTitle,
    String? notificationSubtitle,
  });

  /// Continuous location stream.
  Stream<LocationData> getLocationStream();

  /// Whether location service (GPS) is enabled.
  Future<bool> isServiceEnabled();

  /// Foreground location permission + precise location requirement.
  Future<bool> hasLocationPermission({required bool requireBackground});

  /// Whether precise location is granted.
  Future<bool> hasPreciseLocationPermission();

  /// Whether native background mode is enabled.
  Future<bool> isBackgroundModeEnabled();
}

class LocationServiceImpl implements LocationServiceInterface {
  final loc.Location _location = loc.Location();

  Future<bool> _isPreciseGranted() async {
    try {
      final status = await geo.Geolocator.getLocationAccuracy();
      return status == geo.LocationAccuracyStatus.precise;
    } catch (_) {
      // Some platforms/devices do not expose this API reliably.
      return true;
    }
  }

  @override
  Future<bool> ensureServiceAndPermission({
    required bool requireBackground,
    String? notificationTitle,
    String? notificationSubtitle,
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

    final preciseGranted = await _isPreciseGranted();
    if (!preciseGranted) {
      await geo.Geolocator.openAppSettings();
      return false;
    }

    if (requireBackground) {
      try {
        final bgOk = await _location.enableBackgroundMode(enable: true);
        if (!bgOk) return false;

        await _location.changeNotificationOptions(
          title: notificationTitle ?? 'Sharing location',
          subtitle:
              notificationSubtitle ??
              'The app runs in background to help protect your child',
          onTapBringToFront: true,
        );
      } on PlatformException catch (e) {
        if (e.code == 'PERMISSION_DENIED') {
          return false;
        }
        return false;
      } catch (_) {
        return false;
      }
    }

    await _location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
      // Keep receiving updates even when standing still.
      distanceFilter: 0,
      interval: 10000,
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

    return _isPreciseGranted();
  }

  @override
  Future<bool> hasPreciseLocationPermission() async {
    return _isPreciseGranted();
  }

  @override
  Future<bool> isBackgroundModeEnabled() async {
    return _location.isBackgroundModeEnabled();
  }
}
