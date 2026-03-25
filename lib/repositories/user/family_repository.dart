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

      batch.update(ref, {
        'familyId': familyId,
        if (isActive) 'isActive': true,
      });

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

    return membersRef
        .snapshots()
        .asyncMap((qs) async {
          final memberDocs = qs.docs;
          if (memberDocs.isEmpty) {
            return const <AppUser>[];
          }

          final users = await Future.wait(
            memberDocs.map((memberDoc) async {
              final uid = (memberDoc.data()['uid'] ?? memberDoc.id).toString();
              final userSnap = await userRef(uid).get();
              if (userSnap.exists) {
                return AppUser.fromDoc(userSnap);
              }
              return _fallbackFamilyMember(memberDoc, familyId: familyId);
            }),
          );

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

  AppUser _fallbackFamilyMember(
    DocumentSnapshot<Map<String, dynamic>> memberDoc, {
    required String familyId,
  }) {
    final data = memberDoc.data() ?? const <String, dynamic>{};
    return AppUser(
      uid: (data['uid'] ?? memberDoc.id).toString(),
      role: UserRole.fromValue(data['role']),
      familyId: (data['familyId'] ?? familyId).toString(),
      displayName: data['displayName']?.toString(),
      avatarUrl: data['avatarUrl']?.toString(),
      parentUid: data['parentUid']?.toString(),
    );
  }
}
