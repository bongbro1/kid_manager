import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_otp.dart';

class OtpRepository {
  final FirebaseFirestore _db;

  OtpRepository(this._db);

  static const int _expiryMinutes = 5;
  static const int _maxAttempts = 5;

  /// ================================
  /// PUBLIC API
  /// ================================

  Future<void> createOtp({required String uid, required String email}) async {
    final code = _generateOtp();
    final hash = _hash(code);

    await _db.collection("email_otps").doc(uid).set({
      "codeHash": hash,
      "expiresAt": Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: _expiryMinutes)),
      ),
      "attempts": 0,
      "maxAttempts": _maxAttempts,
      "createdAt": FieldValue.serverTimestamp(),
      "lastSentAt": FieldValue.serverTimestamp(),
    });

    await _sendOtpEmail(email: email, uid: uid, code: code);
  }

  Future<OtpVerifyResult> verifyOtp({
    required String uid,
    required String inputCode,
  }) async {
    final doc = await _db.collection("email_otps").doc(uid).get();

    if (!doc.exists) {
      return OtpVerifyResult.notFound;
    }

    final data = doc.data()!;
    final expiresAt = (data["expiresAt"] as Timestamp).toDate();
    final attempts = data["attempts"] ?? 0;
    final maxAttempts = data["maxAttempts"] ?? _maxAttempts;
    final storedHash = data["codeHash"];

    if (DateTime.now().isAfter(expiresAt)) {
      await doc.reference.delete();
      return OtpVerifyResult.expired;
    }

    if (attempts >= maxAttempts) {
      await doc.reference.delete();
      return OtpVerifyResult.tooManyAttempts;
    }

    final inputHash = _hash(inputCode);

    if (inputHash != storedHash) {
      await doc.reference.update({"attempts": FieldValue.increment(1)});
      return OtpVerifyResult.invalid;
    }

    // ✅ success → activate account
    await _activateUser(uid);

    await doc.reference.delete();

    return OtpVerifyResult.success;
  }

  Future<bool> resendOtp({required String email, required String uid}) async {
    try {
      final ref = _db.collection("email_otps").doc(uid);
      final doc = await ref.get();

      /// OTP chưa tồn tại → tạo mới
      if (!doc.exists) {
        final code = _generateOtp();
        final hash = _hash(code);

        await ref.set({
          "uid": uid,
          "codeHash": hash,
          "attempts": 0,
          "expiresAt": Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: _expiryMinutes)),
          ),
          "lastSentAt": FieldValue.serverTimestamp(),
        });

        await _sendOtpEmail(email: email, uid: uid, code: code);
        return true;
      }

      final data = doc.data()!;

      /// check cooldown resend
      if (data["lastSentAt"] != null) {
        final lastSent = (data["lastSentAt"] as Timestamp).toDate();
        final diff = DateTime.now().difference(lastSent).inSeconds;

        if (diff < 60) {
          return false;
        }
      }

      final code = _generateOtp();
      final hash = _hash(code);

      await ref.update({
        "codeHash": hash,
        "expiresAt": Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: _expiryMinutes)),
        ),
        "lastSentAt": FieldValue.serverTimestamp(),
      });

      await _sendOtpEmail(email: email, uid: uid, code: code);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// ================================
  /// PRIVATE
  /// ================================

  String _generateOtp() {
    final rnd = Random();
    return (1000 + rnd.nextInt(9000)).toString();
  }

  String _hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> _activateUser(String uid) async {
    await _db.collection("users").doc(uid).update({"isActive": true});
  }

  Future<void> _sendOtpEmail({
    required String email,
    required String uid,
    required String code,
  }) async {
    await _db.collection("mail_queue").add({
      "to": email,
      "uid": uid,
      "code": code,
      "type": "verify_email",
      "createdAt": FieldValue.serverTimestamp(),
      "status": "pending",
    });
  }
}
