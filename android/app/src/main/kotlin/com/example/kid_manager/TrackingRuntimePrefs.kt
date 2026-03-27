package com.example.kid_manager

import android.content.Context

object TrackingRuntimePrefs {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_ENABLED = "flutter.tracking.runtime.enabled"
    private const val KEY_APP_LOCALE = "flutter.locale"
    private const val KEY_PREFERRED_LOCALE = "flutter.preferredLocale"
    private const val KEY_LANGUAGE = "flutter.language"

    fun isTrackingEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ENABLED, false)
    }

    fun resolvePreferredLanguageCode(context: Context): String {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val savedLocale = prefs.getString(KEY_APP_LOCALE, null)
            ?: prefs.getString(KEY_PREFERRED_LOCALE, null)
            ?: prefs.getString(KEY_LANGUAGE, null)

        return savedLocale
            ?.let(TrackingNotificationLocalizer::normalizeLanguageCode)
            ?: TrackingNotificationLocalizer.fallbackDeviceLanguageCode()
    }
}
