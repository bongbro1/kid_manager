
class PasswordValidationResult {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;

  const PasswordValidationResult({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
  });

  bool get isValid => hasMinLength && hasUppercase && hasLowercase && hasNumber;
}

class PasswordValidator {
  static PasswordValidationResult validate(String password) {
    return PasswordValidationResult(
      hasMinLength: password.length >= 8,
      hasUppercase: RegExp(r'[A-Z]').hasMatch(password),
      hasLowercase: RegExp(r'[a-z]').hasMatch(password),
      hasNumber: RegExp(r'[0-9]').hasMatch(password),
    );
  }

  // static String? validateError(String password, AppLocalizations l10n) {
  //   final r = validate(password);

  //   if (!r.hasMinLength) return l10n.passwordMinLength;
  //   if (!r.hasUppercase) return l10n.passwordUppercase;
  //   if (!r.hasLowercase) return l10n.passwordLowercase;
  //   if (!r.hasNumber) return l10n.passwordNumber;

  //   return null;
  // }
}
