import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';

class NotificationRepository {
  final FirebaseFirestore _fs;
  NotificationRepository({FirebaseFirestore? fs})
    : _fs = fs ?? FirebaseFirestore.instance;

  final int _maxCountInPage = 20;

  // users/{uid}/notifications
  Stream<List<AppNotification>> streamUserInbox(String uid) {
    return _fs
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => AppNotification.fromMap(
                  d.id,
                  d.data(),
                  store: NotificationStore.userInbox,
                ),
              )
              .toList(),
        );
  }

  // new query
  Future<QuerySnapshot<Map<String, dynamic>>> fetchOlderNotifications({
    required String uid,
    required Timestamp lastCreatedAt,
  }) {
    return _fs
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .startAfter([lastCreatedAt])
        .limit(_maxCountInPage)
        .get();
  }

  // notifications (root)
  Stream<List<AppNotification>> streamUserNotifications(String uid) {
    return _fs
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(_maxCountInPage)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => AppNotification.fromMap(
                  d.id,
                  d.data(),
                  store: NotificationStore.global,
                ),
              )
              .toList(),
        );
  }

  Stream<List<AppNotification>> watchBySource(
    String uid,
    NotificationSource source,
  ) {
    switch (source) {
      case NotificationSource.global:
        return streamUserNotifications(uid);
      case NotificationSource.userInbox:
        return streamUserInbox(uid);
    }
  }

  // ===== giữ để NotificationService không lỗi (global create) =====
  Future<void> create({
    required String senderId,
    required String receiverId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? familyId,
  }) async {
    await _fs.collection('notifications').add({
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

  // ===== mark/delete GLOBAL =====
  Future<void> markAsReadGlobal(String id) async {
    await _fs.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> deleteGlobal(String id) async {
    await _fs.collection('notifications').doc(id).delete();
  }

  // ===== mark/delete INBOX users/{uid}/notifications =====
  Future<void> markAsReadInbox(String uid, String id) async {
    await _fs
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .update({'isRead': true});
  }

  Future<void> deleteInbox(String uid, String id) async {
    await _fs
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(id)
        .delete();
  }

  Future<NotificationDetailModel> getNotificationDetailByItem(
    String uid,
    AppNotification n,
  ) async {
    final docRef = (n.store == NotificationStore.userInbox)
        ? _fs.collection('users').doc(uid).collection('notifications').doc(n.id)
        : _fs.collection('notifications').doc(n.id);

    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Notification not found");

    final map = doc.data() as Map<String, dynamic>;
    final type = (map['type'] ?? '').toString();
    final data = Map<String, dynamic>.from(map['data'] ?? {});
    final content = (map['body'] ?? '').toString();

    return NotificationDetailModel(
      id: doc.id,
      title: (map['title'] ?? '').toString(),
      content: content,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: type,
      data: data,
    );
  }

  Future<NotificationDetailModel> getNotificationDetail(String id) async {
    final doc = await _fs.collection('notifications').doc(id).get();

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