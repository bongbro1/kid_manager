import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/services/secondary_auth_service.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

import '../models/app_user.dart';

class UserItem {
  final String uid;
  final String displayName;

  UserItem({required this.uid, required this.displayName});

  factory UserItem.fromFirestore(Map<String, dynamic> data) {
    return UserItem(
      uid: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
    );
  }
}

class UserRepository {
  final FirebaseFirestore _db;
  // ignore: unused_field
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

  Map<String, dynamic> _familyMemberPublicFields({
    required String uid,
    required String role,
    String? familyId,
    String? displayName,
    String? avatarUrl,
    DateTime? dob,
  }) {
    return <String, dynamic>{
      'uid': uid,
      'role': role,
      if (familyId != null && familyId.isNotEmpty) 'familyId': familyId,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      ...buildBirthdayStorageFields(dob),
    };
  }

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

  Future<List<UserItem>> loadAllUsers() async {
    final snapshot = await _users.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return UserItem(
        uid: data['uid'] ?? doc.id,
        displayName: data['displayName'] ?? '',
      );
    }).toList();
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

      batch.set(familyRef.collection('members').doc(uid), {
        ..._familyMemberPublicFields(
          uid: uid,
          role: 'parent',
          familyId: familyId,
          displayName: data?['displayName']?.toString(),
          avatarUrl: data?['avatarUrl']?.toString(),
          dob:
              parseFlexibleBirthDate(data?['dobIso']) ??
              parseFlexibleBirthDate(data?['dob']),
        ),
        'joinedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      return;
    }

    final familyId = _db.collection('families').doc().id;
    final batch = _db.batch();
    batch.set(
      ref,
      ({
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
        'isActive': false,
      })..removeWhere((_, v) => v == null),
    );

    final familyRef = _db.collection('families').doc(familyId);
    batch.set(familyRef, {
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3️⃣ Thêm parent vào members
    batch.set(familyRef.collection('members').doc(uid), {
      ..._familyMemberPublicFields(
        uid: uid,
        role: 'parent',
        familyId: familyId,
        displayName: displayName,
        avatarUrl: '',
      ),
      'joinedAt': FieldValue.serverTimestamp(),
    });

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

  Stream<List<AppUser>> watchFamilyMembers(String familyId) {
    return _users
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((qs) => qs.docs.map(AppUser.fromDoc).toList());
  }

  Stream<List<AppUser>> watchTrackableLocationMembers(
    String familyId, {
    String? excludeUid,
  }) {
    return _users
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((qs) {
          final list = qs.docs
              .map(AppUser.fromDoc)
              .where((user) {
                if (excludeUid != null &&
                    excludeUid.isNotEmpty &&
                    user.uid == excludeUid) {
                  return false;
                }

                if (user.role == UserRole.child) {
                  return true;
                }

                return user.role == UserRole.guardian && user.allowTracking;
              })
              .toList();

          list.sort((a, b) {
            final roleScoreA = a.role == UserRole.child ? 0 : 1;
            final roleScoreB = b.role == UserRole.child ? 0 : 1;
            final roleCompare = roleScoreA.compareTo(roleScoreB);
            if (roleCompare != 0) return roleCompare;
            final nameA = (a.displayName ?? a.email ?? '').trim().toLowerCase();
            final nameB = (b.displayName ?? b.email ?? '').trim().toLowerCase();
            return nameA.compareTo(nameB);
          });

          return list;
        });
  }

  Future<String?> getFamilyId(String uid) async {
    final snap = await userRef(uid).get();
    if (!snap.exists) return null;
    return snap.data()?['familyId'] as String?;
  }

  Future<String> createChildAccount({
    required String parentUid,
    required String email,
    required String password,
    required String displayName,
    required DateTime? dob,
    String role = 'child',
    required String locale,
    required String timezone,
  }) async {
    final l10n = runtimeL10n();

    try {
      /// 1️⃣ Lấy familyId của parent
      final parentSnap = await userRef(parentUid).get();
      final familyId = parentSnap.data()?['familyId'];

      if (familyId == null || (familyId is String && familyId.isEmpty)) {
        throw 'Parent missing familyId';
      }

      /// 2️⃣ Tạo Auth user
      final cred = await _secondaryAuth!.createUser(
        email: email.trim(),
        password: password,
      );

      final childUid = cred.user!.uid;

      /// 3️⃣ Batch Firestore
      final batch = _db.batch();

      batch.set(
        userRef(childUid),
        {
          'uid': childUid,
          'role': role,
          'displayName': displayName,
          'email': email.trim(),
          'parentUid': parentUid,
          'familyId': familyId,
          'locale': locale,
          'timezone': timezone,
          ...buildBirthdayStorageFields(dob),
          'createdAt': FieldValue.serverTimestamp(),
          'lastActiveAt': FieldValue.serverTimestamp(),
          'avatarUrl': '',
          'isActive': true,
        }..removeWhere((_, v) => v == null),
      );

      batch.set(
        _db.collection('families').doc(familyId).collection('members').doc(
          childUid,
        ),
        {
          ..._familyMemberPublicFields(
            uid: childUid,
            role: 'child',
            familyId: familyId,
            displayName: displayName,
            avatarUrl: '',
            dob: dob,
          ),
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      return childUid;
    }
    /// 🔥 Firebase Auth errors
    on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw l10n.emailInUse;
        case 'invalid-email':
          throw l10n.emailInvalid;
        case 'weak-password':
          throw l10n.weakPassword;
        case 'operation-not-allowed':
          throw l10n.firebaseAuthOperationNotAllowed;
        default:
          throw e.message ?? l10n.userRepositoryCreateAccountFailed;
      }
    }
    /// 🔥 Firestore errors
    on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw l10n.firestorePermissionDenied;
        case 'unavailable':
          throw l10n.firestoreUnavailable;
        default:
          throw e.message ?? l10n.firestoreGenericError;
      }
    }
    /// 🔥 Logic error
    on StateError catch (e) {
      throw e.message;
    } catch (e) {
      throw l10n.userRepositoryCreateChildFailed;
    }
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _db.collection('users').doc(profile.id).set({
      ...profile.toMap(),
    }, SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();

    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data()!);
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final snap = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final doc = snap.docs.first;
    return UserProfile.fromMap(doc.id, doc.data());
  }

  Stream<UserProfile?> listenUserProfile(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          return UserProfile.fromMap(uid, snapshot.data()!);
        });
  }

  Future<List<ChildItem>> getChildrenByParentUid(String parentUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'child')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      debugPrint('===== CHILD QUERY DEBUG =====');
      debugPrint('Parent UID: $parentUid');
      debugPrint('Children found: ${snapshot.docs.length}');
      debugPrint('=============================');

      final now = DateTime.now();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        final lastActive = (data['lastActiveAt'] as Timestamp?)?.toDate();

        var isOnline = false;
        if (lastActive != null) {
          final diff = now.difference(lastActive).inMinutes;
          isOnline = diff <= 2; // online nếu hoạt động trong 2 phút
        }

        return ChildItem(
          id: doc.id,
          name: data['displayName'] ?? '',
          avatarUrl: data['avatarUrl'] ?? '',
          isOnline: isOnline,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ERROR getChildrenByParentUid: $e');
      rethrow;
    }
  }

  /// THÊM HÀM NÀY
  Future<void> updateUserProfileByUid({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Stream<List<AppUser>> watchChildrenByParentUid(String parentUid) {
    return _db
        .collection('users')
        .where('parentUid', isEqualTo: parentUid)
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => AppUser.fromDoc(d)).toList();
        });
  }

  Future<UserRole> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return UserRole.child;

    final data = doc.data()!;
    return roleFromString(data['role'] as String);
  }

  Future<List<ChildUser>> getChildUsers(String parentUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'child')
          .where('parentUid', isEqualTo: parentUid)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return ChildUser(
          id: doc.id,
          displayName: (data['displayName'] ?? '') as String,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ getChildUsers error: $e');
      return [];
    }
  }

  Future<bool> updateUserPhotoUrl({
    required String uid,
    required String url,
    required UserPhotoType type,
  }) async {
    try {
      final ref = userRef(uid);

      final field = type == UserPhotoType.avatar ? 'avatarUrl' : 'coverUrl';

      await ref.update({
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
