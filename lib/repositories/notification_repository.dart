import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_notification.dart';
import 'package:kid_manager/services/storage_service.dart';

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