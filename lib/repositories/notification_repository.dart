import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ==============================
  /// 📡 STREAM INBOX REALTIME
  /// ==============================
  Stream<List<AppNotification>> streamUserNotifications(String uid) {
    return _db
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => AppNotification.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  // Stream<int> listenUnreadCount(String userId) {
  //   return FirebaseFirestore.instance
  //       .collection("notifications")
  //       .where("receiverId", isEqualTo: userId)
  //       .where("isRead", isEqualTo: false)
  //       .snapshots()
  //       .map((snap) => snap.docs.length);
  // }

  /// ==============================
  /// ✉️ CREATE → TRIGGER PUSH
  /// Flutter chỉ tạo doc
  /// Cloud Function sẽ gửi FCM
  /// ==============================
  Future<void> create({
    required String senderId,
    required String receiverId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? familyId,
  }) async {
    await _db.collection('notifications').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'familyId': familyId,

      'type': type,
      'title': title,
      'body': body,
      'data': data ?? {},

      'isRead': false,
      'status': 'pending',

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// ==============================
  /// ✅ MARK AS READ
  /// ==============================
  Future<void> markAsRead(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// ==============================
  /// 🗑 DELETE
  /// ==============================
  Future<void> delete(String notificationId) async {
    await _db.collection('notifications').doc(notificationId).delete();
  }

  Future<NotificationDetailModel> getNotificationDetail(String id) async {
    final doc = await _db.collection('notifications').doc(id).get();

    if (!doc.exists) {
      throw Exception("Notification not found");
    }

    final map = doc.data()!;
    final type = map['type'] ?? '';
    final data = Map<String, dynamic>.from(map['data'] ?? {});

    String content = map['body'] ?? '';

    if (type == NotificationType.blockedApp.value) {
      final appName = data["appName"] ?? "";
      final blockedAt = data["blockedAt"] ?? "";
      final allowedFrom = data["allowedFrom"] ?? "";
      final allowedTo = data["allowedTo"] ?? "";

      content =
          "đã mở ứng dụng $appName lúc $blockedAt "
          "ngoài khung giờ cho phép ($allowedFrom - $allowedTo). "
          "Hệ thống đã tự động chặn ứng dụng.";
    }

    return NotificationDetailModel(
      id: doc.id,
      title: map['title'] ?? '',
      content: content,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: type,
      data: data,
    );
  }
}


// notifications/{notificationId}
// {
//   senderId: "uid" | null,
//   receiverId: "uid",
//   familyId: "...",

//   type: "SOS",

//   title: "...",
//   body: "...",
//   data: {...},

//   isRead: false,
//   status: "pending",   // CF sẽ đổi → sent / failed

//   createdAt: serverTimestamp()
// }