enum MailType {
  verifyEmail,
  resetPassword,
}
extension MailTypeExt on MailType {
  String get value {
    switch (this) {
      case MailType.verifyEmail:
        return "verify_email";
      case MailType.resetPassword:
        return "reset_password";
    }
  }
}