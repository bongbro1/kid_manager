package com.example.kid_manager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.AppOpsManager
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.os.Process
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {

    private val WATCHER_CONFIG_CHANNEL = "watcher_config"
    private val NOTIFICATION_CHANNEL = "notification_intent"
    private val BATTERY_CHANNEL = "battery_optimization"
    private val SOS_ALERTS_CHANNEL = "sos_alerts"
    private val SOS_AUDIO_PREFS = "sos_audio_escalation"
    private val SOS_NOTIFICATION_ID = 1001
    private val KEY_ACTIVE = "active"
    private val KEY_PREVIOUS_RINGER_MODE = "previous_ringer_mode"
    private val KEY_STREAM_PREFIX = "stream_"
    private val SOS_STREAMS = intArrayOf(
        AudioManager.STREAM_ALARM,
        AudioManager.STREAM_NOTIFICATION,
        AudioManager.STREAM_RING,
        AudioManager.STREAM_MUSIC,
    )
    private val TARGET_VOLUME_RATIO = 0.85f


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        TrackingServiceChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
            applicationContext,
        )
        DeviceTimeZoneChannel.register(
            flutterEngine.dartExecutor.binaryMessenger,
        )

        // WATCHER CHANNEL
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCHER_CONFIG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasUsageAccessPermission" -> {
                        result.success(hasUsageAccessPermission())
                    }

                    "saveWatcherConfig" -> {

                        val userId = call.argument<String>("userId")
                        val parentId = call.argument<String>("parentId")?.trim()
                        val childName = call.argument<String>("childName")

                        val prefs = getSharedPreferences("watcher_rules", MODE_PRIVATE)

                        if (userId.isNullOrBlank()) {

                            prefs.edit()
                                .remove("user_id")
                                .remove("parent_id")
                                .remove("child_name")
                                .apply()

                            SupervisionSyncScheduler.cancel(applicationContext)

                            result.success(true)
                            return@setMethodCallHandler
                        }

                        if (parentId.isNullOrBlank()) {
                            Log.w("MainActivity", "saveWatcherConfig with blank parentId for userId=$userId")
                        }

                        prefs.edit()
                            .putString("user_id", userId)
                            .putString("parent_id", parentId)
                            .putString("child_name", childName)
                            .apply()

                        SupervisionSyncScheduler.schedule(applicationContext)

                        Log.d("MainActivity", "watcher_rules saved userId=$userId parentId=$parentId childName=$childName")
                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "isIgnoringBatteryOptimizations" -> {

                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val ignoring = pm.isIgnoringBatteryOptimizations(packageName)

                        result.success(ignoring)
                    }

                    "requestIgnoreBatteryOptimizations" -> {

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {

                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )

                            startActivity(intent)
                        }

                        result.success(true)
                    }

                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SOS_ALERTS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hasNotificationPolicyAccess" -> {
                        result.success(hasNotificationPolicyAccess())
                    }

                    "canUseFullScreenIntent" -> {
                        result.success(canUseFullScreenIntent())
                    }

                    "openNotificationPolicyAccessSettings" -> {
                        openNotificationPolicyAccessSettings()
                        result.success(true)
                    }

                    "openFullScreenIntentSettings" -> {
                        openFullScreenIntentSettings()
                        result.success(true)
                    }

                    "openSosChannelSettings" -> {
                        openSosChannelSettings(call.argument<String>("channelId")?.trim())
                        result.success(true)
                    }

                    "ensureSosNotificationChannel" -> {
                        val channelId = call.argument<String>("channelId")?.trim()
                        val channelName = call.argument<String>("channelName")?.trim()
                        val channelDescription = call.argument<String>("channelDescription")?.trim()
                        val soundResName = call.argument<String>("soundResName")?.trim() ?: "sos"

                        if (channelId.isNullOrBlank() || channelName.isNullOrBlank()) {
                            result.error(
                                "invalid-argument",
                                "channelId and channelName are required",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        ensureSosNotificationChannel(
                            channelId = channelId,
                            channelName = channelName,
                            channelDescription = channelDescription ?: "",
                            soundResName = soundResName,
                        )
                        result.success(true)
                    }

                    "prepareSosAudioEscalation" -> {
                        result.success(prepareSosAudioEscalation())
                    }

                    "restoreSosAudioEscalation" -> {
                        result.success(restoreSosAudioEscalation())
                    }

                    else -> result.notImplemented()
                }
            }

        restoreOrphanedSosAudioEscalationIfNeeded()
    }

    private fun hasUsageAccessPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                packageName
            )
        }

        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun hasNotificationPolicyAccess(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return false
        }

        val manager = getSystemService(NotificationManager::class.java)
        return manager?.isNotificationPolicyAccessGranted == true
    }

    private fun canUseFullScreenIntent(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return true
        }

        val manager = getSystemService(NotificationManager::class.java)
        return manager?.canUseFullScreenIntent() == true
    }

    private fun openNotificationPolicyAccessSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun openFullScreenIntentSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            return
        }

        val intent = Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            startActivity(
                Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:$packageName")
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
        }
    }

    private fun openSosChannelSettings(channelId: String?) {
        val intent = Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS).apply {
            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            putExtra(Settings.EXTRA_CHANNEL_ID, channelId)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        try {
            startActivity(intent)
        } catch (_: ActivityNotFoundException) {
            startActivity(
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                    putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
        }
    }

    private fun ensureSosNotificationChannel(
        channelId: String,
        channelName: String,
        channelDescription: String,
        soundResName: String,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val wantsBypassDnd = hasNotificationPolicyAccess()
        val soundUri = Uri.parse("android.resource://$packageName/raw/$soundResName")
        val audioAttributes = AudioAttributes.Builder()
            .setUsage(AudioAttributes.USAGE_ALARM)
            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
            .build()
        val vibrationPattern = longArrayOf(0, 1200, 300, 1200, 300, 1600)
        val existing = manager.getNotificationChannel(channelId)
        val existingSound = existing?.sound?.toString()
        val desiredSound = soundUri.toString()
        val needsRecreate =
            existing == null ||
                existing.importance != NotificationManager.IMPORTANCE_HIGH ||
                existing.description != channelDescription ||
                existing.canBypassDnd() != wantsBypassDnd ||
                existingSound != desiredSound

        if (!needsRecreate) {
            return
        }

        if (existing != null) {
            manager.deleteNotificationChannel(channelId)
        }

        // Channel sound and DND bypass are sticky on Android, so recreate when
        // the desired escalation profile changes.
        val channel = NotificationChannel(
            channelId,
            channelName,
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            this.description = channelDescription
            enableVibration(true)
            this.vibrationPattern = vibrationPattern
            lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
            setShowBadge(true)
            setSound(soundUri, audioAttributes)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                setBypassDnd(wantsBypassDnd)
            }
        }

        manager.createNotificationChannel(channel)
    }

    private fun prepareSosAudioEscalation(): Boolean {
        restoreOrphanedSosAudioEscalationIfNeeded()

        val audioManager = getSystemService(AudioManager::class.java) ?: return false
        if (audioManager.isVolumeFixed) {
            Log.d("MainActivity", "SOS audio escalation skipped: device volume is fixed")
            return false
        }

        val prefs = getSharedPreferences(SOS_AUDIO_PREFS, Context.MODE_PRIVATE)
        val alreadyActive = prefs.getBoolean(KEY_ACTIVE, false)

        if (!alreadyActive) {
            val editor = prefs.edit()
            editor.putBoolean(KEY_ACTIVE, true)
            editor.putInt(KEY_PREVIOUS_RINGER_MODE, audioManager.ringerMode)
            SOS_STREAMS.forEach { stream ->
                editor.putInt("$KEY_STREAM_PREFIX$stream", audioManager.getStreamVolume(stream))
            }
            editor.apply()
        }

        if (hasNotificationPolicyAccess() &&
            audioManager.ringerMode != AudioManager.RINGER_MODE_NORMAL
        ) {
            try {
                audioManager.ringerMode = AudioManager.RINGER_MODE_NORMAL
            } catch (error: SecurityException) {
                Log.w("MainActivity", "Failed to normalize ringer mode for SOS", error)
            }
        }

        SOS_STREAMS.forEach { stream ->
            val maxVolume = audioManager.getStreamMaxVolume(stream)
            if (maxVolume <= 0) {
                return@forEach
            }

            val targetVolume = ((maxVolume * TARGET_VOLUME_RATIO).toInt()).coerceAtLeast(1)
            val currentVolume = audioManager.getStreamVolume(stream)
            if (currentVolume >= targetVolume) {
                return@forEach
            }

            try {
                audioManager.setStreamVolume(stream, targetVolume, 0)
            } catch (error: SecurityException) {
                Log.w("MainActivity", "Failed to raise stream=$stream for SOS", error)
            }
        }

        return true
    }

    private fun restoreSosAudioEscalation(): Boolean {
        val audioManager = getSystemService(AudioManager::class.java) ?: return false
        val prefs = getSharedPreferences(SOS_AUDIO_PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ACTIVE, false)) {
            return false
        }

        SOS_STREAMS.forEach { stream ->
            if (!prefs.contains("$KEY_STREAM_PREFIX$stream")) {
                return@forEach
            }

            val previousVolume = prefs.getInt("$KEY_STREAM_PREFIX$stream", -1)
            if (previousVolume < 0) {
                return@forEach
            }

            try {
                audioManager.setStreamVolume(stream, previousVolume, 0)
            } catch (error: SecurityException) {
                Log.w("MainActivity", "Failed to restore stream=$stream after SOS", error)
            }
        }

        if (prefs.contains(KEY_PREVIOUS_RINGER_MODE) && hasNotificationPolicyAccess()) {
            val previousRingerMode = prefs.getInt(
                KEY_PREVIOUS_RINGER_MODE,
                AudioManager.RINGER_MODE_NORMAL,
            )
            try {
                audioManager.ringerMode = previousRingerMode
            } catch (error: SecurityException) {
                Log.w("MainActivity", "Failed to restore ringer mode after SOS", error)
            }
        }

        prefs.edit().clear().apply()
        return true
    }

    private fun restoreOrphanedSosAudioEscalationIfNeeded() {
        val prefs = getSharedPreferences(SOS_AUDIO_PREFS, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(KEY_ACTIVE, false)) {
            return
        }

        val manager = getSystemService(NotificationManager::class.java) ?: return
        val hasActiveSosNotification = manager.activeNotifications.any { statusBarNotification ->
            statusBarNotification.id == SOS_NOTIFICATION_ID
        }
        if (!hasActiveSosNotification) {
            restoreSosAudioEscalation()
        }
    }



    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        Log.d("NOTI_DEBUG", "onNewIntent called")
        Log.d("NOTI_DEBUG", "extras=" + intent.extras)

        val payload = intent.extras?.getString("payload")

        Log.d("NOTI_DEBUG", "payload=$payload")

        if (payload != null) {
            MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger!!,
                NOTIFICATION_CHANNEL
            ).invokeMethod("notificationTap", payload)
        }
    }
}
