import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/models/user/user_types.dart';

class ChildUser {
  const ChildUser({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    this.phone,
    this.email,
    this.displayName,
    this.coverUrl,
    this.avatarUrl,
    this.locale,
    this.timezone,
    this.createdAt,
    this.lastActiveAt,
    this.familyId,
    this.isActive = false,
    this.allowTracking = false,
    this.parentUid,
    this.subscription,
    this.managedChildIds = const <String>[],
  });

  final String uid;
  final UserRole role;
  final String? phone;
  final String? email;
  final String? displayName;
  final String? coverUrl;
  final String? avatarUrl;
  final String? locale;
  final String? timezone;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final String? familyId;
  final bool isActive;
  final bool allowTracking;
  final String? parentUid;
  final SubscriptionInfo? subscription;
  final List<String> managedChildIds;

  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;
  bool get isGuardian => role == UserRole.guardian;
  bool get isAdultManager => role.isAdultManager;
  String get roleKey => roleToString(role);

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'role': roleKey,
      'familyId': familyId,
      'email': email,
      'displayName': displayName,
      'coverUrl': coverUrl,
      'avatarUrl': avatarUrl,
      'phone': phone,
      'locale': locale,
      'timezone': timezone,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'isActive': isActive,
      'allowTracking': allowTracking,
      'lastActiveAt': lastActiveAt == null
          ? null
          : Timestamp.fromDate(lastActiveAt!),
      'parentUid': parentUid,
      'subscription': subscription?.toMap(),
      if (managedChildIds.isNotEmpty) 'managedChildIds': managedChildIds,
    }..removeWhere((key, value) => value == null);
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final role = UserRole.fromValue(data['role']);

    return AppUser(
      uid: (data['uid'] ?? doc.id).toString(),
      role: role,
      familyId: data['familyId']?.toString(),
      email: data['email']?.toString(),
      displayName: data['displayName']?.toString(),
      coverUrl: data['coverUrl']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      phone: data['phone']?.toString(),
      locale: data['locale']?.toString(),
      timezone: data['timezone']?.toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      parentUid: data['parentUid']?.toString(),
      isActive: (data['isActive'] as bool?) ?? false,
      allowTracking: _readAllowTracking(data, role: role),
      subscription: data['subscription'] == null
          ? null
          : SubscriptionInfo.fromMap(
              Map<String, dynamic>.from(data['subscription'] as Map),
            ),
      managedChildIds: _readManagedChildIds(data),
    );
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? coverUrl,
    String? avatarUrl,
    String? locale,
    String? phone,
    String? timezone,
    DateTime? lastActiveAt,
    SubscriptionInfo? subscription,
    String? familyId,
    bool? isActive,
    bool? allowTracking,
    List<String>? managedChildIds,
  }) {
    return AppUser(
      uid: uid,
      role: role,
      email: email ?? this.email,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      coverUrl: coverUrl ?? this.coverUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      parentUid: parentUid,
      isActive: isActive ?? this.isActive,
      allowTracking: allowTracking ?? this.allowTracking,
      subscription: subscription ?? this.subscription,
      managedChildIds: managedChildIds ?? this.managedChildIds,
    );
  }

  factory AppUser.fromFirebase(User user) {
    return AppUser(
      uid: user.uid,
      role: UserRole.child,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.photoURL,
      phone: user.phoneNumber,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      isActive: true,
    );
  }

  static List<String> _readManagedChildIds(Map<String, dynamic> data) {
    final raw =
        data['managedChildIds'] ?? data['assignedChildIds'] ?? data['childIds'];
    if (raw is! Iterable) {
      return const <String>[];
    }

    final values = raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return values;
  }

  static bool _readAllowTracking(
    Map<String, dynamic> data, {
    required UserRole role,
  }) {
    final raw = data['allowTracking'];
    if (raw is bool) {
      return raw;
    }
    // Legacy child docs can miss allowTracking entirely.
    // Default them to enabled so parent/guardian do not lose all children on map.
    if (role == UserRole.child) {
      return true;
    }
    return false;
  }
}
