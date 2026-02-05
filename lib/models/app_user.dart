import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { parent, child }

UserRole roleFromString(String v) => v == 'child' ? UserRole.child : UserRole.parent;
String roleToString(UserRole r) => r == UserRole.child ? 'child' : 'parent';

class SubscriptionInfo {
  final String plan; // free|pro
  final String status; // active|trial|expired
  final DateTime? startAt;
  final DateTime? endAt;

  const SubscriptionInfo({
    required this.plan,
    required this.status,
    this.startAt,
    this.endAt,
  });

  Map<String, dynamic> toMap() => {
        'plan': plan,
        'status': status,
        'startAt': startAt == null ? null : Timestamp.fromDate(startAt!),
        'endAt': endAt == null ? null : Timestamp.fromDate(endAt!),
      };

  static SubscriptionInfo fromMap(Map<String, dynamic> map) => SubscriptionInfo(
        plan: (map['plan'] ?? 'free') as String,
        status: (map['status'] ?? 'active') as String,
        startAt: (map['startAt'] as Timestamp?)?.toDate(),
        endAt: (map['endAt'] as Timestamp?)?.toDate(),
      );
}

class AppUser {
  final String uid;
  final UserRole role;

  final String? email;
  final String? displayName;
  final String? phone;
  final String? photoUrl;

  final String? locale;
  final String? timezone;

  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  // child only
  final String? parentUid;

  // parent only
  final SubscriptionInfo? subscription;

  const AppUser({
    required this.uid,
    required this.role,
    this.email,
    this.displayName,
    this.phone,
    this.photoUrl,
    this.locale,
    this.timezone,
    this.createdAt,
    this.lastActiveAt,
    this.parentUid,
    this.subscription,
  });

  bool get isParent => role == UserRole.parent;
  bool get isChild => role == UserRole.child;

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'role': roleToString(role),
        'email': email,
        'displayName': displayName,
        'phone': phone,
        'photoUrl': photoUrl,
        'locale': locale,
        'timezone': timezone,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'lastActiveAt': lastActiveAt == null ? null : Timestamp.fromDate(lastActiveAt!),
        'parentUid': parentUid,
        'subscription': subscription?.toMap(),
      }..removeWhere((k, v) => v == null);

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
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
          : SubscriptionInfo.fromMap(Map<String, dynamic>.from(d['subscription'] as Map)),
    );
  }

  AppUser copyWith({
    String? email,
    String? displayName,
    String? phone,
    String? photoUrl,
    String? locale,
    String? timezone,
    DateTime? lastActiveAt,
    SubscriptionInfo? subscription,
  }) {
    return AppUser(
      uid: uid,
      role: role,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      createdAt: createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      parentUid: parentUid,
      subscription: subscription ?? this.subscription,
    );
  }
}

extension AppUserDisplay on AppUser {
  String get displayLabel {
    if (displayName?.isNotEmpty == true) return displayName!;
    if (email?.isNotEmpty == true) return email!;
    return 'Unknown';
  }
  String get displayEmail {
    if (email?.isNotEmpty == true) return email!;
    return 'Unknown';
  }
}

