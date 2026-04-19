import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/core/network/app_network_error_mapper.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_detail_model.dart';
import 'package:kid_manager/models/notifications/notification_source.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class NotificationRepository {
  final FirebaseFirestore _fs;
  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;
  NotificationRepository({
    FirebaseFirestore? fs,
    FirebaseFunctions? functions,
    FirebaseAuth? auth,
  })
    : _fs = fs ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final int _maxCountInPage = 20;
  static const int _maxBatchDeleteSize = 450;

  Future<User?> _waitForAuthenticatedUser({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser;
    }

    try {
      return await _auth
          .authStateChanges()
          .firstWhere((user) => user != null)
          .timeout(timeout);
    } catch (_) {
      return _auth.currentUser;
    }
  }

  Future<void> _ensureCallableAuthReady() async {
    final user = await _waitForAuthenticatedUser();
    final currentUid = user?.uid;
    debugPrint(
      '[NotificationRepository] auth preflight currentUid=$currentUid',
    );
    if (user == null) {
      return;
    }

    try {
      await user.getIdToken(true);
    } catch (e, st) {
      debugPrint('[NotificationRepository] token refresh error: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Stream<int> watchUnreadCount(
    String uid, {
    List<NotificationSource> sources = const [NotificationSource.global],
  }) {
    return Stream<int>.multi((controller) {
      final subs = <StreamSubscription<Set<String>>>[];
      var globalUnread = <String>{};
      var inboxUnread = <String>{};
      var chatUnread = <String>{};

      void emit() {
        controller.add({...globalUnread, ...inboxUnread, ...chatUnread}.length);
      }

      if (sources.contains(NotificationSource.global)) {
        final globalStream = _fs
            .collection('notifications')
            .where('receiverId', isEqualTo: uid)
            .where('isRead', isEqualTo: false)
            .snapshots()
            .map((snap) => snap.docs.map((doc) => doc.id).toSet());
        subs.add(globalStream.listen(
          (value) {
            globalUnread = value;
            emit();
          },
          onError: controller.addError,
        ));
      }

      if (sources.contains(NotificationSource.userInbox)) {
        final inboxStream = _fs
            .collection('users')
            .doc(uid)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .snapshots()
            .map((snap) => snap.docs.map((doc) => doc.id).toSet());
        subs.add(inboxStream.listen(
          (value) {
            inboxUnread = value;
            emit();
          },
          onError: controller.addError,
        ));
      }

      if (sources.contains(NotificationSource.chatInbox)) {
        final chatStream = _fs
            .collection('users')
            .doc(uid)
            .collection('chatNotifications')
            .where('isRead', isEqualTo: false)
            .snapshots()
            .map((snap) => snap.docs.map((doc) => doc.id).toSet());
        subs.add(chatStream.listen(
          (value) {
            chatUnread = value;
            emit();
          },
          onError: controller.addError,
        ));
      }

      controller.onCancel = () async {
        await Future.wait(subs.map((sub) => sub.cancel()));
      };
    });
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
    final snap = await _fs
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('type', isEqualTo: 'family_chat')
        .where('familyId', isEqualTo: familyId)
        .get();

    if (snap.docs.isEmpty) return;

    for (var i = 0; i < snap.docs.length; i += _maxBatchDeleteSize) {
      final batch = _fs.batch();
      final end = (i + _maxBatchDeleteSize < snap.docs.length)
          ? i + _maxBatchDeleteSize
          : snap.docs.length;

      for (final doc in snap.docs.sublist(i, end)) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    }
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
    };

    debugPrint(
      '[NotificationRepository] create called '
          'senderId=$senderId receiverId=$receiverId '
          'type=$type title="$title" body="$body" familyId=$familyId data=$data',
    );

    try {
      await _ensureCallableAuthReady();

      final callable = _functions.httpsCallable('enqueueAuthorizedNotification');
      final response = await callable.call(payload);

      debugPrint(
        '[NotificationRepository] create success '
        'notificationId=${response.data is Map ? response.data['notificationId'] : null}',
      );
    } on FirebaseFunctionsException catch (e, st) {
      if (e.code == 'unauthenticated') {
        debugPrint(
          '[NotificationRepository] create unauthenticated -> retry after token refresh',
        );
        debugPrintStack(stackTrace: st);

        await _ensureCallableAuthReady();
        final response = await _functions
            .httpsCallable('enqueueAuthorizedNotification')
            .call(payload);

        debugPrint(
          '[NotificationRepository] create success after retry '
          'notificationId=${response.data is Map ? response.data['notificationId'] : null}',
        );
        return;
      }

      debugPrint('[NotificationRepository] create error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    } catch (e, st) {
      debugPrint('[NotificationRepository] create error: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> markAsReadGlobal(String id) async {
    try {
      await _fs.collection('notifications').doc(id).update({'isRead': true});
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> deleteGlobal(String id) async {
    try {
      await _fs.collection('notifications').doc(id).delete();
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> markAsReadInbox(String uid, String id) async {
    try {
      await _fs
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(id)
          .update({'isRead': true});
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> deleteInbox(String uid, String id) async {
    try {
      await _fs
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(id)
          .delete();
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
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
    try {
      late final DocumentReference<Map<String, dynamic>> docRef;

      switch (n.store) {
        case NotificationStore.userInbox:
          docRef = _fs
              .collection('users')
              .doc(uid)
              .collection('notifications')
              .doc(n.id);
          break;
        case NotificationStore.chatInbox:
          docRef = _fs
              .collection('users')
              .doc(uid)
              .collection('chatNotifications')
              .doc(n.id);
          break;
        case NotificationStore.global:
          docRef = _fs.collection('notifications').doc(n.id);
          break;
      }

      final doc = await docRef.get();
      if (!doc.exists) throw Exception('Notification not found');

      final map = doc.data()!;
      final type = (map['type'] ?? '').toString();
      final data = Map<String, dynamic>.from(map['data'] ?? {});
      if (!data.containsKey('eventCategory') && map['eventCategory'] != null) {
        data['eventCategory'] = map['eventCategory'];
      }
      if (!data.containsKey('expiresAt') && map['expiresAt'] != null) {
        data['expiresAt'] = map['expiresAt'];
      }
      final rawContent = (map['body'] ?? '').toString();
      final content = rawContent.startsWith('tracking.')
          ? (data['message']?.toString() ?? rawContent)
          : rawContent;

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
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<AppNotification?> getItemById(String id) async {
    try {
      final doc = await _fs.collection('notifications').doc(id).get();

      if (!doc.exists || doc.data() == null) return null;

      return AppNotification.fromDoc(doc, store: NotificationStore.global);
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> deleteChatNotificationsForFamily({
    required String uid,
    required String familyId,
  }) async {
    try {
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
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<void> markFamilyChatRead({
    required String familyId,
    required String uid,
  }) async {
    try {
      await _functions.httpsCallable('markFamilyChatRead').call();
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }

  Future<NotificationDetailModel?> getNotificationDetail(String id) async {
    try {
      final doc = await _fs.collection('notifications').doc(id).get();

      if (!doc.exists) {
        throw Exception('Notification not found');
      }

      final map = doc.data()!;
      final type = map['type'] ?? '';
      final data = Map<String, dynamic>.from(map['data'] ?? {});
      if (!data.containsKey('eventCategory') && map['eventCategory'] != null) {
        data['eventCategory'] = map['eventCategory'];
      }
      if (!data.containsKey('expiresAt') && map['expiresAt'] != null) {
        data['expiresAt'] = map['expiresAt'];
      }

      final rawContent = (map['body'] ?? '').toString();
      String content = rawContent.startsWith('tracking.')
          ? (data['message']?.toString() ?? rawContent)
          : rawContent;

      if (type == NotificationType.blockedApp.value) {
        final appName = data['appName'] ?? '';
        final blockedAt = data['blockedAt'] ?? '';
        final allowedFrom = data['allowedFrom'] ?? '';
        final allowedTo = data['allowedTo'] ?? '';

        content =
            '\u0110\u00e3 m\u1edf \u1ee9ng d\u1ee5ng $appName l\u00fac $blockedAt '
            'ngo\u00e0i khung gi\u1edd cho ph\u00e9p ($allowedFrom - $allowedTo). H\u1ec7 th\u1ed1ng \u0111\u00e3 t\u1ef1 \u0111\u1ed9ng ch\u1eb7n \u1ee9ng d\u1ee5ng.';
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
    } catch (error) {
      final networkError = AppNetworkErrorMapper.normalize(
        error,
        fallbackMessage: runtimeL10n().appNetworkActionFailed,
      );
      if (networkError != null) {
        throw networkError;
      }
      rethrow;
    }
  }
}
