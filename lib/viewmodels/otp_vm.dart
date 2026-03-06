import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/repositories/otp_repository.dart';

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

    if (data["lockedUntil"] != null) {
      final lockedUntil = data["lockedUntil"].toDate();
      final seconds = lockedUntil.difference(DateTime.now()).inSeconds;

      if (seconds > 0) {
        startCountdown(seconds - 1);
        return;
      }
    }

    if (data["lastSentAt"] != null) {
      final lastSent = data["lastSentAt"].toDate();
      final diff = DateTime.now().difference(lastSent).inSeconds;

      final remaining = 60 - diff;

      if (remaining > 0) {
        startCountdown(remaining);
        return;
      }
    }

    countdown = 0;
    notifyListeners();
  }

  /// =============================
  /// VERIFY OTP
  /// =============================

  Future<OtpVerifyResult> verifyOtp({
    required String uid,
    required String code,
  }) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      final result = await repo.verifyOtp(uid: uid, inputCode: code);

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

  Future<bool> resendOtp({
    required String uid,
    required String email,
    required MailType type,
  }) async {
    if (!canResend) return false;

    try {
      loading = true;
      error = null;
      notifyListeners();

      final ok = await repo.resendOtp(uid: uid, email: email, type: type);

      if (ok) {
        await syncCooldown(uid);
        return true;
      } else {
        error = "Vui lòng chờ trước khi gửi lại mã";
        return false;
      }
    } catch (e) {
      error = e.toString();
      return false;
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
