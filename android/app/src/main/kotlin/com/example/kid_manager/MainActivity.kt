package com.example.kid_manager

import android.content.Intent
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.os.Bundle


class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "watcher")
            .setMethodCallHandler { call, result ->

                if (call.method == "startWatcher") {

                    val intent = Intent(this, AppWatcherService::class.java)
                    startForegroundService(intent)

                    result.success(true)
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "watcher_stream")
            .setStreamHandler(object : EventChannel.StreamHandler {

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    ForegroundAppBridge.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    ForegroundAppBridge.eventSink = null
                }
            })
    }

    private val CHANNEL = "notification_intent"

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        // Log.d("NOTI_DEBUG", "onNewIntent called")
        // Log.d("NOTI_DEBUG", "extras=" + intent.extras)

        val payload = intent.extras?.getString("payload")

        // Log.d("NOTI_DEBUG", "payload=$payload")

        if (payload != null) {
            MethodChannel(
                flutterEngine?.dartExecutor?.binaryMessenger!!,
                CHANNEL
            ).invokeMethod("notificationTap", payload)
        }
    }
}