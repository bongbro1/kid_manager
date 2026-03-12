import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/otp_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/views/auth/reset_pass_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum OtpPurpose { verifyEmail, resetPassword }

class OtpScreen extends StatefulWidget {
  final String uid;
  final String email;
  final OtpPurpose purpose;

  const OtpScreen({
    super.key,
    required this.uid,
    required this.email,
    required this.purpose,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OtpVM>().syncCooldown(widget.uid);
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
    final l10n = AppLocalizations.of(context);

    /// 1. kiểm tra đủ 4 ký tự
    if (otp.length != 4) {
      AlertService.showSnack(l10n.otpNeed4Digits, isError: true);
      return;
    }

    /// 2. kiểm tra toàn number
    if (!RegExp(r'^\d+$').hasMatch(otp)) {
      AlertService.showSnack(l10n.otpDigitsOnly, isError: true);
      return;
    }

    final vm = context.read<OtpVM>();

    /// 3. gọi API verify
    final result = await vm.verifyOtp(uid: widget.uid, code: otp);

    if (!mounted) return;

    /// 4. xử lý result
    switch (result) {
      case OtpVerifyResult.success:
        if (widget.purpose == OtpPurpose.verifyEmail) {
          NotificationDialog.show(
            context,
            type: DialogType.success,
            title: l10n.updateSuccessTitle,
            message: l10n.authRegisterSuccessMessage,
          );

          await Future.delayed(const Duration(milliseconds: 1000));

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }

        if (widget.purpose == OtpPurpose.resetPassword) {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ResetPasswordScreen(uid: widget.uid, email: widget.email),
            ),
          );
        }

        break;

      case OtpVerifyResult.invalid:
        AlertService.showSnack(l10n.otpIncorrect, isError: true);
        break;

      case OtpVerifyResult.expired:
        AlertService.showSnack(l10n.otpExpired, isError: true);
        break;

      case OtpVerifyResult.tooManyAttempts:
        AlertService.showSnack(l10n.otpTooManyAttempts, isError: true);
        vm.startCountdown(600);
        break;
      case OtpVerifyResult.notFound:
        AlertService.showSnack(l10n.otpRequestNotFound, isError: true);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OtpVM>();
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 169,
                    child: Text(
                      l10n.otpTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 250,
                    height: 45,
                    child: Text(
                      l10n.otpInstruction,
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
                    onTap: () async {
                      if (vm.loading || !vm.canResend) return;

                      final result = await vm.resendOtp(
                        uid: widget.uid,
                        email: widget.email,
                        type: widget.purpose == OtpPurpose.verifyEmail
                            ? MailType.verifyEmail
                            : MailType.resetPassword,
                      );

                      if (result != OtpResendResult.success) {
                        AlertService.showSnack(
                          vm.error ?? l10n.authSendOtpFailed,
                        );
                      }
                    },
                    child: Text(
                      vm.countdown > 0
                          ? l10n.otpResendIn(vm.countdown)
                          : l10n.otpResend,
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
                    text: l10n.otpVerifyButton,
                    width: 150,
                    height: 50,
                    onPressed: vm.isLocked ? null : _handleVerifyOtp,
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
