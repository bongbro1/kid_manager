import 'package:flutter/material.dart';

class LocationPermissionScreen extends StatelessWidget {
  final VoidCallback onAllow;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;
  final bool busy;

  const LocationPermissionScreen({
    super.key,
    required this.onAllow,
    required this.onOpenSettings,
    required this.onSkip,
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
            Icons.location_on_rounded,
            size: 96,
            color: Color(0xFF1E88E5),
          ),
          const SizedBox(height: 24),
          const Text(
            'Bật quyền vị trí',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ứng dụng cần quyền vị trí để theo dõi vị trí của trẻ và hỗ trợ các tính năng an toàn.',
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
              'Khuyến nghị: cho phép vị trí khi dùng ứng dụng trước. Nếu app cần chạy nền sau này, bạn có thể xin thêm quyền Always.',
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
                  : const Text('Cho phép vị trí'),
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
          TextButton(
            onPressed: busy ? null : onSkip,
            child: const Text('Để sau'),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}