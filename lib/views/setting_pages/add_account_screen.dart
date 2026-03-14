import 'package:flutter/material.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/app/app_input_component.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
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

  final locale = WidgetsBinding.instance.platformDispatcher.locale;

  late final String languageCode = locale.languageCode;
  late final String? countryCode = locale.countryCode;
  late final String localeString = countryCode == null
      ? languageCode
      : '${languageCode}_$countryCode';

  // timezone chuẩn (Asia/Ho_Chi_Minh)
  final String timezone = DateTime.now().timeZoneName.isNotEmpty
      ? DateTime.now().timeZoneName
      : 'Asia/Ho_Chi_Minh';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _onAddAccount() async {
    final l10n = AppLocalizations.of(context);
    final dob = parseDateFromText(_dobCtrl.text);
    final email = _emailCtrl.text.trim();

    if (dob == null) {
      debugPrint('ChildADD: invalid birth date');
      AlertService.showSnack(l10n.invalidBirthDate, isError: true);
      return;
    }

    // if (!Validators.isValidEmail(email)) {
    //   AlertService.showSnack('Email không hợp lệ', isError: true);
    //   return;
    // }

    final userRepo = context.read<UserRepository>();
    final storage = context.read<StorageService>();
    final parentUid = storage.getString(StorageKeys.uid);

    if (parentUid == null) {
      debugPrint('ChildADD: parent is not signed in');
      AlertService.showSnack(l10n.sessionExpiredLoginAgain, isError: true);
      return;
    }

    try {
      final childId = await userRepo.createChildAccount(
        parentUid: parentUid,
        email: email,
        password: _passwordCtrl.text,
        displayName: _nameCtrl.text.trim(),
        dob: dob,
        locale: localeString,
        timezone: timezone,
      );

      debugPrint('ChildADD: child account created successfully: $childId');

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addAccountTitle)),
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(17),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              ),
              const SizedBox(height: 16),
              AppLabeledTextField(
                label: l10n.birthDateLabel,
                hint: l10n.birthDateHint,
                controller: _dobCtrl,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: l10n.addAccountTitle,
                height: 50,
                onPressed: _onAddAccount,
              ),

              // đệm dưới để không bị bàn phím che
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
