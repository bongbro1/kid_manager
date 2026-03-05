import 'dart:async';
import 'package:flutter/material.dart';
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

  /// =============================
  /// COUNTDOWN
  /// =============================

  void startCountdown(int seconds) {
    countdown = seconds;
    notifyListeners();

    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        timer.cancel();
      } else {
        countdown--;
        notifyListeners();
      }
    });
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

  Future<bool> resendOtp({required String uid, required String email}) async {
    if (!canResend) return false;

    try {
      loading = true;
      error = null;
      notifyListeners();

      final ok = await repo.resendOtp(uid: uid, email: email);

      if (ok) {
        startCountdown(60);
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
