package com.example.kid_manager

import android.content.Context

object TrackingRuntimePrefs {
    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_ENABLED = "flutter.tracking.runtime.enabled"

    fun isTrackingEnabled(context: Context): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getBoolean(KEY_ENABLED, false)
    }
}
