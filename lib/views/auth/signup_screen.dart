import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/models/auth/auth_models.dart';
import 'package:kid_manager/models/auth/password_validator.dart';
import 'package:kid_manager/views/auth/dialog/phone_auth_dialog.dart';
import 'package:kid_manager/views/auth/otp_screen.dart';
import 'package:kid_manager/views/terms_screen.dart';
import 'package:kid_manager/widgets/auth/auth_text_field.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../core/alert_service.dart';
import '../../viewmodels/auth_vm.dart';
import '../../widgets/app/app_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool agreeClause = false;

  String _resolveSignupErrorMessage(AppLocalizations l10n, String? errorKey) {
    switch (errorKey) {
      case 'emailInUse':
        return l10n.emailInUse;
      case 'emailInvalid':
        return l10n.emailInvalid;
      case 'weakPassword':
        return l10n.weakPassword;
      case 'wrongPassword':
        return l10n.wrongPassword;
      case 'loginFailed':
        return l10n.authSignupFailed;
      default:
        if (errorKey == null || errorKey.trim().isEmpty) {
          return l10n.authSignupFailed;
        }
        return errorKey;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignUpPressed() async {
    final vm = context.read<AuthVM>();
    final l10n = AppLocalizations.of(context);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty || !agreeClause) {
      AlertService.showSnack(l10n.authEnterAllInfo, isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AlertService.showSnack(l10n.emailInvalid, isError: true);
      return;
    }

    if (password != confirm) {
      AlertService.showSnack(l10n.authPasswordMismatch, isError: true);
      return;
    }

    final passwordResult = PasswordValidator.validate(password);
    if (!passwordResult.isValid) {
      AlertService.showSnack(
        'Mật khẩu phải có ít nhất 8 ký tự, gồm chữ hoa, chữ thường và số.',
        isError: true,
      );
      return;
    }
    final ok = await vm.register(email, password);

    if (!ok) {
      AlertService.error(message: _resolveSignupErrorMessage(l10n, vm.error));
      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OtpScreen(email: email, purpose: OtpPurpose.verifyEmail),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthVM>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 24,
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxContentWidth = constraints.maxWidth > 420
                      ? 420.0
                      : constraints.maxWidth;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 30),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 266,
                                    ),
                                    child: Text(
                                      l10n.authSignupTitle,
                                      style: textTheme.headlineSmall?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        height: 1.42,
                                        letterSpacing: -0.19,
                                      ),
                                    ),
                                  ),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 266,
                                    ),
                                    child: Text(
                                      l10n.authSignupSubtitle,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              AuthTextField(
                                label: l10n.authEmailLabel,
                                controller: _emailCtrl,
                                hintText: l10n.authEnterEmailHint,
                                keyboardType: TextInputType.emailAddress,
                                prefixSvg: 'assets/icons/user.svg',
                              ),
                              AuthTextField(
                                label: l10n.authPasswordLabel,
                                controller: _passwordCtrl,
                                hintText: l10n.authEnterPasswordHint,
                                keyboardType: TextInputType.text,
                                obscureText: true,
                                isPassword: true,
                                prefixSvg: 'assets/icons/lock.svg',
                              ),
                              AuthTextField(
                                label: l10n.authConfirmPasswordLabel,
                                controller: _confirmCtrl,
                                hintText: l10n.authConfirmPasswordLabel,
                                keyboardType: TextInputType.text,
                                obscureText: true,
                                isPassword: true,
                                prefixSvg: 'assets/icons/lock.svg',
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      agreeClause = !agreeClause;
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 4,
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          margin: const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            color: agreeClause
                                                ? colorScheme.primary
                                                : Colors.transparent,
                                            border: Border.all(
                                              width: 2,
                                              color: agreeClause
                                                  ? colorScheme.primary
                                                  : colorScheme.outline,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              2,
                                            ),
                                          ),
                                          child: agreeClause
                                              ? Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: colorScheme.onPrimary,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              text: l10n.authAgreeTermsPrefix,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: colorScheme.onSurface
                                                        .withValues(alpha: 0.7),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.5,
                                                    letterSpacing: -0.15,
                                                  ),
                                              children: [
                                                TextSpan(
                                                  text: l10n.authAgreeTermsLink,
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            colorScheme.primary,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        decoration:
                                                            TextDecoration.none,
                                                      ),
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (_) =>
                                                              const TermsScreen(),
                                                        ),
                                                      );
                                                    },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24.17),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 360,
                                ),
                                child: AppButton(
                                  height: 50,
                                  text: l10n.authSignupButton,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  onPressed: _onSignUpPressed,
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.4,
                                      ),
                                      thickness: 0.83,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text(
                                      l10n.authOr,
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontSize: 13,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: colorScheme.outline.withValues(
                                        alpha: 0.4,
                                      ),
                                      thickness: 0.83,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 17),
                              Row(
                                children: [
                                  Expanded(
                                    child: _socialBtn(
                                      'assets/icons/google.svg',
                                      () => vm.loginWithGoogle(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _socialBtn(
                                      'assets/icons/facebook.svg',
                                      () => vm.loginWithFacebook(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _socialBtn(
                                      'assets/icons/apple.svg',
                                      () => vm.loginWithApple(),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _socialBtn(
                                      'assets/icons/mobile.svg',
                                      () => PhoneAuthDialog.showPhoneDialog(
                                        context,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                              Align(
                                alignment: Alignment.center,
                                child: Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      l10n.authHaveAccount,
                                      textAlign: TextAlign.center,
                                      style: textTheme.bodyLarge?.copyWith(
                                        color: colorScheme.onSurface,
                                        fontSize: 15,
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text(
                                        l10n.authLoginInline,
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.primary,
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        if (vm.loading) const LoadingOverlay(),
      ],
    );
  }

  Widget _socialBtn(String iconPath, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEFF0F6)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: SvgPicture.asset(iconPath, width: 18, height: 18)),
      ),
    );
  }
}
