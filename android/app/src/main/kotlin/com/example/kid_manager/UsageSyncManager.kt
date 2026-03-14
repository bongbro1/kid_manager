package com.example.kid_manager

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.util.Log
import com.google.firebase.Timestamp
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.google.firebase.firestore.WriteBatch
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import java.text.SimpleDateFormat
import java.util.*

class UsageSyncManager(private val context: Context) {

    companion object {
        private const val TAG = "UsageSync"
    }

    private data class UsageEventsSummary(
        val usageMsByPkg: Map<String, Long>,
        val lastUsedByPkg: MutableMap<String, Long>,
        val usageMsByHour: MutableMap<Int, Long>,
    )

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

            val pkg = stat.packageName ?: continue
            val time = stat.totalTimeInForeground

            if (time > 0) {

                result[pkg] =
                    (result[pkg] ?: 0) + time
            }
        }

        return result
    }

    fun syncUsageApps(userId: String) {

        CoroutineScope(Dispatchers.IO).launch {

            try {
                val firestore = FirebaseFirestore.getInstance()

                val now = System.currentTimeMillis()
                val startOfDay = getStartOfDay()
                val usageManager =
                    context.getSystemService(Context.USAGE_STATS_SERVICE)
                            as UsageStatsManager

                val appsRef = firestore
                    .collection("blocked_items")
                    .document(userId)
                    .collection("apps")

                val appsSnap = appsRef.get().await()
                val trackedPackages = appsSnap.documents
                    .map { it.id }
                    .toSet()

                val events = usageManager.queryEvents(startOfDay, now)

                val usageEventsSummary =
                    computeUsageFromEvents(
                        events = events,
                        startOfDay = startOfDay,
                        now = now,
                        includedPackages = if (trackedPackages.isEmpty()) {
                            null
                        } else {
                            trackedPackages
                        }
                    )

                val lastUsedByPkg = usageEventsSummary.lastUsedByPkg
                val usageMsByHour = usageEventsSummary.usageMsByHour
                val usageMsByPkg = usageEventsSummary.usageMsByPkg

                val totalUsageMsToday = usageMsByPkg.values.sum()

                val rootRef = firestore
                    .collection("blocked_items")
                    .document(userId)

                val batch = firestore.batch()

                val dayKey = SimpleDateFormat(
                    "yyyyMMdd",
                    Locale.US
                ).format(Date(startOfDay))

                var totalMinutesToday = 0
                val minutesByPkg = mutableMapOf<String, Int>()

                for (doc in appsSnap.documents) {

                    val pkg = doc.id

                    val usageMs = usageMsByPkg[pkg]
                    val lastUsedMs = lastUsedByPkg[pkg]
                    val lastUsageDayKey = doc.getString("todayUsageDayKey")
                    val shouldResetForNewDay = lastUsageDayKey != dayKey

                    // Skip writes when there is no new data in the same day.
                    // On day rollover, force a reset to 0 to avoid showing stale usage from yesterday.
                    if (usageMs == null && lastUsedMs == null && !shouldResetForNewDay) continue

                    val usageMsToWrite = usageMs ?: 0L

                    val minutes = usageMsToWrite / 60000

                    if (minutes > 0) {

                        minutesByPkg[pkg] = minutes.toInt()

                        totalMinutesToday += minutes.toInt()
                    }

                    /// DAILY APP USAGE

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

                    batch.set(
                        dailyRef,
                        dailyData,
                        SetOptions.merge()
                    )

                    /// UPDATE APP DOC

                    val updateData = hashMapOf<String, Any?>(
                        "todayUsageMs" to usageMsToWrite,
                        "todayUsageDayKey" to dayKey,
                        "todayLastSeen" to lastUsedMs?.let {
                            Timestamp(Date(it))
                        }
                    )

                    if (lastUsedMs != null && lastUsedMs > 0) {

                        updateData["lastSeen"] =
                            Timestamp(Date(lastUsedMs))
                    }

                    batch.set(
                        doc.reference,
                        updateData,
                        SetOptions.merge()
                    )
                }

                // Recovery path: if app docs were deleted on Firestore,
                // keep total usage from midnight to now instead of 0.
                if (appsSnap.isEmpty && totalUsageMsToday > 0) {
                    totalMinutesToday = (totalUsageMsToday / 60000L).toInt()
                }

                /// HOURLY USAGE (DEVICE LEVEL)
                
                updateHourlyUsage(
                    batch,
                    firestore,
                    userId,
                    dayKey,
                    startOfDay,
                    usageMsByHour
                )

                /// DAILY FLAT SUMMARY

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

                batch.set(
                    flatRef,
                    flatData,
                    SetOptions.merge()
                )

                /// ROOT UPDATE

                batch.set(
                    rootRef,
                    mapOf(
                        "todayTotalUsageMs" to totalUsageMsToday,
                        "lastHeartbeat" to FieldValue.serverTimestamp()
                    ),
                    SetOptions.merge()
                )

                batch.commit().await()

                Log.d(TAG, "Usage sync completed")

            } catch (e: Exception) {

                Log.e(TAG, "Usage sync error", e)
            }
        }
    }

    fun syncInstalledApps(userId: String) {

        CoroutineScope(Dispatchers.IO).launch {

            try {

                val pm = context.packageManager
                val packageName = "com.example.kid_manager"

                var installed = true

                try {

                    pm.getPackageInfo(packageName, 0)

                } catch (e: Exception) {

                    installed = false
                }

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

                docRef.set(
                    data,
                    SetOptions.merge()
                ).await()

                Log.d(TAG, "Kid app status updated")

            } catch (e: Exception) {

                Log.e(TAG, "Installed apps sync error", e)
            }
        }
    }

    private fun computeUsageFromEvents(
        events: UsageEvents,
        startOfDay: Long,
        now: Long,
        includedPackages: Set<String>? = null
    ): UsageEventsSummary {

        val usageMsByPkg = mutableMapOf<String, Long>()
        val lastUsedByPkg = mutableMapOf<String, Long>()
        val usageMsByHour = mutableMapOf<Int, Long>()
        val startTimes = mutableMapOf<String, Long>()

        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {

            events.getNextEvent(event)

            val pkg = event.packageName ?: continue
            if (includedPackages != null && !includedPackages.contains(pkg)) {
                continue
            }

            when (event.eventType) {

                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {

                    startTimes[pkg] =
                        maxOf(event.timeStamp, startOfDay)
                }

                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {

                    val start = startTimes[pkg] ?: continue
                    val end = event.timeStamp
                    val delta = end - start

                    if (delta <= 0) {
                        startTimes.remove(pkg)
                        continue
                    }

                    // per-app usage
                    usageMsByPkg[pkg] =
                        (usageMsByPkg[pkg] ?: 0L) + delta

                    // hourly buckets
                    addDurationToHourBuckets(
                        start,
                        end,
                        usageMsByHour
                    )

                    lastUsedByPkg[pkg] = end

                    startTimes.remove(pkg)
                }
            }
        }

        // Handle apps still in foreground
        for ((pkg, start) in startTimes) {
            if (includedPackages != null && !includedPackages.contains(pkg)) {
                continue
            }

            val delta = now - start
            if (delta <= 0) continue

            usageMsByPkg[pkg] =
                (usageMsByPkg[pkg] ?: 0L) + delta

            addDurationToHourBuckets(
                start,
                now,
                usageMsByHour
            )

            lastUsedByPkg[pkg] = now
        }

        return UsageEventsSummary(
            usageMsByPkg = usageMsByPkg,
            lastUsedByPkg = lastUsedByPkg,
            usageMsByHour = usageMsByHour
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

        batch.set(
            hourlyRef,
            data,
            SetOptions.merge()
        )
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

            usageMsByHour[hour] =
                (usageMsByHour[hour] ?: 0L) + delta

            cursor = segmentEnd
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

}
