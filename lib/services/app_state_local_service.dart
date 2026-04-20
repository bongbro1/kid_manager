import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/storage_service.dart';

class AppStateLocalService {
  final StorageService storage;

  AppStateLocalService(this.storage);

  bool wasRemovalNotified(String childId, String packageName) {
    final key = StorageKeys.appRemovedNotified(childId, packageName);
    return storage.getBool(key) ?? false;
  }

  Future<void> markRemovalNotified(String childId, String packageName) async {
    final key = StorageKeys.appRemovedNotified(childId, packageName);
    await storage.setBool(key, true);
  }

  Future<void> resetRemovalNotified(String childId, String packageName) async {
    final key = StorageKeys.appRemovedNotified(childId, packageName);
    await storage.remove(key);
  }
}
