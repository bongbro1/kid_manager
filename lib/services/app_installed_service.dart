import 'dart:convert';

import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class AppInstalledService {
  /// Lấy app user cài (lọc system + app không launch được)
  Future<List<AppInfo>> getUserInstalledApps({bool withIcon = true}) async {
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false, // ✅ bỏ system app
      excludeNonLaunchableApps: true, // ✅ chỉ lấy app mở được
      withIcon: withIcon, // icon là Uint8List? (nặng nếu nhiều app)
    );

    // Nếu muốn chắc chắn: filter thêm lần nữa theo flag từ model
    // final filtered = apps
    //     .where((a) => a.isSystemApp == false && a.isLaunchableApp == true)
    //     .toList();

    // Sort theo tên
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return apps;
  }

  Map<String, dynamic> toBlockedAppJson(AppInfo a) {
    final iconBytes = a.icon; // Uint8List? (có khi null nếu withIcon:false)

    return {
      "allowed": false,
      "iconBase64": iconBytes == null ? "" : base64Encode(iconBytes),
      "name": a.name,
      "packageName": a.packageName,
      "usageTime": "0h 0m",
      "lastSeen": null,
    };
  }

  
}
