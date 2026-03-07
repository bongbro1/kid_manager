import 'package:flutter/material.dart';

class NotificationPermissionScreen extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final bool busy;

  const NotificationPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onOpenSettings,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        children: [
          const Spacer(),
          const Icon(
            Icons.notifications_active_rounded,
            size: 96,
            color: Color(0xFFE53935),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bật SOS Alerts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ứng dụng cần quyền thông báo để gửi cảnh báo SOS khẩn cấp ngay cả khi bạn không mở app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Lưu ý: Sau khi cấp quyền, hãy đảm bảo kênh "SOS Alerts" được bật âm thanh trong cài đặt thông báo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onAllow,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: busy
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Cho phép thông báo'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onOpenSettings,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Mở cài đặt'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}