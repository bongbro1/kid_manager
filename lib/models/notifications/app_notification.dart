import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/blocked_app_data.dart';

/// Doc đang nằm ở đâu (runtime only)
enum NotificationStore { global, userInbox ,chatInbox}

enum NotificationType {
  appRemoved,
  blockedApp,
  sos,
  heartbeatLost,
  usageLimitExceeded,
  schedule,
  memoryDay,
  importExcel, 
  battery,
  birthday,
  zone, // ✅ thêm
  subscription,
  system,
}

enum NotificationFilter {
  all,
  activity, // hoạt động học tập
  alert, // cảnh báo khẩn
  reminder, // nhắc nhở
  system,
}

extension NotificationTypeX on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.appRemoved:
        return "app_removed";
      case NotificationType.blockedApp:
        return "blocked_app";
      case NotificationType.sos:
        return "sos";
      case NotificationType.heartbeatLost:
        return "heartbeat_lost";
      case NotificationType.usageLimitExceeded:
        return "usage_limit_exceeded";
      case NotificationType.schedule:
        return "schedule";
      case NotificationType.memoryDay:
        return "memory_day";
      case NotificationType.importExcel:
        return "import_excel";
      case NotificationType.battery:
        return "battery";
      case NotificationType.birthday:
        return "birthday";
      case NotificationType.zone:
        return "zone"; // ✅ chuẩn hoá cho app
      case NotificationType.system:
      case NotificationType.subscription:
        return "system";
    }
  }

  NotificationFilter get filter {
    switch (this) {
      case NotificationType.appRemoved:
      case NotificationType.blockedApp:
      case NotificationType.usageLimitExceeded:
        return NotificationFilter.activity;

      case NotificationType.sos:
      case NotificationType.heartbeatLost:
      case NotificationType.battery:
      case NotificationType.zone:
        return NotificationFilter.alert;

      case NotificationType.schedule:
      case NotificationType.memoryDay:
      case NotificationType.importExcel:
      case NotificationType.birthday:
        return NotificationFilter.reminder;

      case NotificationType.system:
      case NotificationType.subscription:
        return NotificationFilter.system;
    }
  }

  /// Convert từ Firestore string → enum
  static NotificationType fromString(String value) {
    final v = value.toString().trim().toLowerCase();

    // ✅ Map tương thích ngược (CF của bạn đang dùng "ZONE")
    if (v == "zone") return NotificationType.zone;
    if (v == "zone_event") return NotificationType.zone;
    if (v == "zoneevent") return NotificationType.zone;
    if (v == "zone-alert") return NotificationType.zone;
    if (v == "zonealert") return NotificationType.zone;
    if (v == "zone_notification") return NotificationType.zone;
    if (v == "zone-notification") return NotificationType.zone;
    if (v == "zone_notif") return NotificationType.zone;
    if (v == "zone-notif") return NotificationType.zone;
    if (v == "zoneevents") return NotificationType.zone;
    if (v == "zoneeventbychild") return NotificationType.zone;
    if (v == "zonebychild") return NotificationType.zone;
    if (v == "zone") return NotificationType.zone;

    // CF bạn đang set "ZONE" (uppercase) => cũng map về zone
    if (v == "zone".toLowerCase() || v == "zone".toUpperCase().toLowerCase()) {
      return NotificationType.zone;
    }
    if (v == "zone".toUpperCase().toLowerCase()) return NotificationType.zone;

    // map uppercase "ZONE"
    if (value.toString().trim() == "ZONE") return NotificationType.zone;

    return NotificationType.values.firstWhere(
      (e) => e.name.toLowerCase() == v,
      orElse: () => NotificationType.system,
    );
  }

  NotificationStyle get style {
    switch (this) {
      case NotificationType.appRemoved:
      case NotificationType.blockedApp:
        return const NotificationStyle(
          icon: Icons.block_rounded,
          bgColor: Color(0xFFFEE2E2),
          borderColor: Color(0xFFFCA5A5),
          iconColor: Color(0xFFDC2626),
        );

      case NotificationType.sos:
        return const NotificationStyle(
          icon: Icons.warning_amber_rounded,
          bgColor: Color(0xFFFECACA),
          borderColor: Color(0xFFF87171),
          iconColor: Color(0xFFB91C1C),
        );

      case NotificationType.heartbeatLost:
        return const NotificationStyle(
          icon: Icons.favorite_rounded,
          bgColor: Color(0xFFFCE7F3),
          borderColor: Color(0xFFF9A8D4),
          iconColor: Color(0xFFDB2777),
        );

      case NotificationType.usageLimitExceeded:
        return const NotificationStyle(
          icon: Icons.timer_off_rounded,
          bgColor: Color(0xFFFEF3C7),
          borderColor: Color(0xFFFCD34D),
          iconColor: Color(0xFFD97706),
        );

      case NotificationType.schedule:
        return const NotificationStyle(
          icon: Icons.calendar_month_rounded,
          bgColor: Color(0xFFEEF2FF),
          borderColor: Color(0xFFC7D2FE),
          iconColor: Color(0xFF4F46E5),
        );

      case NotificationType.memoryDay:
        return const NotificationStyle(
          icon: Icons.star_border_rounded,
          bgColor: Color.fromARGB(255, 250, 255, 176),
          borderColor: Color.fromARGB(255, 192, 189, 0),
          iconColor: Color.fromARGB(255, 192, 189, 0), //Color.fromARGB(255, 252, 143, 0),
        );

      case NotificationType.importExcel:
        return const NotificationStyle(
          icon: Icons.upload_file_rounded,
          bgColor: Color.fromARGB(255, 162, 255, 182),
          borderColor: Color.fromARGB(255, 0, 224, 49),
          iconColor: Color.fromARGB(255, 0, 224, 49),
        );

      case NotificationType.battery:
        return const NotificationStyle(
          icon: Icons.battery_alert_rounded,
          bgColor: Color(0xFFFEF3C7),
          borderColor: Color(0xFFFDE68A),
          iconColor: Color(0xFFD97706),
        );

      case NotificationType.birthday:
        return const NotificationStyle(
          icon: Icons.cake_rounded,
          bgColor: Color(0xFFFDF2F8),
          borderColor: Color(0xFFFBCFE8),
          iconColor: Color(0xFFDB2777),
        );

      case NotificationType.zone:
        return const NotificationStyle(
          icon: Icons.my_location_rounded,
          bgColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFBFDBFE),
          iconColor: Color(0xFF2563EB),
        );

      case NotificationType.subscription:
        return const NotificationStyle(
          icon: Icons.settings_rounded,
          bgColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
        );
      case NotificationType.system:
        return const NotificationStyle(
          icon: Icons.settings_rounded,
          bgColor: Color(0xFFEFF6FF),
          borderColor: Color(0xFFDBEAFE),
          iconColor: Color(0xFF2563EB),
        );
    }
  }
}

class NotificationStyle {
  final IconData icon;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;

  const NotificationStyle({
    required this.icon,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
  });
}

class AppNotification {
  final String id;
  final String senderId;
  final String receiverId;
  final String? familyId;

  final String type;
  final String title;
  final String body;

  final bool isRead;
  final String status;

  final DateTime? createdAt;
  final Map<String, dynamic> data;

  /// runtime: doc ở global hay userInbox
  final NotificationStore store;

  const AppNotification({
    required this.id,
    required this.senderId,
    required this.receiverId,
    this.familyId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.status,
    required this.data,
    required this.createdAt,
    required this.store,
  });

  factory AppNotification.fromMap(
    String id,
    Map<String, dynamic> map, {
    required NotificationStore store,
  }) {
    final rawTitle = (map['title'] ?? '').toString();
    final rawEventKey = (map['eventKey'] ?? map['data']?['eventKey'] ?? '')
        .toString();

    return AppNotification(
      id: id,
      senderId: (map['senderId'] ?? '').toString(),
      receiverId: (map['receiverId'] ?? '').toString(),
      familyId: map['familyId']?.toString(),
      type: (map['type'] ?? '').toString(),
      title: rawTitle.trim().isNotEmpty ? rawTitle : rawEventKey,
      body: (map['body'] ?? '').toString(),
      isRead: (map['isRead'] ?? false) == true,
      status: (map['status'] ?? 'pending').toString(),
      createdAt: _readDate(map['createdAt']),
      data: Map<String, dynamic>.from(map['data'] ?? {}),
      store: store,
    );
  }

  factory AppNotification.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required NotificationStore store,
  }) {
    return AppNotification.fromMap(
      doc.id,
      doc.data() ?? <String, dynamic>{},
      store: store,
    );
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  String? get childId => data['childId']?.toString();

  String? get packageName => data['packageName']?.toString();

  NotificationType get notificationType => NotificationTypeX.fromString(type);

  BlockedAppData? get blockedAppData {
    if (notificationType != NotificationType.blockedApp) return null;
    return BlockedAppData.fromMap(data);
  }
}
