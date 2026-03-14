import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/models/birthday_event.dart';
import 'package:kid_manager/utils/date_utils.dart';

class BirthdayRepository {
  BirthdayRepository(this._firestore, {FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;
  final Set<String> _syncAttemptedFamilies = <String>{};

  Future<List<BirthdayEvent>> getFamilyBirthdays({
    required String familyId,
  }) async {
    var membersSnapshot = await _loadFamilyMembers(familyId);

    if (membersSnapshot.docs.isEmpty) {
      return const <BirthdayEvent>[];
    }

    var birthdays = _mapBirthdays(
      familyId: familyId,
      memberDocs: membersSnapshot.docs,
    );

    if (_needsFamilySync(
      memberDocs: membersSnapshot.docs,
      birthdays: birthdays,
    )) {
      final didSync = await _syncFamilyMembersIfNeeded(familyId);
      if (didSync) {
        membersSnapshot = await _loadFamilyMembers(familyId);
        birthdays = _mapBirthdays(
          familyId: familyId,
          memberDocs: membersSnapshot.docs,
        );
      }
    }

    birthdays.sort((a, b) {
      final monthCompare = a.birthDate.month.compareTo(b.birthDate.month);
      if (monthCompare != 0) return monthCompare;

      final dayCompare = a.birthDate.day.compareTo(b.birthDate.day);
      if (dayCompare != 0) return dayCompare;

      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return birthdays;
  }

  Future<bool> syncFamilyMembers({
    required String familyId,
    bool force = false,
  }) async {
    if (force) {
      _syncAttemptedFamilies.remove(familyId);
    }
    return _syncFamilyMembersIfNeeded(familyId);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _loadFamilyMembers(
    String familyId,
  ) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();
  }

  List<BirthdayEvent> _mapBirthdays({
    required String familyId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> memberDocs,
  }) {
    final birthdays = <BirthdayEvent>[];

    for (final memberDoc in memberDocs) {
      final memberData = memberDoc.data();
      final birthDate =
          parseFlexibleBirthDate(memberData['dobIso']) ??
          parseFlexibleBirthDate(memberData['dob']);

      if (birthDate == null) continue;

      final displayName =
          (memberData['displayName'] ?? memberData['email'] ?? memberDoc.id)
              .toString()
              .trim();

      birthdays.add(
        BirthdayEvent(
          memberUid: memberDoc.id,
          familyId: familyId,
          displayName: displayName.isEmpty ? memberDoc.id : displayName,
          avatarUrl: (memberData['avatarUrl'] ?? '').toString(),
          role: (memberData['role'] ?? 'member').toString(),
          birthDate: birthDate,
        ),
      );
    }

    return birthdays;
  }

  bool _needsFamilySync({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> memberDocs,
    required List<BirthdayEvent> birthdays,
  }) {
    if (memberDocs.isEmpty) return false;

    if (birthdays.length < memberDocs.length) {
      return true;
    }

    return memberDocs.any((memberDoc) {
      final data = memberDoc.data();
      final displayName = (data['displayName'] ?? '').toString().trim();
      final dobIso = (data['dobIso'] ?? '').toString().trim();
      final birthDate =
          parseFlexibleBirthDate(data['dobIso']) ??
          parseFlexibleBirthDate(data['dob']);

      return displayName.isEmpty ||
          birthDate == null ||
          _hasLegacyBirthdayProjection(dobIso);
    });
  }

  bool _hasLegacyBirthdayProjection(String dobIso) {
    if (dobIso.isEmpty) return false;
    return dobIso.contains('T') || dobIso.endsWith('Z');
  }

  Future<bool> _syncFamilyMembersIfNeeded(String familyId) async {
    if (_syncAttemptedFamilies.contains(familyId)) {
      return false;
    }

    _syncAttemptedFamilies.add(familyId);

    try {
      await _functions.httpsCallable('syncFamilyMemberPublicData').call({
        'familyId': familyId,
      });
      return true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'not-found' ||
          e.code == 'permission-denied' ||
          e.code == 'unimplemented') {
        return false;
      }
      rethrow;
    } catch (_) {
      return false;
    }
  }
}
