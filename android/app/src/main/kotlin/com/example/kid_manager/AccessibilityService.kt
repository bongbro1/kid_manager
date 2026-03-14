package com.example.kid_manager

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import android.content.Context
import com.google.firebase.firestore.FirebaseFirestore
import android.os.Handler
import android.os.Looper

class AppAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "AppAccessibilityService"
        private const val RULE_PREFS = "watcher_rules"
        private const val COOLDOWN_MS = 10000L
    }

    private lateinit var blockRuleEvaluator: BlockRuleEvaluator
    private lateinit var ruleSyncManager: FirestoreRuleSyncManager

    private var lastForegroundPackage: String? = null
    private val lastNotifyTimes = mutableMapOf<String, Long>()
    private var syncedChildId: String? = null


    private val handler = Handler(Looper.getMainLooper())

    private var usageSyncManager: UsageSyncManager? = null

    private val usageRunnable = object : Runnable {
        override fun run() {

            val userId = getUserId()

            if (userId != null) {
                usageSyncManager?.syncUsageApps(userId)
            }

            // handler.postDelayed(this, 15 * 60 * 1000)
            handler.postDelayed(this, 60000)
        }
    }

    private val appsRunnable = object : Runnable {
        override fun run() {

            val userId = getUserId()

            if (userId != null) {
                usageSyncManager?.syncInstalledApps(userId)
            }

            // handler.postDelayed(this, 5 * 60 * 1000)
            handler.postDelayed(this, 60000)
        }
    }

    private fun startUsageTimer() {

        handler.removeCallbacks(usageRunnable)
        handler.removeCallbacks(appsRunnable)

        handler.postDelayed(usageRunnable, 10000)
        handler.postDelayed(appsRunnable, 20000)
    }

    override fun onServiceConnected() {
        super.onServiceConnected()


        val userId = getUserId()

        Log.d(TAG, "Accessibility connected with userId = $userId")

        try {
            com.google.firebase.FirebaseApp.initializeApp(this)
        } catch (e: Exception) {
            Log.e(TAG, "Firebase init error", e)
        }

        ruleSyncManager = FirestoreRuleSyncManager(this)
        blockRuleEvaluator = BlockRuleEvaluator(ruleSyncManager)


        usageSyncManager = UsageSyncManager(this)

        startUsageTimer()

        // load childId để sync rules
        val prefs = getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
        val childId = prefs.getString("user_id", null)

        if (!childId.isNullOrBlank()) {
            ruleSyncManager.start(childId)
            // Log.d(TAG, "Started rule sync for childId=$childId")
        } else {
            // Log.d(TAG, "No childId found for rule sync")
        }
    }
    private fun ensureRuleSync() {

        val prefs = getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
        val childId = prefs.getString("user_id", null)

        if (!childId.isNullOrBlank() && childId != syncedChildId) {

            ruleSyncManager.start(childId)

            syncedChildId = childId

            // Log.d(TAG, "Rule sync started for childId=$childId")
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        try {

            ensureRuleSync()

            if (event.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

            val packageName = event.packageName?.toString() ?: return

            if (packageName == lastForegroundPackage) return
            lastForegroundPackage = packageName

            onAppChanged(packageName)

        } catch (e: Exception) {
            Log.e(TAG, "Accessibility error", e)
        }
    }

    private fun onAppChanged(packageName: String) {
        val result = blockRuleEvaluator.checkBlocked(packageName)
        if (!result.isBlocked) return

        if (!shouldNotify(packageName)) return

        handleBlockedApp(
            packageName = packageName,
            allowedFrom = result.allowedFrom,
            allowedTo = result.allowedTo
        )
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

    private fun sendBlockedNotificationToFirestore(
        packageName: String,
        appName: String,
        allowedFrom: String,
        allowedTo: String
    ) {

        val prefs = getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)

        val parentId = prefs.getString("parent_id", null) ?: run {
            // Log.e(TAG, "Missing parent_id in prefs")
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

        FirebaseFirestore.getInstance()
            .collection("notifications")
            .add(payload)
            .addOnSuccessListener { ref ->
                // Log.d(TAG, "Notification created: ${ref.id}")
            }
            .addOnFailureListener { e ->
                // Log.e(TAG, "Failed to create notification", e)
            }
    }

    override fun onInterrupt() {
        // Log.d(TAG, "Accessibility interrupted")
    }

    private fun getUserId(): String? {

        val prefs = getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)

        return prefs.getString("user_id", null)
    }

    override fun onDestroy() {
        super.onDestroy()

        ruleSyncManager.stop()
        handler.removeCallbacks(usageRunnable)
        handler.removeCallbacks(appsRunnable)

        Log.d(TAG, "Accessibility service destroyed")
    }
}