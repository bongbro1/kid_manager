import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class OtpRepository {
  final FirebaseFirestore _db;

  OtpRepository(this._db);

  static const int _maxResendCount = 5;
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

    if (doc.exists) {
      final data = doc.data()!;

      final lockedUntilRaw = data["lockedUntil"];
      if (lockedUntilRaw != null) {
        final lockedUntil = (lockedUntilRaw as Timestamp).toDate();
        final now = DateTime.now();

        if (lockedUntil.isAfter(now)) {
          final seconds = lockedUntil.difference(now).inSeconds;
          throw Exception(runtimeL10n().otpRepositoryLockedMessage(seconds));
        }
      }

      final storedType = (data["type"] ?? "").toString();

      // Nếu OTP hiện tại thuộc cùng purpose, không tạo mới
      if (storedType == type.value) {
        return;
      }

      // Nếu OTP cũ thuộc purpose khác, ghi đè để tránh dùng chéo luồng
    }

    final code = _generateOtp();
    final hash = _hash(code);
    final now = DateTime.now();

    await ref.set({
      "codeHash": hash,
      "type": type.value,
      "expiresAt": Timestamp.fromDate(
        now.add(const Duration(minutes: _expiryMinutes)),
      ),
      "attempts": 0,
      "maxAttempts": _maxAttempts,
      "lockedUntil": null,
      "createdAt": Timestamp.fromDate(now),
      "lastSentAt": Timestamp.fromDate(now),
      "resendCount": 1,
    });

    await _sendOtpEmail(email: email, uid: uid, code: code, type: type);
  }

  Future<OtpVerifyResult> verifyOtp({
    required String uid,
    required String inputCode,
    required MailType type,
  }) async {
    final ref = _db.collection("email_otps").doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      return OtpVerifyResult.notFound;
    }

    final data = doc.data()!;

    final storedPurpose = (data['type'] ?? '').toString();
    if (storedPurpose != type.value) {
      return OtpVerifyResult.invalid;
    }

    final lockedUntil = data["lockedUntil"] != null
        ? (data["lockedUntil"] as Timestamp).toDate()
        : null;

    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      return OtpVerifyResult.tooManyAttempts;
    }

    final expiresAt = (data["expiresAt"] as Timestamp).toDate();
    final attempts = data["attempts"] ?? 0;
    final maxAttempts = data["maxAttempts"] ?? _maxAttempts;
    final storedHash = data["codeHash"];

    if (DateTime.now().isAfter(expiresAt)) {
      await ref.delete();
      return OtpVerifyResult.expired;
    }

    final inputHash = _hash(inputCode);

    if (inputHash != storedHash) {
      final newAttempts = attempts + 1;

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

    if (type == MailType.verifyEmail) {
      await _activateUser(uid);
    }

    await ref.delete();
    return OtpVerifyResult.success;
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> getOtpDoc(String uid) async {
    final doc = await _db.collection("email_otps").doc(uid).get();

    if (!doc.exists) return null;

    return doc;
  }

  Future<OtpResendResult> resendOtp({
    required String email,
    required String uid,
    required MailType type,
  }) async {
    final ref = _db.collection("email_otps").doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      return OtpResendResult.notFound;
    }

    final data = doc.data()!;

    /// check lock
    final lockedUntil = data["lockedUntil"] != null
        ? (data["lockedUntil"] as Timestamp).toDate()
        : null;

    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
      return OtpResendResult.locked;
    }

    /// check resend limit
    final resendCount = data["resendCount"] ?? 0;

    if (resendCount >= _maxResendCount) {
      await ref.update({
        "lockedUntil": Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 10)),
        ),
      });

      return OtpResendResult.maxResend;
    }

    /// check cooldown
    if (data["lastSentAt"] != null) {
      final lastSent = (data["lastSentAt"] as Timestamp).toDate();
      final diff = DateTime.now().difference(lastSent).inSeconds;

      if (diff < 60) {
        return OtpResendResult.cooldown;
      }
    }

    final code = _generateOtp();
    final hash = _hash(code);

    await ref.update({
      "codeHash": hash,
      "expiresAt": Timestamp.fromDate(
        DateTime.now().add(const Duration(minutes: _expiryMinutes)),
      ),
      "lastSentAt": Timestamp.now(),
      "resendCount": FieldValue.increment(1),
    });

    await _sendOtpEmail(email: email, uid: uid, code: code, type: type);

    return OtpResendResult.success;
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
