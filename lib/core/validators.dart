import 'package:kid_manager/l10n/app_localizations.dart';

class Validators {
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  static String? validatePassword(String password, {AppLocalizations? l10n}) {
    if (password.isEmpty) {
      return l10n?.validationPasswordRequired ?? 'Vui lòng nhập mật khẩu';
    }

    if (password.length < 6) {
      return l10n?.validationPasswordMinLength ??
          'Mật khẩu phải có ít nhất 6 ký tự';
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return l10n?.validationPasswordUppercaseRequired ??
          'Mật khẩu phải có ít nhất 1 chữ hoa';
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return l10n?.validationPasswordLowercaseRequired ??
          'Mật khẩu phải có ít nhất 1 chữ thường';
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return l10n?.validationPasswordNumberRequired ??
          'Mật khẩu phải có ít nhất 1 chữ số';
    }

    return null;
  }

  static String? validateConfirmPassword(
    String password,
    String confirmPassword, {
    AppLocalizations? l10n,
  }) {
    if (confirmPassword.isEmpty) {
      return l10n?.validationPasswordConfirmRequired ??
          'Vui lòng nhập lại mật khẩu';
    }

    if (password != confirmPassword) {
      return l10n?.authPasswordMismatch ?? 'Mật khẩu xác nhận không khớp';
    }

    return null;
  }
}
