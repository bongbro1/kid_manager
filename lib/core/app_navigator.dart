import 'package:flutter/material.dart';
import 'package:kid_manager/models/notifications/app_notification.dart';

class AppNavigator {
  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();


  static final messengerKey = GlobalKey<ScaffoldMessengerState>();
}

class NotificationTabNavigator {
  static final key = GlobalKey<NavigatorState>();
}

class NotificationNavigationState {
  static AppNotification? pendingItem;
  static String? pendingType;

  static void set(AppNotification item, {String? type}) {
    pendingItem = item;
    pendingType = type;
  }

  static AppNotification? consume() {
    final item = pendingItem;
    pendingItem = null;
    pendingType = null;
    return item;
  }

  static bool get hasPending => pendingItem != null;
}