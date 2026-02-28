import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/firebase_options.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:workmanager/workmanager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/app_installed_service.dart';
import '../services/usage_sync_service.dart';
import '../repositories/app_management_repository.dart';

const syncAppsTask = "syncAppsTask";
const deviceHeartbeatTask = "deviceHeartbeatTask";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final role = inputData?['role'];
      final userId = inputData?['userId'];
      final packageName = inputData?['packageName'];

      debugPrint("🧩 Worker role: $role");
      debugPrint("📌 Worker Task: $task");
      debugPrint("📌 Worker UserId: $userId");

      final repo = _buildRepository();
      final userRepo = _buildUserRepository();

      /// ================= CHILD =================
      if (role == "child" && task == syncAppsTask) {
        if (userId == null) return true;

        debugPrint("👶 Running child sync");
        await repo.syncTodayUsage(userId: userId);

        return true;
      }

      /// ================= PARENT =================
      if (role == "parent" && task == deviceHeartbeatTask) {
        if (packageName == null || userId == null) {
          debugPrint("❌ Heartbeat missing data");
          return true;
        }

        debugPrint("👨‍👩‍👧 Running parent heartbeat");

        // 🔹 Lấy danh sách child
        final childIds = await userRepo.getChildUserIds(userId);

        for (final childId in childIds) {
          final apps = await repo.loadAppsFromFirestore(childId);

          final alive = await isAppAliveFromInstalled(packageName, apps);

          debugPrint("💓 Heartbeat check for child: $childId");
          debugPrint("📦 package: $packageName");
          debugPrint(alive ? "✅ App still installed" : "🪦 App removed");
        }
        return true;
      }

      /// Skip nếu không đúng role
      debugPrint("⏭ Skipped due to role mismatch");

      return true;
    } catch (e, s) {
      debugPrint("🚨Worker error: $e");
      debugPrint("$s");
      return false;
    }
  });
}

bool isAppAliveFromInstalled(
  String packageName,
  List<AppItemModel> installedApps,
) {
  final now = DateTime.now();

  for (final app in installedApps) {
    if (app.packageName == packageName) {
      final lastSeen = app.lastSeen?.toDate();
      if (lastSeen == null) return false;

      return now.difference(lastSeen) <= const Duration(hours: 1);
    }
  }

  return false;
}

UserRepository _buildUserRepository() {
  final firestore = FirebaseFirestore.instance;
  return UserRepository.background(firestore);
}

AppManagementRepository _buildRepository() {
  final firestore = FirebaseFirestore.instance;

  final appService = AppInstalledService();
  final usageService = UsageSyncService(firestore);

  return AppManagementRepository(appService, usageService, firestore);
}
