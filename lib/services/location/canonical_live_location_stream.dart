import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

typedef CanonicalLiveLocationParser<T> = T? Function(dynamic raw);
typedef CanonicalLiveLocationPoller = Future<dynamic> Function();
typedef CanonicalLiveLocationErrorHandler =
    void Function(Object error, StackTrace stackTrace);

Stream<T> streamCanonicalLiveLocation<T>({
  required DatabaseReference reference,
  required CanonicalLiveLocationPoller pollCanonicalSnapshot,
  required CanonicalLiveLocationParser<T> parseSnapshot,
  required Duration pollingInterval,
  CanonicalLiveLocationErrorHandler? onRealtimeError,
  CanonicalLiveLocationErrorHandler? onPollingError,
  bool forwardPollingErrorsToStream = true,
}) {
  final controller = StreamController<T>();
  StreamSubscription<DatabaseEvent>? realtimeSub;
  Timer? pollTimer;
  var fallbackStarted = false;

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
    }
  }

  void startFallbackPolling() {
    if (fallbackStarted) {
      return;
    }
    fallbackStarted = true;
    pollTimer?.cancel();
    unawaited(pollOnce());
    pollTimer = Timer.periodic(pollingInterval, (_) {
      unawaited(pollOnce());
    });
  }

  realtimeSub = reference.onValue.listen(
    (event) {
      final parsed = parseSnapshot(event.snapshot.value);
      if (parsed != null && !controller.isClosed) {
        if (fallbackStarted) {
          pollTimer?.cancel();
          fallbackStarted = false;
        }
        controller.add(parsed);
        return;
      }

      if (event.snapshot.value == null) {
        startFallbackPolling();
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      onRealtimeError?.call(error, stackTrace);
      unawaited(realtimeSub?.cancel());
      realtimeSub = null;
      startFallbackPolling();
    },
    cancelOnError: false,
  );

  controller.onCancel = () async {
    pollTimer?.cancel();
    await realtimeSub?.cancel();
  };

  return controller.stream;
}
