import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> launchPhoneCall(BuildContext context, String phone) async {
  final sanitized = phone.replaceAll(RegExp(r'[^0-9+]'), '');
  final uri = Uri(scheme: 'tel', path: sanitized);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
    return;
  }

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Không thể mở ứng dụng gọi điện'),
    ),
  );
}