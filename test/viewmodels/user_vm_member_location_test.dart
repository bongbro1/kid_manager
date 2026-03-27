import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/access_control/access_control_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserVm member and location filters', () {
    late StreamController<List<AppUser>> familyMembersController;
    late StreamController<List<AppUser>> locationMembersController;
    late _FakeUserRepository repository;
    late StorageService storage;
    late UserVm viewModel;

    setUp(() async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      storage = await StorageService.create();
      familyMembersController = StreamController<List<AppUser>>();
      locationMembersController = StreamController<List<AppUser>>();
      repository = _FakeUserRepository(
        familyMembersStream: familyMembersController.stream,
        locationMembersStream: locationMembersController.stream,
      );
      viewModel = UserVm(repository, storage, AccessControlService());
    });

    tearDown(() async {
      viewModel.dispose();
      await familyMembersController.close();
      await locationMembersController.close();
    });

    test('guardian family members list only shows parent and assigned children', () async {
      await storage.setString(StorageKeys.uid, 'guardian-1');
      await storage.setString(StorageKeys.role, UserRole.guardian.wireValue);
      await storage.setString(StorageKeys.parentId, 'parent-1');
      await storage.setStringList(StorageKeys.managedChildIds, ['child-1']);

      viewModel.me = _buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-1',
        managedChildIds: const ['child-1'],
      );

      viewModel.watchFamilyMembers('family-1');
      familyMembersController.add(<AppUser>[
        _buildUser(uid: 'parent-1', role: UserRole.parent),
        _buildUser(
          uid: 'child-1',
          role: UserRole.child,
          parentUid: 'parent-1',
        ),
        _buildUser(
          uid: 'child-2',
          role: UserRole.child,
          parentUid: 'parent-1',
        ),
        _buildUser(
          uid: 'guardian-2',
          role: UserRole.guardian,
          parentUid: 'parent-1',
        ),
      ]);

      await _flushAsync();

      expect(repository.lastWatchedFamilyId, 'family-1');
      expect(
        viewModel.familyMembers.map((user) => user.uid).toList(),
        ['parent-1', 'child-1'],
      );
    });

    test('parent location members keep children visible even when tracking is off', () async {
      await storage.setString(StorageKeys.uid, 'parent-1');
      await storage.setString(StorageKeys.role, UserRole.parent.wireValue);

      viewModel.me = _buildUser(
        uid: 'parent-1',
        role: UserRole.parent,
      );

      viewModel.watchLocationMembers('family-1');
      locationMembersController.add(<AppUser>[
        _buildUser(
          uid: 'child-1',
          role: UserRole.child,
          parentUid: 'parent-1',
          allowTracking: false,
        ),
        _buildUser(
          uid: 'child-2',
          role: UserRole.child,
          parentUid: 'parent-1',
          allowTracking: true,
        ),
        _buildUser(
          uid: 'guardian-1',
          role: UserRole.guardian,
          parentUid: 'parent-1',
          allowTracking: true,
        ),
        _buildUser(
          uid: 'guardian-2',
          role: UserRole.guardian,
          parentUid: 'parent-1',
          allowTracking: false,
        ),
        _buildUser(
          uid: 'child-foreign',
          role: UserRole.child,
          parentUid: 'parent-2',
          allowTracking: true,
        ),
      ]);

      await _flushAsync();

      expect(repository.lastWatchedLocationFamilyId, 'family-1');
      expect(repository.lastExcludedUid, 'parent-1');
      expect(
        viewModel.locationMembers.map((user) => user.uid).toList(),
        ['child-1', 'child-2', 'guardian-1'],
      );
    });

    test('guardian location members only keep assigned children in scope', () async {
      await storage.setString(StorageKeys.uid, 'guardian-1');
      await storage.setString(StorageKeys.role, UserRole.guardian.wireValue);
      await storage.setString(StorageKeys.parentId, 'parent-1');
      await storage.setStringList(StorageKeys.managedChildIds, ['child-1']);

      viewModel.me = _buildUser(
        uid: 'guardian-1',
        role: UserRole.guardian,
        parentUid: 'parent-1',
        managedChildIds: const ['child-1'],
      );

      viewModel.watchLocationMembers('family-1');
      locationMembersController.add(<AppUser>[
        _buildUser(
          uid: 'child-1',
          role: UserRole.child,
          parentUid: 'parent-1',
          allowTracking: false,
        ),
        _buildUser(
          uid: 'child-2',
          role: UserRole.child,
          parentUid: 'parent-1',
          allowTracking: true,
        ),
        _buildUser(
          uid: 'guardian-2',
          role: UserRole.guardian,
          parentUid: 'parent-1',
          allowTracking: true,
        ),
      ]);

      await _flushAsync();

      final ids = viewModel.locationMembers.map((user) => user.uid).toSet();
      expect(ids.contains('child-1'), isTrue);
      expect(ids.contains('child-2'), isFalse);
      expect(ids.contains('guardian-2'), isTrue);
    });
  });
}

AppUser _buildUser({
  required String uid,
  required UserRole role,
  String? parentUid,
  bool allowTracking = true,
  List<String> managedChildIds = const <String>[],
}) {
  return AppUser(
    uid: uid,
    role: role,
    parentUid: parentUid,
    allowTracking: allowTracking,
    managedChildIds: managedChildIds,
  );
}

Future<void> _flushAsync() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _FakeUserRepository implements UserRepository {
  _FakeUserRepository({
    required Stream<List<AppUser>> familyMembersStream,
    required Stream<List<AppUser>> locationMembersStream,
  })  : _familyMembersStream = familyMembersStream,
        _locationMembersStream = locationMembersStream;

  final Stream<List<AppUser>> _familyMembersStream;
  final Stream<List<AppUser>> _locationMembersStream;

  String? lastWatchedFamilyId;
  String? lastWatchedLocationFamilyId;
  String? lastExcludedUid;

  @override
  Stream<List<AppUser>> watchFamilyMembers(String familyId) {
    lastWatchedFamilyId = familyId;
    return _familyMembersStream;
  }

  @override
  Stream<List<AppUser>> watchTrackableLocationMembers(
    String familyId, {
    String? excludeUid,
  }) {
    lastWatchedLocationFamilyId = familyId;
    lastExcludedUid = excludeUid;
    return _locationMembersStream;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'Unexpected UserRepository call: ${invocation.memberName}',
    );
  }
}
