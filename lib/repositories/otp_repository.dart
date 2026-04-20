import 'package:cloud_functions/cloud_functions.dart';
import 'package:kid_manager/core/network/app_network_error_mapper.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class PasswordResetOtpVerifyResponse {
  const PasswordResetOtpVerifyResponse({
    required this.result,
    this.resetSessionToken,
  });

  final OtpVerifyResult result;
  final String? resetSessionToken;
}

class OtpRepository {
  OtpRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  HttpsCallable _callable(String name) => _functions.httpsCallable(name);

  Future<void> requestEmailOtp() async {
    try {
      await _callable('requestEmailOtp').call();
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await _callable('requestPasswordReset').call({'email': email.trim()});
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<OtpVerifyResult> verifyEmailOtp({required String inputCode}) async {
    try {
      await _callable('verifyEmailOtp').call({'otp': inputCode.trim()});
      return OtpVerifyResult.success;
    } on FirebaseFunctionsException catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      return _mapVerifyError(error);
    }
  }

  Future<PasswordResetOtpVerifyResponse> verifyPasswordResetOtp({
    required String email,
    required String inputCode,
  }) async {
    try {
      final response = await _callable(
        'verifyPasswordResetOtp',
      ).call({'email': email.trim(), 'otp': inputCode.trim()});

      final data = Map<String, dynamic>.from(
        (response.data as Map?) ?? const <String, dynamic>{},
      );

      return PasswordResetOtpVerifyResponse(
        result: OtpVerifyResult.success,
        resetSessionToken: data['resetSessionToken']?.toString(),
      );
    } on FirebaseFunctionsException catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      return PasswordResetOtpVerifyResponse(result: _mapVerifyError(error));
    }
  }

  Future<OtpResendResult> resendOtp({
    required String email,
    required MailType type,
  }) async {
    try {
      switch (type) {
        case MailType.verifyEmail:
          await requestEmailOtp();
          break;
        case MailType.resetPassword:
          await requestPasswordReset(email: email);
          break;
      }
      return OtpResendResult.success;
    } on FirebaseFunctionsException catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      return _mapResendError(error);
    }
  }

  OtpVerifyResult _mapVerifyError(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'resource-exhausted':
        return OtpVerifyResult.tooManyAttempts;
      case 'failed-precondition':
        return OtpVerifyResult.expired;
      case 'invalid-argument':
        return OtpVerifyResult.invalid;
      default:
        return OtpVerifyResult.notFound;
    }
  }

  OtpResendResult _mapResendError(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'resource-exhausted':
        return OtpResendResult.locked;
      case 'failed-precondition':
        return OtpResendResult.cooldown;
      default:
        return OtpResendResult.notFound;
    }
  }
}
