package com.example.kid_manager

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.firestore.FirebaseFirestore

class AppWatcherService : Service() {

    private lateinit var workerThread: HandlerThread
    private lateinit var workerHandler: Handler

    private lateinit var ruleSyncManager: FirestoreRuleSyncManager
    private lateinit var blockRuleEvaluator: BlockRuleEvaluator

    private var lastForegroundPackage: String? = null
    private val lastNotifyTimes = mutableMapOf<String, Long>()

    companion object {
        @JvmStatic
        var isRunning: Boolean = false
        private const val SERVICE_CHANNEL_ID = "watcher_channel"
        private const val ALERT_CHANNEL_ID = "blocked_app_channel"
        private const val RULE_PREFS = "watcher_rules"
        private const val POLL_INTERVAL_MS = 2000L
        private const val COOLDOWN_MS = 10_000L
        private const val TAG = "AppWatcherService"
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        Log.d(TAG, "onTaskRemoved called")

        val prefs = getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
        val userId = prefs.getString("user_id", null)
        val parentId = prefs.getString("parent_id", null)
        val childName = prefs.getString("child_name", null)

        if (!userId.isNullOrBlank()) {
            val restartIntent = Intent(applicationContext, AppWatcherService::class.java).apply {
                putExtra("userId", userId)
                putExtra("parentId", parentId)
                putExtra("childName", childName)
            }

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    applicationContext.startForegroundService(restartIntent)
                } else {
                    applicationContext.startService(restartIntent)
                }
                Log.d(TAG, "Requested restart from onTaskRemoved")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to restart from onTaskRemoved", e)
            }
        }
        showServiceAliveNotification()
        isRunning = true

        super.onTaskRemoved(rootIntent)
    }
    override fun onCreate() {
        super.onCreate()

        isRunning = true
        try {
            com.google.firebase.FirebaseApp.initializeApp(this)
        } catch (e: Exception) {
            Log.e(TAG, "Firebase init error", e)
        }

        ruleSyncManager = FirestoreRuleSyncManager(this)
        blockRuleEvaluator = BlockRuleEvaluator(this)

        workerThread = HandlerThread("AppWatcherThread")
        workerThread.start()
        workerHandler = Handler(workerThread.looper)

        val runnable = object : Runnable {
            override fun run() {
                try {
                    val pkg = getForegroundApp()

                    if (!pkg.isNullOrBlank() && pkg != lastForegroundPackage) {
                        lastForegroundPackage = pkg

                        // Log.d(TAG, "Foreground app changed: $pkg")

                        val appName = getAppName(pkg)

                        val blockResult = blockRuleEvaluator.checkBlocked(pkg)

                        // Log.d(
                        //     TAG,
                        //     "Block check result for $pkg -> " +
                        //         "isBlocked=${blockResult.isBlocked}, " +
                        //         "reason=${blockResult.reason}, " +
                        //         "allowedFrom=${blockResult.allowedFrom}, " +
                        //         "allowedTo=${blockResult.allowedTo}"
                        // )

                        if (blockResult.isBlocked && shouldNotify(pkg)) {
                            handleBlockedApp(
                                packageName = pkg,
                                allowedFrom = blockResult.allowedFrom,
                                allowedTo = blockResult.allowedTo
                            )
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "Watcher loop error", e)
                } finally {
                    workerHandler.postDelayed(this, POLL_INTERVAL_MS)
                }
            }
        }

        workerHandler.post(runnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val notification = showServiceAliveNotification()
        startForeground(1001, notification)

        val childId = intent?.getStringExtra("userId")
        val parentId = intent?.getStringExtra("parentId")
        val childName = intent?.getStringExtra("childName")

        Log.d(
            TAG,
            "onStartCommand childId=$childId parentId=$parentId childName=$childName"
        )

        if (!childId.isNullOrBlank()) {
            val prefs = getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
            prefs.edit()
                .putString("user_id", childId)
                .putString("parent_id", parentId)
                .putString("child_name", childName ?: "Unknown")
                .apply()

            ruleSyncManager.start(childId)
        } else {
            Log.e(TAG, "Missing userId when starting watcher service")
        }

        showServiceAliveNotification()
        isRunning = true
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        val manager = getSystemService(NotificationManager::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "watcher_status",
                "Watcher Status",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            manager.createNotificationChannel(channel)
        }

        val notification = NotificationCompat.Builder(this, "watcher_status")
            .setContentTitle("Watcher bị dừng")
            .setContentText("Service đã bị hủy")
            .setSmallIcon(android.R.drawable.ic_delete)
            .setAutoCancel(true)
            .build()

        manager.notify(8888, notification)

        ruleSyncManager.stop()
        workerThread.quitSafely()
        Log.d(TAG, "Service destroyed")

        isRunning = false

        super.onDestroy()
    }

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

    private fun shouldNotify(packageName: String): Boolean {
        val now = System.currentTimeMillis()
        val last = lastNotifyTimes[packageName] ?: 0L

        return if (now - last >= COOLDOWN_MS) {
            lastNotifyTimes[packageName] = now
            true
        } else {
            false
        }
    }

    private fun handleBlockedApp(
        packageName: String,
        allowedFrom: String,
        allowedTo: String
    ) {
        val appName = getAppName(packageName)

        // Log.d(TAG, "Blocked app opened: $appName ($packageName)")

        sendBlockedNotificationToFirestore(
            packageName = packageName,
            appName = appName,
            allowedFrom = allowedFrom,
            allowedTo = allowedTo
        )
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = applicationContext.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun createServiceChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                SERVICE_CHANNEL_ID,
                "Kid Manager Protection",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createAlertChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                ALERT_CHANNEL_ID,
                "Blocked App Alerts",
                NotificationManager.IMPORTANCE_HIGH
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun showServiceAliveNotification(): Notification {
        val manager = getSystemService(NotificationManager::class.java)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                SERVICE_CHANNEL_ID,
                "Kid Manager Protection",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                setShowBadge(false)
                description = "Foreground protection service"
            }

            manager.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, SERVICE_CHANNEL_ID)
            .setContentTitle("Kid Manager đang bảo vệ")
            .setContentText("Đang theo dõi ứng dụng foreground")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun sendBlockedNotificationToFirestore(
        packageName: String,
        appName: String,
        allowedFrom: String,
        allowedTo: String
    ) {
        val prefs = getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)

        val parentId = prefs.getString("parent_id", null) ?: run {
            Log.e(TAG, "Missing parent_id in watcher_rules")
            return
        }

        val childName = prefs.getString("child_name", "Unknown") ?: "Unknown"

        val now = java.text.SimpleDateFormat(
            "HH:mm:ss",
            java.util.Locale.getDefault()
        ).format(java.util.Date())

        val payload = hashMapOf(
            "receiverId" to parentId,
            "senderId" to "system",
            "type" to "blockedApp",
            "title" to "Ứng dụng bị chặn",
            "body" to "$childName đang mở ứng dụng bị cấm: $appName",
            "isRead" to false,
            "status" to "pending",
            "data" to hashMapOf(
                "studentName" to childName,
                "appName" to appName,
                "packageName" to packageName,
                "blockedAt" to now,
                "allowedFrom" to allowedFrom,
                "allowedTo" to allowedTo
            ),
            "createdAt" to com.google.firebase.Timestamp.now()
        )

        // Log.d(TAG, "Creating notification for receiverId=$parentId payload=$payload")

        FirebaseFirestore.getInstance()
            .collection("notifications")
            .add(payload)
            .addOnSuccessListener { ref ->
                Log.d(TAG, "Notification doc created in Firestore: ${ref.id}")
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "Failed to create notification doc", e)
            }
    }
}