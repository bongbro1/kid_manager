package com.example.kid_manager

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AppWatcherService : Service() {

    private lateinit var handler: Handler
    private lateinit var runnable: Runnable

    override fun onCreate() {
        super.onCreate()

        handler = Handler(Looper.getMainLooper())

        runnable = object : Runnable {
            override fun run() {

                val pkg = getForegroundApp()

                if (pkg != null) {
                    Log.d("WATCHER", "Foreground app: $pkg")
                    ForegroundAppBridge.send(pkg)
                }

                handler.postDelayed(this, 2000)
            }
        }

        handler.post(runnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {

        val channelId = "watcher_channel"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Kid Manager Protection",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Kid Manager đang bảo vệ")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .build()

        startForeground(1, notification)

        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun getForegroundApp(): String? {

        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val begin = end - 5000

        val events = usm.queryEvents(begin, end)
        val event = UsageEvents.Event()

        var lastApp: String? = null

        while (events.hasNextEvent()) {
            events.getNextEvent(event)

            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                lastApp = event.packageName
            }
        }

        return lastApp
    }
}