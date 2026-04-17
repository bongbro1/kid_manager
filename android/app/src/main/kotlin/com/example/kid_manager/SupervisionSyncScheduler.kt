package com.example.kid_manager

import android.content.Context
import androidx.work.BackoffPolicy
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.NetworkType
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.util.concurrent.TimeUnit

object SupervisionSyncScheduler {
    private const val PERIODIC_WORK_NAME = "child_supervision_sync_periodic"
    private const val NEAR_REALTIME_WORK_NAME = "child_supervision_sync_near_realtime"
    private const val DEFAULT_NEAR_REALTIME_DELAY_MINUTES = 5L

    fun schedule(context: Context) {
        val workManager = WorkManager.getInstance(context)
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val periodicWork = PeriodicWorkRequestBuilder<SupervisionSyncWorker>(
            15,
            TimeUnit.MINUTES
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                10,
                TimeUnit.SECONDS
            )
            .build()

        workManager.enqueueUniquePeriodicWork(
            PERIODIC_WORK_NAME,
            ExistingPeriodicWorkPolicy.UPDATE,
            periodicWork
        )

        enqueueNearRealtime(context, 0)
    }

    fun scheduleFollowUp(context: Context, delayMinutes: Long = DEFAULT_NEAR_REALTIME_DELAY_MINUTES) {
        enqueueNearRealtime(context, delayMinutes)
    }

    fun cancel(context: Context) {
        val workManager = WorkManager.getInstance(context)
        workManager.cancelUniqueWork(NEAR_REALTIME_WORK_NAME)
        workManager.cancelUniqueWork(PERIODIC_WORK_NAME)
    }

    private fun enqueueNearRealtime(context: Context, delayMinutes: Long) {
        val workManager = WorkManager.getInstance(context)
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val builder = OneTimeWorkRequestBuilder<SupervisionSyncWorker>()
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                10,
                TimeUnit.SECONDS
            )

        if (delayMinutes > 0) {
            builder.setInitialDelay(delayMinutes, TimeUnit.MINUTES)
        }

        workManager.enqueueUniqueWork(
            NEAR_REALTIME_WORK_NAME,
            ExistingWorkPolicy.REPLACE,
            builder.build()
        )
    }
}
