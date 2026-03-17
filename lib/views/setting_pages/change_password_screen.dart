import 'package:flutter/material.dart';
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
    final authVm = context.read<AuthVM>();

    await authVm.changePassword(
      oldPassword: _oldCtrl.text.trim(),
      newPassword: _newCtrl.text.trim(),
      confirmPassword: _confirmCtrl.text.trim(),
    );

    if (!mounted) return;

    if (authVm.error != null) {
      NotificationDialog.show(
        context,
        type: DialogType.error,
        title: 'Thất bại',
        message: authVm.error!,
      );
      return;
    }

    NotificationDialog.show(
      context,
      type: DialogType.success,
      title: 'Thành công',
      message: 'Đổi mật khẩu thành công',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
              "Đổi mật khẩu",
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
                          label: "Mật khẩu hiện tại",
                          hint: "Nhập mật khẩu hiện tại",
                          controller: _oldCtrl,
                          obscureText: hideOld,
                          suffixIcon: IconButton(
                            icon: Icon(
                              hideOld ? Icons.visibility_off : Icons.visibility,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                hideOld = !hideOld;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        AppLabeledTextField(
                          label: "Mật khẩu mới",
                          hint: "Nhập mật khẩu mới",
                          controller: _newCtrl,
                          obscureText: hideNew,
                          suffixIcon: IconButton(
                            icon: Icon(
                              hideNew ? Icons.visibility_off : Icons.visibility,
                              color: scheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(() {
                                hideNew = !hideNew;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        AppLabeledTextField(
                          label: "Xác nhận mật khẩu",
                          hint: "Nhập lại mật khẩu mới",
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
                              setState(() {
                                hideConfirm = !hideConfirm;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// button
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
                        "Cập nhật mật khẩu",
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
