import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:kid_manager/background/background_tracking_runtime.dart';
import 'package:kid_manager/background/tracking_runtime_store.dart';
import 'package:kid_manager/firebase_options.dart';
import 'package:kid_manager/repositories/location/location_repository_impl.dart';
import 'package:kid_manager/services/firebase_app_check_service.dart';
import 'package:kid_manager/services/location/location_service.dart';

class BackgroundTrackingHost {
  BackgroundTrackingHost._();

  static final BackgroundTrackingHost instance = BackgroundTrackingHost._();

  BackgroundTrackingRuntime? _runtime;
  Timer? _maintenanceTimer;
  Completer<void>? _keepAlive;

  Future<void> start() async {
    _keepAlive ??= Completer<void>();
    await _ensureInitialized();

    _maintenanceTimer?.cancel();
    _maintenanceTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(_maintain()),
    );

    await _maintain();
    await _keepAlive!.future;
  }

  Future<void> _maintain() async {
    try {
      final config = await TrackingRuntimeStore.loadConfig();
      if (config == null || !config.enabled) {
        await TrackingRuntimeStore.setPublisherReady(false);
        await _runtime?.stop();
        return;
      }

      final authReady = await _waitForExpectedAuthUser(config.userId);
      if (!authReady) {
        await TrackingRuntimeStore.setPublisherReady(false);
        debugPrint(
          'BackgroundTrackingHost waiting for FirebaseAuth restore for ${config.userId}.',
        );
        return;
      }

      final runtime = _runtime ??= BackgroundTrackingRuntime(
        LocationRepositoryImpl(),
        LocationServiceImpl(),
      );

      if (runtime.isRunning) {
        return;
      }

      final started = await runtime.start(
        requireBackground: config.requireBackground,
        currentOnly: config.currentOnly,
      );

      if (!started) {
        debugPrint('BackgroundTrackingHost runtime start deferred.');
      }
    } catch (e, st) {
      debugPrint('BackgroundTrackingHost maintain error: $e');
      debugPrint('$st');
    }
  }

  Future<void> _ensureInitialized() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await activateFirebaseAppCheck(background: true);
  }

  Future<bool> _waitForExpectedAuthUser(String expectedUid) async {
    final current = FirebaseAuth.instance.currentUser?.uid;
    if (current == expectedUid) {
      return true;
    }

    try {
      final user = await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((user) => user?.uid == expectedUid)
          .timeout(const Duration(seconds: 20));
      return user?.uid == expectedUid;
    } catch (_) {
      return false;
    }
  }
}

@pragma('vm:entry-point')
Future<void> backgroundTrackingMain() async {
  await BackgroundTrackingHost.instance.start();
}
