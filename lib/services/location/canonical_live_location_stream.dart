import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kid_manager/core/async/polling_backoff.dart';

typedef CanonicalLiveLocationParser<T> = T? Function(dynamic raw);
typedef CanonicalLiveLocationPoller = Future<dynamic> Function();
typedef CanonicalLiveLocationErrorHandler =
    void Function(Object error, StackTrace stackTrace);

Stream<T> streamCanonicalLiveLocation<T>({
  required DatabaseReference reference,
  required CanonicalLiveLocationPoller pollCanonicalSnapshot,
  required CanonicalLiveLocationParser<T> parseSnapshot,
  required Duration pollingInterval,
  Duration maxPollingInterval = const Duration(seconds: 30),
  Duration realtimeRetryInterval = const Duration(minutes: 1),
  bool enableRealtime = true,
  bool usePollingBackoff = true,
  CanonicalLiveLocationErrorHandler? onRealtimeError,
  CanonicalLiveLocationErrorHandler? onPollingError,
  bool forwardPollingErrorsToStream = true,
}) {
  final controller = StreamController<T>();
  StreamSubscription<DatabaseEvent>? realtimeSub;
  Timer? pollTimer;
  Timer? realtimeRetryTimer;
  var fallbackStarted = false;
  var fixedPollingAttempt = 0;
  final backoff = PollingBackoff(
    initialDelay: pollingInterval,
    maxDelay: maxPollingInterval,
  );
  late void Function() startRealtimeListener;
  late void Function() scheduleRealtimeRetry;
  late void Function(String reason) startFallbackPolling;
  late void Function() scheduleNextPoll;

  void cancelRealtimeRetryTimer() {
    realtimeRetryTimer?.cancel();
    realtimeRetryTimer = null;
  }

  scheduleRealtimeRetry = () {
    if (!enableRealtime ||
        controller.isClosed ||
        realtimeSub != null ||
        realtimeRetryTimer != null) {
      return;
    }

    realtimeRetryTimer = Timer(realtimeRetryInterval, () {
      realtimeRetryTimer = null;
      if (!controller.isClosed && fallbackStarted && realtimeSub == null) {
        debugPrint(
          '[CanonicalLiveLocation] retry realtime listener ref=${reference.path}',
        );
        startRealtimeListener();
      }
    });
  };

  Future<void> pollOnce() async {
    var shouldContinuePolling = true;

    try {
      final parsed = parseSnapshot(await pollCanonicalSnapshot());
      if (parsed != null && !controller.isClosed) {
        controller.add(parsed);
      }
    } catch (error, stackTrace) {
      onPollingError?.call(error, stackTrace);

      final message = error.toString();
      final isPermanentError =
          message.contains('permission-denied') ||
          message.contains('unauthenticated');

      if (isPermanentError) {
        shouldContinuePolling = false;
        fallbackStarted = false;
        pollTimer?.cancel();
        cancelRealtimeRetryTimer();

        debugPrint(
          '[CanonicalLiveLocation] stop polling ref=${reference.path} '
          'reason=permanent_error error=$error',
        );
      }

      if (forwardPollingErrorsToStream && !controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    } finally {
      if (!controller.isClosed && fallbackStarted && shouldContinuePolling) {
        scheduleRealtimeRetry();
        scheduleNextPoll();
      }
    }
  }

  scheduleNextPoll = () {
    pollTimer?.cancel();
    if (!fallbackStarted || controller.isClosed) {
      return;
    }

    final delay = usePollingBackoff ? backoff.nextDelay() : pollingInterval;
    final attempt = usePollingBackoff
        ? backoff.attemptCount
        : ++fixedPollingAttempt;
    debugPrint(
      '[CanonicalLiveLocation] fallback polling ref=${reference.path} '
      'attempt=$attempt nextInMs=${delay.inMilliseconds}',
    );
    pollTimer = Timer(delay, () {
      if (!controller.isClosed && fallbackStarted) {
        unawaited(pollOnce());
      }
    });
  };

  startFallbackPolling = (String reason) {
    if (fallbackStarted) {
      return;
    }
    fallbackStarted = true;
    pollTimer?.cancel();
    backoff.reset();
    fixedPollingAttempt = 0;
    debugPrint(
      '[CanonicalLiveLocation] enter fallback polling ref=${reference.path} '
      'reason=$reason',
    );
    unawaited(pollOnce());
    scheduleRealtimeRetry();
  };

  void stopFallbackPolling({required bool logRestore}) {
    pollTimer?.cancel();
    pollTimer = null;
    cancelRealtimeRetryTimer();
    backoff.reset();
    fixedPollingAttempt = 0;
    if (fallbackStarted && logRestore) {
      debugPrint(
        '[CanonicalLiveLocation] restore realtime listener ref=${reference.path}',
      );
    }
    fallbackStarted = false;
  }

  startRealtimeListener = () {
    realtimeSub ??= reference.onValue.listen(
      (event) {
        final parsed = parseSnapshot(event.snapshot.value);
        if (parsed != null && !controller.isClosed) {
          stopFallbackPolling(logRestore: true);
          controller.add(parsed);
          return;
        }

        if (event.snapshot.value == null) {
          startFallbackPolling('empty_snapshot');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        onRealtimeError?.call(error, stackTrace);
        debugPrint(
          '[CanonicalLiveLocation] realtime error ref=${reference.path} error=$error',
        );
        unawaited(realtimeSub?.cancel());
        realtimeSub = null;
        startFallbackPolling('realtime_error');
      },
      cancelOnError: false,
    );
  };

  if (enableRealtime) {
    startRealtimeListener();
  } else {
    startFallbackPolling('realtime_disabled');
  }

  controller.onCancel = () async {
    pollTimer?.cancel();
    cancelRealtimeRetryTimer();
    await realtimeSub?.cancel();
  };

  return controller.stream;
}
