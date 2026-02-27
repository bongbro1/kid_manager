import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_role.dart';
import 'package:kid_manager/services/secondary_auth_service.dart';
import '../models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth? _auth;
  final SecondaryAuthService? _secondaryAuth;
  UserRepository(this._db, this._auth, this._secondaryAuth);

  factory UserRepository.background(FirebaseFirestore db) {
    return UserRepository(db, null, null);
  }

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
    if (snap.exists) {
      final data = snap.data();
      if (data?['familyId'] != null) return;

      final familyId = _db.collection('families').doc().id;

      final batch = _db.batch();

      batch.update(ref, {'familyId': familyId});

      final familyRef = _db.collection('families').doc(familyId);

      batch.set(familyRef, {
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(
        familyRef.collection('members').doc(uid),
        {
          'uid': uid,
          'role': 'parent',
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      return;
    }
    final familyId = _db.collection('families').doc().id;
    final batch = _db.batch();
    batch.set(ref,(
        {
          'uid': uid,
          'role': 'parent',
          'email': email,
          'familyId': familyId,
          'displayName': displayName,
          'locale': locale,
          'timezone': timezone,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
          'avatarUrl': '',
          'subscription': {
            'plan': 'free',
            'status': 'active',
            'startAt': FieldValue.serverTimestamp(),
            'endAt': null,
          },
        })..removeWhere((_, v) => v == null)
    );

    final familyRef = _db.collection('families').doc(familyId);
    batch.set(familyRef, {
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3️⃣ Thêm parent vào members
    batch.set(
      familyRef.collection('members').doc(uid),
      {
        'uid': uid,
        'role': 'parent',
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
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
    try {
      // 1) Lấy familyId của parent
      final parentSnap = await userRef(parentUid).get();
      final familyId = parentSnap.data()?['familyId'];

      if (familyId == null || (familyId is String && familyId.isEmpty)) {
        throw StateError("Parent missing familyId");
      }

      // 2) Tạo Auth user
      final cred = await _secondaryAuth!.createUser(
        email: email.trim(),
        password: password,
      );

      final childUid = cred.user!.uid;

      // 3) Ghi Firestore bằng batch
      final batch = _db.batch();

      batch.set(
        userRef(childUid),
        {
          'uid': childUid,
          'role': 'child',
          'displayName': displayName,
          'email': email.trim(),
          'parentUid': parentUid,
          'familyId': familyId,
          'locale': locale,
          'timezone': timezone,
          'dob': dob != null ? Timestamp.fromDate(dob) : null,
          'createdAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
          'avatarUrl': '',
        }..removeWhere((_, v) => v == null),
      );
      print("Lỗi ở đây 1");
      batch.set(
        _db.collection('families').doc(familyId).collection('members').doc(childUid),
        {
          'uid': childUid,
          'role': 'child',
          'familyId': familyId,
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );
      print("Lỗi ở đây 2");
      await batch.commit();

      return childUid;
    }

    // ✅ Bắt lỗi Firebase Auth (email trùng, password yếu, email sai định dạng...)
    on FirebaseAuthException catch (e) {
      // Gợi ý message theo code
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception("Email đã được sử dụng.");
        case 'invalid-email':
          throw Exception("Email không hợp lệ.");
        case 'weak-password':
          throw Exception("Mật khẩu quá yếu (hãy dùng mạnh hơn).");
        case 'operation-not-allowed':
          throw Exception("Chức năng tạo tài khoản chưa được bật trong Firebase Auth.");
        default:
          throw Exception("Lỗi tạo tài khoản: ${e.message ?? e.code}");
      }
    }

    // ✅ Bắt lỗi Firestore
    on FirebaseException catch (e) {
      // FirebaseException dùng cho Firestore/Storage... (Firestore thường code: permission-denied, unavailable...)
      switch (e.code) {
        case 'permission-denied':
          throw Exception("Không đủ quyền ghi dữ liệu (permission-denied).");
        case 'unavailable':
          throw Exception("Firestore tạm thời không khả dụng. Thử lại sau.");
        default:
          throw Exception("Lỗi Firestore: ${e.message ?? e.code}");
      }
    }

    // ✅ Bắt lỗi logic (familyId null, v.v.)
    on StateError catch (e) {
      throw Exception("Dữ liệu không hợp lệ: ${e.message}");
    }

    // ✅ Bắt mọi lỗi còn lại
    catch (e) {
      throw Exception("Tạo tài khoản con thất bại: $e");
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.collection("users").doc(profile.id).set({
      ...profile.toMap(),
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();

    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<List<ChildItem>> getChildrenByParentUid(String parentUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'child')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      debugPrint("===== CHILD QUERY DEBUG =====");
      debugPrint("Parent UID: $parentUid");
      debugPrint("Children found: ${snapshot.docs.length}");
      debugPrint("=============================");

      final now = DateTime.now();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        final lastActive = (data['lastActiveAt'] as Timestamp?)?.toDate();

        bool isOnline = false;
        if (lastActive != null) {
          final diff = now.difference(lastActive).inMinutes;
          isOnline = diff <= 2; // online nếu hoạt động trong 2 phút
        }

        return ChildItem(
          id: doc.id,
          name: data['displayName'] ?? '',
          avatarUrl: data['photoUrl'] ?? '',
          isOnline: isOnline,
        );
      }).toList();
    } catch (e) {
      debugPrint("❌ ERROR getChildrenByParentUid: $e");
      rethrow;
    }
  }

  Future<UserRole> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return UserRole.child;

    final data = doc.data()!;
    return roleFromString(data['role'] as String);
  }

  Future<List<String>> getChildUserIds(String parentUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'child')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint("❌ getChildUserIds error: $e");
      return [];
    }
  }
}
