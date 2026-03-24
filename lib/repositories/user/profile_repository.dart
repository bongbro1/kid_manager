import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_profile_patch.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';

class ProfileRepository {
  ProfileRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userRef(String uid) => _users.doc(uid);

  Future<AppUser?> getUserById(String uid) async {
    final snap = await userRef(uid).get();
    if (!snap.exists) {
      return null;
    }
    return AppUser.fromDoc(snap);
  }

  Stream<AppUser?> watchUserById(String uid) {
    return userRef(uid).snapshots().map((snap) {
      if (!snap.exists) {
        return null;
      }
      return AppUser.fromDoc(snap);
    });
  }

  Future<List<UserItem>> loadAllUsers() async {
    final snapshot = await _users.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UserItem(
        uid: (data['uid'] ?? doc.id).toString(),
        displayName: (data['displayName'] ?? '').toString(),
      );
    }).toList(growable: false);
  }

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

  Future<void> patchUserProfile({
    required String uid,
    required UserProfilePatch patch,
  }) async {
    if (patch.isEmpty) {
      return;
    }
    await _users.doc(uid).set(patch.toMap(), SetOptions(merge: true));
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    await _users.doc(profile.id).set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      return null;
    }
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final snap = await _users
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      return null;
    }

    final doc = snap.docs.first;
    return UserProfile.fromMap(doc.id, doc.data());
  }

  Stream<UserProfile?> listenUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserProfile.fromMap(uid, snapshot.data()!);
    });
  }

  Future<UserRole> getUserRole(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) {
      return UserRole.child;
    }

    final data = doc.data()!;
    return UserRole.fromValue(data['role']);
  }

  Future<bool> updateUserPhotoUrl({
    required String uid,
    required String url,
    required UserPhotoType type,
  }) async {
    try {
      final field = type == UserPhotoType.avatar ? 'avatarUrl' : 'coverUrl';
      await userRef(uid).update({
        field: url,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Update photo error: $e');
      return false;
    }
  }
}

class UserItem {
  const UserItem({
    required this.uid,
    required this.displayName,
  });

  final String uid;
  final String displayName;

  factory UserItem.fromFirestore(Map<String, dynamic> data) {
    return UserItem(
      uid: (data['uid'] ?? '').toString(),
      displayName: (data['displayName'] ?? '').toString(),
    );
  }
}
