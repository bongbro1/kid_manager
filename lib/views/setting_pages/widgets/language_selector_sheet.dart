import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_languages.dart';
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
    final scheme = Theme.of(context).colorScheme;

    final storage = context.read<StorageService>();
    final localeVm = context.watch<LocaleVm>();

    final currentLocale = localeVm.locale.languageCode.isNotEmpty
        ? localeVm.locale.languageCode
        : (storage.getString(StorageKeys.locale) ??
              storage.getString('preferredLocale') ??
              'vi');

    final languages = AppLanguages.languages;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          /// Title
          Text(
            l10n.languageSetting,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 20),

          /// Language list
          Expanded(
            child: ListView(
              children: languages.map((lang) {
                final isSelected = lang['code'] == currentLocale;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _changeLanguage(context, lang['code']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? scheme.primary
                              : scheme.outline.withOpacity(.3),
                        ),
                        color: isSelected
                            ? scheme.primary.withOpacity(.08)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang['flag']!,
                            style: const TextStyle(fontSize: 22),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              lang['name']!,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          if (isSelected)
                            Icon(Icons.check_circle, color: scheme.primary),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(BuildContext context, String value) async {
    final l10n = AppLocalizations.of(context);
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
  }
}
