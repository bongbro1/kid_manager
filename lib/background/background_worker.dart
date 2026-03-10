import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/firebase_options.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';
import 'package:kid_manager/models/notifications/notification_payload.dart';
import 'package:kid_manager/models/notifications/removed_app_data.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/services/app_state_local_service.dart';
import 'package:kid_manager/services/notifications/notification_service.dart';
import 'package:kid_manager/services/storage_service.dart';
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

      final repo = await _buildRepository();
      final userRepo = _buildUserRepository();

      /// ================= CHILD =================
      if (role == "child" && task == syncAppsTask) {
        if (userId == null) return true;

        debugPrint("👶 Running child sync");
        await NotificationService.sendSystem(
              NotificationPayload(
                receiverId: userId,
                type: NotificationType.system,
                title: "Đã cập nhật dữ liệu sử dụng",
                body: "Hệ thống đã cập nhật dữ liệu sử dụng của: $userId lên cloud.",
                data: null,
              ),
            );

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
        final childrens = await userRepo.getChildUsers(userId);
        final storage = await StorageService.create();
        final localState = AppStateLocalService(storage);

        for (final child in childrens) {
          final apps = await repo.loadAppsFromFirestore(child.id);

          final alive = isAppAliveFromInstalled(packageName, apps);

          final appName = apps[packageName].name;

          final wasSent = localState.wasRemovalNotified(child.id, packageName);

          if (!alive && !wasSent) {
            final removedData = RemovedAppData(
              childId: child.id,
              childName: child.displayName,
              packageName: packageName,
              appName: appName,
              removedAt: DateFormat("HH:mm:ss").format(DateTime.now()),
            );

            await NotificationService.sendSystem(
              NotificationPayload(
                receiverId: userId,
                type: NotificationType.appRemoved,
                title: "Ứng dụng đã bị gỡ",
                body: "Thiết bị của con đã gỡ ứng dụng: $appName",
                data: removedData.toMap(),
              ),
            );

            await localState.markRemovalNotified(child.id, packageName);
          }

          if (alive && wasSent) {
            await localState.resetRemovalNotified(child.id, packageName);
          }
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

Future<AppManagementRepository> _buildRepository() async {
  final firestore = FirebaseFirestore.instance;

  final appService = AppInstalledService();
  final storageService = await StorageService.create(); // 🔥 quan trọng
  final usageService = UsageSyncService(firestore);

  return AppManagementRepository(
    appService,
    usageService,
    firestore,
    storageService,
  );
}
