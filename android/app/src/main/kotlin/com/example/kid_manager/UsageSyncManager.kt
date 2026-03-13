package com.example.kid_manager

import android.content.Context
import android.app.usage.UsageStatsManager
import android.util.Log

import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.SetOptions
import com.google.firebase.Timestamp
import com.google.firebase.firestore.WriteBatch
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.tasks.await
import android.app.usage.UsageEvents
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

class UsageSyncManager(private val context: Context) {

    
    companion object {
        private const val TAG = "UsageSync"
    }
    fun syncUsageApps(userId: String) {

        CoroutineScope(Dispatchers.IO).launch {

            try {

                val firestore = FirebaseFirestore.getInstance()

                val now = System.currentTimeMillis()

                val start = getStartOfDay()

                /// 🔹 Lấy usage events

                val usageManager =
                    context.getSystemService(Context.USAGE_STATS_SERVICE)
                        as UsageStatsManager

                val events = usageManager.queryEvents(start, now)

                val (usageMsByPkg, lastUsedByPkg) =
                    computeUsageFromEvents(events)

                val appsRef = firestore
                    .collection("blocked_items")
                    .document(userId)
                    .collection("apps")

                val appsSnap = appsRef.get().await()

                val batch = firestore.batch()

                var totalMinutesToday = 0
                val minutesByPkg = mutableMapOf<String, Int>()

                val dayKey = SimpleDateFormat("yyyyMMdd", Locale.US)
                    .format(Date())

                val hour = getCurrentHour()

                for (doc in appsSnap.documents) {

                    val pkg = doc.id

                    val usageMs = usageMsByPkg[pkg]
                    val lastUsedMs = lastUsedByPkg[pkg]

                    if (usageMs == null && lastUsedMs == null) continue

                    val minutes = (usageMs ?: 0) / 60000

                    if (minutes > 0) {

                        minutesByPkg[pkg] = minutes.toInt()

                        totalMinutesToday += minutes.toInt()
                    }

                    /// DAILY USAGE

                    val dailyRef = doc.reference
                        .collection("usage_daily")
                        .document(dayKey)

                    val dailyData = hashMapOf(
                        "userId" to userId,
                        "package" to pkg,
                        "dateKey" to dayKey,
                        "date" to Timestamp(Date(start)),
                        "usageMs" to (usageMs ?: 0),
                        "updatedAt" to FieldValue.serverTimestamp()
                    )

                    batch.set(dailyRef, dailyData, SetOptions.merge())

                    /// DELTA USAGE

                    val prevUsage = doc.getLong("todayUsageMs") ?: 0

                    val deltaMs = (usageMs ?: 0) - prevUsage

                    val deltaMinutes = ((deltaMs ?: 0) / 60000)
                                    .toInt()
                                    .coerceAtLeast(0)

                    /// HOURLY

                    updateHourlyUsage(
                        batch,
                        firestore,
                        userId,
                        dayKey,
                        start,
                        hour,
                        deltaMinutes
                    )

                    /// UPDATE APP DOC

                    val updateData = hashMapOf<String, Any?>(
                        "todayUsageMs" to (usageMs ?: 0),
                        "todayLastSeen" to lastUsedMs?.let {
                            Timestamp(Date(it))
                        }
                    )

                    if (lastUsedMs != null && lastUsedMs > 0) {
                        updateData["lastSeen"] =
                            Timestamp(Date(lastUsedMs))
                    }

                    batch.set(doc.reference, updateData, SetOptions.merge())
                }

                /// DAILY FLAT

                val flatRef = firestore
                    .collection("blocked_items")
                    .document(userId)
                    .collection("usage_daily_flat")
                    .document(dayKey)

                val flatData = hashMapOf(
                    "date" to Timestamp(Date(start)),
                    "totalMinutes" to totalMinutesToday,
                    "apps" to minutesByPkg,
                    "updatedAt" to FieldValue.serverTimestamp()
                )

                batch.set(flatRef, flatData, SetOptions.merge())

                /// HEARTBEAT

                val rootRef = firestore
                    .collection("blocked_items")
                    .document(userId)

                batch.set(
                    rootRef,
                    mapOf(
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

                // Log.d("InstalledTAG", "Check kid app installed for $userId")

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

                docRef.set(data, SetOptions.merge()).await()

                Log.d("InstalledTAG", "Kid app status updated")

            } catch (e: Exception) {

                Log.e("InstalledTAG", "Installed apps sync error", e)

            }
        }
    }


    // helper

    private fun computeUsageFromEvents(
        events: UsageEvents
    ): Pair<MutableMap<String, Long>, MutableMap<String, Long>> {

        val usageMsByPkg = mutableMapOf<String, Long>()
        val lastUsedByPkg = mutableMapOf<String, Long>()
        val startTimes = mutableMapOf<String, Long>()

        val event = UsageEvents.Event()

        while (events.hasNextEvent()) {

            events.getNextEvent(event)

            val pkg = event.packageName ?: continue

            when (event.eventType) {

                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    startTimes[pkg] = event.timeStamp
                }

                UsageEvents.Event.ACTIVITY_PAUSED -> {

                    val start = startTimes[pkg] ?: continue
                    val delta = event.timeStamp - start

                    usageMsByPkg[pkg] =
                        (usageMsByPkg[pkg] ?: 0) + delta

                    lastUsedByPkg[pkg] = event.timeStamp

                    startTimes.remove(pkg)
                }
            }
        }

        return usageMsByPkg to lastUsedByPkg
    }
    
    private fun getStartOfDay(): Long {
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        return calendar.timeInMillis
    }
    private fun getCurrentHour(): Int {
        return Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
    }
    private fun calculateDeltaUsage(current: Long?, previous: Long?): Long {

        val now = current ?: 0
        val old = previous ?: 0

        val delta = now - old

        return if (delta > 0) delta else 0
    }

    private fun updateHourlyUsage(
        batch: WriteBatch,
        firestore: FirebaseFirestore,
        userId: String,
        dayKey: String,
        startOfDay: Long,
        hour: Int,
        deltaMinutes: Int
    ) {

        if (deltaMinutes <= 0) return

        val hourlyRef = firestore
            .collection("blocked_items")
            .document(userId)
            .collection("usage_hourly")
            .document(dayKey)

        val data = mapOf(
            "date" to Timestamp(Date(startOfDay)),
            "hours.$hour" to FieldValue.increment(deltaMinutes.toLong()),
            "updatedAt" to FieldValue.serverTimestamp()
        )

        batch.set(hourlyRef, data, SetOptions.merge())
    }
}