import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/child_item.dart';
import 'package:kid_manager/models/user/user_profile_patch.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user/family_repository.dart';
import 'package:kid_manager/repositories/user/membership_repository.dart';
import 'package:kid_manager/repositories/user/profile_repository.dart';
import 'package:kid_manager/services/secondary_auth_service.dart';

export 'package:kid_manager/repositories/user/profile_repository.dart'
    show UserItem;

class UserRepository {
  UserRepository(
    FirebaseFirestore db,
    FirebaseAuth? auth,
    SecondaryAuthService? secondaryAuth, {
    ProfileRepository? profileRepository,
    FamilyRepository? familyRepository,
    MembershipRepository? membershipRepository,
  }) : _db = db,
       _auth = auth,
       _secondaryAuth = secondaryAuth,
       _profileRepository = profileRepository ?? ProfileRepository(db),
       _membershipRepository =
           membershipRepository ?? MembershipRepository(db, secondaryAuth),
       _familyRepository =
           familyRepository ??
           FamilyRepository(
             db,
             profileRepository ?? ProfileRepository(db),
             auth: auth,
           );

  final FirebaseFirestore _db;
  final FirebaseAuth? _auth;
  final SecondaryAuthService? _secondaryAuth;
  final ProfileRepository _profileRepository;
  final FamilyRepository _familyRepository;
  final MembershipRepository _membershipRepository;

  factory UserRepository.background(FirebaseFirestore db) {
    return UserRepository(db, null, null);
  }

  FirebaseFirestore get db => _db;
  FirebaseAuth? get auth => _auth;
  SecondaryAuthService? get secondaryAuth => _secondaryAuth;
  ProfileRepository get profiles => _profileRepository;
  FamilyRepository get families => _familyRepository;
  MembershipRepository get memberships => _membershipRepository;

  Future<AppUser?> getUserById(String uid) =>
      _profileRepository.getUserById(uid);

  Stream<AppUser?> watchUserById(String uid) =>
      _profileRepository.watchUserById(uid);

  Future<List<UserItem>> loadFamilyUsers(String familyId) =>
      _profileRepository.loadFamilyUsers(familyId);

  Future<void> createParentIfMissing({
    required String uid,
    required String email,
    String? displayName,
    String locale = 'vi',
    String timezone = 'Asia/Ho_Chi_Minh',
    bool isActive = false,
  }) {
    return _familyRepository.createParentIfMissing(
      uid: uid,
      email: email,
      displayName: displayName,
      locale: locale,
      timezone: timezone,
      isActive: isActive,
    );
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? phone,
    String? photoUrl,
    String? locale,
    String? timezone,
  }) {
    return _profileRepository.updateProfile(
      uid: uid,
      displayName: displayName,
      phone: phone,
      photoUrl: photoUrl,
      locale: locale,
      timezone: timezone,
    );
  }

  Future<void> updateTimeZone({
    required String uid,
    required String timezone,
  }) {
    return _profileRepository.updateTimeZone(uid: uid, timezone: timezone);
  }

  Future<void> touchActive(String uid) => _profileRepository.touchActive(uid);

  Stream<List<AppUser>> watchChildren(String parentUid) =>
      _membershipRepository.watchChildren(parentUid);

  Stream<List<AppUser>> watchFamilyMembers(String familyId) =>
      _familyRepository.watchFamilyMembers(familyId);

  Future<void> syncFamilyMemberPublicData(String familyId) =>
      _familyRepository.syncPublicMembersIfNeeded(familyId);

  Stream<List<AppUser>> watchTrackableLocationMembers(
    String familyId, {
    String? excludeUid,
  }) {
    return _membershipRepository.watchTrackableLocationMembers(
      familyId,
      excludeUid: excludeUid,
    );
  }

  Future<String?> getFamilyId(String uid) => _familyRepository.getFamilyId(uid);

  Future<String> createChildAccount({
    required String parentUid,
    required String email,
    required String password,
    required String displayName,
    required DateTime? dob,
    UserRole role = UserRole.child,
    required String locale,
    required String timezone,
  }) {
    return _membershipRepository.createManagedAccount(
      parentUid: parentUid,
      email: email,
      password: password,
      displayName: displayName,
      dob: dob,
      role: role,
      locale: locale,
      timezone: timezone,
    );
  }

  Future<void> saveUserProfile(UserProfile profile) =>
      _profileRepository.saveUserProfile(profile);

  Future<UserProfile?> getUserProfile(String uid) =>
      _profileRepository.getUserProfile(uid);

  Stream<UserProfile?> listenUserProfile(String uid) =>
      _profileRepository.listenUserProfile(uid);

  Future<void> patchUserProfile({
    required String uid,
    required UserProfilePatch patch,
  }) {
    return _profileRepository.patchUserProfile(uid: uid, patch: patch);
  }

  Stream<List<AppUser>> watchChildrenByFamilyId(String familyId) {
    return _db
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .where('role', isEqualTo: roleToString(UserRole.child))
        .snapshots()
        .map((snap) {
          return snap.docs.map((d) => AppUser.fromDoc(d)).toList();
        });
  }

  Future<List<ChildItem>> getChildrenByParentUid(String parentUid) =>
      _membershipRepository.getChildrenByParentUid(parentUid);

  Stream<List<AppUser>> watchChildrenByParentUid(String parentUid) =>
      _membershipRepository.watchChildrenByParentUid(parentUid);

  Future<UserRole> getUserRole(String uid) =>
      _profileRepository.getUserRole(uid);

  Future<List<ChildUser>> getChildUsers(String parentUid) =>
      _membershipRepository.getChildUsers(parentUid);

  Future<List<AppUser>> getGuardiansByParentUid(String parentUid) =>
      _membershipRepository.getGuardiansByParentUid(parentUid);

  Future<void> assignGuardianChildren({
    required String parentUid,
    required String guardianUid,
    required List<String> childIds,
  }) {
    return _membershipRepository.assignGuardianChildren(
      parentUid: parentUid,
      guardianUid: guardianUid,
      childIds: childIds,
    );
  }

  Future<bool> updateUserPhotoUrl({
    required String uid,
    required String url,
    required UserPhotoType type,
  }) {
    return _profileRepository.updateUserPhotoUrl(
      uid: uid,
      url: url,
      type: type,
    );
  }
}
