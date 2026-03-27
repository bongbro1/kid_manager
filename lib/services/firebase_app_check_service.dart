import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

Future<void> activateFirebaseAppCheck({required bool background}) async {
  if (kDebugMode) {
    if (!background) {
      debugPrint('AppCheck disabled while running in debug mode.');
    }
    return;
  }

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck,
    );
  } catch (e) {
    debugPrint('AppCheck activation failed: $e');
    return;
  }

  try {
    await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
  } catch (e) {
    debugPrint('AppCheck auto-refresh setup failed: $e');
  }
}
