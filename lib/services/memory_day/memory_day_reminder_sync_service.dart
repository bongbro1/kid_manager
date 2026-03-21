import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../models/memory_day.dart';
import '../../repositories/user_repository.dart';

class MemoryDayReminderSyncService {
  MemoryDayReminderSyncService(this._firestore, this._userRepository);

  final FirebaseFirestore _firestore;
  final UserRepository _userRepository;

  CollectionReference<Map<String, dynamic>> _metaCollection(
    String ownerParentUid,
  ) {
    // Phase 2: Reminder meta is stored under the same parent-owned namespace
    // used by Schedule/Memory Day, including guardian flows.
    return _firestore
        .collection('parents')
        .doc(ownerParentUid)
        .collection('memoryReminderMeta');
  }

  Future<void> syncMemoryDay({
    required String ownerParentUid,
    required MemoryDay memory,
    String? actorUid,
  }) async {
    final reminderOffsets = _normalizeReminderOffsets(memory.reminderOffsets);
    final docRef = _metaCollection(ownerParentUid).doc(memory.id);

    if (memory.id.trim().isEmpty) {
      throw Exception('MemoryDay id is required for reminder sync');
    }

    if (reminderOffsets.isEmpty) {
      await _safeDelete(docRef);
      return;
    }

    final familyId = await _resolveFamilyId(
      ownerParentUid: ownerParentUid,
      actorUid: actorUid,
    );
    if (familyId == null || familyId.isEmpty) {
      throw Exception(
        'Family id not found for ownerParentUid=$ownerParentUid actorUid=$actorUid',
      );
    }

    final now = Timestamp.fromDate(DateTime.now());
    await docRef.set({
      'memoryDayId': memory.id,
      'ownerParentUid': ownerParentUid,
      'familyId': familyId,
      'title': memory.title,
      'note': memory.note,
      'date': Timestamp.fromDate(memory.date),
      'year': memory.date.year,
      'month': memory.month,
      'day': memory.day,
      'repeatYearly': memory.repeatYearly,
      'reminderOffsets': reminderOffsets,
      'createdAt': memory.createdAt == null
          ? now
          : Timestamp.fromDate(memory.createdAt!),
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  Future<void> deleteMemoryDay({
    required String ownerParentUid,
    required String memoryDayId,
  }) async {
    if (memoryDayId.trim().isEmpty) return;
    await _safeDelete(_metaCollection(ownerParentUid).doc(memoryDayId));
  }

  Future<String?> _resolveFamilyId({
    required String ownerParentUid,
    String? actorUid,
  }) async {
    final candidates = <String>[
      if (actorUid != null && actorUid.trim().isNotEmpty) actorUid.trim(),
      ownerParentUid,
    ];

    for (final candidateUid in candidates) {
      final user = await _userRepository.getUserById(candidateUid);
      final familyId = user?.familyId?.trim();

      if (familyId != null && familyId.isNotEmpty) {
        return familyId;
      }
    }

    return null;
  }

  Future<void> _safeDelete(
    DocumentReference<Map<String, dynamic>> docRef,
  ) async {
    try {
      await docRef.delete();
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') {
        rethrow;
      }
      debugPrint('[MEMORY_DAY_REMINDER_SYNC] delete skipped ${docRef.path}');
    }
  }

  List<int> _normalizeReminderOffsets(List<int> offsets) {
    final values =
        offsets
            .where((value) => value == 1 || value == 3 || value == 7)
            .toSet()
            .toList()
          ..sort();
    return values;
  }
}
