import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/usage_rule.dart';
import 'package:usage_stats/usage_stats.dart';

import '../services/app_installed_service.dart';
import '../services/usage_sync_service.dart';

class AppManagementRepository {
  final AppInstalledService appService;
  final UsageSyncService usageService;
  final FirebaseFirestore db;

  AppManagementRepository(this.appService, this.usageService, this.db);

  /// 1. Lấy app đã cài (DATA THÔ) (chỉ lấy ở account child)
  Future<List<AppInfo>> getInstalledApps() {
    return appService.getUserInstalledApps(withIcon: true);
  }

  Future<List<AppItemModel>> loadAppsFromFirestore(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    final snapshot = await db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .get();

    final List<AppItemModel> apps = [];

    for (final doc in snapshot.docs) {
      final base = AppItemModel.fromFirestore(doc);
      final data = doc.data();
      final todayUsageMs = (data["todayUsageMs"] ?? 0) as int;
      apps.add(base.copyWith(usageTime: formatDuration(todayUsageMs)));
    }

    apps.sort((a, b) {
      final aMin = parseUsageTimeToMinutes(a.usageTime);
      final bMin = parseUsageTimeToMinutes(b.usageTime);
      return bMin.compareTo(aMin);
    });

    return apps;
  }

  Future<void> loadAndSeedAppToFirebase(String userId) async {
    final apps = await getInstalledApps();
    await seedApps(userId, apps);
    await syncTodayUsage(userId: userId);
  }

  /// 2. Seed apps lên Firestore

  Future<void> seedApps(String userId, List<AppInfo> apps) async {
    final col = db.collection("blocked_items").doc(userId).collection("apps");

    // 🔹 Lấy các package đã có trên Firestore
    final existingSnap = await col.get();

    final existingPackages = existingSnap.docs.map((d) => d.id).toSet();

    // debugPrint("📦 Existing apps on Firestore: ${existingPackages.length}");

    WriteBatch batch = db.batch();
    int count = 0;
    // int added = 0;

    for (final app in apps) {
      final pkg = app.packageName;
      if (pkg == null || pkg.isEmpty) continue;

      // 🔥 BỎ QUA nếu đã tồn tại
      if (existingPackages.contains(pkg)) continue;

      batch.set(
        col.doc(pkg),
        appService.toBlockedAppJson(app),
        SetOptions(merge: true),
      );

      // added++;
      count++;

      if (count >= 400) {
        await batch.commit();
        batch = db.batch();
        count = 0;
      }
    }

    if (count > 0) {
      await batch.commit();
    }

    // debugPrint("✅ New apps seeded: $added");
  }

  Future<void> saveUsageRuleForApp({
    required String userId,
    required String packageName,
    required UsageRule rule,
  }) async {
    final today = DateTime.now().weekday;
    final appRef = db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .doc(packageName);

    final ruleRef = appRef.collection("usage_rule").doc("config");

    // 1. Lưu rule
    await ruleRef.set({
      ...rule.toMap(),
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 2. Lưu dailyLimitMinutes để dùng cho progress
    await appRef.set({
      "dailyLimitMinutes": rule.dailyLimitForWeekday(today),
    }, SetOptions(merge: true));
  }

  Future<UsageRule?> fetchUsageRule({
    required String userId,
    required String packageName,
  }) async {
    final doc = await db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .doc(packageName)
        .collection("usage_rule")
        .doc("config")
        .get();

    if (!doc.exists) return null;

    return UsageRule.fromMap(doc.data()!);
  }

  Future<void> syncTodayUsage({required String userId}) async {
    final day = DateTime.now();
    final start = startOfDay(day);
    final end = day;

    final stats = await UsageStats.queryUsageStats(start, end);

    // const target = 'com.example.kid_manager';

    // debugPrint('--- RANGE ---');
    // debugPrint('start=$start  (${start.millisecondsSinceEpoch})');
    // debugPrint('end  =$end    (${end.millisecondsSinceEpoch})');
    // debugPrint('diffHours=${end.difference(start).inMinutes / 60}');

    // final rows = stats.where((e) => e.packageName == target).toList();
    // debugPrint('--- $target rows=${rows.length} ---');

    // for (final r in rows) {
    //   debugPrint(
    //     'pkg=${r.packageName} '
    //     'totalFG=${r.totalTimeInForeground} '
    //     'lastUsed=${r.lastTimeUsed} '
    //     'first=${r.firstTimeStamp} '
    //     'last=${r.lastTimeStamp}',
    //   );
    // }

    // aggregate per package
    final Map<String, int> usageMsByPkg = {};
    final Map<String, int> lastUsedByPkg = {};
    const selfPkg = 'com.example.kid_manager';

    for (final s in stats) {
      final pkg = s.packageName;
      if (pkg == null || pkg.isEmpty) continue;

      final ms = int.tryParse(s.totalTimeInForeground ?? '') ?? 0;
      final last = int.tryParse(s.lastTimeUsed ?? '') ?? 0;

      usageMsByPkg[pkg] = (usageMsByPkg[pkg] ?? 0) + ms;
      if (last > (lastUsedByPkg[pkg] ?? 0)) {
        lastUsedByPkg[pkg] = last;
      }
    }

    final appsSnap = await db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .get();

    final batch = db.batch();
    final key = dayKey(day);
    for (final doc in appsSnap.docs) {
      final pkg = doc.id;

      final usageMs = usageMsByPkg[pkg] ?? 0;
      final lastUsedMs = lastUsedByPkg[pkg] ?? 0;

      final dailyRef = doc.reference.collection('usage_daily').doc(key);

      batch.set(dailyRef, {
        "date": Timestamp.fromDate(start),
        "usageMs": usageMs,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      batch.set(doc.reference, {
        "todayUsageMs": usageMs,
        "todayLastSeen": lastUsedMs > 0
            ? Timestamp.fromMillisecondsSinceEpoch(lastUsedMs)
            : null,
        "lastSeen": lastUsedMs > 0
            ? Timestamp.fromMillisecondsSinceEpoch(lastUsedMs)
            : null,
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<Map<DateTime, int>> loadUsageHistory(String userId) async {
    final Map<DateTime, int> result = {};

    try {
      debugPrint("📥 loadUsageHistory START for child = $userId");

      final appsSnapshot = await db
          .collection("blocked_items")
          .doc(userId)
          .collection("apps")
          .get();

      for (final appDoc in appsSnapshot.docs) {
        final usageSnapshot = await appDoc.reference
            .collection("usage_daily")
            .get();

        for (final doc in usageSnapshot.docs) {
          final date = DateTime.parse(doc.id);

          final usageMs = (doc.data()["usageMs"] ?? 0) as int;
          final minutes = (usageMs / 60000).round();

          result.update(
            date,
            (value) => value + minutes,
            ifAbsent: () => minutes,
          );
        }
      }

      debugPrint("📊 Usage map loaded: ${result.length} days");
    } catch (e) {
      debugPrint("❌ loadUsageHistory ERROR: $e");
    }

    return result;
  }
}


// blocked_items
//  └── userId
//      └── apps
//          └── com.facebook.katana
//              ├── usage_daily
//              │    └── 2026-02-27
//              │         ├── usageMs
//              │         └── lastUsedMs
//              │
//              └── usage_rule
//                        ├── enabled: true
//                        ├── startMin: 480
//                        ├── endMin: 1200
//                        ├── weekdays: [1..7]
//                        ├── overrides:
//                        │     2026-02-05: allowFullDay
//                        │     2026-02-13: blockFullDay
//                        └── updatedAt



// I/flutter (12971): 📊 Usage map loaded: 4 days
// I/flutter (12971): 📊 RAW usageMap from repo:
// I/flutter (12971):   2026-02-25T00:00:00.000 -> 323 min
// I/flutter (12971):   2026-02-26T00:00:00.000 -> 477 min
// I/flutter (12971):   2026-02-27T00:00:00.000 -> 635 min
// I/flutter (12971):   2026-02-28T00:00:00.000 -> 264 min
// I/flutter (12971): ✅ usageMap assigned to VM:
// I/flutter (12971):   2026-02-25T00:00:00.000 -> 323 min
// I/flutter (12971):   2026-02-26T00:00:00.000 -> 477 min
// I/flutter (12971):   2026-02-27T00:00:00.000 -> 635 min
// I/flutter (12971):   2026-02-28T00:00:00.000 -> 264 min
// I/flutter (12971): 📤 loadUsageHistory END
// I/flutter (12971): 📊 Usage map loaded: 4 days
// I/flutter (12971): 📊 RAW usageMap from repo:
// I/flutter (12971):   2026-02-25T00:00:00.000 -> 323 min
// I/flutter (12971):   2026-02-26T00:00:00.000 -> 477 min
// I/flutter (12971):   2026-02-27T00:00:00.000 -> 635 min
// I/flutter (12971):   2026-02-28T00:00:00.000 -> 264 min
// I/flutter (12971): ✅ usageMap assigned to VM:
// I/flutter (12971):   2026-02-25T00:00:00.000 -> 323 min
// I/flutter (12971):   2026-02-26T00:00:00.000 -> 477 min
// I/flutter (12971):   2026-02-27T00:00:00.000 -> 635 min
// I/flutter (12971):   2026-02-28T00:00:00.000 -> 264 min
// I/flutter (12971): 📤 loadUsageHistory END