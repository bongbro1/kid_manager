import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/auth/country.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:provider/provider.dart';

class PhoneAuthDialog {
  static final RegExp _nonDigitRegExp = RegExp(r'\D');
  static final RegExp _e164RegExp = RegExp(r'^\+[1-9]\d{7,14}$');

  static final List<Country> countries = [
    Country(name: 'Vietnam', dialCode: '+84', code: 'VN'),
    Country(name: 'United States', dialCode: '+1', code: 'US'),
    Country(name: 'Japan', dialCode: '+81', code: 'JP'),
    Country(name: 'Korea', dialCode: '+82', code: 'KR'),
  ];

  static String _digitsOnly(String value) {
    return value.replaceAll(_nonDigitRegExp, '');
  }

  static bool _dropsNationalPrefixZero(String dialCode) {
    return dialCode == '+84' || dialCode == '+81' || dialCode == '+82';
  }

  static String normalizePhone(String phone, String dialCode) {
    final trimmed = phone.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('00')) {
      return '+${_digitsOnly(trimmed.substring(2))}';
    }

    if (trimmed.startsWith('+')) {
      return '+${_digitsOnly(trimmed)}';
    }

    final dialDigits = _digitsOnly(dialCode);
    var digits = _digitsOnly(trimmed);
    if (digits.isEmpty) {
      return '';
    }

    if (digits.startsWith(dialDigits)) {
      digits = digits.substring(dialDigits.length);
    }

    if (_dropsNationalPrefixZero(dialCode) && digits.startsWith('0')) {
      digits = digits.substring(1);
    }

    return '+$dialDigits$digits';
  }

  static String? validatePhone(String phone, AppLocalizations l10n) {
    final isVietnamese = l10n.localeName.toLowerCase().startsWith('vi');
    if (phone.isEmpty) {
      return isVietnamese
          ? 'Vui lòng nhập số điện thoại'
          : 'Please enter a phone number';
    }

    if (!_e164RegExp.hasMatch(phone)) {
      return isVietnamese
          ? 'Số điện thoại không hợp lệ. Hãy nhập đúng định dạng quốc tế, ví dụ +84973564344.'
          : 'Invalid phone number. Please use an international format such as +84973564344.';
    }

    return null;
  }

  static String mapPhoneAuthErrorMessage(AppLocalizations l10n, Object error) {
    final raw = error.toString();
    final isVietnamese = l10n.localeName.toLowerCase().startsWith('vi');

    if (raw.contains('too-many-requests')) {
      return isVietnamese
          ? 'Thiết bị này đang bị Firebase chặn tạm thời vì gửi quá nhiều yêu cầu OTP. Hãy chờ một lúc rồi thử lại.'
          : 'This device is temporarily blocked by Firebase because it sent too many OTP requests. Please wait and try again later.';
    }

    if (raw.contains('invalid-phone-number')) {
      return isVietnamese
          ? 'Số điện thoại chưa đúng chuẩn quốc tế (E.164). Hãy kiểm tra lại mã quốc gia và số điện thoại.'
          : 'The phone number is not in valid international (E.164) format. Please check the country code and number.';
    }

    if (raw.contains('app-not-authorized')) {
      return isVietnamese
          ? 'Ứng dụng Android này chưa được cấu hình hợp lệ cho Firebase Phone Auth. Cần kiểm tra package name, SHA-1 và SHA-256 trong Firebase Console.'
          : 'This Android app is not properly configured for Firebase Phone Auth. Check the package name, SHA-1, and SHA-256 in Firebase Console.';
    }

    return raw;
  }

  static Future<void> showPhoneDialog(BuildContext context) async {
    final parentContext = context;
    final l10n = AppLocalizations.of(context);
    final phoneController = TextEditingController();

    Country selectedCountry = countries.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final vm = sheetContext.watch<AuthVM>();
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return StatefulBuilder(
          builder: (context, setState) {
            final mediaQuery = MediaQuery.of(context);
            return AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.phoneAuthTitle,
                    style: textTheme.titleLarge?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: '973564344',
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.45),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Country>(
                            value: selectedCountry,
                            dropdownColor: colorScheme.surface,
                            iconEnabledColor: colorScheme.onSurface,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            onChanged: (Country? value) {
                              if (value != null) {
                                setState(() {
                                  selectedCountry = value;
                                });
                              }
                            },
                            items: countries.map((country) {
                              return DropdownMenuItem<Country>(
                                value: country,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(country.flag),
                                    const SizedBox(width: 6),
                                    Text(country.dialCode),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.4,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.4,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 1.4,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: vm.isSendingOtp
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.sms_outlined),
                      label: Text(
                        vm.isSendingOtp
                            ? (l10n.localeName.toLowerCase().startsWith('vi')
                                  ? 'Đang gửi...'
                                  : 'Sending...')
                            : l10n.phoneAuthSendOtpButton,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        disabledBackgroundColor: colorScheme.primary
                            .withOpacity(0.6),
                        disabledForegroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: vm.isSendingOtp
                          ? null
                          : () async {
                              try {
                                final normalizedPhone = normalizePhone(
                                  phoneController.text,
                                  selectedCountry.dialCode,
                                );
                                final validationMessage = validatePhone(
                                  normalizedPhone,
                                  l10n,
                                );

                                if (validationMessage != null) {
                                  NotificationDialog.show(
                                    parentContext,
                                    type: DialogType.error,
                                    title:
                                        l10n.localeName
                                            .toLowerCase()
                                            .startsWith('vi')
                                        ? 'Thất bại'
                                        : 'Failed',
                                    message: validationMessage,
                                  );
                                  return;
                                }

                                await vm.sendOtpSms(normalizedPhone);

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                }

                                Future.microtask(() {
                                  showOtpDialog(parentContext);
                                });
                              } catch (e) {
                                NotificationDialog.show(
                                  parentContext,
                                  type: DialogType.error,
                                  title:
                                      l10n.localeName.toLowerCase().startsWith(
                                        'vi',
                                      )
                                      ? 'Thất bại'
                                      : 'Failed',
                                  message: mapPhoneAuthErrorMessage(l10n, e),
                                );
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static void showOtpDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final otpController = TextEditingController();

    showDialog(
      context: context,
      builder: (sheetContext) {
        final vm = sheetContext.watch<AuthVM>();
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return Stack(
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
                  backgroundColor: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 42,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.phoneAuthOtpTitle,
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.phoneAuthOtpInstruction,
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: otpController,
                          keyboardType: TextInputType.phone,
                          textAlign: TextAlign.center,
                          onChanged: (_) {
                            setState(() {});
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          style: textTheme.titleLarge?.copyWith(
                            letterSpacing: 6,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••',
                            hintStyle: textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.4),
                            ),
                            filled: true,
                            fillColor: colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.4),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withOpacity(0.4),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 1.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.onSurface,
                                  side: BorderSide(
                                    color: colorScheme.outline.withOpacity(0.5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.cancelButton,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: otpController.text.length == 6
                                    ? () async {
                                        try {
                                          await vm.verifyOtpSmS(
                                            otpController.text,
                                          );

                                          if (!context.mounted) return;
                                          Navigator.pop(context);
                                        } catch (_) {
                                          AlertService.showSnack(
                                            l10n.otpIncorrect,
                                            isError: true,
                                          );
                                        }
                                      }
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  l10n.confirmButton,
                                  style: textTheme.labelLarge?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (vm.isSendingOtp) const LoadingOverlay(),
          ],
        );
      },
    );
  }
}
