import 'package:kid_manager/background/tracking_runtime_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrackingRuntimeStore {
  TrackingRuntimeStore._();

  static const prefsKeyEnabled = 'tracking.runtime.enabled';
  static const prefsKeyUserId = 'tracking.runtime.userId';
  static const prefsKeyRequireBackground = 'tracking.runtime.requireBackground';
  static const prefsKeyCurrentOnly = 'tracking.runtime.currentOnly';
  static const prefsKeyParentUid = 'tracking.runtime.parentUid';
  static const prefsKeyFamilyId = 'tracking.runtime.familyId';
  static const prefsKeyDisplayName = 'tracking.runtime.displayName';
  static const prefsKeyTimeZone = 'tracking.runtime.timeZone';
  static const prefsKeyPublisherReady = 'tracking.runtime.publisherReady';

  static Future<void> saveConfig(TrackingRuntimeConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKeyUserId, config.userId);
    await prefs.setBool(prefsKeyEnabled, config.enabled);
    await prefs.setBool(
      prefsKeyRequireBackground,
      config.requireBackground,
    );
    await prefs.setBool(prefsKeyCurrentOnly, config.currentOnly);

    if (_hasText(config.parentUid)) {
      await prefs.setString(prefsKeyParentUid, config.parentUid!.trim());
    } else {
      await prefs.remove(prefsKeyParentUid);
    }

    if (_hasText(config.familyId)) {
      await prefs.setString(prefsKeyFamilyId, config.familyId!.trim());
    } else {
      await prefs.remove(prefsKeyFamilyId);
    }

    if (_hasText(config.displayName)) {
      await prefs.setString(prefsKeyDisplayName, config.displayName!.trim());
    } else {
      await prefs.remove(prefsKeyDisplayName);
    }

    if (_hasText(config.timeZone)) {
      await prefs.setString(prefsKeyTimeZone, config.timeZone!.trim());
    } else {
      await prefs.remove(prefsKeyTimeZone);
    }

    await prefs.setBool(prefsKeyPublisherReady, false);
  }

  static Future<TrackingRuntimeConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(prefsKeyUserId)?.trim();
    final enabled = prefs.getBool(prefsKeyEnabled) ?? false;
    final requireBackground =
        prefs.getBool(prefsKeyRequireBackground) ?? true;
    final currentOnly = prefs.getBool(prefsKeyCurrentOnly) ?? false;

    if (userId == null || userId.isEmpty) {
      return null;
    }

    return TrackingRuntimeConfig(
      userId: userId,
      enabled: enabled,
      requireBackground: requireBackground,
      currentOnly: currentOnly,
      parentUid: prefs.getString(prefsKeyParentUid)?.trim(),
      familyId: prefs.getString(prefsKeyFamilyId)?.trim(),
      displayName: prefs.getString(prefsKeyDisplayName)?.trim(),
      timeZone: prefs.getString(prefsKeyTimeZone)?.trim(),
    );
  }

  static Future<void> saveRoutingContext(
    TrackingRoutingContext context,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKeyUserId, context.userId);

    if (_hasText(context.parentUid)) {
      await prefs.setString(prefsKeyParentUid, context.parentUid!.trim());
    } else {
      await prefs.remove(prefsKeyParentUid);
    }

    if (_hasText(context.familyId)) {
      await prefs.setString(prefsKeyFamilyId, context.familyId!.trim());
    } else {
      await prefs.remove(prefsKeyFamilyId);
    }

    if (_hasText(context.timeZone)) {
      await prefs.setString(prefsKeyTimeZone, context.timeZone!.trim());
    } else {
      await prefs.remove(prefsKeyTimeZone);
    }
  }

  static Future<TrackingRoutingContext?> loadRoutingContext(
    String userId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString(prefsKeyUserId)?.trim();
    if (storedUserId == null || storedUserId.isEmpty || storedUserId != userId) {
      return null;
    }

    final context = TrackingRoutingContext(
      userId: storedUserId,
      parentUid: prefs.getString(prefsKeyParentUid)?.trim(),
      familyId: prefs.getString(prefsKeyFamilyId)?.trim(),
      timeZone: prefs.getString(prefsKeyTimeZone)?.trim(),
    );
    return context.isComplete ? context : null;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKeyEnabled);
    await prefs.remove(prefsKeyUserId);
    await prefs.remove(prefsKeyRequireBackground);
    await prefs.remove(prefsKeyCurrentOnly);
    await prefs.remove(prefsKeyParentUid);
    await prefs.remove(prefsKeyFamilyId);
    await prefs.remove(prefsKeyDisplayName);
    await prefs.remove(prefsKeyTimeZone);
    await prefs.remove(prefsKeyPublisherReady);
  }

  static Future<void> syncTimeZone({
    required String userId,
    required String timeZone,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedTimeZone = timeZone.trim();
    if (normalizedUserId.isEmpty || normalizedTimeZone.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedUserId = prefs.getString(prefsKeyUserId)?.trim();
    if (storedUserId == null || storedUserId != normalizedUserId) {
      return;
    }

    await prefs.setString(prefsKeyTimeZone, normalizedTimeZone);
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
