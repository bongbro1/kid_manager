import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/models/auth/password_validator.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/auth/auth_text_field.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String uid;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.uid,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  @override
  void initState() {
    super.initState();

    _passwordController.addListener(_validatePassword);
  }

  PasswordValidationResult _validation = const PasswordValidationResult(
    hasMinLength: false,
    hasUppercase: false,
    hasLowercase: false,
    hasNumber: false,
  );

  void _validatePassword() {
    final password = _passwordController.text;

    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);

      _validation = PasswordValidator.validate(password);
    });
  }

  bool get _isPasswordValid => _validation.isValid;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final authVM = context.read<AuthVM>();
    final l10n = AppLocalizations.of(context);
    if (!_isPasswordValid) return;

    if (_passwordController.text != _confirmController.text) {
      AlertService.showSnack(l10n.resetPasswordConfirmMismatch, isError: true);
      return;
    }

    try {
      await authVM.resetPassword(
        uid: widget.uid,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      NotificationDialog.show(
        context,
        type: DialogType.success,
        title: l10n.updateSuccessTitle,
        message: l10n.resetPasswordSuccessMessage,
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      AlertService.showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthVM>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
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
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: SizedBox(
                          width: 289,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.resetPasswordTitle,
                                style: textTheme.headlineSmall?.copyWith(
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
                                l10n.resetPasswordSubtitle,
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(
                                    0.75,
                                  ),
                                  fontSize: 15,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      AuthTextField(
                        label: l10n.resetPasswordNewLabel,
                        controller: _passwordController,
                        hintText: l10n.authEnterPasswordHint,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        isPassword: true,
                        prefixSvg: 'assets/icons/lock.svg',
                      ),

                      AuthTextField(
                        label: l10n.resetPasswordConfirmLabel,
                        controller: _confirmController,
                        hintText: l10n.resetPasswordConfirmLabel,
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        isPassword: true,
                        prefixSvg: 'assets/icons/lock.svg',
                      ),

                      const SizedBox(height: 10),

                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.6),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.resetPasswordRuleTitle,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: colorScheme.onSurface,
                              ),
                            ),

                            const SizedBox(height: 10),

                            _buildRule(
                              _hasMinLength,
                              l10n.resetPasswordRuleMinLength,
                            ),
                            _buildRule(
                              _hasUppercase,
                              l10n.resetPasswordRuleUppercase,
                            ),
                            _buildRule(
                              _hasLowercase,
                              l10n.resetPasswordRuleLowercase,
                            ),
                            _buildRule(
                              _hasNumber,
                              l10n.resetPasswordRuleNumber,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      AppButton(
                        height: 60,
                        text: l10n.resetPasswordCompleteButton,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        onPressed: _isPasswordValid ? _resetPassword : null,
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (vm.loading) const LoadingOverlay(),
      ],
    );
  }

  Widget _buildRule(bool valid, String text) {
    return Builder(
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        const successColor = Color(0xFF22C55E);
        final inactiveColor = colorScheme.outline;
        final inactiveTextColor = colorScheme.onSurface.withOpacity(0.65);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: valid ? successColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: valid ? successColor : inactiveColor,
                  ),
                ),
                child: valid
                    ? Icon(Icons.check, size: 12, color: colorScheme.onPrimary)
                    : null,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: (textTheme.bodySmall ?? const TextStyle()).copyWith(
                    fontSize: 13,
                    color: valid ? successColor : inactiveTextColor,
                    fontWeight: valid ? FontWeight.w500 : FontWeight.w400,
                  ),
                  child: Text(text),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
