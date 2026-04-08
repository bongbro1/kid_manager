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
import java.util.Calendar
import java.util.Date
import java.util.Locale

class UsageSyncManager(private val context: Context) {

    companion object {
        private const val TAG = "UsageSync"
    }

    private data class UsageEventsSummary(
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
                result[pkg] = (result[pkg] ?: 0L) + time
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

                val includedPackages = if (trackedPackages.isEmpty()) {
                    null
                } else {
                    trackedPackages
                }

                // 1) Reliable per-app totals for the day
                val usageMsByPkgRaw = queryUsageStats(
                    usageManager = usageManager,
                    start = startOfDay,
                    end = now
                )

                val usageMsByPkg = if (includedPackages == null) {
                    usageMsByPkgRaw
                } else {
                    usageMsByPkgRaw
                        .filterKeys { includedPackages.contains(it) }
                        .toMutableMap()
                }

                // 2) Event-based details for hourly buckets and last used
                val events = usageManager.queryEvents(startOfDay, now)

                val usageEventsSummary = computeUsageFromEvents(
                    events = events,
                    startOfDay = startOfDay,
                    now = now,
                    includedPackages = includedPackages
                )

                val lastUsedByPkg = usageEventsSummary.lastUsedByPkg
                val usageMsByHour = usageEventsSummary.usageMsByHour

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
                    // On day rollover, force a reset to 0 to avoid stale usage from yesterday.
                    if (usageMs == null && lastUsedMs == null && !shouldResetForNewDay) {
                        continue
                    }

                    val usageMsToWrite = usageMs ?: 0L
                    val minutes = (usageMsToWrite / 60000L).toInt()

                    if (minutes > 0) {
                        minutesByPkg[pkg] = minutes
                        totalMinutesToday += minutes
                    }

                    // DAILY APP USAGE
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

                    // UPDATE APP DOC
                    val updateData = hashMapOf<String, Any?>(
                        "todayUsageMs" to usageMsToWrite,
                        "todayUsageDayKey" to dayKey,
                        "todayLastSeen" to lastUsedMs?.let { Timestamp(Date(it)) }
                    )

                    if (lastUsedMs != null && lastUsedMs > 0) {
                        updateData["lastSeen"] = Timestamp(Date(lastUsedMs))
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

                // HOURLY USAGE (DEVICE LEVEL)
                updateHourlyUsage(
                    batch = batch,
                    firestore = firestore,
                    userId = userId,
                    dayKey = dayKey,
                    startOfDay = startOfDay,
                    usageMsByHour = usageMsByHour
                )

                // DAILY FLAT SUMMARY
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

                // ROOT UPDATE
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

                Log.d(TAG, "Usage sync completed")

            } catch (e: Exception) {
                Log.e(TAG, "Usage sync error", e)
            }
        }
    }

    fun syncInstalledApps(userId: String) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
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

    /**
     * Event-based processing for:
     * - hourly usage buckets
     * - last used timestamps
     *
     * Important:
     * - We only use MOVE_TO_FOREGROUND / MOVE_TO_BACKGROUND
     * - We track ONE active package at a time to avoid overlap double counting
     */
    private fun computeUsageFromEvents(
        events: UsageEvents,
        startOfDay: Long,
        now: Long,
        includedPackages: Set<String>? = null
    ): UsageEventsSummary {

        val lastUsedByPkg = mutableMapOf<String, Long>()
        val usageMsByHour = mutableMapOf<Int, Long>()

        var activePkg: String? = null
        var activeStart: Long? = null

        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {
            events.getNextEvent(event)

            val pkg = event.packageName ?: continue
            if (includedPackages != null && !includedPackages.contains(pkg)) {
                continue
            }

            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    val newStart = maxOf(event.timeStamp, startOfDay)

                    // Close previous active session before opening a new one
                    if (activePkg != null && activeStart != null) {
                        val end = minOf(event.timeStamp, now)
                        val delta = end - activeStart!!
                        if (delta > 0) {
                            addDurationToHourBuckets(
                                startMs = activeStart!!,
                                endMs = end,
                                usageMsByHour = usageMsByHour
                            )
                            lastUsedByPkg[activePkg!!] = end
                        }
                    }

                    activePkg = pkg
                    activeStart = newStart
                }

                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    if (activePkg == pkg && activeStart != null) {
                        val end = minOf(event.timeStamp, now)
                        val delta = end - activeStart!!
                        if (delta > 0) {
                            addDurationToHourBuckets(
                                startMs = activeStart!!,
                                endMs = end,
                                usageMsByHour = usageMsByHour
                            )
                            lastUsedByPkg[pkg] = end
                        }
                        activePkg = null
                        activeStart = null
                    }
                }
            }
        }

        // Handle app still in foreground
        if (activePkg != null && activeStart != null) {
            val delta = now - activeStart!!
            if (delta > 0) {
                addDurationToHourBuckets(
                    startMs = activeStart!!,
                    endMs = now,
                    usageMsByHour = usageMsByHour
                )
                lastUsedByPkg[activePkg!!] = now
            }
        }

        return UsageEventsSummary(
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

            usageMsByHour[hour] = (usageMsByHour[hour] ?: 0L) + delta
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