import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/views/setting_pages/widgets/date_pick_widget.dart';
import 'package:kid_manager/widgets/app/app_input_component.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class AddAccountScreen extends StatefulWidget {
  const AddAccountScreen({super.key});

  @override
  State<AddAccountScreen> createState() => _AddAccountScreenState();
}

class _AddAccountScreenState extends State<AddAccountScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  String role = "child";
  bool hidePassword = true;

  final String localeString =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode == null
      ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
      : '${WidgetsBinding.instance.platformDispatcher.locale.languageCode}_${WidgetsBinding.instance.platformDispatcher.locale.countryCode}';

  final String timezone = DateTime.now().timeZoneName.isNotEmpty
      ? DateTime.now().timeZoneName
      : 'Asia/Ho_Chi_Minh';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  // -------------------------
  // DATE PICKER
  // -------------------------

  Future<void> pickDate() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 10, now.month, now.day);

    final parsed = _parseDate(_dobCtrl.text);
    if (parsed != null) {
      initial = parsed;
    }

    final date = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => WheelDatePicker(initialDate: initial),
    );

    if (date != null) {
      _dobCtrl.text = "${date.day}/${date.month}/${date.year}";
    }
  }

  DateTime? _parseDate(String text) {
    try {
      if (text.isEmpty) return null;

      final parts = text.split("/");
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  // -------------------------
  // ROLE CHIP
  // -------------------------

  Widget roleChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: role == value,
      onSelected: (_) {
        setState(() {
          role = value;
        });
      },
    );
  }

  // -------------------------
  // ADD ACCOUNT
  // -------------------------

  Future<void> _onAddAccount() async {
    final l10n = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final dobText = _dobCtrl.text;

    if (name.isEmpty) {
      AlertService.showSnack('Vui lòng nhập tên', isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AlertService.showSnack('Email không hợp lệ', isError: true);
      return;
    }

    if (password.length < 6) {
      AlertService.showSnack('Mật khẩu phải ít nhất 6 ký tự', isError: true);
      return;
    }

    // ✅ Parse DOB
    DateTime dob;
    try {
      dob = DateFormat('dd/MM/yyyy').parseStrict(dobText);
    } catch (_) {
      AlertService.showSnack('Ngày sinh không hợp lệ', isError: true);
      return;
    }

    final vm = context.read<UserVm>();

    try {
      await vm.addChildAccount(
        name: name,
        email: email,
        password: password,
        dob: dob,
        role: role,
        locale: localeString,
        timezone: timezone,
      );

      if (!mounted) return;

      await NotificationDialog.show(
        context,
        type: DialogType.success,
        title: l10n.updateSuccessTitle,
        message: l10n.addAccountSuccessMessage,
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      AlertService.showSnack(error.toString(), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final vm = context.watch<UserVm>();
    return Stack(
      children: [
        Scaffold(
          backgroundColor: scheme.background,

          appBar: AppBar(
            elevation: 0,
            backgroundColor: scheme.surface,
            centerTitle: true,
            title: Text(
              l10n.addAccountTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            iconTheme: IconThemeData(color: scheme.onSurface),
          ),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// FORM CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        color: Colors.black.withOpacity(.05),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      AppLabeledTextField(
                        label: l10n.fullNameLabel,
                        hint: l10n.fullNameHint,
                        controller: _nameCtrl,
                      ),

                      const SizedBox(height: 16),

                      AppLabeledTextField(
                        label: l10n.authEmailLabel,
                        hint: l10n.authEnterEmailHint,
                        controller: _emailCtrl,
                      ),

                      const SizedBox(height: 16),

                      AppLabeledTextField(
                        label: l10n.authPasswordLabel,
                        hint: l10n.authEnterPasswordHint,
                        controller: _passwordCtrl,
                        obscureText: hidePassword,
                        suffixIcon: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            size: 18,
                          ),
                          onPressed: () {
                            setState(() {
                              hidePassword = !hidePassword;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      AppLabeledTextField(
                        label: l10n.birthDateLabel,
                        hint: l10n.birthDateHint,
                        controller: _dobCtrl,
                        readOnly: true,
                        onTap: pickDate,
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),

                      const SizedBox(height: 20),

                      /// ROLE
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Quyền truy cập",
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        children: [
                          roleChip("child", "Con"),
                          roleChip("guardian", "Phụ huynh"),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                /// BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _onAddAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: scheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.addAccountTitle,
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
        if (vm.loading) LoadingOverlay(),
      ],
    );
  }
}
