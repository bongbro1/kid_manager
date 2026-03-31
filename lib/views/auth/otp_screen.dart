import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/helpers/mail_helper.dart';
import 'package:kid_manager/models/app_otp.dart';
import 'package:kid_manager/models/auth/auth_models.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/viewmodels/otp_vm.dart';
import 'package:kid_manager/views/auth/reset_pass_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key, required this.email, required this.purpose});

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
      if (!mounted) {
        return;
      }
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
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otp;
    final l10n = AppLocalizations.of(context);
    final authVM = context.read<AuthVM>();

    // Validate OTP length
    if (otp.length != 6) {
      AlertService.showSnack(l10n.authGenericError, isError: true);
      return;
    }

    // Validate digits only
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

    if (!mounted) return;

    switch (result) {
      case OtpVerifyResult.success:
        if (widget.purpose == OtpPurpose.verifyEmail) {
          // Lưu pending OTP trước khi logout
          authVM.setPendingOtp(widget.email, widget.purpose);

          // logout hiện tại vẫn giữ để sync state với backend
          await authVM.logout();

          if (!mounted) return;

          // Hiển thị dialog success
          NotificationDialog.show(
            context,
            type: DialogType.success,
            title: l10n.updateSuccessTitle,
            message: l10n.authRegisterSuccessMessage,
          );

          // Clear pending OTP sau khi hiển thị xong
          authVM.clearPendingOtp();

          await Future.delayed(const Duration(milliseconds: 1000));

          if (!mounted) return;

          // Pop về màn đầu tiên (login)
          Navigator.of(context).popUntil((route) => route.isFirst);
          return;
        }

        // OTP reset password
        final resetSessionToken = vm.resetSessionToken;
        if (resetSessionToken == null || resetSessionToken.isEmpty) {
          AlertService.showSnack(l10n.authGenericError, isError: true);
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ResetPasswordScreen(resetSessionToken: resetSessionToken),
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
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 24,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxContentWidth = constraints.maxWidth > 420
                      ? 420.0
                      : constraints.maxWidth;
                  final otpGap = maxContentWidth < 340 ? 4.0 : 6.0;
                  final otpCellWidth = ((maxContentWidth - (otpGap * 5)) / 6)
                      .clamp(38.0, 44.0);
                  final otpCellHeight = (otpCellWidth * 1.34).clamp(52.0, 59.0);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: maxContentWidth,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 260,
                                ),
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
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: Text(
                                  l10n.otpInstruction,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.75,
                                    ),
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              OtpInput(
                                onCompleted: (otp) {
                                  setState(() {
                                    _otp = otp;
                                  });
                                },
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
                                        ? colorScheme.onSurface.withValues(
                                            alpha: 0.5,
                                          )
                                        : colorScheme.primary,
                                    fontSize: 14,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 180,
                                ),
                                child: AppButton(
                                  text: l10n.otpVerifyButton,
                                  height: 50,
                                  onPressed: vm.isLocked
                                      ? null
                                      : _handleVerifyOtp,
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
          if (vm.loading) const LoadingOverlay(),
        ],
      ),
    );
  }
}

class OtpInput extends StatefulWidget {
  final Function(String) onCompleted;

  const OtpInput({super.key, required this.onCompleted});

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String get otp => _controllers.map((c) => c.text).join();

  int get _nextIndex {
    for (int i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.isEmpty) return i;
    }
    return _controllers.length - 1;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      value = value.substring(0, 1);
      _controllers[index].text = value;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }

    if (otp.length == 6) {
      _focusNodes[index].unfocus();
      widget.onCompleted(otp);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        _focusNodes[_nextIndex].requestFocus();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final char = _controllers[index].text;
          final isActive = index == _nextIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: SizedBox(
              width: 44,
              height: 59,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // UI box (giống bản cũ)
                  Container(
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
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),

                  // TextField thật (ẩn)
                  Focus(
                    onKeyEvent: (node, event) {
                      if (event.logicalKey == LogicalKeyboardKey.backspace &&
                          event is KeyDownEvent) {
                        if (_controllers[index].text.isEmpty && index > 0) {
                          _controllers[index - 1].clear();
                          _focusNodes[index - 1].requestFocus();
                          setState(() {});
                          return KeyEventResult.handled;
                        }

                        if (_controllers[index].text.isNotEmpty) {
                          _controllers[index].clear();
                          setState(() {});
                          return KeyEventResult.handled;
                        }
                      }

                      return KeyEventResult.ignored;
                    },
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          onChanged: (v) => _onChanged(index, v),
                          decoration: const InputDecoration(
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
