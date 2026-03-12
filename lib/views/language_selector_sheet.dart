import 'package:flutter/material.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/locale_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/app/app_overlay_sheet.dart';
import 'package:provider/provider.dart';

class LanguageSelectorSheet extends StatelessWidget {
  const LanguageSelectorSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final storage = context.read<StorageService>();
    final localeVm = context.watch<LocaleVm>();
    final currentLocale = localeVm.locale.languageCode.isNotEmpty
        ? localeVm.locale.languageCode
        : (storage.getString(StorageKeys.locale) ??
              storage.getString('preferredLocale') ??
              'vi');

    final languages = [
      {'code': 'vi', 'name': l10n.vietnamese},
      {'code': 'en', 'name': l10n.english},
    ];

    return AppOverlaySheet(
      height: 250,
      showHandle: true,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              l10n.languageSetting,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            ...languages.map(
              (lang) => RadioListTile<String>(
                title: Text(lang['name']!),
                value: lang['code']!,
                groupValue: currentLocale,
                onChanged: (value) async {
                  if (value == null || value == currentLocale) return;

                  final vm = context.read<UserVm>();
                  final localeState = context.read<LocaleVm>();
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  var remoteUpdated = true;
                  final profile = vm.profile;
                  if (profile != null) {
                    remoteUpdated = await vm.updateUserInfo(
                      name: profile.name,
                      phone: profile.phone,
                      gender: profile.gender,
                      dob: profile.dob,
                      address: profile.address,
                      allowTracking: profile.allowTracking,
                      locale: value,
                    );
                  }

                  await localeState.setLocaleCode(value);
                  if (!context.mounted) return;

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        remoteUpdated
                            ? l10n.updateSuccessMessage
                            : (vm.error ?? l10n.unknownError),
                      ),
                    ),
                  );

                  navigator.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
