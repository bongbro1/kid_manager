import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/network/network_action_guard.dart';
import 'package:kid_manager/core/validators.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/location/device_time_zone_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/setting_pages/widgets/date_pick_widget.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
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

  UserRole role = UserRole.child;
  bool hidePassword = true;

  final String localeString =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode == null
      ? WidgetsBinding.instance.platformDispatcher.locale.languageCode
      : '${WidgetsBinding.instance.platformDispatcher.locale.languageCode}_${WidgetsBinding.instance.platformDispatcher.locale.countryCode}';

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
    var initial = DateTime(now.year - 10, now.month, now.day);

    final parsed = _parseDate(_dobCtrl.text);
    if (parsed != null) {
      initial = parsed;
    }

    final date = await showModalBottomSheet<DateTime>(
      context: context,
      builder: (_) => WheelDatePicker(initialDate: initial),
    );

    if (date != null) {
      _dobCtrl.text = '${date.day}/${date.month}/${date.year}';
    }
  }

  DateTime? _parseDate(String text) {
    try {
      if (text.isEmpty) return null;

      final parts = text.split('/');
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

  Widget roleChip(UserRole value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: role == value,
      onSelected: (_) {
        setState(() => role = value);
      },
    );
  }

  // -------------------------
  // ADD ACCOUNT
  // -------------------------

  Future<void> _onAddAccount() async {
    final l10n = AppLocalizations.of(context);
    final actor = context.read<UserVm>().actorSnapshot;
    if (actor == null ||
        !context.read<AccessControlService>().canAddManagedAccounts(
          actor: actor,
        )) {
      AlertService.showSnack(l10n.firestorePermissionDenied, isError: true);
      return;
    }

    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    final dobText = _dobCtrl.text;

    if (name.isEmpty) {
      AlertService.showSnack(l10n.addAccountNameRequired, isError: true);
      return;
    }

    if (!Validators.isValidEmail(email)) {
      AlertService.showSnack(l10n.emailInvalid, isError: true);
      return;
    }

    if (password.length < 6) {
      AlertService.showSnack(l10n.weakPassword, isError: true);
      return;
    }

    // ✅ Parse DOB
    DateTime dob;
    try {
      dob = DateFormat('dd/MM/yyyy').parseStrict(dobText);
    } catch (_) {
      AlertService.showSnack(l10n.invalidBirthDate, isError: true);
      return;
    }

    final vm = context.read<UserVm>();
    final timezone = await DeviceTimeZoneService.instance.getDeviceTimeZone();

    try {
      final ok = await runGuardedNetworkVoidAction(
        context,
        action: () => vm.addChildAccount(
          name: name,
          email: email,
          password: password,
          dob: dob,
          role: role,
          locale: localeString,
          timezone: timezone,
        ),
      );
      if (!ok) {
        return;
      }

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
    final actor = context.select<UserVm, AppUser?>(
      (value) => value.actorSnapshot,
    );
    final canAddAccount =
        actor != null &&
        context.read<AccessControlService>().canAddManagedAccounts(
          actor: actor,
        );

    if (!canAddAccount) {
      return Scaffold(
        backgroundColor: scheme.background,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: scheme.surface,
          centerTitle: true,
          title: Text(
            l10n.addAccountTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
              fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
            ),
          ),
          iconTheme: IconThemeData(color: scheme.onSurface),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.firestorePermissionDenied,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

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
                fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
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
                            setState(() => hidePassword = !hidePassword);
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
                          l10n.addAccountAccessLabel,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: Theme.of(
                                  context,
                                ).appTypography.body.fontSize!,
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children: [
                          roleChip(UserRole.child, l10n.addAccountRoleChild),
                          roleChip(
                            UserRole.guardian,
                            l10n.addAccountRoleGuardian,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                /// BUTTON
                SizedBox(
                  height: 52,
                  child: AppButton(
                    text: l10n.addAccountTitle,
                    onPressed: _onAddAccount,
                    backgroundColor: scheme.primary,
                    foregroundColor: scheme.onPrimary,
                    height: 52,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (vm.loading) const LoadingOverlay(),
      ],
    );
  }
}

class _WheelDatePicker extends StatefulWidget {
  final DateTime initialDate;

  const _WheelDatePicker({required this.initialDate});

  @override
  State<_WheelDatePicker> createState() => _WheelDatePickerState();
}

class _WheelDatePickerState extends State<_WheelDatePicker> {
  late int day;
  late int month;
  late int year;

  @override
  void initState() {
    super.initState();

    day = widget.initialDate.day;
    month = widget.initialDate.month;
    year = widget.initialDate.year;
  }

  final List<int> years = List.generate(60, (i) => 1970 + i);

  int daysInMonth(int year, int month) {
    final date = DateTime(year, month + 1, 0);
    return date.day;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maxDay = daysInMonth(year, month);

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          /// handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Text(
            l10n.addAccountSelectBirthDateTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                /// DAY
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: day - 1,
                    ),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        day = i + 1;
                      });
                    },
                    children: List.generate(
                      maxDay,
                      (i) => Center(child: Text('${i + 1}')),
                    ),
                  ),
                ),

                /// MONTH
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: month - 1,
                    ),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        month = i + 1;

                        if (day > daysInMonth(year, month)) {
                          day = daysInMonth(year, month);
                        }
                      });
                    },
                    children: List.generate(
                      12,
                      (i) => Center(child: Text('${i + 1}')),
                    ),
                  ),
                ),

                /// YEAR
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 40,
                    scrollController: FixedExtentScrollController(
                      initialItem: years.indexOf(year),
                    ),
                    onSelectedItemChanged: (i) {
                      setState(() {
                        year = years[i];

                        if (day > daysInMonth(year, month)) {
                          day = daysInMonth(year, month);
                        }
                      });
                    },
                    children: years
                        .map((value) => Center(child: Text('$value')))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: AppButton(
              text: l10n.addAccountSelectButton,
              onPressed: () {
                Navigator.pop(context, DateTime(year, month, day));
              },
              backgroundColor: scheme.primary,
              foregroundColor: scheme.onPrimary,
              height: 50,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
