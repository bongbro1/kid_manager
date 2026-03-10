import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';

class NotificationRepository {
  final FirebaseFirestore _fs;
  NotificationRepository({FirebaseFirestore? fs})
    : _fs = fs ?? FirebaseFirestore.instance;

  final Map<String, String> _childNameCache = {};
  final Map<String, String> _appNameCache = {};

  final int _maxCountInPage = 20;
  Future<String?> getChildDisplayName(String childId) async {
    if (_childNameCache.containsKey(childId)) {
      return _childNameCache[childId];
    }

    try {
      final doc = await _fs.collection('users').doc(childId).get();

      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // optional: đảm bảo đúng role child
      if (data['role'] != 'child') return null;

      final name = data['displayName'] as String?;

      if (name != null && name.isNotEmpty) {
        _childNameCache[childId] = name;
      }

      return name;
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAppName({
    required String userId,
    required String packageName,
  }) async {
    final key = "$userId|$packageName";

    final cached = _appNameCache[key];
    if (cached != null) return cached;

    try {
      final doc = await _fs
          .doc("blocked_items/$userId/apps/$packageName")
          .get();

      final name = doc.data()?['name'] as String?;

      if (name != null) {
        _appNameCache[key] = name;
      }

      return name;
    } catch (_) {
      return null;
    }
  }

  Future<void> resolveNotificationMetadata(List<AppNotification> list) async {
    final childIds = <String>{};
    final appPairs = <MapEntry<String, String>>[];

    for (final n in list) {
      if (n.childId != null) {
        childIds.add(n.childId!);
        if (n.packageName != null) {
          appPairs.add(MapEntry(n.childId!, n.packageName!));
        }
      }
    }
    await Future.wait([
      ...childIds.map(getChildDisplayName),
      ...appPairs.map((e) => getAppName(userId: e.key, packageName: e.value)),
    ]);
  }

  String? getCachedChildName(String? childId) {
    if (childId == null) return null;
    return _childNameCache[childId];
  }

  String? getCachedAppName({
    required String userId,
    required String packageName,
  }) {
    final key = "$userId|$packageName";
    return _appNameCache[key];
  }

  Stream<int> watchUnreadCount(String uid) {
    return _fs
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

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

  Future<void> deleteFamilyChatNotificationsForFamily({
    required String uid,
    required String familyId,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('type', isEqualTo: 'family_chat')
        .where('familyId', isEqualTo: familyId)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
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
      case NotificationSource.chatInbox:
        return streamUserChatNotifications(uid);
    }
  }

  Future<void> create({
    required String senderId,
    required String receiverId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? familyId,
  }) async {

    if (type == 'family_chat') {
      debugPrint(
        '[NotificationRepository] skip root notification for family_chat',
      );
      return;
    }
    final payload = <String, dynamic>{
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
    };

    debugPrint(
      '[NotificationRepository] create called '
          'senderId=$senderId receiverId=$receiverId '
          'type=$type title="$title" body="$body" familyId=$familyId data=$data',
    );

    try {
      final docRef = await _fs.collection('notifications').add(payload);

      debugPrint(
        '[NotificationRepository] create success docId=${docRef.id}',
      );
    } catch (e, st) {
      debugPrint('[NotificationRepository] create error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> markAsReadGlobal(String id) async {
    await _fs.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> deleteGlobal(String id) async {
    await _fs.collection('notifications').doc(id).delete();
  }

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


  Stream<int> watchChatUnreadCount(String uid) {
    return _fs
        .collection('users')
        .doc(uid)
        .collection('chatNotifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.size);
  }

  Stream<List<AppNotification>> streamUserChatNotifications(String uid) {
    return _fs
        .collection('users')
        .doc(uid)
        .collection('chatNotifications')
        .orderBy('createdAt', descending: true)
        .limit(_maxCountInPage)
        .snapshots()
        .map(
          (snap) => snap.docs
          .map(
            (d) => AppNotification.fromMap(
          d.id,
          d.data(),
          store: NotificationStore.chatInbox,
        ),
      )
          .toList(),
    );
  }
  Future<NotificationDetailModel> getNotificationDetailByItem(
      String? uid,
      AppNotification n,
      ) async {
    late final DocumentReference<Map<String, dynamic>> docRef;

    switch (n.store) {
      case NotificationStore.userInbox:
        docRef = _fs.collection('users').doc(uid).collection('notifications').doc(n.id);
        break;
      case NotificationStore.chatInbox:
        docRef = _fs.collection('users').doc(uid).collection('chatNotifications').doc(n.id);
        break;
      case NotificationStore.global:
        docRef = _fs.collection('notifications').doc(n.id);
        break;
    }

    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Notification not found");

    final map = doc.data()!;
    final type = (map['type'] ?? '').toString();
    final data = Map<String, dynamic>.from(map['data'] ?? {});
    final content = (map['body'] ?? '').toString();

    return NotificationDetailModel(
      id: doc.id,
      title: (map['title'] ?? map['senderName'] ?? '').toString(),
      content: content,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      type: type,
      data: data,
    );
  }

  Future<AppNotification?> getItemById(String id) async {
    final doc = await _fs.collection('notifications').doc(id).get();

    if (!doc.exists || doc.data() == null) return null;

    return AppNotification.fromDoc(doc, store: NotificationStore.global);
  }

  Future<void> deleteChatNotificationsForFamily({
    required String uid,
    required String familyId,
  }) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatNotifications')
        .where('type', isEqualTo: 'family_chat')
        .where('familyId', isEqualTo: familyId)
        .get();

    if (snap.docs.isEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> markFamilyChatRead({
    required String familyId,
    required String uid,
  }) async {
    await FirebaseFirestore.instance
        .doc('families/$familyId/chatStates/$uid')
        .set({
      'uid': uid,
      'unreadCount': 0,
      'lastReadAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<NotificationDetailModel?> getNotificationDetail(String id) async {
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
          "đã mở ứng dụng $appName lúc $blockedAt ngoài khung giờ cho phép "
          "($allowedFrom - $allowedTo). Hệ thống đã tự động chặn ứng dụng.";
    }

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