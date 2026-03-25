import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/background/tracking_runtime_config.dart';
import 'package:kid_manager/background/tracking_runtime_store.dart';

class TrackingBackgroundService {
  TrackingBackgroundService._();

  static const MethodChannel _channel = MethodChannel('tracking_service');

  static Future<bool> startForCurrentUser({
    required bool requireBackground,
    String? parentUid,
    String? displayName,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid.trim();
    if (userId == null || userId.isEmpty) {
      return false;
    }

    final config = TrackingRuntimeConfig(
      userId: userId,
      enabled: true,
      requireBackground: requireBackground,
      parentUid: parentUid?.trim(),
      displayName: displayName?.trim(),
    );

    await TrackingRuntimeStore.saveConfig(config);

    try {
      final result = await _channel.invokeMethod<bool>('startTrackingService');
      final started = result ?? false;
      if (!started) {
        await TrackingRuntimeStore.clear();
      }
      return started;
    } on PlatformException catch (e) {
      debugPrint(
        'TrackingBackgroundService.start PlatformException: ${e.code} ${e.message}',
      );
      await TrackingRuntimeStore.clear();
      return false;
    } catch (e) {
      debugPrint('TrackingBackgroundService.start error: $e');
      await TrackingRuntimeStore.clear();
      return false;
    }
  }

  static Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 4),
    Duration pollInterval = const Duration(milliseconds: 250),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await TrackingRuntimeStore.isPublisherReady()) {
        return true;
      }
      await Future.delayed(pollInterval);
    }
    return TrackingRuntimeStore.isPublisherReady();
  }

  static Future<void> stop({bool clearConfig = true}) async {
    try {
      await _channel.invokeMethod<void>('stopTrackingService');
    } on PlatformException catch (e) {
      debugPrint(
        'TrackingBackgroundService.stop PlatformException: ${e.code} ${e.message}',
      );
    } catch (e) {
      debugPrint('TrackingBackgroundService.stop error: $e');
    } finally {
      if (clearConfig) {
        await TrackingRuntimeStore.clear();
      }
    }
  }

  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTrackingServiceRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
        'TrackingBackgroundService.isRunning PlatformException: ${e.code} ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('TrackingBackgroundService.isRunning error: $e');
      return false;
    }
  }
}
