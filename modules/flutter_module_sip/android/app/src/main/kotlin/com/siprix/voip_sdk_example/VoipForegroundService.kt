package com.siprix.voip_sdk_example

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Simple foreground service to keep the VoIP stack alive so the app
 * has a better chance to receive incoming calls while in background.
 *
 * Lưu ý: Hành vi khi user vuốt khỏi đa nhiệm phụ thuộc ROM/Android.
 * Foreground service giúp giảm khả năng bị kill, nhưng không thể
 * đảm bảo 100% giống các app được OEM whitelist như Zalo.
 */
class VoipForegroundService : Service() {

    override fun onCreate() {
        super.onCreate()
        startAsForeground()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Giữ service sống, nếu bị kill hệ thống sẽ cố gắng restart
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startAsForeground() {
        val channelId = "voip_foreground_channel"
        val channelName = "VoIP Service"

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (manager.getNotificationChannel(channelId) == null) {
                // Channel ít gây chú ý: không sound, không rung, ưu tiên thấp
                val channel = NotificationChannel(
                    channelId,
                    channelName,
                    NotificationManager.IMPORTANCE_MIN
                ).apply {
                    setSound(null, null)
                    enableVibration(false)
                    enableLights(false)
                    description = "Giữ kết nối VoIP để nhận cuộc gọi đến"
                }
                manager.createNotificationChannel(channel)
            }
        }

        // Khi bấm vào notification sẽ mở lại app
        val launchIntent = Intent(this, MainActivity::class.java)
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0
        )

        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("OneCX đang chạy nền")
            .setContentText("Sẵn sàng nhận cuộc gọi")
            .setSmallIcon(R.mipmap.ic_launcher) // dùng icon app
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_MIN) // ưu tiên rất thấp
            .setSilent(true) // không sound
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        startForeground(1001, notification)
    }
}


