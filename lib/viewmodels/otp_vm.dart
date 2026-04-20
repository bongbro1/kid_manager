import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/network/app_network_error_mapper.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/repositories/otp_repository.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class OtpVM extends ChangeNotifier {
  OtpVM(this.repo);

  final OtpRepository repo;

  int countdown = 0;
  Timer? _timer;

  bool loading = false;
  String? error;
  String? resetSessionToken;

  bool get canResend => countdown == 0;
  bool get isLocked => countdown > 61;

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

  void armInitialCooldown() {
    if (countdown == 0) {
      startCountdown(60);
    }
  }

  Future<OtpVerifyResult> verifyOtp({
    required String email,
    required String code,
    required MailType type,
  }) async {
    try {
      loading = true;
      error = null;
      resetSessionToken = null;
      notifyListeners();

      switch (type) {
        case MailType.verifyEmail:
          final result = await repo.verifyEmailOtp(inputCode: code);
          if (result == OtpVerifyResult.tooManyAttempts) {
            startCountdown(600);
          }
          return result;
        case MailType.resetPassword:
          final response = await repo.verifyPasswordResetOtp(
            email: email,
            inputCode: code,
          );
          resetSessionToken = response.resetSessionToken;
          if (response.result == OtpVerifyResult.tooManyAttempts) {
            startCountdown(600);
          }
          return response.result;
      }
    } catch (e) {
      final networkError = AppNetworkErrorMapper.normalize(
        e,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      error = networkError?.message ?? e.toString();
      return OtpVerifyResult.invalid;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Gửi OTP mới hoàn toàn, giống như lần đầu request.
  Future<bool> requestFreshOtp({
    required String email,
    required MailType type,
  }) async {
    try {
      loading = true;
      error = null;
      notifyListeners();

      switch (type) {
        case MailType.verifyEmail:
          await repo.requestEmailOtp();
          break;
        case MailType.resetPassword:
          await repo.requestPasswordReset(email: email);
          break;
      }

      // Reset lại countdown như lần đầu
      startCountdown(60);

      return true;
    } catch (e) {
      final networkError = AppNetworkErrorMapper.normalize(
        e,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      error = networkError?.message ?? e.toString();
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<OtpResendResult> resendOtp({
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

      final result = await repo.resendOtp(email: email, type: type);

      switch (result) {
        case OtpResendResult.success:
          startCountdown(60);
          break;
        case OtpResendResult.cooldown:
          error = runtimeL10n().otpResendCooldownError;
          startCountdown(60);
          break;
        case OtpResendResult.locked:
        case OtpResendResult.maxResend:
          error = runtimeL10n().otpResendLockedError;
          startCountdown(600);
          break;
        case OtpResendResult.notFound:
          error = runtimeL10n().authSendOtpFailed;
          break;
      }

      return result;
    } catch (e) {
      final networkError = AppNetworkErrorMapper.normalize(
        e,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      error = networkError?.message ?? e.toString();
      return OtpResendResult.notFound;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
