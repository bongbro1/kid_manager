import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum AppConnectivityState { unknown, online, offline }

class AppConnectivityVm extends ChangeNotifier {
  AppConnectivityVm({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    unawaited(_bootstrap());
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  AppConnectivityState _state = AppConnectivityState.unknown;
  AppConnectivityState get state => _state;

  bool get isOffline => _state == AppConnectivityState.offline;
  bool get isOnline => _state == AppConnectivityState.online;

  Future<void> _bootstrap() async {
    try {
      final initialResults = await _connectivity.checkConnectivity();
      _applyResults(initialResults);
    } catch (_) {
      _setState(AppConnectivityState.unknown);
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      _applyResults,
      onError: (_) => _setState(AppConnectivityState.unknown),
    );
  }

  void _applyResults(List<ConnectivityResult> results) {
    final nextState =
        results.isEmpty ||
            results.every((result) => result == ConnectivityResult.none)
        ? AppConnectivityState.offline
        : AppConnectivityState.online;
    _setState(nextState);
  }

  void _setState(AppConnectivityState nextState) {
    if (_state == nextState) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
