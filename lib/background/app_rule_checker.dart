import 'package:flutter/rendering.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/usage_rule.dart';

class AppRuleChecker {
  static final Map<String, UsageRule> _rules = {};

  static void updateRule(String pkg, UsageRule rule) {
    _rules[pkg] = rule;
    debugPrint("📥 Rule updated for $pkg");
  }

  static UsageRule? getRule(String pkg) {
    return _rules[pkg];
  }
  
  static bool isBlocked(String pkg) {
    final rule = _rules[pkg];
    if (rule == null) return false;

    if (!rule.enabled) return false;

    final today = TimeUtils.todayKey();
    final nowMin = TimeUtils.nowMin();
    final weekday = TimeUtils.todayWeekday();

    /// 🔁 Override check
    final override = rule.overrides?[today];

    if (override == "allowFullDay") return false;
    if (override == "blockFullDay") return true;

    /// 📅 Không nằm trong weekday → không block
    if (!rule.weekdays.contains(weekday)) return false;

    /// 🕒 Check time window
    final inAllowedTime = nowMin >= rule.startMin && nowMin <= rule.endMin;

    /// 👉 ngoài giờ cho phép = BLOCK
    return !inAllowedTime;
  }
}
