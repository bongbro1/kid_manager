import 'package:flutter/material.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/common/social_login_button.dart';

import '../../core/app_colors.dart';
import '../../widgets/app/app_button.dart';

import 'login_screen.dart';
import 'signup_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  final _policyStyle = const TextStyle(
    color: Color(0xFF8E8E93),
    fontSize: 12,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w500,
    height: 2,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 24,
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        l10n.authStartTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF333333),
                          fontSize: 32,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          height: 0.75,
                          letterSpacing: 0.50,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 180),
                        child: Text(
                          l10n.authStartSubtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF333333),
                            fontSize: 16,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            height: 1.50,
                            letterSpacing: 0.50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SocialLoginButton(
                        text: l10n.authContinueWithGoogle,
                        iconAsset: 'assets/icons/google.svg',
                        onTap: () {
                          // TODO: Google login
                        },
                      ),
                      const SizedBox(height: 16),
                      SocialLoginButton(
                        text: l10n.authContinueWithFacebook,
                        iconAsset: 'assets/icons/facebook.svg',
                        onTap: () {
                          // TODO: Facebook login
                        },
                      ),
                      const SizedBox(height: 16),
                      SocialLoginButton(
                        text: l10n.authContinueWithApple,
                        iconAsset: 'assets/icons/apple.svg',
                        onTap: () {
                          // TODO: Apple login
                        },
                      ),
                      const SizedBox(height: 16),
                      SocialLoginButton(
                        text: l10n.authContinueWithPhone,
                        iconAsset: 'assets/icons/mobile.svg',
                        onTap: () {
                          // TODO: Phone login
                        },
                      ),
                      const SizedBox(height: 29),
                      Container(
                        width: 147.78,
                        height: 0.83,
                        decoration: const BoxDecoration(
                          color: Color(0x331A1A1A),
                        ),
                      ),
                      const SizedBox(height: 24.17),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppButton(
                              height: 60,
                              text: l10n.authLoginButton,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              text: l10n.authSignupButton,
                              height: 60,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SignupScreen(),
                                  ),
                                );
                              },
                              backgroundColor: AppColors.primarySoft,
                              foregroundColor: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: 147.78,
                        height: 1,
                        decoration: const BoxDecoration(
                          color: Color(0x331A1A1A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          Text(l10n.authPrivacyPolicy, style: _policyStyle),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF8E8E93),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(width: 4, height: 4),
                          ),
                          Text(l10n.authTermsOfService, style: _policyStyle),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
