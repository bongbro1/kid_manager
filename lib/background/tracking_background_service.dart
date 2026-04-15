import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kid_manager/background/tracking_runtime_config.dart';
import 'package:kid_manager/background/tracking_runtime_store.dart';

class TrackingBackgroundService {
  TrackingBackgroundService._();

  static const MethodChannel _channel = MethodChannel('tracking_service');
  static Future<bool>? _startInFlight;
  static TrackingRuntimeConfig? _startInFlightConfig;
  static TrackingRuntimeConfig? _lastStartedConfig;
  static int _debugStartRequestCount = 0;
  static int _debugDedupedInFlightCount = 0;
  static int _debugDedupedRunningCount = 0;
  static int _debugNativeInvokeCount = 0;
  static int _debugStartSuccessCount = 0;
  static int _debugStartFailureCount = 0;

  static Future<bool> startForCurrentUser({
    required bool requireBackground,
    bool currentOnly = false,
    String? parentUid,
    String? familyId,
    String? displayName,
    String? timeZone,
  }) async {
    _debugStartRequestCount += 1;
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid.trim();
    if (userId == null || userId.isEmpty) {
      _debugStartFailureCount += 1;
      _debugLog('start skipped: missing auth user ${_debugStatsSummary()}');
      return false;
    }

    final existingConfig = await TrackingRuntimeStore.loadConfig();
    final preservedConfig =
        existingConfig != null && existingConfig.userId == userId
        ? existingConfig
        : null;

    final config = TrackingRuntimeConfig(
      userId: userId,
      enabled: true,
      requireBackground: requireBackground,
      currentOnly: currentOnly,
      parentUid: parentUid?.trim() ?? preservedConfig?.parentUid,
      familyId: familyId?.trim() ?? preservedConfig?.familyId,
      displayName: displayName?.trim() ?? preservedConfig?.displayName,
      timeZone: timeZone?.trim() ?? preservedConfig?.timeZone,
    );

    if (_startInFlight != null) {
      if (_isEquivalentConfig(_startInFlightConfig, config)) {
        _debugDedupedInFlightCount += 1;
        _debugLog('start deduped by in-flight config ${_debugStatsSummary()}');
        return _startInFlight!;
      }
      _debugLog('start waiting for in-flight config before retry');
      await _startInFlight;
      return startForCurrentUser(
        requireBackground: requireBackground,
        currentOnly: currentOnly,
        parentUid: parentUid,
        familyId: familyId,
        displayName: displayName,
        timeZone: timeZone,
      );
    }

    if (_isEquivalentConfig(_lastStartedConfig, config) && await isRunning()) {
      _debugDedupedRunningCount += 1;
      _debugLog('start skipped: already running with same config ${_debugStatsSummary()}');
      return true;
    }

    final startFuture = _startInternal(config);
    _startInFlight = startFuture;
    _startInFlightConfig = config;

    try {
      return await startFuture;
    } finally {
      if (identical(_startInFlight, startFuture)) {
        _startInFlight = null;
        _startInFlightConfig = null;
      }
    }
  }

  static Future<bool> _startInternal(TrackingRuntimeConfig config) async {
    await TrackingRuntimeStore.saveConfig(config);

    try {
      _debugNativeInvokeCount += 1;
      _debugLog(
        'native start invoke user=${config.userId} '
        'bg=${config.requireBackground} currentOnly=${config.currentOnly} '
        '${_debugStatsSummary()}',
      );
      final result = await _channel.invokeMethod<bool>('startTrackingService');
      final started = result ?? false;
      if (!started) {
        await TrackingRuntimeStore.clear();
        if (_isEquivalentConfig(_lastStartedConfig, config)) {
          _lastStartedConfig = null;
        }
        _debugStartFailureCount += 1;
        _debugLog('native start returned false ${_debugStatsSummary()}');
      } else {
        _lastStartedConfig = config;
        _debugStartSuccessCount += 1;
        _debugLog('native start success ${_debugStatsSummary()}');
      }
      return started;
    } on PlatformException catch (e) {
      debugPrint(
        'TrackingBackgroundService.start PlatformException: ${e.code} ${e.message}',
      );
      await TrackingRuntimeStore.clear();
      if (_isEquivalentConfig(_lastStartedConfig, config)) {
        _lastStartedConfig = null;
      }
      _debugStartFailureCount += 1;
      _debugLog('native start platform exception ${e.code} ${_debugStatsSummary()}');
      return false;
    } catch (e) {
      debugPrint('TrackingBackgroundService.start error: $e');
      await TrackingRuntimeStore.clear();
      if (_isEquivalentConfig(_lastStartedConfig, config)) {
        _lastStartedConfig = null;
      }
      _debugStartFailureCount += 1;
      _debugLog('native start exception $e ${_debugStatsSummary()}');
      return false;
    }
  }

  static Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 4),
    Duration pollInterval = const Duration(milliseconds: 250),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await TrackingRuntimeStore.isPublisherReady()) {
        return true;
      }
      await Future.delayed(pollInterval);
    }
    return TrackingRuntimeStore.isPublisherReady();
  }

  static Future<void> stop({bool clearConfig = true}) async {
    try {
      await _channel.invokeMethod<void>('stopTrackingService');
    } on PlatformException catch (e) {
      debugPrint(
        'TrackingBackgroundService.stop PlatformException: ${e.code} ${e.message}',
      );
    } catch (e) {
      debugPrint('TrackingBackgroundService.stop error: $e');
    } finally {
      _startInFlight = null;
      _startInFlightConfig = null;
      _lastStartedConfig = null;
      if (clearConfig) {
        await TrackingRuntimeStore.clear();
      }
    }
  }

  static Future<bool> isRunning() async {
    try {
      final result = await _channel.invokeMethod<bool>('isTrackingServiceRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint(
        'TrackingBackgroundService.isRunning PlatformException: ${e.code} ${e.message}',
      );
      return false;
    } catch (e) {
      debugPrint('TrackingBackgroundService.isRunning error: $e');
      return false;
    }
  }

  static bool _isEquivalentConfig(
    TrackingRuntimeConfig? left,
    TrackingRuntimeConfig? right,
  ) {
    if (left == null || right == null) {
      return false;
    }

    return left.userId == right.userId &&
        left.enabled == right.enabled &&
        left.requireBackground == right.requireBackground &&
        left.currentOnly == right.currentOnly &&
        _normalize(left.parentUid) == _normalize(right.parentUid) &&
        _normalize(left.familyId) == _normalize(right.familyId) &&
        _normalize(left.displayName) == _normalize(right.displayName) &&
        _normalize(left.timeZone) == _normalize(right.timeZone);
  }

  static String _normalize(String? value) => value?.trim() ?? '';

  static Map<String, int> debugStats() => <String, int>{
    'startRequests': _debugStartRequestCount,
    'dedupedInFlight': _debugDedupedInFlightCount,
    'dedupedRunning': _debugDedupedRunningCount,
    'nativeInvokes': _debugNativeInvokeCount,
    'startSuccess': _debugStartSuccessCount,
    'startFailure': _debugStartFailureCount,
  };

  static void debugResetStats() {
    _debugStartRequestCount = 0;
    _debugDedupedInFlightCount = 0;
    _debugDedupedRunningCount = 0;
    _debugNativeInvokeCount = 0;
    _debugStartSuccessCount = 0;
    _debugStartFailureCount = 0;
    _debugLog('debug stats reset');
  }

  static void _debugLog(String message) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[TrackingBackgroundService] $message');
  }

  static String _debugStatsSummary() {
    final stats = debugStats();
    return 'stats='
        'requests:${stats['startRequests']} '
        'dedupeInFlight:${stats['dedupedInFlight']} '
        'dedupeRunning:${stats['dedupedRunning']} '
        'native:${stats['nativeInvokes']} '
        'success:${stats['startSuccess']} '
        'failure:${stats['startFailure']}';
  }
}
