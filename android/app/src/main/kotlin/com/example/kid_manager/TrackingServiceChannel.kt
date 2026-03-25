package com.example.kid_manager

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

object TrackingServiceChannel {
    private const val CHANNEL = "tracking_service"

    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTrackingService" -> {
                    result.success(TrackingForegroundService.start(context))
                }

                "stopTrackingService" -> {
                    TrackingForegroundService.stop(context)
                    result.success(true)
                }

                "isTrackingServiceRunning" -> {
                    result.success(TrackingForegroundService.isRunning)
                }

                else -> result.notImplemented()
            }
        }
    }
}
