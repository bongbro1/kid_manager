import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/statical_utils.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';
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

  Future<void> migrateLegacyTimeRange(String userId) async {
    final appsSnap = await db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .get();

    for (final appDoc in appsSnap.docs) {
      final ruleRef = appDoc.reference.collection("usage_rule").doc("config");

      final ruleSnap = await ruleRef.get();
      if (!ruleSnap.exists) continue;

      final data = ruleSnap.data()!;
      final hasLegacy =
          data.containsKey("startMin") || data.containsKey("endMin");

      if (!hasLegacy) continue;

      await ruleRef.update({
        "startMin": FieldValue.delete(),
        "endMin": FieldValue.delete(),
      });
    }
  }

  Future<void> loadAndSeedAppToFirebase(String userId) async {
    final apps = await getInstalledApps();
    await seedApps(userId, apps);
    await syncTodayUsage(userId: userId);
  }

  /// 2. Seed apps lên Firestore

  Future<void> seedApps(String userId, List<AppInfo> apps) async {
    final col = db.collection("blocked_items").doc(userId).collection("apps");

    // 🔹 Apps đã tồn tại
    final existingSnap = await col.get();
    final existingPackages = existingSnap.docs.map((d) => d.id).toSet();

    // 🔹 Rules đã tồn tại
    final notExistingRules = <String>{};

    for (final doc in existingSnap.docs) {
      final ruleDoc = await doc.reference
          .collection("usage_rule")
          .doc("config")
          .get();

      if (!ruleDoc.exists) {
        notExistingRules.add(doc.id);
      }
    }
    WriteBatch batch = db.batch();
    int count = 0;

    for (final app in apps) {
      final pkg = app.packageName;
      if (pkg == null || pkg.isEmpty) continue;

      final isNewApp = !existingPackages.contains(pkg);
      final missingRule = notExistingRules.contains(pkg);

      // ⭐ Tạo rule cho app mới hoặc app thiếu rule
      if (isNewApp || missingRule) {
        await _createDefaultRule(
          batch: batch,
          userId: userId,
          packageName: pkg,
        );
        count++;
      }
      // 🔹 Bỏ qua nếu app đã tồn tại
      if (existingPackages.contains(pkg)) continue;

      batch.set(
        col.doc(pkg),
        appService.toBlockedAppJson(app),
        SetOptions(merge: true),
      );

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
  }

  Future<void> _createDefaultRule({
    required WriteBatch batch,
    required String userId,
    required String packageName,
  }) async {
    final ruleRef = db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .doc(packageName)
        .collection("usage_rule")
        .doc("config");

    final defaultRule = UsageRule.defaults();
    final today = DateTime.now().weekday;

    batch.set(ruleRef, {
      ...defaultRule.toMap(),
      "isDefault": true,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    final appRef = db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .doc(packageName);

    batch.set(appRef, {
      "dailyLimitMinutes": defaultRule.dailyLimitForWeekday(today),
    }, SetOptions(merge: true));
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
    final ruleRef = db
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .doc(packageName)
        .collection("usage_rule")
        .doc("config");

    final doc = await ruleRef.get();
    if (!doc.exists) return null;
    return UsageRule.fromMap(doc.data()!);
  }

  Future<void> syncTodayUsage({required String userId}) async {
    final day = DateTime.now();
    final start = startOfDay(day);
    final end = day;
    final key = dayKey(day);

    final stats = await UsageStats.queryUsageStats(start, end);

    final Map<String, int> usageMsByPkg = {};
    final Map<String, int> lastUsedByPkg = {};

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

    for (final doc in appsSnap.docs) {
      final pkg = doc.id;

      final usageMs = usageMsByPkg[pkg] ?? 0;
      final lastUsedMs = lastUsedByPkg[pkg] ?? 0;

      final dailyRef = doc.reference.collection('usage_daily').doc(key);

      /// 🔥 upgraded daily doc
      batch.set(dailyRef, {
        "userId": userId,
        "package": pkg,
        "dateKey": key,
        "date": Timestamp.fromDate(start),
        "usageMs": usageMs,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      /// app snapshot
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

  Future<UsageHistoryResult> loadUsageHistory(String userId) async {
    final totalResult = <DateTime, int>{};
    final perAppResult = <String, Map<DateTime, int>>{};

    try {
      final snapshot = await db
          .collection("blocked_items")
          .doc(userId)
          .collection("usage_daily_flat")
          .get();

      for (final doc in snapshot.docs) {
        try {
          final date = _parseLocalDate(doc.id);
          final data = doc.data();

          /// TOTAL
          final total = (data["totalMinutes"] ?? 0) as int;
          totalResult[date] = total;

          /// PER APP
          final apps = (data["apps"] ?? {}) as Map<String, dynamic>;

          apps.forEach((pkg, minutes) {
            perAppResult.putIfAbsent(pkg, () => {});
            perAppResult[pkg]![date] = minutes as int;
          });
        } catch (e) {
          debugPrint("⚠️ Skip invalid flat doc: ${doc.id}");
        }
      }

      // debugPrint(
      //   "📊 FLAT usage loaded: totalDays=${totalResult.length}, apps=${perAppResult.length}",
      // );
    } catch (e) {
      debugPrint("❌ loadUsageHistory ERROR: $e");
    }

    return UsageHistoryResult(
      totalUsage: totalResult,
      perAppUsage: perAppResult,
    );
  }

  Future<void> rebuildUsageDailyFlat(String userId) async {
    try {
      debugPrint("🔄 rebuildUsageDailyFlat START for $userId");

      final appsSnap = await db
          .collection("blocked_items")
          .doc(userId)
          .collection("apps")
          .get();

      final Map<String, Map<String, int>> dailyApps = {};
      final Map<String, int> dailyTotal = {};

      final chunks = chunkList(appsSnap.docs, 20);

      for (final batch in chunks) {
        final futures = batch.map(
          (appDoc) => appDoc.reference.collection("usage_daily").get(),
        );

        final results = await Future.wait(futures);

        for (final usageSnap in results) {
          for (final doc in usageSnap.docs) {
            final data = doc.data();

            final String? package = data["package"];
            final String? dateKey = data["dateKey"];
            final int usageMs = data["usageMs"] ?? 0;

            if (package == null || dateKey == null) continue;

            final minutes = (usageMs / 60000).round();
            if (minutes <= 0) continue;

            dailyApps.putIfAbsent(dateKey, () => {});
            dailyApps[dateKey]!.update(
              package,
              (v) => v + minutes,
              ifAbsent: () => minutes,
            );

            dailyTotal.update(
              dateKey,
              (v) => v + minutes,
              ifAbsent: () => minutes,
            );
          }
        }
      }

      final batchWrite = db.batch();
      final flatRef = db
          .collection("blocked_items")
          .doc(userId)
          .collection("usage_daily_flat");

      dailyApps.forEach((dateKey, apps) {
        batchWrite.set(flatRef.doc(dateKey), {
          "totalMinutes": dailyTotal[dateKey] ?? 0,
          "apps": apps,
          "updatedAt": FieldValue.serverTimestamp(),
        });
      });

      await batchWrite.commit();

      debugPrint("✅ rebuildUsageDailyFlat DONE (${dailyApps.length} days)");
    } catch (e) {
      debugPrint("❌ rebuildUsageDailyFlat ERROR: $e");
    }
  }

  List<List<T>> chunkList<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  DateTime _parseLocalDate(String id) {
    if (id.length != 8) {
      throw Exception("Invalid date id: $id");
    }

    final year = int.parse(id.substring(0, 4));
    final month = int.parse(id.substring(4, 6));
    final day = int.parse(id.substring(6, 8));

    return DateTime(year, month, day);
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