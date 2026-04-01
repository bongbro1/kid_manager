import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/models/auth/auth_models.dart';
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

    if (email.isEmpty) {
      AlertService.showSnack(l10n.authEnterAllInfo, isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AlertService.showSnack(l10n.emailInvalid, isError: true);
      return;
    }

    final ok = await authVm.forgotPassword(email);

    if (!ok) {
      AlertService.showSnack(
        authVm.error ?? l10n.authSendOtpFailed,
        isError: true,
      );
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OtpScreen(email: email, purpose: OtpPurpose.resetPassword),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthVM>();
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
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                0,
                horizontalPadding,
                MediaQuery.viewInsetsOf(context).bottom,
              ),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    behavior: HitTestBehavior.opaque,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/icons/back.svg',
                                        width: 17,
                                        height: 12.5,
                                        colorFilter: ColorFilter.mode(
                                          colorScheme.onSurface,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.authForgotPasswordTitle,
                                        style: textTheme.headlineSmall
                                            ?.copyWith(
                                              fontSize: 24,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.w600,
                                              height: 1.42,
                                              letterSpacing: -0.19,
                                              color: colorScheme.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        l10n.authForgotPasswordSubtitle,
                                        style: textTheme.bodyLarge?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.75),
                                          fontSize: 15,
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  AuthTextField(
                                    label: l10n.authEnterYourEmailLabel,
                                    controller: _emailController,
                                    hintText: l10n.authEnterEmailHint,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixSvg: 'assets/icons/user.svg',
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  bottom: 24,
                                ),
                                child: AppButton(
                                  height: 60,
                                  text: l10n.authContinueButton,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  onPressed: _sendOtp,
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                              ),
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
        if (authVM.loading) const LoadingOverlay(),
      ],
    );
  }
}
