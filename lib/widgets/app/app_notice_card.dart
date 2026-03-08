import 'package:flutter/material.dart';
import 'package:kid_manager/widgets/common/notification_modal.dart';

class AppNoticeCard extends StatelessWidget {
  final AppNoticeType type;
  final String? title;
  final String? message;

  const AppNoticeCard({
    super.key,
    required this.type,
    this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _mapNotice(type);

    return NotificationModal(
      maxHeight: 320,
      onBackgroundTap: () {
        Navigator.of(context).pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cfg.icon,
              size: 72,
              color: cfg.color,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? cfg.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message ?? cfg.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AppNoticeType { success, error, warning, info }

class _NoticeConfig {
  final IconData icon;
  final Color color;
  final String title;
  final String message;

  _NoticeConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });
}

_NoticeConfig _mapNotice(AppNoticeType type) {
  switch (type) {
    case AppNoticeType.success:
      return _NoticeConfig(
        icon: Icons.check_circle,
        color: const Color(0xFF22C55E),
        title: 'Hoàn thành',
        message: 'Thao tác đã được thực hiện thành công',
      );

    case AppNoticeType.error:
      return _NoticeConfig(
        icon: Icons.cancel,
        color: const Color(0xFFEF4444),
        title: 'Thất bại',
        message: 'Có lỗi xảy ra, vui lòng thử lại',
      );

    case AppNoticeType.warning:
      return _NoticeConfig(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFF59E0B),
        title: 'Cảnh báo',
        message: 'Hành động này có thể ảnh hưởng dữ liệu',
      );

    case AppNoticeType.info:
      return _NoticeConfig(
        icon: Icons.info,
        color: const Color(0xFF3B82F6),
        title: 'Thông tin',
        message: 'Cập nhật đã được ghi nhận',
      );
  }
}