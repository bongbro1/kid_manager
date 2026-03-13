package com.example.kid_manager

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityManager


class MainActivity : FlutterActivity() {

    private val WATCHER_CONFIG_CHANNEL = "watcher_config"
    private val NOTIFICATION_CHANNEL = "notification_intent"
    private val ACCESSIBILITY_CHANNEL = "accessibility"
    private val SCHEDULE_USAGE_CHANNEL = "schedule_usage_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // WATCHER CHANNEL
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCHER_CONFIG_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    "saveWatcherConfig" -> {

                        val userId = call.argument<String>("userId")
                        val parentId = call.argument<String>("parentId")
                        val childName = call.argument<String>("childName")

                        if (userId.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "userId required", null)
                            return@setMethodCallHandler
                        }

                        val prefs = getSharedPreferences("watcher_rules", MODE_PRIVATE)

                        prefs.edit()
                            .putString("user_id", userId)
                            .putString("parent_id", parentId)
                            .putString("child_name", childName)
                            .apply()

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