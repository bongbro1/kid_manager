package com.example.kid_manager

import android.content.Context
import android.os.Build
import java.util.Locale

data class TrackingNotificationStrings(
    val notificationTitle: String,
    val notificationText: String,
    val channelName: String,
    val channelDescription: String,
)

object TrackingNotificationLocalizer {
    fun resolve(context: Context): TrackingNotificationStrings {
        return when (TrackingRuntimePrefs.resolvePreferredLanguageCode(context)) {
            "en" -> TrackingNotificationStrings(
                notificationTitle = "Sharing location",
                notificationText = "Location tracking continues in the background",
                channelName = "Background tracking",
                channelDescription = "Keeps child location tracking alive in the background",
            )

            else -> TrackingNotificationStrings(
                notificationTitle = "Đang chia sẻ vị trí",
                notificationText = "Theo dõi vị trí vẫn tiếp tục khi chạy nền",
                channelName = "Theo dõi vị trí nền",
                channelDescription = "Giữ theo dõi vị trí của trẻ hoạt động khi chạy nền",
            )
        }
    }

    fun fallbackDeviceLanguageCode(): String {
        val locale = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            Locale.getDefault(Locale.Category.DISPLAY)
        } else {
            Locale.getDefault()
        }

        return normalizeLanguageCode(locale.toLanguageTag())
    }

    fun normalizeLanguageCode(raw: String?): String {
        val normalized = raw
            ?.trim()
            ?.replace('_', '-')
            ?.lowercase(Locale.ROOT)
            ?.takeIf { it.isNotEmpty() }
            ?: return "vi"

        val language = normalized.substringBefore('-')
        return if (language == "en") "en" else "vi"
    }
}
