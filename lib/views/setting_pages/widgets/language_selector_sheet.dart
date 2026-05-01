import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_languages.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/locale_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
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
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withOpacity(.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),

            /// Title
            Text(l10n.languageSetting, style: theme.textTheme.titleMedium),
            const SizedBox(height: 20),

            /// Language list
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
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
                              style: TextStyle(
                                fontSize: Theme.of(
                                  context,
                                ).appTypography.itemTitle.fontSize,
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
          ],
        ),
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
