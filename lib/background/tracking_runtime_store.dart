import 'package:kid_manager/background/tracking_runtime_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackingRuntimeStore {
  TrackingRuntimeStore._();

  static const prefsKeyEnabled = 'tracking.runtime.enabled';
  static const prefsKeyUserId = 'tracking.runtime.userId';
  static const prefsKeyRequireBackground = 'tracking.runtime.requireBackground';
  static const prefsKeyParentUid = 'tracking.runtime.parentUid';
  static const prefsKeyDisplayName = 'tracking.runtime.displayName';
  static const prefsKeyPublisherReady = 'tracking.runtime.publisherReady';

  static Future<void> saveConfig(TrackingRuntimeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKeyUserId, config.userId);
    await prefs.setBool(prefsKeyEnabled, config.enabled);
    await prefs.setBool(
      prefsKeyRequireBackground,
      config.requireBackground,
    );

    if (_hasText(config.parentUid)) {
      await prefs.setString(prefsKeyParentUid, config.parentUid!.trim());
    } else {
      await prefs.remove(prefsKeyParentUid);
    }

    if (_hasText(config.displayName)) {
      await prefs.setString(prefsKeyDisplayName, config.displayName!.trim());
    } else {
      await prefs.remove(prefsKeyDisplayName);
    }

    await prefs.setBool(prefsKeyPublisherReady, false);
  }

  static Future<TrackingRuntimeConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(prefsKeyUserId)?.trim();
    final enabled = prefs.getBool(prefsKeyEnabled) ?? false;
    final requireBackground =
        prefs.getBool(prefsKeyRequireBackground) ?? true;

    if (userId == null || userId.isEmpty) {
      return null;
    }

    return TrackingRuntimeConfig(
      userId: userId,
      enabled: enabled,
      requireBackground: requireBackground,
      parentUid: prefs.getString(prefsKeyParentUid)?.trim(),
      displayName: prefs.getString(prefsKeyDisplayName)?.trim(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKeyEnabled);
    await prefs.remove(prefsKeyUserId);
    await prefs.remove(prefsKeyRequireBackground);
    await prefs.remove(prefsKeyParentUid);
    await prefs.remove(prefsKeyDisplayName);
    await prefs.remove(prefsKeyPublisherReady);
  }

  static Future<void> setPublisherReady(bool ready) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefsKeyPublisherReady, ready);
  }

  static Future<bool> isPublisherReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefsKeyPublisherReady) ?? false;
  }

  static bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
}
