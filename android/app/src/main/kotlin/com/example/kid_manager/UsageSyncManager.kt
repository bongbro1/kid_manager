package com.example.kid_manager

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log
import com.google.firebase.Timestamp
import com.google.firebase.functions.FirebaseFunctions
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.WriteBatch
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class UsageSyncManager(private val context: Context) {

    companion object {
        private const val TAG = "UsageSync"
        private const val RULE_PREFS = "watcher_rules"
        private const val KEY_LAST_EVENT_SCAN_AT = "last_usage_event_scan_at"
        private const val NOTIFY_COOLDOWN_MS = 15 * 60 * 1000L
        private const val EVENT_SCAN_OVERLAP_MS = 60 * 1000L
    }

    private data class UsageEventsSummary(
        val lastUsedByPkg: MutableMap<String, Long>,
        val usageMsByHour: MutableMap<Int, Long>,
        val usageMsByPkg: MutableMap<String, Long>
    )

    fun syncUsageApps(userId: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                syncUsageAppsOnce(userId)
            } catch (e: Exception) {
                Log.e(TAG, "Usage sync error", e)
            }
        }
    }

    suspend fun syncUsageAppsOnce(userId: String) {
        val firestore = FirebaseFirestore.getInstance()
        val now = System.currentTimeMillis()
        val startOfDay = getStartOfDay()
        val usageManager =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager

        val appsRef = firestore
            .collection("blocked_items")
            .document(userId)
            .collection("apps")

        val appsSnap = appsRef.get().await()
        val trackedPackages = appsSnap.documents.map { it.id }.toSet()
        val includedPackages = trackedPackages.takeIf { it.isNotEmpty() }

        val events = usageManager.queryEvents(startOfDay, now)
        val usageEventsSummary = computeUsageFromEvents(
            events = events,
            startOfDay = startOfDay,
            now = now,
            includedPackages = includedPackages
        )

        val usageMsByPkg = usageEventsSummary.usageMsByPkg
        val lastUsedByPkg = usageEventsSummary.lastUsedByPkg
        val usageMsByHour = usageEventsSummary.usageMsByHour
        val totalUsageMsToday = usageMsByPkg.values.sum()

        val rootRef = firestore
            .collection("blocked_items")
            .document(userId)

        val batch = firestore.batch()

        val dayKey = SimpleDateFormat("yyyyMMdd", Locale.US).format(Date(startOfDay))
        var totalMinutesToday = 0
        val minutesByPkg = mutableMapOf<String, Int>()

        val installedPackages = try {
            context.packageManager.getInstalledPackages(0).map { it.packageName }.toSet()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to get installed packages", e)
            null
        }

        for (doc in appsSnap.documents) {
            val pkg = doc.id

            // If app is not installed on device, remove from tracking list
            if (installedPackages != null && !installedPackages.contains(pkg)) {
                Log.i(TAG, "App $pkg not found on device, removing from Firestore")
                batch.delete(doc.reference)
                continue
            }

            val usageMs = usageMsByPkg[pkg] ?: 0L
            val lastUsedMs = lastUsedByPkg[pkg]
            val lastUsageDayKey = doc.getString("todayUsageDayKey")
            val currentUsageMsInFirestore = doc.getLong("todayUsageMs") ?: 0L
            val shouldResetForNewDay = lastUsageDayKey != dayKey

            // Chỉ skip nếu: Cùng ngày VÀ usage không thay đổi VÀ không có thông tin lastUsed mới
            if (!shouldResetForNewDay && usageMs == currentUsageMsInFirestore && lastUsedMs == null) {
                continue
            }

            val usageMsToWrite = usageMs
            val minutes = (usageMsToWrite / 60000L).toInt()

            if (minutes > 0) {
                minutesByPkg[pkg] = minutes
                totalMinutesToday += minutes
            }

            val dailyRef = doc.reference
                .collection("usage_daily")
                .document(dayKey)

            val dailyData = hashMapOf(
                "userId" to userId,
                "package" to pkg,
                "dateKey" to dayKey,
                "date" to Timestamp(Date(startOfDay)),
                "usageMs" to usageMsToWrite,
                "updatedAt" to FieldValue.serverTimestamp()
            )

            batch.set(dailyRef, dailyData, SetOptions.merge())

            val updateData = hashMapOf<String, Any?>(
                "todayUsageMs" to usageMsToWrite,
                "todayUsageDayKey" to dayKey,
                "todayLastSeen" to lastUsedMs?.let { Timestamp(Date(it)) }
            )

            if (lastUsedMs != null && lastUsedMs > 0) {
                updateData["lastSeen"] = Timestamp(Date(lastUsedMs))
            }

            batch.set(doc.reference, updateData, SetOptions.merge())
        }

        if (appsSnap.isEmpty && totalUsageMsToday > 0) {
            totalMinutesToday = (totalUsageMsToday / 60000L).toInt()
        }

        updateHourlyUsage(
            batch = batch,
            firestore = firestore,
            userId = userId,
            dayKey = dayKey,
            startOfDay = startOfDay,
            usageMsByHour = usageMsByHour
        )

        val flatRef = firestore
            .collection("blocked_items")
            .document(userId)
            .collection("usage_daily_flat")
            .document(dayKey)

        val flatData = hashMapOf(
            "date" to Timestamp(Date(startOfDay)),
            "totalMinutes" to totalMinutesToday,
            "apps" to minutesByPkg,
            "updatedAt" to FieldValue.serverTimestamp()
        )

        batch.set(flatRef, flatData, SetOptions.merge())
        batch.set(
            rootRef,
            mapOf(
                "todayTotalUsageMs" to totalUsageMsToday,
                "lastHeartbeat" to FieldValue.serverTimestamp()
            ),
            SetOptions.merge()
        )

        batch.commit().await()

        val totalMinutesSafe = (totalUsageMsToday / 60000L).toInt()
        if (totalMinutesSafe > 24 * 60) {
            Log.w(TAG, "Suspicious total usage > 24h: $totalMinutesSafe minutes")
        }

        Log.d(TAG, "Usage sync completed userId=$userId trackedPackages=${trackedPackages.size}")
    }

    fun syncInstalledApps(userId: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                syncInstalledAppsOnce(userId)
            } catch (e: Exception) {
                Log.e(TAG, "Installed apps sync error", e)
            }
        }
    }

    suspend fun syncInstalledAppsOnce(userId: String) {
        val packageName = context.packageName
        val firestore = FirebaseFirestore.getInstance()

        val docRef = firestore
            .collection("blocked_items")
            .document(userId)
            .collection("apps")
            .document(packageName)

        val data = mapOf(
            "kidLastSeen" to FieldValue.serverTimestamp(),
            "kidAppRemovedAlertSent" to false
        )

        docRef.set(data, SetOptions.merge()).await()
        Log.d(TAG, "Kid app status updated userId=$userId")
    }

    suspend fun syncUsageViolationsOnce(userId: String) {
        val prefs = context.getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
        val lastScanAt = prefs.getLong(KEY_LAST_EVENT_SCAN_AT, 0L)
        val now = System.currentTimeMillis()
        val startOfDay = getStartOfDay()
        val scanFrom = maxOf(lastScanAt - EVENT_SCAN_OVERLAP_MS, startOfDay)

        if (scanFrom >= now) {
            Log.d(TAG, "Skip violation scan because scanFrom >= now")
            return
        }

        val firestore = FirebaseFirestore.getInstance()
        val appsSnap = firestore
            .collection("blocked_items")
            .document(userId)
            .collection("apps")
            .get()
            .await()

        if (appsSnap.isEmpty) {
            prefs.edit().putLong(KEY_LAST_EVENT_SCAN_AT, now).apply()
            Log.d(TAG, "Skip violation scan because no apps were found for userId=$userId")
            return
        }

        val rulesByPackage = loadRulesByPackage(appsSnap)
        val trackedPackages = rulesByPackage.keys
        if (trackedPackages.isEmpty()) {
            prefs.edit().putLong(KEY_LAST_EVENT_SCAN_AT, now).apply()
            Log.d(TAG, "Skip violation scan because no rules were found for userId=$userId")
            return
        }

        val blockedNowPackages = rulesByPackage.entries.mapNotNull { (packageName, rule) ->
            val result = BlockRuleEvaluator.checkBlocked(rule = rule, atMillis = now)
            if (!result.isBlocked) {
                null
            } else {
                "$packageName(${getAppName(packageName)})"
            }
        }
        Log.d(
            TAG,
            "[VIOLATION_TRACE] blocked_now_candidates count=${blockedNowPackages.size} " +
                "packages=${blockedNowPackages.take(10)}"
        )

        val usageManager =
            context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val events = usageManager.queryEvents(scanFrom, now)
        val event = UsageEvents.Event()

        val latestViolationAtByPkg = mutableMapOf<String, Long>()
        val latestViolationResultByPkg = mutableMapOf<String, BlockCheckResult>()
        var scannedEventCount = 0
        var matchedForegroundEventCount = 0

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            scannedEventCount += 1

            if (!isForegroundStartEvent(event.eventType)) {
                continue
            }

            matchedForegroundEventCount += 1

            val packageName = event.packageName ?: continue
            if (!trackedPackages.contains(packageName)) {
                continue
            }

            val rule = rulesByPackage[packageName] ?: continue
            val result = BlockRuleEvaluator.checkBlocked(
                rule = rule,
                atMillis = event.timeStamp
            )

            if (!result.isBlocked) {
                continue
            }

            val currentLatest = latestViolationAtByPkg[packageName]
            if (currentLatest == null || event.timeStamp > currentLatest) {
                latestViolationAtByPkg[packageName] = event.timeStamp
                latestViolationResultByPkg[packageName] = result
            }
        }

        Log.d(
            TAG,
            "Violation scan completed userId=$userId scanFrom=$scanFrom now=$now " +
                "scannedEvents=$scannedEventCount foregroundEvents=$matchedForegroundEventCount " +
                "violatingPackages=${latestViolationAtByPkg.size}"
        )

        for ((packageName, eventAt) in latestViolationAtByPkg) {
            if (!shouldNotifyViolation(prefs, packageName, eventAt)) {
                continue
            }

            val result = latestViolationResultByPkg[packageName] ?: continue
            Log.d(
                TAG,
                "[VIOLATION_TRACE] notify_candidate package=$packageName eventAt=$eventAt " +
                    "allowedFrom=${result.allowedFrom} allowedTo=${result.allowedTo}"
            )
            sendUsageViolationNotification(
                prefs = prefs,
                packageName = packageName,
                eventAt = eventAt,
                allowedFrom = result.allowedFrom,
                allowedTo = result.allowedTo
            )
            markViolationNotified(prefs, packageName, eventAt)
        }

        prefs.edit().putLong(KEY_LAST_EVENT_SCAN_AT, now).apply()
    }

    private fun shouldNotifyViolation(
        prefs: android.content.SharedPreferences,
        packageName: String,
        eventAt: Long
    ): Boolean {
        val key = "last_violation_notify_$packageName"
        val last = prefs.getLong(key, 0L)
        if (eventAt - last < NOTIFY_COOLDOWN_MS) {
            Log.d(TAG, "Skip violation notify due to cooldown package=$packageName")
            return false
        }

        return true
    }

    private fun markViolationNotified(
        prefs: android.content.SharedPreferences,
        packageName: String,
        eventAt: Long
    ) {
        prefs.edit().putLong("last_violation_notify_$packageName", eventAt).apply()
    }

    private suspend fun sendUsageViolationNotification(
        prefs: android.content.SharedPreferences,
        packageName: String,
        eventAt: Long,
        allowedFrom: String,
        allowedTo: String
    ) {
        val parentId = prefs.getString("parent_id", null)?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?: run {
                Log.w(TAG, "Skip violation notification because parent_id is missing")
                return
            }

        val childName = prefs.getString("child_name", "Unknown") ?: "Unknown"
        val appName = getAppName(packageName)
        val blockedAt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())
            .format(Date(eventAt))
        val traceId = buildViolationTraceId(packageName, eventAt)

        val payload = hashMapOf(
            "receiverId" to parentId,
            "type" to "blockedApp",
            "title" to "Ứng dụng ngoài khung giờ",
            "body" to "$childName đã mở ứng dụng ngoài khung giờ: $appName",
            "data" to hashMapOf(
                "studentName" to childName,
                "appName" to appName,
                "packageName" to packageName,
                "blockedAt" to blockedAt,
                "allowedFrom" to allowedFrom,
                "allowedTo" to allowedTo,
                "debugTraceId" to traceId,
                "debugSource" to "usage_events_worker",
                "debugEventAtMs" to eventAt.toString()
            )
        )

        val response = FirebaseFunctions.getInstance("asia-southeast1")
            .getHttpsCallable("enqueueAuthorizedNotification")
            .call(payload)
            .await()
        val notificationId = (response.data as? Map<*, *>)?.get("notificationId")

        Log.d(
            TAG,
            "[VIOLATION_TRACE] notification_enqueued traceId=$traceId notificationId=$notificationId " +
                "parentId=$parentId package=$packageName blockedAt=$blockedAt"
        )
    }

    private suspend fun loadRulesByPackage(
        appsSnap: com.google.firebase.firestore.QuerySnapshot
    ): Map<String, NativeRule> {
        val rules = mutableMapOf<String, NativeRule>()

        for (doc in appsSnap.documents) {
            val packageName = doc.id
            val ruleSnap = doc.reference
                .collection("usage_rule")
                .document("config")
                .get()
                .await()

            if (!ruleSnap.exists()) {
                continue
            }

            val data = ruleSnap.data ?: continue
            rules[packageName] = parseRule(data)
        }

        return rules
    }

    private fun parseRule(data: Map<String, Any>): NativeRule {
        val enabled = data["enabled"] as? Boolean ?: true

        val weekdays = (data["weekdays"] as? List<*>)
            ?.mapNotNull { (it as? Number)?.toInt() }
            ?.toSet()
            ?: emptySet()

        val windows = (data["windows"] as? List<*>)
            ?.mapNotNull {
                val map = it as? Map<*, *> ?: return@mapNotNull null
                val start = (map["startMin"] as? Number)?.toInt()
                    ?: return@mapNotNull null
                val end = (map["endMin"] as? Number)?.toInt()
                    ?: return@mapNotNull null
                NativeTimeWindow(start, end)
            }
            ?: emptyList()

        val overrides = (data["overrides"] as? Map<*, *>)
            ?.mapNotNull { (k, v) ->
                val key = k?.toString() ?: return@mapNotNull null
                val value = v?.toString() ?: return@mapNotNull null
                key to value
            }
            ?.toMap()
            ?: emptyMap()

        return NativeRule(
            enabled = enabled,
            weekdays = weekdays,
            windows = windows,
            overrides = overrides
        )
    }

    private fun queryUsageStats(
        usageManager: UsageStatsManager,
        start: Long,
        end: Long
    ): MutableMap<String, Long> {
        val result = mutableMapOf<String, Long>()
        val stats = usageManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            start,
            end
        )

        for (stat in stats) {
            // Chỉ lấy dữ liệu của các buckets kết thúc sau thời điểm bắt đầu ngày (start)
            // Loại bỏ các buckets thuộc về ngày hôm trước nhưng vẫn bị trả về do giao thoa ranh giới
            if (stat.lastTimeStamp < start) continue

            val pkg = stat.packageName ?: continue
            val time = stat.totalTimeInForeground
            if (time > 0) {
                result[pkg] = (result[pkg] ?: 0L) + time
            }
        }

        return result
    }

    private fun computeUsageFromEvents(
        events: UsageEvents,
        startOfDay: Long,
        now: Long,
        includedPackages: Set<String>? = null
    ): UsageEventsSummary {
        val lastUsedByPkg = mutableMapOf<String, Long>()
        val usageMsByHour = mutableMapOf<Int, Long>()
        val usageMsByPkg = mutableMapOf<String, Long>()

        var activePkg: String? = null
        var activeStart: Long? = null

        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)

            val pkg = event.packageName ?: continue
            if (includedPackages != null && !includedPackages.contains(pkg)) {
                continue
            }

            when {
                isForegroundStartEvent(event.eventType) -> {
                    val newStart = maxOf(event.timeStamp, startOfDay)

                    if (activePkg != null && activeStart != null) {
                        val end = minOf(event.timeStamp, now)
                        val delta = end - activeStart!!
                        if (delta > 0) {
                            addDurationToHourBuckets(
                                startMs = activeStart!!,
                                endMs = end,
                                usageMsByHour = usageMsByHour
                            )
                            usageMsByPkg[activePkg!!] = (usageMsByPkg[activePkg!!] ?: 0L) + delta
                            lastUsedByPkg[activePkg!!] = end
                        }
                    }

                    activePkg = pkg
                    activeStart = newStart
                }

                isForegroundStopEvent(event.eventType) -> {
                    if (activePkg == pkg && activeStart != null) {
                        val end = minOf(event.timeStamp, now)
                        val delta = end - activeStart!!
                        if (delta > 0) {
                            addDurationToHourBuckets(
                                startMs = activeStart!!,
                                endMs = end,
                                usageMsByHour = usageMsByHour
                            )
                            usageMsByPkg[pkg] = (usageMsByPkg[pkg] ?: 0L) + delta
                            lastUsedByPkg[pkg] = end
                        }
                        activePkg = null
                        activeStart = null
                    }
                }
            }
        }

        if (activePkg != null && activeStart != null) {
            val delta = now - activeStart!!
            if (delta > 0) {
                addDurationToHourBuckets(
                    startMs = activeStart!!,
                    endMs = now,
                    usageMsByHour = usageMsByHour
                )
                usageMsByPkg[activePkg!!] = (usageMsByPkg[activePkg!!] ?: 0L) + delta
                lastUsedByPkg[activePkg!!] = now
            }
        }

        return UsageEventsSummary(
            lastUsedByPkg = lastUsedByPkg,
            usageMsByHour = usageMsByHour,
            usageMsByPkg = usageMsByPkg
        )
    }

    private fun updateHourlyUsage(
        batch: WriteBatch,
        firestore: FirebaseFirestore,
        userId: String,
        dayKey: String,
        startOfDay: Long,
        usageMsByHour: Map<Int, Long>
    ) {
        val hourlyRef = firestore
            .collection("blocked_items")
            .document(userId)
            .collection("usage_hourly")
            .document(dayKey)

        val hoursMap = mutableMapOf<String, Int>()
        for (hour in 0..23) {
            val usageMs = usageMsByHour[hour] ?: 0L
            hoursMap[hour.toString()] = (usageMs / 60000L).toInt()
        }

        val data = mapOf(
            "date" to Timestamp(Date(startOfDay)),
            "hours" to hoursMap,
            "updatedAt" to FieldValue.serverTimestamp()
        )

        batch.set(hourlyRef, data, SetOptions.merge())
    }

    private fun addDurationToHourBuckets(
        startMs: Long,
        endMs: Long,
        usageMsByHour: MutableMap<Int, Long>
    ) {
        if (endMs <= startMs) return

        val calendar = Calendar.getInstance()
        var cursor = startMs

        while (cursor < endMs) {
            calendar.timeInMillis = cursor

            val hour = calendar.get(Calendar.HOUR_OF_DAY)

            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            calendar.add(Calendar.HOUR_OF_DAY, 1)

            val nextHourStart = calendar.timeInMillis
            val segmentEnd = minOf(endMs, nextHourStart)
            val delta = segmentEnd - cursor

            usageMsByHour[hour] = (usageMsByHour[hour] ?: 0L) + delta
            cursor = segmentEnd
        }
    }

    private fun getAppName(packageName: String): String {
        return try {
            val pm = context.packageManager
            val appInfo = pm.getApplicationInfo(packageName, 0)
            pm.getApplicationLabel(appInfo).toString()
        } catch (e: Exception) {
            packageName
        }
    }

    private fun getStartOfDay(): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }

    private fun isForegroundStartEvent(eventType: Int): Boolean {
        return eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
            eventType == UsageEvents.Event.ACTIVITY_RESUMED
    }

    private fun isForegroundStopEvent(eventType: Int): Boolean {
        return eventType == UsageEvents.Event.MOVE_TO_BACKGROUND ||
            eventType == UsageEvents.Event.ACTIVITY_PAUSED ||
            eventType == UsageEvents.Event.ACTIVITY_STOPPED
    }

    private fun buildViolationTraceId(packageName: String, eventAt: Long): String {
        return "violation_${packageName.replace('.', '_')}_$eventAt"
    }
}
