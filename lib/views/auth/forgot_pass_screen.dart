import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/otp_vm.dart';
import 'package:kid_manager/views/auth/otp_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/auth/auth_text_field.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final authVm = context.read<AuthVM>();
    final otpVm = context.read<OtpVM>();

    final email = _emailController.text.trim();

    /// Validate
    if (email.isEmpty) {
      AlertService.showSnack('Vui lòng nhập đầy đủ thông tin', isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AlertService.showSnack('Email không hợp lệ', isError: true);
      return;
    }

    final uid = await authVm.forgotPassword(email);

    if (uid == null) {
      AlertService.showSnack(authVm.error ?? 'Gửi OTP thất bại', isError: true);
      return;
    }

    /// start cooldown ngay lập tức

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          uid: uid,
          email: email,
          purpose: OtpPurpose.resetPassword,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthVM>();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: SvgPicture.asset(
                        'assets/icons/back.svg',
                        width: 17,
                        height: 12.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Title + description
                  Padding(
                    padding: EdgeInsets.only(left: 14),
                    child: SizedBox(
                      width: 289,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUÊN MẬT KHẨU?',
                            style: TextStyle(
                              fontSize: 24,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              height: 1.42,
                              letterSpacing: -0.19,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Bạn đã quên mật khẩu?, vui lòng làm theo các bước sau để lấy lại mật khẩu của bạn!',
                            style: TextStyle(
                              color: Color(0xFF4A4A4A),
                              fontSize: 15,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Label
                  const Padding(
                    padding: EdgeInsets.only(left: 14, bottom: 8),
                    child: Text(
                      'Nhập Email của bạn',
                      style: TextStyle(
                        color: Color(0xFF4A4A4A),
                        fontSize: 15,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Email input
                  AuthTextField(
                    controller: _emailController,
                    hintText: 'Nhập email',
                    keyboardType: TextInputType.emailAddress,
                    prefixSvg: 'assets/icons/user.svg',
                  ),

                  const Spacer(),

                  // Button bottom
                  AppButton(
                    height: 60,
                    text: 'Tiếp tục',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    onPressed: _sendOtp,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        if (authVM.loading) const LoadingOverlay(),
      ],
    );
  }
}
