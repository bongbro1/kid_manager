import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user/user_document_fields.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/utils/date_utils.dart';

class FamilyRepository {
  FamilyRepository(
    this._db,
    this._profileRepository,
  );

  final FirebaseFirestore _db;
  final ProfileRepository _profileRepository;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  DocumentReference<Map<String, dynamic>> userRef(String uid) => _users.doc(uid);

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
      if (data?['familyId'] != null) {
        return;
      }

      final familyId = _db.collection('families').doc().id;
      final batch = _db.batch();

      batch.update(ref, {'familyId': familyId});

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
          email: data?['email']?.toString(),
          avatarUrl: data?['avatarUrl']?.toString(),
          dob:
              parseFlexibleBirthDate(data?['dobIso']) ??
              parseFlexibleBirthDate(data?['dob']),
          isActive: (data?['isActive'] as bool?) ?? false,
          allowTracking: (data?['allowTracking'] as bool?) ?? false,
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
        'isActive': false,
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
        email: email,
        avatarUrl: '',
        isActive: false,
        allowTracking: false,
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

  Stream<List<AppUser>> watchFamilyMembers(String familyId) {
    final membersRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members');

    return membersRef.snapshots().map((qs) {
      final memberDocs = qs.docs;
      if (memberDocs.isEmpty) {
        return const <AppUser>[];
      }

      final inferredParentUid = _inferFamilyParentUid(memberDocs);
      final users = memberDocs
          .map(
            (memberDoc) => _normalizeFamilyMember(
              memberDoc,
              familyId: familyId,
              inferredParentUid: inferredParentUid,
            ),
          )
          .toList(growable: false);

      users.sort((a, b) {
        final roleCompare = _roleSortOrder(a.role).compareTo(
          _roleSortOrder(b.role),
        );
        if (roleCompare != 0) {
          return roleCompare;
        }
        final nameA = (a.displayName ?? a.email ?? '').trim().toLowerCase();
        final nameB = (b.displayName ?? b.email ?? '').trim().toLowerCase();
        return nameA.compareTo(nameB);
      });
      return users;
    });
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

  String? _inferFamilyParentUid(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> memberDocs,
  ) {
    for (final memberDoc in memberDocs) {
      final data = memberDoc.data();
      if (UserRole.fromValue(data['role']) != UserRole.parent) {
        continue;
      }
      final uid = (data['uid'] ?? memberDoc.id).toString().trim();
      if (uid.isNotEmpty) {
        return uid;
      }
    }
    return null;
  }

  AppUser _normalizeFamilyMember(
    DocumentSnapshot<Map<String, dynamic>> memberDoc, {
    required String familyId,
    required String? inferredParentUid,
  }) {
    final data = memberDoc.data() ?? const <String, dynamic>{};
    final user = AppUser.fromMap(data, docId: memberDoc.id);
    final normalizedFamilyId =
        (user.familyId ?? '').trim().isEmpty ? familyId : user.familyId;
    final normalizedParentUid =
        (user.parentUid ?? '').trim().isEmpty &&
            (user.role == UserRole.child || user.role == UserRole.guardian)
        ? inferredParentUid
        : user.parentUid;
    final normalizedAllowTracking =
        user.role == UserRole.child ? true : user.allowTracking;

    if (normalizedFamilyId == user.familyId &&
        normalizedParentUid == user.parentUid &&
        normalizedAllowTracking == user.allowTracking) {
      return user;
    }

    return user.copyWith(
      familyId: normalizedFamilyId,
      parentUid: normalizedParentUid,
      allowTracking: normalizedAllowTracking,
    );
  }
}
