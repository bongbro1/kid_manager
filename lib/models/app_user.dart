import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/models/user/user_subscription.dart';

class ChildUser {
  final String id;
  final String displayName;

  ChildUser({
    required this.id,
    required this.displayName,
  });
}

class AppUser {
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

  /// child only
  final String? parentUid;

  /// parent only
  final SubscriptionInfo? subscription;

  const AppUser({
    required this.uid,
    required this.role,
    this.familyId, // 👈 thêm dòng này
    this.avatarUrl,
    this.email,
    this.displayName,
    this.coverUrl,
    this.locale,
    this.timezone,
    this.createdAt,
    this.lastActiveAt,
    this.parentUid,
    this.subscription,
    this.isActive = false,
    this.phone,
  });

  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;

  // ================= FIRESTORE =================

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'role': roleToString(role),
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
    'lastActiveAt': lastActiveAt == null
        ? null
        : Timestamp.fromDate(lastActiveAt!),
    'parentUid': parentUid,
    'subscription': subscription?.toMap(),
  }..removeWhere((k, v) => v == null);

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    return AppUser(
      uid: d['uid'] ?? doc.id,
      role: roleFromString(d['role'] ?? 'parent'),
      familyId: d['familyId'],
      email: d['email'],
      displayName: d['displayName'],
      coverUrl: d['coverUrl'],
      avatarUrl: d['avatarUrl'],
      phone: d['phone'],
      locale: d['locale'],
      timezone: d['timezone'],
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (d['lastActiveAt'] as Timestamp?)?.toDate(),
      parentUid: d['parentUid'],
      isActive: d['isActive'] ?? false,
      subscription: d['subscription'] == null
          ? null
          : SubscriptionInfo.fromMap(
              Map<String, dynamic>.from(d['subscription']),
            ),
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
      subscription: subscription ?? this.subscription,
    );
  }
}
