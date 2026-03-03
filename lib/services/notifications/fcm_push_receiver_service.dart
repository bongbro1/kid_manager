import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';

class FcmPushReceiverService {
  static final _messaging = FirebaseMessaging.instance;
  static final _db = FirebaseFirestore.instance;

  /// ===============================
  /// INIT (gọi sau khi login thành công)
  /// ===============================
  static Future<void> init(String uid) async {
    await _saveToken(uid);

    /// token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _saveToken(uid, token: newToken);
    });

    /// foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("📩 Foreground message: ${message.data}");
    });

    /// click notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("👉 User clicked notification: ${message.data}");
    });
  }

  /// ===============================
  /// SAVE TOKEN
  /// ===============================
  static Future<void> _saveToken(String uid, {String? token}) async {
    token ??= await _messaging.getToken();
    if (token == null) return;
    String platform;

    if (Platform.isAndroid) {
      platform = "android";
    } else if (Platform.isIOS) {
      platform = "ios";
    } else {
      platform = "unknown";
    }

    final tokenId = sha256.convert(utf8.encode(token)).toString();

    // 🔥 Lấy familyId từ user doc
    final userSnap = await _db.collection('users').doc(uid).get();

    final familyId = userSnap.data()?['familyId'];

    await _db
        .collection('users')
        .doc(uid)
        .collection('fcmTokens')
        .doc(tokenId)
        .set({
          "token": token,
          "familyId": familyId,
          "platform": platform,
          "updatedAt": FieldValue.serverTimestamp(),
        });

    debugPrint("✅ FCM token saved");
  }
}
