import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
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

  /// 3. Sync usage
  // Future<void> syncTodayUsage(String userId) {
  //   return usageService.syncTodayUsage(userId: userId);
  // }
  Future<void> syncTodayUsage({required String userId}) async {
    final day = DateTime.now();
    final start = startOfDay(day);
    final end = day;

    final stats = await UsageStats.queryUsageStats(start, end);

    // aggregate per package
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
    final key = dayKey(day);

    for (final doc in appsSnap.docs) {
      final pkg = doc.id;

      final usageMs = usageMsByPkg[pkg] ?? 0;
      final lastUsedMs = lastUsedByPkg[pkg] ?? 0;

      // Nếu bạn muốn vẫn ghi 0 cho app không có usage hôm nay thì bỏ continue
      // if (usageMs == 0) continue;

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
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
