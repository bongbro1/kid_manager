import 'package:flutter/material.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final notificationTabIndexNotifier = ValueNotifier<int>(0);

final ValueNotifier<int> activeTabNotifier = ValueNotifier<int>(0);
