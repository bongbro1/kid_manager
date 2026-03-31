import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/statical_utils.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

import '../services/app_installed_service.dart';

class AppManagementRepository {
  final AppInstalledService appService;
  final FirebaseFirestore db;
  final StorageService _storage;

  AppManagementRepository(
    this.appService,
    this.db,
    this._storage,
  );

  /// 1. Lấy app đã cài (DATA THÔ) (chỉ lấy ở account child)
  Future<List<AppInfo>> getInstalledApps() {
    return appService.getUserInstalledApps(withIcon: true);
  }

  DocumentReference<Map<String, dynamic>> _blockedItemsUserRef(String userId) {
    final normalizedUid = userId.trim();
    if (normalizedUid.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'userId is required');
    }
    return db.collection("blocked_items").doc(normalizedUid);
  }

  CollectionReference<Map<String, dynamic>> _blockedItemsAppsRef(String userId) {
    return _blockedItemsUserRef(userId).collection("apps");
  }

  Future<List<AppItemModel>> loadAppsFromFirestore(String userId) async {
    final snapshot = await _blockedItemsAppsRef(userId).get();

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
    final appsSnap = await _blockedItemsAppsRef(userId).get();

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
    final remoteApps = await loadAppsFromFirestore(userId);

    final localPackages = apps.map((e) => e.packageName).toSet();
    final remotePackages = remoteApps.map((e) => e.packageName).toSet();

    final missingOnServer = localPackages.difference(remotePackages);

    if (missingOnServer.isNotEmpty) {
      // debugPrint("🔥 Firestore missing apps → reseed");

      await seedApps(userId, apps);
    } else {
      // debugPrint("⚡ Server already synced");
    }
  }

  Future<void> seedApps(String userId, List<AppInfo> apps) async {
    final col = _blockedItemsAppsRef(userId);

    final existingSnap = await col.get();
    final existingPackages = existingSnap.docs.map((d) => d.id).toSet();

    WriteBatch batch = db.batch();
    int count = 0;

    final today = DateTime.now().weekday;
    final defaultRule = UsageRule.defaults();

    for (final app in apps) {
      final pkg = app.packageName;
      if (pkg == null || pkg.isEmpty) continue;

      final docRef = col.doc(pkg);

      // ✅ Nếu là app mới thì tạo document
      if (!existingPackages.contains(pkg)) {
        batch.set(
          docRef,
          appService.toBlockedAppJson(app),
          SetOptions(merge: true),
        );
        count++;
      }

      // ✅ Luôn đảm bảo rule tồn tại (merge an toàn)
      _createDefaultRule(
        batch: batch,
        docRef: docRef,
        defaultRule: defaultRule,
        today: today,
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

  void _createDefaultRule({
    required WriteBatch batch,
    required DocumentReference docRef,
    required UsageRule defaultRule,
    required int today,
  }) {
    final ruleRef = docRef.collection("usage_rule").doc("config");

    batch.set(ruleRef, {
      ...defaultRule.toMap(),
      "isDefault": true,
      "updatedAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    batch.set(docRef, {
      "dailyLimitMinutes": defaultRule.dailyLimitForWeekday(today),
    }, SetOptions(merge: true));
  }

  Future<void> saveUsageRuleForApp({
    required String userId,
    required String packageName,
    required UsageRule rule,
  }) async {
    final today = DateTime.now().weekday;
    final appRef = _blockedItemsAppsRef(userId).doc(packageName);

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
    final ruleRef = _blockedItemsAppsRef(userId)
        .doc(packageName)
        .collection("usage_rule")
        .doc("config");

    final doc = await ruleRef.get();
    if (!doc.exists) return null;
    return UsageRule.fromMap(doc.data()!);
  }

  Future<UsageHistoryResult> loadUsageHistory(String userId) async {
    final totalResult = <DateTime, int>{};
    final perAppResult = <String, Map<DateTime, int>>{};
    final hourlyResult = <DateTime, Map<int, int>>{};

    try {
      final userRef = _blockedItemsUserRef(userId);

      /// -------- DAILY USAGE --------
      final dailySnapshot = await userRef.collection("usage_daily_flat").get();

      for (final doc in dailySnapshot.docs) {
        try {
          final date = _parseLocalDate(doc.id);
          final data = doc.data();

          debugPrint("DOC ID: ${doc.id} -> PARSED DATE: $date");

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

      /// -------- HOURLY USAGE --------
      final hourlySnapshot = await userRef.collection("usage_hourly").get();

      for (final doc in hourlySnapshot.docs) {
        try {
          final date = _parseLocalDate(doc.id);
          final data = doc.data();

          final hourMap = <int, int>{};
          final nestedHours = data["hours"];

          if (nestedHours is Map) {
            nestedHours.forEach((key, value) {
              final hour = int.tryParse(key.toString());

              if (hour != null) {
                hourMap[hour] = (value as num?)?.toInt() ?? 0;
              }
            });
          } else {
            // Backward compatibility for old flattened keys: "hours.9"
            data.forEach((key, value) {
              if (key.startsWith("hours.")) {
                final hourStr = key.substring(6);
                final hour = int.tryParse(hourStr);

                if (hour != null) {
                  hourMap[hour] = (value as num?)?.toInt() ?? 0;
                }
              }
            });
          }

          hourlyResult[date] = hourMap;
        } catch (e) {
          debugPrint("⚠️ Skip invalid hourly doc: ${doc.id}");
        }
      }
    } catch (e) {
      debugPrint("❌ loadUsageHistory ERROR: $e");
    }

    return UsageHistoryResult(
      totalUsage: totalResult,
      perAppUsage: perAppResult,
      hourlyUsage: hourlyResult,
    );
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
//    user123
//       todayTotalUsageMs
//       lastHeartbeat

//       apps
//          com.youtube.android
//             todayUsageMs
//             lastSeen
//             todayLastSeen

//             usage_daily
//                20260313

//       usage_daily_flat
//          20260313

//       usage_hourly
//          20260313
//             hours:
//                9: 12
//                10: 25
//                11: 3
