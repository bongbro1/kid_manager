import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/user/user_profile_patch.dart';
import 'package:kid_manager/models/user/user_profile.dart';
import 'package:kid_manager/models/user/user_subscription.dart';
import 'package:kid_manager/models/user/user_types.dart';

void main() {
  group('SubscriptionInfo serialization', () {
    test('toMap keeps Firestore wire values', () {
      final now = DateTime(2026, 3, 23, 10, 0);
      final endAt = now.add(const Duration(days: 30));
      final subscription = SubscriptionInfo(
        plan: SubscriptionPlan.pro,
        status: SubscriptionStatus.trial,
        startAt: now,
        endAt: endAt,
        isTrial: true,
        autoRenew: false,
        productId: 'pro_monthly',
        platform: 'android',
      );

      final map = subscription.toMap();

      expect(map['plan'], 'pro');
      expect(map['status'], 'trial');
      expect(map['startAt'], isA<Timestamp>());
      expect(map['endAt'], isA<Timestamp>());
      expect(map['isTrial'], isTrue);
      expect(map['autoRenew'], isFalse);
      expect(map['productId'], 'pro_monthly');
      expect(map['platform'], 'android');
      expect(map['updatedAt'], isNotNull);
    });

    test('fromMap parses enums and effective plan fallback', () {
      final now = DateTime.now();
      final expired = SubscriptionInfo.fromMap({
        'plan': 'pro',
        'status': 'expired',
        'endAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
      });

      expect(expired.plan, SubscriptionPlan.pro);
      expect(expired.status, SubscriptionStatus.expired);
      expect(expired.isActiveNow, isFalse);
      expect(expired.effectivePlan, SubscriptionPlan.free);
    });
  });

  group('UserProfile serialization', () {
    test('fromMap parses role and legacy managed child ids', () {
      final profile = UserProfile.fromMap('guardian-1', {
        'displayName': 'Guardian',
        'phone': '0123',
        'gender': 'Nữ',
        'dobIso': '2010-03-23',
        'address': 'HN',
        'allowTracking': true,
        'role': 'guardian',
        'assignedChildIds': ['child-1', 'child-2'],
      });

      expect(profile.role, UserRole.guardian);
      expect(profile.managedChildIds, ['child-1', 'child-2']);
      expect(profile.roleKey, 'guardian');
    });

    test(
      'patch toMap omits role when not provided for partial update safety',
      () {
        const patch = UserProfilePatch(
          name: 'Parent',
          phone: '0123',
          gender: 'Nam',
          dob: '23/03/2000',
          address: 'HN',
          allowTracking: true,
        );

        final map = patch.toMap();

        expect(map.containsKey('role'), isFalse);
        expect(map['displayName'], 'Parent');
      },
    );
  });

  group('AppUser member parsing', () {
    test('fromMap parses denormalized member fields for guardian docs', () {
      final lastActiveAt = DateTime(2026, 3, 25, 9, 15);
      final user = AppUser.fromMap({
        'role': 'guardian',
        'familyId': 'family-1',
        'email': 'guardian@example.com',
        'displayName': 'Guardian',
        'avatarUrl': 'https://example.com/avatar.jpg',
        'parentUid': 'parent-1',
        'isActive': true,
        'allowTracking': true,
        'managedChildIds': ['child-1', 'child-2', 'child-1'],
        'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      }, docId: 'guardian-1');

      expect(user.uid, 'guardian-1');
      expect(user.role, UserRole.guardian);
      expect(user.familyId, 'family-1');
      expect(user.email, 'guardian@example.com');
      expect(user.parentUid, 'parent-1');
      expect(user.isActive, isTrue);
      expect(user.allowTracking, isTrue);
      expect(user.lastActiveAt, lastActiveAt);
      expect(user.managedChildIds, ['child-1', 'child-2']);
    });

    test(
      'fromMap keeps legacy child docs visible on location when allowTracking is missing',
      () {
        final user = AppUser.fromMap({
          'role': 'child',
          'familyId': 'family-1',
          'parentUid': 'parent-1',
          'displayName': 'Child',
        }, docId: 'child-1');

        expect(user.uid, 'child-1');
        expect(user.role, UserRole.child);
        expect(user.allowTracking, isTrue);
      },
    );
  });
}
