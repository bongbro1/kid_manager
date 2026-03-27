package com.example.kid_manager

import androidx.core.content.ContextCompat
import android.content.Intent
import android.content.Context
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager
import android.os.PowerManager
import android.provider.Settings
import android.net.Uri
import android.os.Build


class MainActivity : FlutterActivity() {

    private val WATCHER_CONFIG_CHANNEL = "watcher_config"
    private val NOTIFICATION_CHANNEL = "notification_intent"
    private val ACCESSIBILITY_CHANNEL = "accessibility"
    private val SCHEDULE_USAGE_CHANNEL = "schedule_usage_channel"
    private val BATTERY_CHANNEL = "battery_optimization"


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

                        Log.d("MainActivity", "watcher_rules saved userId=$userId parentId=$parentId childName=$childName")
                        result.success(true)
                    }
                    "isAccessibilityEnabled" -> {

                        val expectedService =
                            "$packageName/com.example.kid_manager.AppAccessibilityService"

                        val enabledServices = android.provider.Settings.Secure.getString(
                            contentResolver,
                            android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
                        )

                        val enabled = enabledServices?.contains(expectedService) == true

                        result.success(enabled)
                    }

                    else -> result.notImplemented()
                }
            }

        // ACCESSIBILITY CHANNEL
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {

                    "isAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }

                    "openAccessibilitySettings" -> {

                        val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

                        startActivity(intent)

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

    private fun isAccessibilityServiceEnabled(): Boolean {

        val manager = getSystemService(ACCESSIBILITY_SERVICE) as AccessibilityManager

        val enabledServices =
            manager.getEnabledAccessibilityServiceList(
                AccessibilityServiceInfo.FEEDBACK_ALL_MASK
            )

        for (service in enabledServices) {

            if (service.resolveInfo.serviceInfo.packageName == packageName &&
                service.resolveInfo.serviceInfo.name.contains("AppAccessibilityService")
            ) {
                return true
            }
        }

        return false
    }

    
}
