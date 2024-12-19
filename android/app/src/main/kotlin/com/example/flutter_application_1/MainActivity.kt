package com.example.flutter_application_1

import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Bundle

class MainActivity : FlutterActivity() {
    private val CHANNEL_ID = "channel_id"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Background Service"
            val descriptionText = "Channel for background service"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            val notificationManager: NotificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
