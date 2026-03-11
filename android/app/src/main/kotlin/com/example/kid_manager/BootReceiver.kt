package com.example.kid_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_LOCKED_BOOT_COMPLETED) {

            val prefs = context.getSharedPreferences("watcher_prefs", Context.MODE_PRIVATE)
            val enabled = prefs.getBoolean("watcher_enabled", false)
            val userId = prefs.getString("userId", null)
            val parentId = prefs.getString("parentId", null)
            val childName = prefs.getString("childName", null)

            Log.d("BootReceiver", "rebooted -> enabled=$enabled, userId=$userId")

            if (!enabled || userId.isNullOrBlank()) return

            val serviceIntent = Intent(context, AppWatcherService::class.java).apply {
                putExtra("userId", userId)
                putExtra("parentId", parentId)
                putExtra("childName", childName)
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            } catch (e: Exception) {
                Log.e("BootReceiver", "Failed to restart watcher after boot", e)
            }
        }
    }
}