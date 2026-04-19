import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/firebase_options.dart';

class FirebaseInitService {
  FirebaseInitService._();

  static Future<FirebaseApp>? _defaultInitInFlight;

  static Future<FirebaseApp> ensureInitialized() {
    final existing = _tryGetDefaultApp();
    if (existing != null) {
      return Future.value(existing);
    }

    final inFlight = _defaultInitInFlight;
    if (inFlight != null) {
      return inFlight;
    }

    final future = _initializeDefaultWithRetry();
    _defaultInitInFlight = future;

    return future.whenComplete(() {
      if (identical(_defaultInitInFlight, future)) {
        _defaultInitInFlight = null;
      }
    });
  }

  static FirebaseApp? _tryGetDefaultApp() {
    try {
      return Firebase.app();
    } catch (_) {
      return null;
    }
  }

  static Future<FirebaseApp> _initializeDefaultWithRetry() async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(milliseconds: 900),
      Duration(milliseconds: 1400),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        return await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        if (!_isRetryableConcurrentInitError(e) ||
            attempt == retryDelays.length) {
          rethrow;
        }

        if (kDebugMode) {
          debugPrint(
            'Firebase initializeApp retry ${attempt + 1}/${retryDelays.length} '
            'after concurrent init error: $e',
          );
        }

        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    throw StateError('Firebase initialization failed after retries.');
  }

  static bool _isRetryableConcurrentInitError(Object error) {
    final message = error.toString();
    return message.contains('ConcurrentModificationException') ||
        message.contains('ExecutionException');
  }
}
