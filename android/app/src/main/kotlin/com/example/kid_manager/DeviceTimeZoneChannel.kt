package com.example.kid_manager

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

object DeviceTimeZoneChannel {
    private const val CHANNEL = "device_timezone"
    private const val FALLBACK_TIME_ZONE = "Asia/Ho_Chi_Minh"

    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getDeviceTimeZone" -> {
                    result.success(normalizeTimeZoneId(TimeZone.getDefault().id))
                }

                "normalizeTimeZone" -> {
                    val requested = call.argument<String>("timeZone")
                    val fallback = call.argument<String>("fallbackTimeZone")
                    result.success(normalizeTimeZoneId(requested, fallback))
                }

                "resolveDayKeyForTimestamp" -> {
                    val timestampMs = (call.argument<Number>("timestampMs") ?: 0L).toLong()
                    val timeZoneId = normalizeTimeZoneId(call.argument("timeZone"))
                    result.success(dayKeyForTimestamp(timestampMs, timeZoneId))
                }

                "resolveLocalPartsForTimestamp" -> {
                    val timestampMs = (call.argument<Number>("timestampMs") ?: 0L).toLong()
                    val timeZoneId = normalizeTimeZoneId(call.argument("timeZone"))
                    val calendar = Calendar.getInstance(TimeZone.getTimeZone(timeZoneId), Locale.US)
                    calendar.timeInMillis = timestampMs
                    result.success(
                        mapOf(
                            "dayKey" to dayKeyForCalendar(calendar),
                            "minuteOfDay" to (calendar.get(Calendar.HOUR_OF_DAY) * 60) +
                                calendar.get(Calendar.MINUTE),
                            "year" to calendar.get(Calendar.YEAR),
                            "month" to (calendar.get(Calendar.MONTH) + 1),
                            "day" to calendar.get(Calendar.DAY_OF_MONTH),
                            "hour" to calendar.get(Calendar.HOUR_OF_DAY),
                            "minute" to calendar.get(Calendar.MINUTE),
                            "second" to calendar.get(Calendar.SECOND),
                        )
                    )
                }

                "resolveUtcRangeForLocalDay" -> {
                    val dayKey = call.argument<String>("dayKey")
                    val timeZoneId = normalizeTimeZoneId(call.argument("timeZone"))
                    val startMinuteOfDay =
                        (call.argument<Number>("startMinuteOfDay") ?: 0).toInt()
                    val endMinuteOfDay =
                        (call.argument<Number>("endMinuteOfDay") ?: 0).toInt()
                    if (dayKey.isNullOrBlank()) {
                        result.error("invalid-argument", "dayKey is required", null)
                        return@setMethodCallHandler
                    }

                    val parsed = parseDayKey(dayKey)
                    if (parsed == null) {
                        result.error("invalid-argument", "dayKey must be YYYY-MM-DD", null)
                        return@setMethodCallHandler
                    }

                    val fromCalendar = buildCalendarForMinute(
                        parsed.first,
                        parsed.second,
                        parsed.third,
                        startMinuteOfDay,
                        timeZoneId,
                    )
                    val toCalendar = buildCalendarForMinute(
                        parsed.first,
                        parsed.second,
                        parsed.third,
                        endMinuteOfDay,
                        timeZoneId,
                    ).apply {
                        add(Calendar.SECOND, 59)
                        add(Calendar.MILLISECOND, 999)
                    }

                    result.success(
                        mapOf(
                            "fromTs" to fromCalendar.timeInMillis,
                            "toTs" to toCalendar.timeInMillis,
                        )
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun buildCalendarForMinute(
        year: Int,
        month: Int,
        day: Int,
        minuteOfDay: Int,
        timeZoneId: String,
    ): Calendar {
        val normalizedMinute = minuteOfDay.coerceIn(0, (24 * 60) - 1)
        return Calendar.getInstance(TimeZone.getTimeZone(timeZoneId), Locale.US).apply {
            clear()
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, month - 1)
            set(Calendar.DAY_OF_MONTH, day)
            set(Calendar.HOUR_OF_DAY, normalizedMinute / 60)
            set(Calendar.MINUTE, normalizedMinute % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
    }

    private fun parseDayKey(dayKey: String): Triple<Int, Int, Int>? {
        val parts = dayKey.split("-")
        if (parts.size != 3) {
            return null
        }

        val year = parts[0].toIntOrNull() ?: return null
        val month = parts[1].toIntOrNull() ?: return null
        val day = parts[2].toIntOrNull() ?: return null
        return Triple(year, month, day)
    }

    private fun dayKeyForTimestamp(timestampMs: Long, timeZoneId: String): String {
        val calendar = Calendar.getInstance(TimeZone.getTimeZone(timeZoneId), Locale.US)
        calendar.timeInMillis = timestampMs
        return dayKeyForCalendar(calendar)
    }

    private fun dayKeyForCalendar(calendar: Calendar): String {
        val year = calendar.get(Calendar.YEAR)
        val month = calendar.get(Calendar.MONTH) + 1
        val day = calendar.get(Calendar.DAY_OF_MONTH)
        return String.format(Locale.US, "%04d-%02d-%02d", year, month, day)
    }

    private fun normalizeTimeZoneId(
        raw: String?,
        fallback: String? = null,
    ): String {
        val trimmed = raw?.trim().orEmpty()
        if (trimmed.isNotEmpty() && isKnownTimeZoneId(trimmed)) {
            return trimmed
        }

        val fallbackValue = fallback?.trim().orEmpty()
        if (fallbackValue.isNotEmpty() && isKnownTimeZoneId(fallbackValue)) {
            return fallbackValue
        }

        return FALLBACK_TIME_ZONE
    }

    private fun isKnownTimeZoneId(value: String): Boolean {
        if (value == "UTC") {
            return true
        }
        return TimeZone.getAvailableIDs().contains(value)
    }
}
