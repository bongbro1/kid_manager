import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:flutter/foundation.dart';

class NotificationRepository {
  final FirebaseFirestore _fs;
  NotificationRepository({FirebaseFirestore? fs})
      : _fs = fs ?? FirebaseFirestore.instance;

  Stream<List<AppNotification>> streamUserInbox(String uid) {
    return _fs
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => AppNotification.fromMap(
      d.id,
      d.data(),
      store: NotificationStore.userInbox,
    ))
        .toList());
  }

  Stream<List<AppNotification>> streamUserNotifications(String uid) {
    return _fs
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => AppNotification.fromMap(
      d.id,
      d.data(),
      store: NotificationStore.global,
    ))
        .toList());
  }

  Stream<List<AppNotification>> watchBySource(String uid, NotificationSource source) {
    switch (source) {
      case NotificationSource.global:
        return streamUserNotifications(uid);
      case NotificationSource.userInbox:
        return streamUserInbox(uid);
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


  void debugPrintMap(
      Map<String, dynamic> map, {
        String title = 'DEBUG MAP',
        int indent = 0,
      }) {
    final space = '  ' * indent;

    if (indent == 0) {
      debugPrint('========== $title ==========');
    }

    map.forEach((key, value) {
      if (value is Map) {
        debugPrint('$space$key: {');
        debugPrintMap(
          Map<String, dynamic>.from(value),
          title: title,
          indent: indent + 1,
        );
        debugPrint('$space}');
      } else if (value is List) {
        debugPrint('$space$key: [');
        for (int i = 0; i < value.length; i++) {
          final item = value[i];
          if (item is Map) {
            debugPrint('$space  [$i]: {');
            debugPrintMap(
              Map<String, dynamic>.from(item),
              title: title,
              indent: indent + 2,
            );
            debugPrint('$space  }');
          } else {
            debugPrint('$space  [$i]: $item (${item.runtimeType})');
          }
        }
        debugPrint('$space]');
      } else {
        debugPrint('$space$key: $value (${value.runtimeType})');
      }
    });

    if (indent == 0) {
      debugPrint('================================');
    }
  }

  Future<NotificationDetailModel> getNotificationDetailByItem(String uid, AppNotification n) async {
    final docRef = n.store == NotificationStore.userInbox
        ? _fs.collection('users').doc(uid).collection('notifications').doc(n.id)
        : _fs.collection('notifications').doc(n.id);

    final doc = await docRef.get();
    if (!doc.exists) throw Exception("Notification not found");

    final map = doc.data() as Map<String, dynamic>;
    final type = (map['type'] ?? '').toString();
    final data = Map<String, dynamic>.from(map['data'] ?? {});
    String content = (map['body'] ?? '').toString();
    debugPrint('=========== getNotificationDetailByItem ===========');
    debugPrint('doc.id = ${doc.id}');
    debugPrint('type = $type');
    debugPrint('title = ${map['title']}');
    debugPrint('body = ${map['body']}');
    debugPrintMap(data, title: 'NOTIFICATION DATA');
    debugPrint('===================================================');

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