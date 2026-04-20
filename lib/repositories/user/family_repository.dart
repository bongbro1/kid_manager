import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user/user_document_fields.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/utils/date_utils.dart';

class FamilyRepository {
  FamilyRepository(
    this._db,
    this._profileRepository, {
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFirestore _db;
  final ProfileRepository _profileRepository;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;
  final Set<String> _syncAttemptedFamilies = <String>{};

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _users.doc(uid);

  Future<void> createParentIfMissing({
    required String uid,
    required String email,
    String? displayName,
    String locale = 'vi',
    String timezone = 'Asia/Ho_Chi_Minh',
    bool isActive = false,
  }) async {
    final ref = userRef(uid);
    final snap = await ref.get();
    if (snap.exists) {
      final data = snap.data();
      if (data?['familyId'] != null) {
        return;
      }

      final familyId = _db.collection('families').doc().id;
      final batch = _db.batch();

      batch.update(ref, {'familyId': familyId, if (isActive) 'isActive': true});

      final familyRef = _db.collection('families').doc(familyId);
      batch.set(familyRef, {
        'createdBy': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(familyRef.collection('members').doc(uid), {
        ...buildFamilyMemberPublicFields(
          uid: uid,
          role: UserRole.parent,
          familyId: familyId,
          displayName: data?['displayName']?.toString(),
          avatarUrl: data?['avatarUrl']?.toString(),
          dob:
              parseFlexibleBirthDate(data?['dobIso']) ??
              parseFlexibleBirthDate(data?['dob']),
          isActive: (data?['isActive'] as bool?) ?? false,
          lastActiveAt: data?['lastActiveAt'] ?? FieldValue.serverTimestamp(),
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
        'role': roleToString(UserRole.parent),
        'email': email,
        'familyId': familyId,
        'displayName': displayName,
        'locale': locale,
        'timezone': timezone,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'avatarUrl': '',
        'subscription': SubscriptionInfo(
          plan: SubscriptionPlan.free,
          status: SubscriptionStatus.active,
          startAt: DateTime.now(),
        ).toMap(),
        'isActive': isActive,
      })..removeWhere((key, value) => value == null),
    );

    final familyRef = _db.collection('families').doc(familyId);
    batch.set(familyRef, {
      'createdBy': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(familyRef.collection('members').doc(uid), {
      ...buildFamilyMemberPublicFields(
        uid: uid,
        role: UserRole.parent,
        familyId: familyId,
        displayName: displayName,
        avatarUrl: '',
        isActive: false,
        lastActiveAt: FieldValue.serverTimestamp(),
      ),
      'joinedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<String?> getFamilyId(String uid) async {
    final snap = await userRef(uid).get();
    if (!snap.exists) {
      return null;
    }
    return snap.data()?['familyId'] as String?;
  }

  Future<void> syncPublicMembersIfNeeded(String familyId) async {
    final normalizedFamilyId = familyId.trim();
    if (normalizedFamilyId.isEmpty ||
        _syncAttemptedFamilies.contains(normalizedFamilyId)) {
      return;
    }

    _syncAttemptedFamilies.add(normalizedFamilyId);
    try {
      await _functions.httpsCallable('syncFamilyMemberPublicData').call({
        'familyId': normalizedFamilyId,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' ||
          e.code == 'permission-denied' ||
          e.code == 'unauthenticated' ||
          e.code == 'unimplemented') {
        return;
      }
      return;
    } catch (_) {
      return;
    }
  }

  Stream<List<AppUser>> watchFamilyMembers(String familyId) {
    final membersRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members');

    final viewerUid = _auth.currentUser?.uid.trim();

    late final StreamController<List<AppUser>> controller;
    QuerySnapshot<Map<String, dynamic>>? latestMembers;
    var managementByUid = <String, AppUser>{};
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? managementSub;
    var cancelled = false;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? membersSub;

    void emit() {
      final memberDocs = latestMembers?.docs;
      if (memberDocs == null || controller.isClosed) {
        return;
      }
      if (memberDocs.isEmpty) {
        controller.add(const <AppUser>[]);
        return;
      }

      final users = memberDocs
          .map(
            (memberDoc) => _normalizeFamilyMember(
              memberDoc,
              familyId: familyId,
              managementMeta: managementByUid[memberDoc.id],
            ),
          )
          .toList(growable: false);

      users.sort((a, b) {
        final roleCompare = _roleSortOrder(
          a.role,
        ).compareTo(_roleSortOrder(b.role));
        if (roleCompare != 0) {
          return roleCompare;
        }
        final nameA = (a.displayName ?? a.uid).trim().toLowerCase();
        final nameB = (b.displayName ?? b.uid).trim().toLowerCase();
        return nameA.compareTo(nameB);
      });
      controller.add(users);
    }

    controller = StreamController<List<AppUser>>(
      onListen: () {
        membersSub = membersRef.snapshots().listen((qs) {
          latestMembers = qs;
          emit();
        }, onError: controller.addError);

        unawaited(() async {
          if (viewerUid == null || viewerUid.isEmpty) {
            return;
          }

          try {
            final viewer = await _profileRepository.getUserById(viewerUid);
            if (cancelled || viewer?.role != UserRole.parent) {
              return;
            }

            final managementQuery = _db
                .collection('families')
                .doc(familyId)
                .collection('managementMembers')
                .where('parentUid', isEqualTo: viewerUid);

            managementSub = managementQuery.snapshots().listen((qs) {
              managementByUid = {
                for (final doc in qs.docs) doc.id: AppUser.fromDoc(doc),
              };
              emit();
            }, onError: controller.addError);
          } catch (e, st) {
            debugPrint(
              '[FamilyRepository] watchFamilyMembers management load error: $e',
            );
            debugPrintStack(stackTrace: st);
          }
        }());
      },
      onCancel: () async {
        cancelled = true;
        await membersSub?.cancel();
        await managementSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<AppUser?> getUserById(String uid) {
    return _profileRepository.getUserById(uid);
  }

  int _roleSortOrder(UserRole role) {
    switch (role) {
      case UserRole.parent:
        return 0;
      case UserRole.guardian:
        return 1;
      case UserRole.child:
        return 2;
    }
  }

  AppUser _normalizeFamilyMember(
    DocumentSnapshot<Map<String, dynamic>> memberDoc, {
    required String familyId,
    AppUser? managementMeta,
  }) {
    final data = memberDoc.data() ?? const <String, dynamic>{};
    final user = AppUser.fromMap(data, docId: memberDoc.id);
    final normalizedFamilyId = (user.familyId ?? '').trim().isEmpty
        ? familyId
        : user.familyId;
    final normalizedManagedChildIds =
        managementMeta?.managedChildIds ?? user.managedChildIds;

    if (normalizedFamilyId == user.familyId &&
        listEquals(normalizedManagedChildIds, user.managedChildIds)) {
      return user;
    }

    return user.copyWith(
      familyId: normalizedFamilyId,
      managedChildIds: normalizedManagedChildIds,
    );
  }
}
