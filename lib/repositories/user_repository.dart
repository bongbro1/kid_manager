import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/services/secondary_auth_service.dart';
import '../models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _db;
  final SecondaryAuthService _secondaryAuth;
  UserRepository(this._db, this._secondaryAuth);

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _users.doc(uid);

  // ===== READ =====

  /// 🔹 One-time fetch (Session bootstrap)
  Future<AppUser?> getUserById(String uid) async {
    final snap = await userRef(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }

  /// 🔹 Realtime stream (role change, profile update)
  Stream<AppUser?> watchUserById(String uid) {
    return userRef(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromDoc(snap);
    });
  }

  // ===== CREATE =====

  Future<void> createParentIfMissing({
    required String uid,
    required String email,
    String? displayName,
    String locale = 'vi',
    String timezone = 'Asia/Ho_Chi_Minh',
  }) async {
    final ref = userRef(uid);
    final snap = await ref.get();
    if (snap.exists) return;

    await ref.set(
      {
        'uid': uid,
        'role': 'parent',
        'email': email,
        'displayName': displayName,
        'locale': locale,
        'timezone': timezone,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'subscription': {
          'plan': 'free',
          'status': 'active',
          'startAt': FieldValue.serverTimestamp(),
          'endAt': null,
        },
      }..removeWhere((_, v) => v == null),
    );
  }

  // ===== UPDATE =====

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
    String? photoUrl,
    String? locale,
    String? timezone,
  }) async {
    await userRef(uid).update({
      if (displayName != null) 'displayName': displayName,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (locale != null) 'locale': locale,
      if (timezone != null) 'timezone': timezone,
      'lastActiveAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> touchActive(String uid) async {
    await userRef(uid).update({'lastActiveAt': FieldValue.serverTimestamp()});
  }

  // ===== CHILDREN =====

  Stream<List<AppUser>> watchChildren(String parentUid) {
    return _users
        .where('role', isEqualTo: 'child')
        .where('parentUid', isEqualTo: parentUid)
        .snapshots()
        .map((qs) => qs.docs.map(AppUser.fromDoc).toList());
  }

  Future<String> createChildAccount({
    required String parentUid,
    required String email,
    required String password,
    required String displayName,
    required DateTime? dob,
    required String locale,
    required String timezone,
  }) async {
    final cred = await _secondaryAuth.createUser(
      email: email.trim(),
      password: password,
    );

    final childUid = cred.user!.uid;

    // 2️⃣ Create Firestore document
    final ref = userRef(childUid);
    final snap = await ref.get();
    if (snap.exists) "NOT FOUND";

    await ref.set(
      {
        'uid': childUid,
        'role': 'child',
        'displayName': displayName,
        'email': email,
        'parentUid': parentUid,
        'locale': 'vi',
        'timezone': 'Asia/Ho_Chi_Minh',
        'dob': dob != null ? Timestamp.fromDate(dob) : null,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }..removeWhere((_, v) => v == null),
    );

    return childUid;
  }
}
