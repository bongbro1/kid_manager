import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/repositories/otp_repository.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class OtpVM extends ChangeNotifier {
  final OtpRepository repo;

  OtpVM(this.repo);

  /// =============================
  /// STATE
  /// =============================

  int countdown = 0;
  Timer? _timer;

  bool loading = false;
  String? error;

  bool get canResend => countdown == 0;
  bool get isLocked => countdown > 61;

  /// =============================
  /// COUNTDOWN
  /// =============================

  void startCountdown(int seconds) {
    _timer?.cancel();

    countdown = seconds;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown <= 1) {
        countdown = 0;
        timer.cancel();
      } else {
        countdown--;
      }

      notifyListeners();
    });
  }

  Future<void> syncCooldown(String uid) async {
    final doc = await repo.getOtpDoc(uid);

    if (doc == null) {
      countdown = 0;
      notifyListeners();
      return;
    }

    final data = doc.data()!;
    final now = DateTime.now();

    /// check locked
    if (data["lockedUntil"] != null) {
      final lockedUntil = (data["lockedUntil"] as Timestamp).toDate();
      final seconds = lockedUntil.difference(now).inSeconds;

      if (seconds > 0) {
        startCountdown(seconds);
        return;
      }
    }

    /// check resend cooldown
    if (data["lastSentAt"] != null) {
      final lastSent = (data["lastSentAt"] as Timestamp).toDate();
      final diff = now.difference(lastSent).inSeconds;

      final remaining = 60 - diff;

      if (remaining > 0) {
        startCountdown(remaining);
        return;
      }
    }

    /// nếu không bị lock và hết cooldown
    countdown = 0;
    notifyListeners();
  }

  /// =============================
  /// VERIFY OTP
  /// =============================

  Future<OtpVerifyResult> verifyOtp({
    required String uid,
    required String code,
    required MailType type
  }) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final result = await repo.verifyOtp(uid: uid, inputCode: code, type: type);

      if (result == OtpVerifyResult.tooManyAttempts) {
        await syncCooldown(uid);
      }

      return result;
    } catch (e) {
      error = e.toString();
      return OtpVerifyResult.invalid;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// =============================
  /// RESEND OTP
  /// =============================

  Future<OtpResendResult> resendOtp({
    required String uid,
    required String email,
    required MailType type,
  }) async {
    if (!canResend) {
      return OtpResendResult.cooldown;
    }

    try {
      loading = true;
      error = null;
      notifyListeners();

      final result = await repo.resendOtp(uid: uid, email: email, type: type);

      switch (result) {
        case OtpResendResult.success:
          await syncCooldown(uid);
          break;

        case OtpResendResult.cooldown:
          error = runtimeL10n().otpResendCooldownError;
          break;

        case OtpResendResult.locked:
          error = runtimeL10n().otpResendLockedError;
          await syncCooldown(uid);
          break;

        case OtpResendResult.maxResend:
          error = runtimeL10n().otpResendMaxError;
          await syncCooldown(uid);
          break;

        case OtpResendResult.notFound:
          error = runtimeL10n().otpRequestNotFound;
          break;
      }

      return result;
    } catch (e) {
      error = e.toString();
      return OtpResendResult.notFound;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// =============================
  /// CLEANUP
  /// =============================

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
