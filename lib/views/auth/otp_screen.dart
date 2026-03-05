import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/models/notifications/notification_type.dart';
import 'package:kid_manager/viewmodels/otp_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  final String uid;
  final String email;

  const OtpScreen({super.key, required this.uid, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<OtpVM>();
      vm.startCountdown(60);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  String _otp = '';

  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocus = FocusNode();

  void _onOtpChanged(String value) {
    if (value.length > 4) {
      value = value.substring(0, 4);
    }

    setState(() {
      _otp = value;
    });

    if (_otp.length == 4) {
      _otpFocus.unfocus();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otp;

    /// 1. kiểm tra đủ 4 ký tự
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ 4 số OTP")),
      );
      return;
    }

    /// 2. kiểm tra toàn number
    if (!RegExp(r'^\d+$').hasMatch(otp)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("OTP chỉ được chứa số")));
      return;
    }

    final vm = context.read<OtpVM>();

    /// 3. gọi API verify
    final result = await vm.verifyOtp(uid: widget.uid, code: otp);

    if (!mounted) return;

    /// 4. xử lý result
    switch (result) {
      case OtpVerifyResult.success:
        NotificationDialog.show(
          context,
          type: DialogType.success,
          title: "Thành công",
          message: "Đăng ký tài khoản thành công",
        );
        
        await Future.delayed(const Duration(milliseconds: 1000));

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        break;

      case OtpVerifyResult.invalid:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("OTP không đúng")));
        break;

      case OtpVerifyResult.expired:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("OTP đã hết hạn")));
        break;

      case OtpVerifyResult.tooManyAttempts:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bạn đã nhập sai quá nhiều lần")),
        );
        break;
      case OtpVerifyResult.notFound:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy yêu cầu OTP")),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OtpVM>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 169,
                    child: Text(
                      'NHẬP MÃ OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 250,
                    height: 45,
                    child: Text(
                      'Chúng tôi đã gửi mã xác minh đến địa chỉ email của bạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF4A4A4A),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(_otpFocus);
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        /// INPUT THẬT (ẨN)
                        Opacity(
                          opacity: 0,
                          child: SizedBox(
                            width: 1,
                            child: TextField(
                              controller: _otpController,
                              focusNode: _otpFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 4,
                              onChanged: _onOtpChanged,
                            ),
                          ),
                        ),

                        /// UI OTP BOX
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            String char = '';

                            if (index < _otp.length) {
                              char = _otp[index];
                            }

                            bool isActive = index == _otp.length;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Container(
                                width: 59,
                                height: 59,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    width: 1.6,
                                    color: isActive
                                        ? const Color(0xFF3A7DFF)
                                        : const Color(0xFFDDDDDD),
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: vm.canResend
                        ? () async {
                            final ok = await vm.resendOtp(
                              uid: widget.uid,
                              email: widget.email,
                            );

                            if (!ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Vui lòng chờ trước khi gửi lại mã",
                                  ),
                                ),
                              );
                            }
                          }
                        : null,
                    child: Text(
                      vm.countdown > 0
                          ? 'Gửi lại mã sau ${vm.countdown}s'
                          : 'Gửi lại mã',
                      style: TextStyle(
                        color: vm.countdown > 0
                            ? Colors.grey
                            : const Color(0xFF3A7DFF),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  AppButton(
                    text: 'Xác minh',
                    width: 150,
                    height: 50,
                    onPressed: _handleVerifyOtp,
                  ),
                ],
              ),
            ),
          ),

          // 👇 Overlay loading
          if (vm.loading) const LoadingOverlay(),
        ],
      ),
    );
  }
}
