package com.example.kid_manager

import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper

object ForegroundAppBridge {

    var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun send(packageName: String) {
        mainHandler.post {
            eventSink?.success(packageName)
        }
    }
}