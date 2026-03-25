package com.example.kid_manager

import android.app.AlarmManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugins.GeneratedPluginRegistrant

class TrackingForegroundService : Service() {
    private var flutterEngine: FlutterEngine? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_START
        if (action == ACTION_STOP) {
            stopSelf()
            return START_NOT_STICKY
        }

        startForeground(NOTIFICATION_ID, buildNotification())
        startFlutterEngineIfNeeded()
        isRunning = flutterEngine != null
        if (!isRunning) {
            stopSelf()
            return START_NOT_STICKY
        }
        return START_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)

        if (!TrackingRuntimePrefs.isTrackingEnabled(applicationContext)) {
            return
        }

        val restartIntent = Intent(applicationContext, TrackingForegroundService::class.java)
            .setAction(ACTION_START)

        val pendingIntent = PendingIntent.getService(
            applicationContext,
            RESTART_REQUEST_CODE,
            restartIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val triggerAt = System.currentTimeMillis() + 1000L

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !alarmManager.canScheduleExactAlarms()
            ) {
                scheduleInexactRestart(alarmManager, triggerAt, pendingIntent)
                return
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    pendingIntent,
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        } catch (e: SecurityException) {
            Log.w(TAG, "Exact alarm unavailable, falling back to inexact restart", e)
            scheduleInexactRestart(alarmManager, triggerAt, pendingIntent)
        }
    }

    override fun onDestroy() {
        flutterEngine?.destroy()
        flutterEngine = null
        isRunning = false
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startFlutterEngineIfNeeded() {
        if (flutterEngine != null) {
            return
        }

        try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationComplete(applicationContext, null)

            val engine = FlutterEngine(applicationContext)
            GeneratedPluginRegistrant.registerWith(engine)
            TrackingServiceChannel.register(engine.dartExecutor.binaryMessenger, applicationContext)

            val bundlePath = loader.findAppBundlePath()
            val dartEntrypoint = DartExecutor.DartEntrypoint(
                bundlePath,
                "backgroundTrackingMain",
            )
            engine.dartExecutor.executeDartEntrypoint(dartEntrypoint)
            flutterEngine = engine
        } catch (e: Throwable) {
            Log.e(TAG, "Failed to start background tracking engine", e)
        }
    }

    private fun buildNotification(): Notification {
        ensureNotificationChannel()

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("Sharing location")
            .setContentText("Location tracking continues in the background")
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java)
        val existing = manager.getNotificationChannel(CHANNEL_ID)
        if (existing != null) {
            return
        }

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Background tracking",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Keeps child location tracking alive in the background"
            setShowBadge(false)
            lockscreenVisibility = Notification.VISIBILITY_PRIVATE
        }

        manager.createNotificationChannel(channel)
    }

    private fun scheduleInexactRestart(
        alarmManager: AlarmManager,
        triggerAt: Long,
        pendingIntent: PendingIntent,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                pendingIntent,
            )
        } else {
            alarmManager.set(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    companion object {
        private const val TAG = "TrackingFgService"
        private const val CHANNEL_ID = "background_tracking_service"
        private const val NOTIFICATION_ID = 32017
        private const val RESTART_REQUEST_CODE = 32018

        const val ACTION_START = "com.example.kid_manager.action.START_TRACKING"
        const val ACTION_STOP = "com.example.kid_manager.action.STOP_TRACKING"

        @Volatile
        var isRunning: Boolean = false
            private set

        fun start(context: Context): Boolean {
            return try {
                val intent = Intent(context, TrackingForegroundService::class.java)
                    .setAction(ACTION_START)
                ContextCompat.startForegroundService(context, intent)
                true
            } catch (e: Throwable) {
                Log.e(TAG, "Failed to start tracking foreground service", e)
                false
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, TrackingForegroundService::class.java)
                .setAction(ACTION_STOP)
            context.stopService(intent)
        }
    }
}
