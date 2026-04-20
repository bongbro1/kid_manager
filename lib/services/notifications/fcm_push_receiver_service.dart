import 'dart:async';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/services/notifications/fcm_installation_service.dart';

class FcmPushReceiverService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static StreamSubscription<String>? _tokenRefreshSub;
  static String? _currentUid;
  static bool _listenersAttached = false;

  static Future<void> init(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;

    final shouldSyncCurrentToken = _currentUid != normalizedUid;
    _currentUid = normalizedUid;

    if (!_listenersAttached) {
      _listenersAttached = true;
      _tokenRefreshSub = _messaging.onTokenRefresh.listen((newToken) async {
        final activeUid = _currentUid;
        if (activeUid == null || activeUid.isEmpty) return;
        await _registerToken(activeUid, token: newToken);
      });
    }

    if (shouldSyncCurrentToken) {
      await _registerToken(normalizedUid);
    }
  }

  static Future<void> onSignedOut() async {
    _currentUid = null;
  }

  static Future<void> dispose() async {
    _currentUid = null;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _listenersAttached = false;
  }

  static Future<void> _registerToken(String uid, {String? token}) async {
    token ??= await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    final installationId = await FcmInstallationService.getInstallationId();
    if (_currentUid != uid) return;

    try {
      await FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('registerFcmToken').call({
        'installationId': installationId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });

      debugPrint('[FcmPushReceiverService] registerFcmToken success uid=$uid');
    } on FirebaseFunctionsException catch (e, st) {
      if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('User profile not found')) {
        if (kDebugMode) {
          debugPrint(
            '[FcmPushReceiverService] registerFcmToken skipped: user profile not ready for uid=$uid',
          );
        }
        return;
      }
      debugPrint(
        '[FcmPushReceiverService] registerFcmToken fail '
        'code=${e.code} message=${e.message} details=${e.details}',
      );
      debugPrintStack(stackTrace: st);
    } catch (e, st) {
      debugPrint('[FcmPushReceiverService] registerFcmToken error: $e');
      debugPrintStack(stackTrace: st);
    }
  }
}
