package com.example.kid_manager

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel


class MainActivity : FlutterActivity() {

    private val WATCHER_CONFIG_CHANNEL = "watcher_config"
    private val NOTIFICATION_CHANNEL = "notification_intent"
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
