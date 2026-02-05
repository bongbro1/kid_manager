import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/app_user.dart';

UserRole roleFromString(String v) =>
    v == 'child' ? UserRole.child : UserRole.parent;

String roleToString(UserRole r) =>
    r == UserRole.child ? 'child' : 'parent';

class SubscriptionInfoModel extends SubscriptionInfo {
  const SubscriptionInfoModel({
    required super.plan,
    required super.status,
    super.startAt,
    super.endAt,
  });

  factory SubscriptionInfoModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfoModel(
      plan: (map['plan'] ?? 'free') as String,
      status: (map['status'] ?? 'active') as String,
      startAt: (map['startAt'] as Timestamp?)?.toDate(),
      endAt: (map['endAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'plan': plan,
    'status': status,
    'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
    'endAt': endAt == null ? null : Timestamp.fromDate(endAt!),
  };
}

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.role,
    super.email,
    super.displayName,
    super.phone,
    super.photoUrl,
    super.locale,
    super.timezone,
    super.createdAt,
    super.lastActiveAt,
    super.parentUid,
    super.subscription,
  });

  /// 🔹 Firestore → Model
  factory AppUserModel.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final d = doc.data() ?? {};

    return AppUserModel(
      uid: (d['uid'] ?? doc.id) as String,
      role: roleFromString((d['role'] ?? 'parent') as String),
      email: d['email'] as String?,
      displayName: d['displayName'] as String?,
      phone: d['phone'] as String?,
      photoUrl: d['photoUrl'] as String?,
      locale: d['locale'] as String?,
      timezone: d['timezone'] as String?,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (d['lastActiveAt'] as Timestamp?)?.toDate(),
      parentUid: d['parentUid'] as String?,
      subscription: d['subscription'] == null
          ? null
          : SubscriptionInfoModel.fromMap(
        Map<String, dynamic>.from(d['subscription'] as Map),
      ),
    );
  }

  /// 🔹 Model → Firestore
  Map<String, dynamic> toMap() => {
    'uid': uid,
    'role': roleToString(role),
    'email': email,
    'displayName': displayName,
    'phone': phone,
    'photoUrl': photoUrl,
    'locale': locale,
    'timezone': timezone,
    'createdAt':
    createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'lastActiveAt':
    lastActiveAt == null ? null : Timestamp.fromDate(lastActiveAt!),
    'parentUid': parentUid,
    'subscription': subscription is SubscriptionInfoModel
        ? (subscription as SubscriptionInfoModel).toMap()
        : null,
  }..removeWhere((k, v) => v == null);

  /// 🔹 Entity → Model (để write)
  factory AppUserModel.fromEntity(AppUser u) {
    return AppUserModel(
      uid: u.uid,
      role: u.role,
      email: u.email,
      displayName: u.displayName,
      phone: u.phone,
      photoUrl: u.photoUrl,
      locale: u.locale,
      timezone: u.timezone,
      createdAt: u.createdAt,
      lastActiveAt: u.lastActiveAt,
      parentUid: u.parentUid,
      subscription: u.subscription,
    );
  }
}
