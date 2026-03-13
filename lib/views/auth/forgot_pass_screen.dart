import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/views/auth/otp_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/auth/auth_text_field.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

    final email = _emailController.text.trim();

    /// Validate
    if (email.isEmpty) {
      AlertService.showSnack(l10n.authEnterAllInfo, isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AlertService.showSnack(l10n.emailInvalid, isError: true);
      return;
    }

    final uid = await authVm.forgotPassword(email);

    if (uid == null) {
      AlertService.showSnack(
        authVm.error ?? l10n.authSendOtpFailed,
        isError: true,
      );
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
    final l10n = AppLocalizations.of(context);
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
                            l10n.authForgotPasswordTitle,
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
                            l10n.authForgotPasswordSubtitle,
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
                  Padding(
                    padding: EdgeInsets.only(left: 14, bottom: 8),
                    child: Text(
                      l10n.authEnterYourEmailLabel,
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
                    hintText: l10n.authEnterEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    prefixSvg: 'assets/icons/user.svg',
                  ),

                  const Spacer(),

                  // Button bottom
                  AppButton(
                    height: 60,
                    text: l10n.authContinueButton,
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
