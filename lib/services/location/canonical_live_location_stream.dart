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
  CanonicalLiveLocationErrorHandler? onRealtimeError,
  CanonicalLiveLocationErrorHandler? onPollingError,
  bool forwardPollingErrorsToStream = true,
}) {
  final controller = StreamController<T>();
  StreamSubscription<DatabaseEvent>? realtimeSub;
  Timer? pollTimer;
  Timer? realtimeRetryTimer;
  var fallbackStarted = false;
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
    if (controller.isClosed || realtimeSub != null || realtimeRetryTimer != null) {
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
    try {
      final parsed = parseSnapshot(await pollCanonicalSnapshot());
      if (parsed != null && !controller.isClosed) {
        controller.add(parsed);
      }
    } catch (error, stackTrace) {
      onPollingError?.call(error, stackTrace);
      if (forwardPollingErrorsToStream && !controller.isClosed) {
        controller.addError(error, stackTrace);
      }
    } finally {
      if (!controller.isClosed && fallbackStarted) {
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

    final delay = backoff.nextDelay();
    debugPrint(
      '[CanonicalLiveLocation] fallback polling ref=${reference.path} '
      'attempt=${backoff.attemptCount} nextInMs=${delay.inMilliseconds}',
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

  startRealtimeListener();

  controller.onCancel = () async {
    pollTimer?.cancel();
    cancelRealtimeRetryTimer();
    await realtimeSub?.cancel();
  };

  return controller.stream;
}
