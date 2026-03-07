enum OtpVerifyResult {
  success,
  invalid,
  expired,
  tooManyAttempts,
  notFound,
}
enum OtpResendResult {
  success,
  cooldown,
  locked,
  maxResend,
  notFound,
}