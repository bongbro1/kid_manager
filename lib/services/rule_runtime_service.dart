import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kid_manager/background/app_rule_checker.dart';
import 'package:kid_manager/utils/usage_rule.dart';

class RuleRuntimeService {
  static final Map<String, StreamSubscription> _ruleSubs = {};

  static Future<void> start(String userId) async {
    stop();

    final appsSnap = await FirebaseFirestore.instance
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .get();

    for (final app in appsSnap.docs) {
      _listenRule(userId, app.id);
    }
  }

  static void _listenRule(String userId, String package) {
    final sub = FirebaseFirestore.instance
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .doc(package)
        .collection("usage_rule")
        .doc("config")
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;

          final rule = UsageRule.fromMap(doc.data()!);

          AppRuleChecker.updateRule(package, rule);
        });

    _ruleSubs[package] = sub;
  }

  static void stop() {
    for (final sub in _ruleSubs.values) {
      sub.cancel();
    }
    _ruleSubs.clear();
  }
}
