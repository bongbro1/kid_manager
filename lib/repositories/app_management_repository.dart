import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_format.dart';

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

    final apps = snapshot.docs
        .map((doc) => AppItemModel.fromFirestore(doc))
        .toList();

    // sort theo usageTime giảm dần (null coi như 0)
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
  Future<void> syncTodayUsage(String userId) {
    return usageService.syncTodayUsage(userId: userId);
  }
}
