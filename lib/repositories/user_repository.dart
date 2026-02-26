import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_profile.dart';
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

    // 1️⃣ Lấy familyId của parent
    final parentSnap = await userRef(parentUid).get();
    final familyId = parentSnap.data()?['familyId'];

    if (familyId == null) {
      throw Exception("Parent missing familyId");
    }

    // 2️⃣ Tạo Auth user
    final cred = await _secondaryAuth!.createUser(
      email: email.trim(),
      password: password,
    );

    final childUid = cred.user!.uid;

    final batch = _db.batch();

    // 3️⃣ Tạo Firestore user document
    batch.set(
      userRef(childUid),
      {
        'uid': childUid,
        'role': 'child',
        'displayName': displayName,
        'email': email,
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

    // 4️⃣ Add vào family members
    batch.set(
      _db.collection('families')
          .doc(familyId)
          .collection('members')
          .doc(childUid),
      {
        'uid': childUid,
        'role': 'child',
        'joinedAt': FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
    print("Tạo thành công");
    return childUid;
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.collection("users").doc(profile.id).set({
      ...profile.toMap(),
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection("users").doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data()!;

    return UserProfile(
      id: uid,
      name: (data['displayName'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      gender: (data['gender'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      allowTracking: data['allowTracking'] ?? false,
      avatarUrl: data['avatarUrl']?.toString(),
      dob: data['dob'] is int
          ? Timestamp.fromMillisecondsSinceEpoch(data['dob'])
          : data['dob'],
      role: (data['role'] ?? 'child').toString(),
    );
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
