import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/widgets/notifications/blocked_app_detail_widget.dart';
import 'package:provider/provider.dart';

class NotificationDetailScreen extends StatefulWidget {
  final String notificationId;

  const NotificationDetailScreen({super.key, required this.notificationId});

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();

    /// Load detail sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationVM>().loadNotificationDetail(
        widget.notificationId,
      );
    });
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return "";

    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} phút trước";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} giờ trước";
    } else {
      return "${diff.inDays} ngày trước";
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationVM>();
    final detail = vm.notificationDetail;
    if (detail == null) return LoadingOverlay();

    final style = detail.notificationType.style;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Chi tiết thông báo",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? const Center(child: Text("Không có dữ liệu"))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ===== HEADER BLOCK =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(color: Colors.white),
                    child: Column(
                      children: [
                        /// ICON
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: style.bgColor,
                            border: Border.all(color: style.borderColor),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            style.icon,
                            size: 36,
                            color: style.iconColor,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// TITLE
                        Text(
                          detail.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// TIME
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              detail.timeDisplay,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ===== DETAIL CARD =====
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF0F0F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x07000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                        BoxShadow(
                          color: Color(0x0C000000),
                          blurRadius: 6,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: const Text(
                            "CHI TIẾT",
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        BlockedAppDetailWidget(detail: detail),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
