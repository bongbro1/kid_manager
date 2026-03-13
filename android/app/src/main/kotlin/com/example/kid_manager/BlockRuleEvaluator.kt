package com.example.kid_manager

import android.content.Context

data class NativeTimeWindow(
    val startMin: Int,
    val endMin: Int
)

data class NativeRule(
    val enabled: Boolean,
    val weekdays: Set<Int>,
    val windows: List<NativeTimeWindow>,
    val overrides: Map<String, String>
)

data class BlockCheckResult(
    val isBlocked: Boolean,
    val reason: String? = null,
    val allowedFrom: String = "",
    val allowedTo: String = ""
)

class BlockRuleEvaluator(
    private val ruleSyncManager: FirestoreRuleSyncManager
) {
    companion object {
        private const val RULE_PREFS = "watcher_rules"
        private const val KEY_BLOCKED_PACKAGES = "blocked_packages"
    }

    fun readRule(packageName: String): NativeRule? {
        return ruleSyncManager.getRule(packageName)
    }
    fun checkBlocked(packageName: String): BlockCheckResult {
        val rule = readRule(packageName) ?: return BlockCheckResult(isBlocked = false)

        if (!rule.enabled) {
            return BlockCheckResult(isBlocked = true, reason = "rule_disabled")
        }

        val today = todayKey()
        val nowMin = nowMin()
        val weekday = todayWeekday()

        val override = rule.overrides[today]

        if (override == "allowFullDay") {
            return BlockCheckResult(isBlocked = false)
        }

        if (override == "blockFullDay") {
            return BlockCheckResult(isBlocked = true, reason = "override_block")
        }

        if (!rule.weekdays.contains(weekday)) {
            return BlockCheckResult(isBlocked = true, reason = "invalid_weekday")
        }

        for (w in rule.windows) {
            if (nowMin >= w.startMin && nowMin <= w.endMin) {
                return BlockCheckResult(
                    isBlocked = false,
                    allowedFrom = formatMinutes(w.startMin),
                    allowedTo = formatMinutes(w.endMin)
                )
            }
        }

        val first = rule.windows.firstOrNull()
        return BlockCheckResult(
            isBlocked = true,
            reason = "outside_window",
            allowedFrom = first?.let { formatMinutes(it.startMin) } ?: "",
            allowedTo = first?.let { formatMinutes(it.endMin) } ?: ""
        )
    }

    private fun todayKey(): String {
        val cal = java.util.Calendar.getInstance()
        val year = cal.get(java.util.Calendar.YEAR)
        val month = cal.get(java.util.Calendar.MONTH) + 1
        val day = cal.get(java.util.Calendar.DAY_OF_MONTH)
        return String.format("%04d-%02d-%02d", year, month, day)
    }

    private fun nowMin(): Int {
        val cal = java.util.Calendar.getInstance()
        return cal.get(java.util.Calendar.HOUR_OF_DAY) * 60 +
                cal.get(java.util.Calendar.MINUTE)
    }

    private fun todayWeekday(): Int {
        val day = java.util.Calendar.getInstance().get(java.util.Calendar.DAY_OF_WEEK)
        return when (day) {
            java.util.Calendar.MONDAY -> 1
            java.util.Calendar.TUESDAY -> 2
            java.util.Calendar.WEDNESDAY -> 3
            java.util.Calendar.THURSDAY -> 4
            java.util.Calendar.FRIDAY -> 5
            java.util.Calendar.SATURDAY -> 6
            java.util.Calendar.SUNDAY -> 7
            else -> 1
        }
    }

    private fun formatMinutes(totalMinutes: Int): String {
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60
        return String.format("%02d:%02d", hours, minutes)
    }
}