package com.example.kid_manager

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val WATCHER_CHANNEL = "watcher"
    private val NOTIFICATION_CHANNEL = "notification_intent"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WATCHER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startWatcher" -> {
                        val userId = call.argument<String>("userId")
                        val parentId = call.argument<String>("parentId")
                        val childName = call.argument<String>("childName")

                        if (userId.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "userId is required", null)
                            return@setMethodCallHandler
                        }

                        val prefs = getSharedPreferences("watcher_prefs", MODE_PRIVATE)
                        prefs.edit()
                            .putString("userId", userId)
                            .putString("parentId", parentId)
                            .putString("childName", childName)
                            .putBoolean("watcher_enabled", true)
                            .apply()

                        val intent = Intent(this, AppWatcherService::class.java).apply {
                            putExtra("userId", userId)
                            putExtra("parentId", parentId)
                            putExtra("childName", childName)
                        }

                        startForegroundService(intent)
                        result.success(true)
                    }

                    "stopWatcher" -> {
                        val prefs = getSharedPreferences("watcher_prefs", MODE_PRIVATE)
                        prefs.edit()
                            .putBoolean("watcher_enabled", false)
                            .remove("userId")
                            .remove("parentId")
                            .remove("childName")
                            .apply()

                        val intent = Intent(this, AppWatcherService::class.java)
                        stopService(intent)
                        result.success(true)
                    }


                    "isWatcherRunning" -> {
                        result.success(AppWatcherService.isRunning)
                    }

                    
                    else -> result.notImplemented()
                }
            }

        // EventChannel(flutterEngine.dartExecutor.binaryMessenger, "watcher_stream")
        //     .setStreamHandler(object : EventChannel.StreamHandler {
        //         override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        //             ForegroundAppBridge.eventSink = events
        //         }

        //         override fun onCancel(arguments: Any?) {
        //             ForegroundAppBridge.eventSink = null
        //         }
        //     })
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