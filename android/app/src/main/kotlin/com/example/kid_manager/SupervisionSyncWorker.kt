package com.example.kid_manager

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters

class SupervisionSyncWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    companion object {
        private const val TAG = "SupervisionSyncWorker"
        private const val RULE_PREFS = "watcher_rules"
    }

    override suspend fun doWork(): Result {
        val prefs = applicationContext.getSharedPreferences(RULE_PREFS, Context.MODE_PRIVATE)
        val userId = prefs.getString("user_id", null)?.trim()

        if (userId.isNullOrEmpty()) {
            Log.d(TAG, "Skipping supervision sync because user_id is missing")
            return Result.success()
        }

        return try {
            try {
                com.google.firebase.FirebaseApp.initializeApp(applicationContext)
            } catch (_: Exception) {
                // Firebase may already be initialized for this process.
            }

            val usageSyncManager = UsageSyncManager(applicationContext)
            usageSyncManager.syncUsageAppsOnce(userId)
            usageSyncManager.syncInstalledAppsOnce(userId)
            usageSyncManager.syncUsageViolationsOnce(userId)
            SupervisionSyncScheduler.scheduleFollowUp(applicationContext)

            Log.d(TAG, "Supervision sync completed for userId=$userId")
            Result.success()
        } catch (e: Exception) {
            Log.e(TAG, "Supervision sync failed for userId=$userId", e)
            Result.retry()
        }
    }
}
