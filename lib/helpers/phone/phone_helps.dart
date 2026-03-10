import 'package:flutter/material.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/widgets/app/app_notice_card.dart';
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
    String phone = (profile?.phone ?? '').trim();

    if (phone.isEmpty) {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (_) => AddChildPhoneScreen(
            childId: childId,
            childName: childName,
          ),
        ),
      );

      if (result == null || result.trim().isEmpty) return;
      if (!context.mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AppNoticeCard(
          type: AppNoticeType.success,
          title: 'Thêm thành công',
          message: 'Số điện thoại của bé đã được lưu thành công',
        ),
      );

      return; // không tự gọi ngay sau khi thêm
    }

    if (!context.mounted) return;
    await launchPhoneCall(context, phone);
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Không thể thực hiện cuộc gọi: $e'),
      ),
    );
  }
}

Future<void> launchPhoneCall(BuildContext context, String phone) async {
  final cleanedPhone = phone.replaceAll(RegExp(r'\s+'), '');
  final uri = Uri(scheme: 'tel', path: cleanedPhone);

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể mở ứng dụng điện thoại'),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gọi điện thất bại: $e'),
        ),
      );
    }
  }
}