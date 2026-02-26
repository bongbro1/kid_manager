import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:usage_stats/usage_stats.dart';

class UsageSyncService {
  final FirebaseFirestore _db;
  UsageSyncService(this._db);


  /// Sync usage hôm nay cho tất cả app
  // Future<void> syncTodayUsage({required String userId}) async {
  //   debugPrint("======== DEBUG ===========");

  //   final now = DateTime.now();
  //   final start = DateTime(now.year, now.month, now.day, 0, 0, 0);

  //   // Query usage stats (cần Usage Access)
  //   final stats = await UsageStats.queryUsageStats(start, now);

  //   // Map packageName -> usage info
  //   final Map<String, UsageInfo> map = {
  //     for (final s in stats) s.packageName ?? "": s,
  //   };

  //   // Lấy list apps đã seed trong firestore
  //   final appsSnap = await _db
  //       .collection("blocked_items")
  //       .doc(userId)
  //       .collection("apps")
  //       .get();

  //   final batch = _db.batch();
  //   for (final doc in appsSnap.docs) {
  //     final pkg = doc.id;
  //     final usage = map[pkg];
  //     if (usage == null) continue;

  //     debugPrint(
  //       "pkg=$pkg total=${usage.totalTimeInForeground} last=${usage.lastTimeUsed}",
  //     );

  //     final totalTimeMs = int.tryParse(usage.totalTimeInForeground ?? "0") ?? 0;
  //     final lastTimeUsedMs = int.tryParse(usage.lastTimeUsed ?? "0") ?? 0;

  //     batch.set(doc.reference, {
  //       "usageTime": _formatDuration(totalTimeMs),
  //       "lastSeen": lastTimeUsedMs > 0
  //           ? Timestamp.fromMillisecondsSinceEpoch(lastTimeUsedMs)
  //           : null,
  //     }, SetOptions(merge: true));
  //   }

  //   await batch.commit();
  // }


  // Future<void> ensureUsageRange({
  //   required String userId,
  //   required String packageName,
  //   required DateTime startDay,
  //   required DateTime endDayInclusive,
  // }) async {
  //   final appRef = _db
  //       .collection("blocked_items")
  //       .doc(userId)
  //       .collection("apps")
  //       .doc(packageName);

  //   // Lấy daily docs trong range
  //   final q = await appRef
  //       .collection('usage_daily')
  //       .where(
  //         'date',
  //         isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay(startDay)),
  //       )
  //       .where(
  //         'date',
  //         isLessThanOrEqualTo: Timestamp.fromDate(startOfDay(endDayInclusive)),
  //       )
  //       .get();

  //   final existing = <String>{for (final d in q.docs) d.id};

  //   // Loop các ngày, thiếu thì sync
  //   for (
  //     DateTime d = startOfDay(startDay);
  //     !d.isAfter(startOfDay(endDayInclusive));
  //     d = d.add(const Duration(days: 1))
  //   ) {
  //     final k = dayKey(d);
  //     if (!existing.contains(k)) {
  //       await syncUsageForDay(userId: userId, day: d); // sync cho tất cả apps
  //     }
  //   }
  // }

  // // để tạm
  // Future<List<Map<String, dynamic>>> loadDailySeries({
  //   required String userId,
  //   required String packageName,
  //   required DateTime startDay,
  //   required DateTime endDayInclusive,
  // }) async {
  //   final appRef = _db
  //       .collection("blocked_items")
  //       .doc(userId)
  //       .collection("apps")
  //       .doc(packageName);

  //   final snap = await appRef
  //       .collection('usage_daily')
  //       .where(
  //         'date',
  //         isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay(startDay)),
  //       )
  //       .where(
  //         'date',
  //         isLessThan: Timestamp.fromDate(endOfDayExclusive(endDayInclusive)),
  //       )
  //       .orderBy('date')
  //       .get();

  //   return snap.docs.map((d) => d.data()).toList();
  // }

  // // convert series -> list usageMs theo từng ngày (đảm bảo đủ ngày, thiếu thì 0)
  // List<int> buildDailyMsList(
  //   DateTime startDay,
  //   DateTime endDay,
  //   List<Map<String, dynamic>> series,
  // ) {
  //   final map = <String, int>{};
  //   for (final item in series) {
  //     final ts = item['date'] as Timestamp;
  //     final d = ts.toDate();
  //     map[dayKey(d)] = (item['usageMs'] ?? 0) as int;
  //   }

  //   final out = <int>[];
  //   for (
  //     DateTime d = startOfDay(startDay);
  //     !d.isAfter(startOfDay(endDay));
  //     d = d.add(const Duration(days: 1))
  //   ) {
  //     out.add(map[dayKey(d)] ?? 0);
  //   }
  //   return out;
  // }
}
