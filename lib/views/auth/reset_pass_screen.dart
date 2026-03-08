import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/features/sessionguard/session_guard.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/views/auth/login_screen.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/auth/auth_text_field.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
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

  void _validatePassword() {
    final password = _passwordController.text;

    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'[0-9]').hasMatch(password);
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final authVM = context.read<AuthVM>();
    if (!_isPasswordValid) return;

    if (_passwordController.text != _confirmController.text) {
      AlertService.showSnack('Mật khẩu nhập lại không khớp', isError: true);
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
        title: "Thành công",
        message: "Đặt lại mật khẩu thành công",
      );
      await Future.delayed(const Duration(milliseconds: 1000));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SessionGuard()),
      );
    } catch (e) {
      AlertService.showSnack(e.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthVM>();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
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
                        child: SvgPicture.asset(
                          'assets/icons/back.svg',
                          width: 17,
                          height: 12.5,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.only(left: 14),
                        child: SizedBox(
                          width: 289,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'ĐẶT LẠI \nMẬT KHẨU MỚI',
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
                                'Điền mật khẩu mới của bạn!',
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

                      const SizedBox(height: 20),

                      AuthTextField(
                        label: 'Mật khẩu mới',
                        controller: _passwordController,
                        hintText: 'Nhập mật khẩu',
                        keyboardType: TextInputType.text,
                        obscureText: true,
                        isPassword: true,
                        prefixSvg: 'assets/icons/lock.svg',
                      ),

                      AuthTextField(
                        label: 'Nhập lại mật khẩu',
                        controller: _confirmController,
                        hintText: 'Nhập lại mật khẩu',
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
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E5EA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Mật khẩu cần có",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 10),

                            _buildRule(_hasMinLength, "Ít nhất 8 ký tự"),
                            _buildRule(_hasUppercase, "Có chữ hoa"),
                            _buildRule(_hasLowercase, "Có chữ thường"),
                            _buildRule(_hasNumber, "Có số"),
                          ],
                        ),
                      ),

                      const Spacer(),

                      AppButton(
                        height: 60,
                        text: 'Hoàn tất',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        onPressed: _isPasswordValid ? _resetPassword : null,
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: valid ? const Color(0xFF22C55E) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: valid
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            child: valid
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),

          const SizedBox(width: 10),

          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 13,
              color: valid ? const Color(0xFF22C55E) : const Color(0xFF6B7280),
              fontWeight: valid ? FontWeight.w500 : FontWeight.w400,
            ),
            child: Text(text),
          ),
        ],
      ),
    );
  }
}
