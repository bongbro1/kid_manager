import 'package:flutter/material.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/auth/password_validator.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/widgets/app/app_input_component.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool hideOld = true;
  bool hideNew = true;
  bool hideConfirm = true;
  Future<void> _handleChangePassword() async {
    final vm = context.read<AuthVM>();
    final l10n = AppLocalizations.of(context);

    final oldPassword = _oldCtrl.text.trim();
    final newPassword = _newCtrl.text.trim();
    final confirmPassword = _confirmCtrl.text.trim();

    // Validate
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      AlertService.showSnack(l10n.authEnterAllInfo, isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      AlertService.showSnack(l10n.authPasswordMismatch, isError: true);
      return;
    }

    final passwordResult = PasswordValidator.validate(newPassword);
    if (!passwordResult.isValid) {
      AlertService.showSnack(
        'Mật khẩu phải có ít nhất 8 ký tự, gồm chữ hoa, chữ thường và số.',
        isError: true,
      );
      return;
    }

    try {
      // 🔥 không còn return bool nữa
      await vm.changePassword(
        oldPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (!mounted) return;

      await NotificationDialog.show(
        context,
        type: DialogType.success,
        title: l10n.updateSuccessTitle,
        message: l10n.changePasswordSuccessMessage,
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      AlertService.showSnack(
        e.toString().replaceFirst("Exception: ", ""),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<AuthVM>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: scheme.background,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: scheme.surface,
            centerTitle: true,
            title: Text(
              l10n.changePasswordTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            iconTheme: IconThemeData(color: scheme.onSurface),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// form card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow.withOpacity(.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        AppLabeledTextField(
                          label: l10n.changePasswordCurrentPasswordLabel,
                          hint: l10n.changePasswordCurrentPasswordHint,
                          controller: _oldCtrl,
                          obscureText: hideOld,
                          suffixIcon: IconButton(
                            icon: Icon(
                              hideOld ? Icons.visibility_off : Icons.visibility,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() => hideOld = !hideOld);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppLabeledTextField(
                          label: l10n.changePasswordNewPasswordLabel,
                          hint: l10n.changePasswordNewPasswordHint,
                          controller: _newCtrl,
                          obscureText: hideNew,
                          suffixIcon: IconButton(
                            icon: Icon(
                              hideNew ? Icons.visibility_off : Icons.visibility,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() => hideNew = !hideNew);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppLabeledTextField(
                          label: l10n.changePasswordConfirmPasswordLabel,
                          hint: l10n.changePasswordConfirmPasswordHint,
                          controller: _confirmCtrl,
                          obscureText: hideConfirm,
                          suffixIcon: IconButton(
                            icon: Icon(
                              hideConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() => hideConfirm = !hideConfirm);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: scheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.changePasswordUpdateButton,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (vm.loading) const LoadingOverlay(),
      ],
    );
  }
}
