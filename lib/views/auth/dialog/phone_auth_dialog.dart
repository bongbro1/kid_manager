import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/core/alert_service.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/viewmodels/auth_vm.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:provider/provider.dart';

class PhoneAuthDialog {
  static String normalizePhone(String phone) {
    phone = phone.replaceAll(" ", "");

    if (phone.startsWith("0")) {
      return "+84${phone.substring(1)}";
    }

    if (!phone.startsWith("+")) {
      return "+84$phone";
    }

    return phone;
  }

  static void showPhoneDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final vm = context.read<AuthVM>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
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

              const Text(
                "Đăng nhập bằng số điện thoại",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "973564344",

                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          "+84",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        SizedBox(width: 8),
                        SizedBox(
                          height: 24,
                          child: VerticalDivider(thickness: 1),
                        ),
                      ],
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
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text(
                    "Gửi mã OTP",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    String phone = phoneController.text.trim();
                    phone = normalizePhone(phone);

                    await vm.sendOtpSms(phone);

                    Navigator.pop(context);

                    showOtpDialog(context);
                  },
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  static void showOtpDialog(BuildContext context) {
    final otpController = TextEditingController();
    final vm = context.read<AuthVM>();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
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

                    const Text(
                      "Nhập mã xác thực",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Vui lòng nhập mã OTP được gửi đến điện thoại của bạn",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,

                      onChanged: (_) {
                        setState(() {}); // rebuild dialog
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
                        hintText: "••••••",
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
                            child: const Text("Hủy"),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton(
                            onPressed: otpController.text.length == 6
                                ? () async {
                                    try {
                                      await vm.verifyOtpSmS(otpController.text);

                                      Navigator.pop(context);
                                    } catch (e) {
                                      AlertService.showSnack(
                                        'OTP không đúng',
                                        isError: true,
                                      );
                                      // NotificationDialog.show(
                                      //   context,
                                      //   type: DialogType.error,
                                      //   title: 'Thất bại',
                                      //   message: 'OTP không đúng',
                                      // );
                                    }
                                  }
                                : null,
                            child: const Text("Xác nhận"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
