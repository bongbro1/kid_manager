import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/helpers/app_rule_checker_helper.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

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

  static Future<void> _listenRule(String userId, String package) async {
    final ref = FirebaseFirestore.instance
        .collection("blocked_items")
        .doc(userId)
        .collection("apps")
        .doc(package)
        .collection("usage_rule")
        .doc("config");

    try {
      await ref.get(); // test permission
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        debugPrint("⛔ No permission for $package");
        return;
      }
    }

    final sub = ref.snapshots().listen(
      (doc) {
        if (!doc.exists) return;

        final rule = UsageRule.fromMap(doc.data()!);
        AppRuleChecker.updateRule(package, rule);
      },
      onError: (e) {
        debugPrint("🔥 listenRule error ($package): $e");
        _ruleSubs[package]?.cancel();
        _ruleSubs.remove(package);
      },
    );

    _ruleSubs[package] = sub;
  }

  static void stop() {
    for (final sub in _ruleSubs.values) {
      sub.cancel();
    }
    _ruleSubs.clear();
  }
}
