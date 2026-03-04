import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/usage_rule_utils.dart';

class AppRuleChecker {
  static final Map<String, UsageRule> _rules = {};

  static void updateRule(String pkg, UsageRule rule) {
    _rules[pkg] = rule;
    // debugPrint("📥 Rule updated for $pkg");
  }

  static UsageRule? getRule(String pkg) {
    return _rules[pkg];
  }

  static bool isBlocked(String pkg) {
    final rule = _rules[pkg];
    if (rule == null) return false;

    // debugPrint("⚙️ Enabled: ${rule.enabled}");

    if (!rule.enabled) return true;

    final today = TimeUtils.todayKey();
    final nowMin = TimeUtils.nowMin();
    final weekday = TimeUtils.todayWeekday();

    /// 🔁 Override check
    final override = rule.overrides?[today];

    if (override == "allowFullDay") return false;
    if (override == "blockFullDay") return true;

    /// 📅 Không nằm trong weekday → không block
    if (!rule.weekdays.contains(weekday)) {
      // debugPrint("📅 Weekday $weekday not allowed → BLOCK");
      return true;
    }

    /// 🕒 Check time window
    bool inAllowedTime = false;

    for (final w in rule.windows) {
      if (nowMin >= w.startMin && nowMin <= w.endMin) {
        inAllowedTime = true;
        break;
      }
    }

    // debugPrint("🕒 Now: $nowMin");
    // debugPrint(
    //   "🪟 Windows: ${rule.windows.map((e) => "${e.startMin}-${e.endMin}").toList()}",
    // );
    // debugPrint("✅ In allowed time: $inAllowedTime");

    /// 👉 ngoài tất cả window = BLOCK
    return !inAllowedTime;
  }
}
