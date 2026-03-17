class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  /// PASSWORD VALIDATION
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return "Vui lòng nhập mật khẩu";
    }

    if (password.length < 6) {
      return "Mật khẩu phải có ít nhất 6 ký tự";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Mật khẩu phải có ít nhất 1 chữ hoa";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Mật khẩu phải có ít nhất 1 chữ thường";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Mật khẩu phải có ít nhất 1 chữ số";
    }

    return null;
  }

  static String? validateConfirmPassword(
    String password,
    String confirmPassword,
  ) {
    if (confirmPassword.isEmpty) {
      return "Vui lòng nhập lại mật khẩu";
    }

    if (password != confirmPassword) {
      return "Mật khẩu xác nhận không khớp";
    }

    return null;
  }
}