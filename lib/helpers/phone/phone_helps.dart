import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/widgets/parent/phone/add_children_phone.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> handleCallChildByProfile({
  required BuildContext context,
  required String childId,
  required String childName,
}) async {
  final repo = context.read<UserRepository>();

  try {
    final profile = await repo.getUserProfile(childId);
    final phone = (profile?.phone ?? '').trim();

    if (phone.isEmpty) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AddChildPhoneScreen(childId: childId, childName: childName),
        ),
      );

      if (result == null || result.trim().isEmpty) return;
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.3),
        builder: (dialogContext) {
          final config = DialogConfig.from(DialogType.success);

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  config.iconBuilder(),
                  const SizedBox(height: 20),
                  const Text(
                    'Thêm thành công',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Số điện thoại của bé đã được lưu thành công',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: config.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }

    if (!context.mounted) return;
    await launchPhoneCall(context, phone);
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Không thể thực hiện cuộc gọi: $e')));
  }
}

Future<void> launchPhoneCall(BuildContext context, String phone) async {
  final cleanedPhone = phone.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: cleanedPhone);

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng điện thoại')),
      );
    }
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Gọi điện thất bại: $e')));
  }
}
