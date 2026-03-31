enum OtpPurpose { verifyEmail, resetPassword }

class PendingOtp {
  final String email;
  final OtpPurpose purpose;
  PendingOtp({required this.email, required this.purpose});
  Map<String, dynamic> toJson() => {'email': email, 'purpose': purpose.index};

  factory PendingOtp.fromJson(Map<String, dynamic> json) => PendingOtp(
    email: json['email'] as String,
    purpose: OtpPurpose.values[json['purpose'] as int],
  );
}
