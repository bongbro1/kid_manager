import 'package:flutter/material.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/otp_vm.dart';
import 'package:kid_manager/views/auth/reset_pass_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum OtpPurpose { verifyEmail, resetPassword }

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.email,
    required this.purpose,
  });

  final String email;
  final OtpPurpose purpose;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OtpVM>().armInitialCooldown();
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

  MailType get _mailType => widget.purpose == OtpPurpose.verifyEmail
      ? MailType.verifyEmail
      : MailType.resetPassword;

  void _onOtpChanged(String value) {
    if (value.length > 6) {
      value = value.substring(0, 6);
    }

    setState(() {
      _otp = value;
    });

    if (_otp.length == 6) {
      _otpFocus.unfocus();
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otp;
    final l10n = AppLocalizations.of(context);

    if (otp.length != 6) {
      AlertService.showSnack(l10n.authGenericError, isError: true);
      return;
    }

    if (!RegExp(r'^\d+$').hasMatch(otp)) {
      AlertService.showSnack(l10n.otpDigitsOnly, isError: true);
      return;
    }

    final vm = context.read<OtpVM>();
    final result = await vm.verifyOtp(
      email: widget.email,
      code: otp,
      type: _mailType,
    );

    if (!mounted) {
      return;
    }

    switch (result) {
      case OtpVerifyResult.success:
        if (widget.purpose == OtpPurpose.verifyEmail) {
          await context.read<AuthVM>().logout();
          if (!mounted) {
            return;
          }

          NotificationDialog.show(
            context,
            type: DialogType.success,
            title: l10n.updateSuccessTitle,
            message: l10n.authRegisterSuccessMessage,
          );

          await Future.delayed(const Duration(milliseconds: 1000));

          if (!mounted) {
            return;
          }

          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }

        final resetSessionToken = vm.resetSessionToken;
        if (resetSessionToken == null || resetSessionToken.isEmpty) {
          AlertService.showSnack(l10n.authGenericError, isError: true);
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ResetPasswordScreen(
              resetSessionToken: resetSessionToken,
            ),
          ),
        );
        return;
      case OtpVerifyResult.invalid:
        AlertService.showSnack(l10n.otpIncorrect, isError: true);
        return;
      case OtpVerifyResult.expired:
        AlertService.showSnack(l10n.otpExpired, isError: true);
        return;
      case OtpVerifyResult.tooManyAttempts:
        AlertService.showSnack(l10n.otpTooManyAttempts, isError: true);
        vm.startCountdown(600);
        return;
      case OtpVerifyResult.notFound:
        AlertService.showSnack(l10n.authGenericError, isError: true);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OtpVM>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                      style: textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
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
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.75),
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
                        Opacity(
                          opacity: 0,
                          child: SizedBox(
                            width: 1,
                            child: TextField(
                              controller: _otpController,
                              focusNode: _otpFocus,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              onChanged: _onOtpChanged,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            var char = '';

                            if (index < _otp.length) {
                              char = _otp[index];
                            }

                            final isActive = index == _otp.length;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Container(
                                width: 44,
                                height: 59,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    width: 1.6,
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.outline.withOpacity(0.7),
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontSize: 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.7,
                                    ),
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
                      if (vm.loading || !vm.canResend) {
                        return;
                      }

                      final result = await vm.resendOtp(
                        email: widget.email,
                        type: _mailType,
                      );

                      if (!mounted) {
                        return;
                      }

                      if (result != OtpResendResult.success) {
                        AlertService.showSnack(
                          vm.error ?? l10n.authSendOtpFailed,
                          isError: true,
                        );
                      }
                    },
                    child: Text(
                      vm.countdown > 0
                          ? l10n.otpResendIn(vm.countdown)
                          : l10n.otpResend,
                      style: textTheme.bodyMedium?.copyWith(
                        color: vm.countdown > 0
                            ? colorScheme.onSurface.withOpacity(0.5)
                            : colorScheme.primary,
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
          if (vm.loading) const LoadingOverlay(),
        ],
      ),
    );
  }
}
