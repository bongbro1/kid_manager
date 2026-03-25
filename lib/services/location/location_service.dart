import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:kid_manager/models/location/location_data.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as permission;

abstract class LocationServiceInterface {
  /// Ensure GPS + foreground/background permission depending on requireBackground.
  Future<bool> ensureServiceAndPermission({
    required bool requireBackground,
    bool requestIfNeeded = true,
    bool enablePluginBackgroundMode = true,
    bool applyPluginLocationSettings = true,
    String? notificationTitle,
    String? notificationSubtitle,
  });

  /// Continuous location stream.
  Stream<LocationData> getLocationStream({bool usePlatformPlugin = true});

  /// Whether location service (GPS) is enabled.
  Future<bool> isServiceEnabled();

  /// Foreground location permission + precise location requirement.
  Future<bool> hasLocationPermission({required bool requireBackground});

  /// Whether precise location is granted.
  Future<bool> hasPreciseLocationPermission();

  /// Whether native background mode is enabled.
  Future<bool> isBackgroundModeEnabled();

  /// Whether Android background location permission is granted.
  Future<bool> hasBackgroundLocationPermission();
}

class LocationServiceImpl implements LocationServiceInterface {
  final loc.Location _location = loc.Location();

  Future<int?> _androidSdkInt() async {
    if (!Platform.isAndroid) return null;
    try {
      return (await DeviceInfoPlugin().androidInfo).version.sdkInt;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _hasForegroundLocationPermission() async {
    final status = await permission.Permission.locationWhenInUse.status;
    return status.isGranted;
  }

  Future<bool> _requestForegroundLocationPermission() async {
    final status = await permission.Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  Future<bool> _hasBackgroundLocationPermissionSafe() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkInt();
      if (sdkInt != null && sdkInt < 29) {
        return _hasForegroundLocationPermission();
      }
    }

    final status = await permission.Permission.locationAlways.status;
    return status.isGranted;
  }

  Future<bool> _requestBackgroundLocationPermissionSafe() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final sdkInt = await _androidSdkInt();
      if (sdkInt != null && sdkInt < 29) {
        return _requestForegroundLocationPermission();
      }
    }

    final hasForeground = await _hasForegroundLocationPermission();
    if (!hasForeground) {
      final grantedForeground = await _requestForegroundLocationPermission();
      if (!grantedForeground) {
        return false;
      }
    }

    final status = await permission.Permission.locationAlways.request();
    return status.isGranted;
  }

  Future<bool> _safeServiceEnabled() async {
    try {
      return await _location.serviceEnabled();
    } on PlatformException catch (e) {
      if (e.code == 'SERVICE_STATUS_ERROR') {
        return _fallbackServiceEnabled();
      }
      return _fallbackServiceEnabled();
    } catch (_) {
      return _fallbackServiceEnabled();
    }
  }

  Future<bool> _fallbackServiceEnabled() async {
    try {
      return await geo.Geolocator.isLocationServiceEnabled();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeRequestService() async {
    try {
      return await _location.requestService();
    } on PlatformException catch (_) {
      try {
        await geo.Geolocator.openLocationSettings();
      } catch (_) {}
      return _safeServiceEnabled();
    } catch (_) {
      return _safeServiceEnabled();
    }
  }

  Future<bool> _safeBackgroundModeEnabled() async {
    try {
      return await _location.isBackgroundModeEnabled();
    } on PlatformException catch (_) {
      return hasBackgroundLocationPermission();
    } catch (_) {
      return hasBackgroundLocationPermission();
    }
  }

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
    bool requestIfNeeded = true,
    bool enablePluginBackgroundMode = true,
    bool applyPluginLocationSettings = true,
    String? notificationTitle,
    String? notificationSubtitle,
  }) async {
    bool serviceEnabled = await _safeServiceEnabled();
    if (!serviceEnabled) {
      if (!requestIfNeeded) return false;
      serviceEnabled = await _safeRequestService();
      if (!serviceEnabled) return false;
    }

    var fgGranted = await _hasForegroundLocationPermission();
    if (!fgGranted && requestIfNeeded) {
      fgGranted = await _requestForegroundLocationPermission();
    }
    if (!fgGranted) return false;

    if (requireBackground) {
      var bgGranted = await _hasBackgroundLocationPermissionSafe();
      if (!bgGranted && requestIfNeeded) {
        bgGranted = await _requestBackgroundLocationPermissionSafe();
      }
      if (!bgGranted) return false;
    }

    final preciseGranted = await _isPreciseGranted();
    if (!preciseGranted) {
      if (requestIfNeeded) {
        await geo.Geolocator.openAppSettings();
      }
      return false;
    }

    if (requireBackground && enablePluginBackgroundMode) {
      if (!requestIfNeeded) {
        final backgroundEnabled = await _safeBackgroundModeEnabled();
        if (!backgroundEnabled) return false;
      }

      try {
        final bgOk = requestIfNeeded
            ? await _location.enableBackgroundMode(enable: true)
            : true;
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

    if (applyPluginLocationSettings) {
      try {
        await _location.changeSettings(
          accuracy: loc.LocationAccuracy.high,
          // Balance responsiveness with battery/noise. Software filtering still
          // handles indoor drift and standing-still suppression on top of this.
          distanceFilter: 6,
          interval: 5000,
        );
      } on PlatformException catch (e) {
        debugPrint(
          'LocationServiceImpl.changeSettings failed, using plugin defaults instead: ${e.code}',
        );
      } catch (e) {
        debugPrint(
          'LocationServiceImpl.changeSettings failed, using plugin defaults instead: $e',
        );
      }
    }

    return true;
  }

  @override
  Stream<LocationData> getLocationStream({bool usePlatformPlugin = true}) {
    if (usePlatformPlugin) {
      return _pluginLocationStream();
    }
    return _geolocatorLocationStream();
  }

  Stream<LocationData> _pluginLocationStream() {
    return _location.onLocationChanged.map((loc.LocationData l) {
      return LocationData(
        latitude: l.latitude ?? 0,
        longitude: l.longitude ?? 0,
        accuracy: (l.accuracy ?? 0).toDouble(),
        speed: (l.speed ?? 0).toDouble(),
        heading: (l.heading ?? 0).toDouble(),
        timestamp: l.time?.round() ?? DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  Stream<LocationData> _geolocatorLocationStream() {
    final geo.LocationSettings settings;
    if (Platform.isAndroid) {
      settings = geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 6,
        intervalDuration: Duration(seconds: 5),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      settings = geo.AppleSettings(
        accuracy: geo.LocationAccuracy.best,
        distanceFilter: 6,
      );
    } else {
      settings = const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 6,
      );
    }

    return geo.Geolocator.getPositionStream(locationSettings: settings).map((
      geo.Position p,
    ) {
      return LocationData(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracy: p.accuracy,
        speed: p.speed,
        heading: p.heading,
        isMock: p.isMocked,
        timestamp:
            p.timestamp?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
    });
  }

  @override
  Future<bool> isServiceEnabled() async {
    return _safeServiceEnabled();
  }

  @override
  Future<bool> hasLocationPermission({required bool requireBackground}) async {
    final fgGranted = await _hasForegroundLocationPermission();
    if (!fgGranted) return false;

    if (requireBackground) {
      final bgGranted = await _hasBackgroundLocationPermissionSafe();
      if (!bgGranted) return false;
    }

    return _isPreciseGranted();
  }

  @override
  Future<bool> hasPreciseLocationPermission() async {
    return _isPreciseGranted();
  }

  @override
  Future<bool> isBackgroundModeEnabled() async {
    return _safeBackgroundModeEnabled();
  }

  @override
  Future<bool> hasBackgroundLocationPermission() async {
    return _hasBackgroundLocationPermissionSafe();
  }
}
