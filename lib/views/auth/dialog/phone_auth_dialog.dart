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
  static final List<Country> countries = [
    Country(name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
    Country(name: 'United States', dialCode: '+1', flag: '🇺🇸'),
    Country(name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
    Country(name: 'Korea', dialCode: '+82', flag: '🇰🇷'),
  ];

  static String normalizePhone(String phone, String dialCode) {
    phone = phone.replaceAll(' ', '');

    if (phone.startsWith('+')) return phone;

    if (dialCode == '+84' && phone.startsWith('0')) {
      return '$dialCode${phone.substring(1)}';
    }

    return '$dialCode$phone';
  }

  static Future<void> showPhoneDialog(BuildContext context) async {
    final parentContext = context;
    final l10n = AppLocalizations.of(context);
    final phoneController = TextEditingController();

    Country selectedCountry = countries.first;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final vm = sheetContext.watch<AuthVM>();
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Text(
                    l10n.phoneAuthTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '973564344',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 8),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Country>(
                            value: selectedCountry,
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: vm.isSendingOtp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sms_outlined),
                      label: Text(
                        vm.isSendingOtp
                            ? 'Đang gửi...'
                            : l10n.phoneAuthSendOtpButton,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor: Colors.blue,
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: vm.isSendingOtp
                          ? null
                          : () async {
                              try {
                                debugPrint('STEP 1');
                                var phone = phoneController.text.trim();

                                if (phone.isEmpty) {
                                  NotificationDialog.show(
                                    parentContext,
                                    type: DialogType.error,
                                    title: 'Thất bại',
                                    message: 'Vui lòng nhập số điện thoại',
                                  );
                                  return;
                                }

                                phone = normalizePhone(
                                  phone,
                                  selectedCountry.dialCode,
                                );

                                debugPrint('PHONE_NORMALIZED = $phone');
                                debugPrint('STEP 2 before sendOtpSms');

                                await vm.sendOtpSms(phone);

                                debugPrint('STEP 3 after sendOtpSms');

                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  debugPrint('STEP 4 after pop');
                                }

                                Future.microtask(() {
                                  debugPrint('STEP 5 show otp dialog');
                                  showOtpDialog(parentContext);
                                });
                              } catch (e) {
                                debugPrint('STEP ERROR: $e');

                                NotificationDialog.show(
                                  parentContext,
                                  type: DialogType.error,
                                  title: 'Thất bại',
                                  message: 'Không gửi được OTP: $e',
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
        return Stack(
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return Dialog(
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.phoneAuthOtpInstruction,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
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
                          style: const TextStyle(
                            letterSpacing: 6,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '••••••',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.cancelButton),
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
                                child: Text(l10n.confirmButton),
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
            if (vm.isSendingOtp) LoadingOverlay(),
          ],
        );
      },
    );
  }
}
