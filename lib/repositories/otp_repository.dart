import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';

class OtpRepository {
  final FirebaseFirestore _db;

  OtpRepository(this._db);

  static const int _expiryMinutes = 5;
  static const int _maxAttempts = 3;

  /// ================================
  /// PUBLIC API
  /// ================================

  Future<void> createOtp({
    required String uid,
    required String email,
    required MailType type,
  }) async {
    final ref = _db.collection("email_otps").doc(uid);
    final doc = await ref.get();

    /// nếu OTP đã tồn tại → không tạo mới
    if (doc.exists) {
      final data = doc.data()!;

      /// check locked
      if (data["lockedUntil"] != null) {
        final lockedUntil = data["lockedUntil"].toDate();
        final now = DateTime.now();

        if (lockedUntil.isAfter(now)) {
          final seconds = lockedUntil.difference(now).inSeconds;

          throw Exception(
            "Bạn đã bị khóa gửi OTP. Vui lòng thử lại sau ${seconds}s",
          );
        }
      }

      /// OTP đã tồn tại nhưng không bị lock
      // throw Exception("OTP already exists. Use resend.");
      return;
    }

    final code = _generateOtp();
    final hash = _hash(code);

    await ref.set({
      "codeHash": hash,
      "expiresAt": Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: _expiryMinutes)),
      ),
      "attempts": 0,
      "maxAttempts": _maxAttempts,
      "lockedUntil": null,
      "createdAt": FieldValue.serverTimestamp(),
      "lastSentAt": FieldValue.serverTimestamp(),
    });

    await _sendOtpEmail(email: email, uid: uid, code: code, type: type);
  }

  Future<OtpVerifyResult> verifyOtp({
    required String uid,
    required String inputCode,
  }) async {
    final ref = _db.collection("email_otps").doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      return OtpVerifyResult.notFound;
    }

    final data = doc.data()!;

    final lockedUntil = data["lockedUntil"] != null
        ? (data["lockedUntil"] as Timestamp).toDate()
        : null;

    /// nếu đang bị lock
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      return OtpVerifyResult.tooManyAttempts;
    }

    final expiresAt = (data["expiresAt"] as Timestamp).toDate();
    final attempts = data["attempts"] ?? 0;
    final maxAttempts = data["maxAttempts"] ?? _maxAttempts;
    final storedHash = data["codeHash"];

    /// OTP hết hạn
    if (DateTime.now().isAfter(expiresAt)) {
      await ref.delete();
      return OtpVerifyResult.expired;
    }

    final inputHash = _hash(inputCode);

    /// OTP sai
    if (inputHash != storedHash) {
      final newAttempts = attempts + 1;

      /// vượt quá số lần cho phép
      if (newAttempts >= maxAttempts) {
        await ref.update({
          "attempts": newAttempts,
          "lockedUntil": Timestamp.fromDate(
            DateTime.now().add(const Duration(minutes: 10)),
          ),
        });

        return OtpVerifyResult.tooManyAttempts;
      }

      await ref.update({"attempts": newAttempts});

      return OtpVerifyResult.invalid;
    }

    /// OTP đúng
    await _activateUser(uid);
    await ref.delete();

    return OtpVerifyResult.success;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getOtpDoc(String uid) async {
    final doc = await _db.collection("email_otps").doc(uid).get();

    if (!doc.exists) return null;

    return doc;
  }

  Future<bool> resendOtp({
    required String email,
    required String uid,
    required MailType type,
  }) async {
    final ref = _db.collection("email_otps").doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      return false;
    }

    final data = doc.data()!;

    /// check lock
    final lockedUntil = data["lockedUntil"] != null
        ? (data["lockedUntil"] as Timestamp).toDate()
        : null;

    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      return false;
    }

    /// check resend cooldown
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

    await _sendOtpEmail(email: email, uid: uid, code: code, type: type);

    return true;
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
    required MailType type,
  }) async {
    await _db.collection("mail_queue").add({
      "to": email,
      "uid": uid,
      "code": code,
      "type": type.value,
      "createdAt": FieldValue.serverTimestamp(),
      "status": "pending",
    });
  }
}
