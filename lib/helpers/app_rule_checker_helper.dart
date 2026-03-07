import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

class BlockCheckResult {
  final bool isBlocked;
  final String? reason; // ví dụ: "outside_window"
  final TimeWindow? window; // khung giờ hợp lệ (nếu có)

  const BlockCheckResult({required this.isBlocked, this.reason, this.window});
}

class AppRuleChecker {
  static final Map<String, UsageRule> _rules = {};

  static void updateRule(String pkg, UsageRule rule) {
    _rules[pkg] = rule;
    // debugPrint("📥 Rule updated for $pkg");
  }

  static UsageRule? getRule(String pkg) {
    return _rules[pkg];
  }

  static BlockCheckResult check(String pkg) {
    final rule = _rules[pkg];
    if (rule == null) {
      return const BlockCheckResult(isBlocked: false);
    }

    if (!rule.enabled) {
      return const BlockCheckResult(isBlocked: true, reason: "rule_disabled");
    }

    final today = TimeUtils.todayKey();
    final nowMin = TimeUtils.nowMin();
    final weekday = TimeUtils.todayWeekday();

    /// 🔁 Override
    final override = rule.overrides?[today];

    if (override == "allowFullDay") {
      return const BlockCheckResult(isBlocked: false);
    }

    if (override == "blockFullDay") {
      return const BlockCheckResult(isBlocked: true, reason: "override_block");
    }

    /// 📅 Không đúng weekday
    if (!rule.weekdays.contains(weekday)) {
      return const BlockCheckResult(isBlocked: true, reason: "invalid_weekday");
    }

    /// 🕒 Check window
    for (final w in rule.windows) {
      if (nowMin >= w.startMin && nowMin <= w.endMin) {
        return BlockCheckResult(isBlocked: false, window: w);
      }
    }

    /// 👉 Ngoài mọi window
    return BlockCheckResult(
      isBlocked: true,
      reason: "outside_window",
      window: rule.windows.isNotEmpty ? rule.windows.first : null,
    );
  }
}
