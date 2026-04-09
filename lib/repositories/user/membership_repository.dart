import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user/user_document_fields.dart';
import 'package:kid_manager/services/secondary_auth_service.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class MembershipRepository {
  MembershipRepository(
    this._db,
    this._secondaryAuth,
  );

  final FirebaseFirestore _db;
  final SecondaryAuthService? _secondaryAuth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userRef(String uid) => _users.doc(uid);

  Stream<List<AppUser>> watchChildren(String parentUid) {
    return _users
        .where('role', isEqualTo: roleToString(UserRole.child))
        .where('parentUid', isEqualTo: parentUid)
        .snapshots()
        .map((qs) => qs.docs.map(AppUser.fromDoc).toList(growable: false));
  }

  Stream<List<AppUser>> watchTrackableLocationMembers(
    String familyId, {
    String? excludeUid,
  }) {
    final normalizedFamilyId = familyId.trim();
    final normalizedExcludeUid = excludeUid?.trim();

    return _db
        .collection('families')
        .doc(normalizedFamilyId)
        .collection('locationMembers')
        .snapshots()
        .map((qs) {
          final list = qs.docs
              .map(
                (doc) => _normalizeFamilyLocationMember(
                  doc,
                  familyId: normalizedFamilyId,
                ),
              )
              .where((user) {
                if (normalizedExcludeUid != null &&
                    normalizedExcludeUid.isNotEmpty &&
                    user.uid == normalizedExcludeUid) {
                  return false;
                }

                if (user.role == UserRole.child) {
                  return true;
                }

                if (user.role == UserRole.guardian && user.allowTracking) {
                  return true;
                }

                return user.role == UserRole.parent && user.allowTracking;
              })
              .toList(growable: false);

          list.sort((a, b) {
            final roleScoreA = a.role == UserRole.child ? 0 : 1;
            final roleScoreB = b.role == UserRole.child ? 0 : 1;
            final roleCompare = roleScoreA.compareTo(roleScoreB);
            if (roleCompare != 0) {
              return roleCompare;
            }
            final nameA = (a.displayName ?? a.uid).trim().toLowerCase();
            final nameB = (b.displayName ?? b.uid).trim().toLowerCase();
            return nameA.compareTo(nameB);
          });

          return list;
        });
  }

  AppUser _normalizeFamilyLocationMember(
    DocumentSnapshot<Map<String, dynamic>> memberDoc, {
    required String familyId,
  }) {
    final user = AppUser.fromDoc(memberDoc);
    final normalizedFamilyId =
        (user.familyId ?? '').trim().isEmpty ? familyId : user.familyId;
    final normalizedAllowTracking =
        user.role == UserRole.child ? true : user.allowTracking;

    if (normalizedFamilyId == user.familyId &&
        normalizedAllowTracking == user.allowTracking) {
      return user;
    }

    return user.copyWith(
      familyId: normalizedFamilyId,
      allowTracking: normalizedAllowTracking,
    );
  }

  Future<String> createManagedAccount({
    required String parentUid,
    required String email,
    required String password,
    required String displayName,
    required DateTime? dob,
    UserRole role = UserRole.child,
    required String locale,
    required String timezone,
  }) async {
    final l10n = runtimeL10n();

    try {
      final parentSnap = await userRef(parentUid).get();
      final familyId = parentSnap.data()?['familyId'];

      if (familyId == null || (familyId is String && familyId.isEmpty)) {
        throw StateError('Parent missing familyId');
      }

      final cred = await _secondaryAuth!.createUser(
        email: email.trim(),
        password: password,
      );

      final managedUid = cred.user!.uid;
      final batch = _db.batch();

      batch.set(
        userRef(managedUid),
        {
          'uid': managedUid,
          'role': roleToString(role),
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
          'allowTracking': role == UserRole.child,
        }..removeWhere((key, value) => value == null),
      );

      batch.set(
        _db.collection('families').doc(familyId).collection('members').doc(
              managedUid,
            ),
        {
          ...buildFamilyMemberPublicFields(
            uid: managedUid,
            role: role,
            familyId: familyId,
            displayName: displayName,
            avatarUrl: '',
            dob: dob,
            isActive: true,
            lastActiveAt: FieldValue.serverTimestamp(),
          ),
          'joinedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      return managedUid;
    } on FirebaseAuthException catch (e) {
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
    } on FirebaseException catch (e) {
      switch (e.code) {
        case 'permission-denied':
          throw l10n.firestorePermissionDenied;
        case 'unavailable':
          throw l10n.firestoreUnavailable;
        default:
          throw e.message ?? l10n.firestoreGenericError;
      }
    } on StateError catch (e) {
      throw e.message;
    } catch (_) {
      throw l10n.userRepositoryCreateChildFailed;
    }
  }

  Future<List<ChildItem>> getChildrenByParentUid(String parentUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: roleToString(UserRole.child))
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
          isOnline = now.difference(lastActive).inMinutes <= 2;
        }

        return ChildItem(
          id: doc.id,
          name: (data['displayName'] ?? '').toString(),
          avatarUrl: (data['avatarUrl'] ?? '').toString(),
          isOnline: isOnline,
        );
      }).toList(growable: false);
    } catch (e) {
      debugPrint('ERROR getChildrenByParentUid: $e');
      rethrow;
    }
  }

  Stream<List<AppUser>> watchChildrenByParentUid(String parentUid) {
    return _db
        .collection('users')
        .where('role', isEqualTo: roleToString(UserRole.child))
        .where('parentUid', isEqualTo: parentUid)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList(growable: false));
  }

  Future<List<ChildUser>> getChildUsers(String parentUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: roleToString(UserRole.child))
          .where('parentUid', isEqualTo: parentUid)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChildUser(
          id: doc.id,
          displayName: (data['displayName'] ?? '').toString(),
        );
      }).toList(growable: false);
    } catch (e) {
      debugPrint('getChildUsers error: $e');
      return [];
    }
  }

  Future<List<AppUser>> getGuardiansByParentUid(String parentUid) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: roleToString(UserRole.guardian))
          .where('parentUid', isEqualTo: parentUid)
          .get();

      return snapshot.docs.map(AppUser.fromDoc).toList(growable: false);
    } catch (e) {
      debugPrint('getGuardiansByParentUid error: $e');
      return [];
    }
  }

  Future<void> assignGuardianChildren({
    required String parentUid,
    required String guardianUid,
    required List<String> childIds,
  }) async {
    final normalizedParentUid = parentUid.trim();
    final normalizedGuardianUid = guardianUid.trim();
    final normalizedChildIds = childIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);

    if (normalizedParentUid.isEmpty || normalizedGuardianUid.isEmpty) {
      throw StateError('Invalid parent or guardian id');
    }

    final guardianSnap = await userRef(normalizedGuardianUid).get();
    final guardian = guardianSnap.exists ? AppUser.fromDoc(guardianSnap) : null;
    if (guardian == null) {
      throw StateError('Guardian not found');
    }
    if (guardian.role != UserRole.guardian) {
      throw StateError('Target user is not guardian');
    }
    if ((guardian.parentUid ?? '').trim() != normalizedParentUid) {
      throw StateError('Guardian does not belong to this parent');
    }

    if (normalizedChildIds.isNotEmpty) {
      final childSnapshot = await _users
          .where('role', isEqualTo: roleToString(UserRole.child))
          .where('parentUid', isEqualTo: normalizedParentUid)
          .get();

      final allowedChildIds = childSnapshot.docs
          .map((doc) => doc.id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();

      final invalidIds = normalizedChildIds
          .where((id) => !allowedChildIds.contains(id))
          .toList(growable: false);
      if (invalidIds.isNotEmpty) {
        throw StateError('Child does not belong to this parent');
      }
    }

    await userRef(normalizedGuardianUid).set({
      'managedChildIds': normalizedChildIds,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
