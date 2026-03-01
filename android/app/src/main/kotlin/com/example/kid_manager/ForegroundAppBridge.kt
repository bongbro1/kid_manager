package com.example.kid_manager

import io.flutter.plugin.common.EventChannel

object ForegroundAppBridge {
    var eventSink: EventChannel.EventSink? = null

    fun send(packageName: String) {
        eventSink?.success(packageName)
    }
}