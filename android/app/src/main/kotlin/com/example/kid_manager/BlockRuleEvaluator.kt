package com.example.kid_manager

import java.util.Calendar

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

object BlockRuleEvaluator {
    fun checkBlocked(
        rule: NativeRule?,
        atMillis: Long = System.currentTimeMillis()
    ): BlockCheckResult {
        if (rule == null) {
            return BlockCheckResult(isBlocked = false)
        }

        if (!rule.enabled) {
            return BlockCheckResult(isBlocked = true, reason = "rule_disabled")
        }

        val today = dayKey(atMillis)
        val nowMin = minuteOfDay(atMillis)
        val weekday = weekday(atMillis)
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

        for (window in rule.windows) {
            if (nowMin in window.startMin..window.endMin) {
                return BlockCheckResult(
                    isBlocked = false,
                    allowedFrom = formatMinutes(window.startMin),
                    allowedTo = formatMinutes(window.endMin)
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

    private fun dayKey(atMillis: Long): String {
        val cal = Calendar.getInstance().apply { timeInMillis = atMillis }
        val year = cal.get(Calendar.YEAR)
        val month = cal.get(Calendar.MONTH) + 1
        val day = cal.get(Calendar.DAY_OF_MONTH)
        return String.format("%04d-%02d-%02d", year, month, day)
    }

    private fun minuteOfDay(atMillis: Long): Int {
        val cal = Calendar.getInstance().apply { timeInMillis = atMillis }
        return cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE)
    }

    private fun weekday(atMillis: Long): Int {
        val day = Calendar.getInstance().apply { timeInMillis = atMillis }
            .get(Calendar.DAY_OF_WEEK)
        return when (day) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }
    }

    fun formatMinutes(totalMinutes: Int): String {
        val hours = totalMinutes / 60
        val minutes = totalMinutes % 60
        return String.format("%02d:%02d", hours, minutes)
    }
}
