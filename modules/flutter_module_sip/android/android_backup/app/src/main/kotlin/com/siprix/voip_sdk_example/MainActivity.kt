package com.siprix.voip_sdk_example

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onStart() {
        super.onStart()
        // TẠM THỜI TẮT foreground service:
        // startVoipForegroundService()
    }

    // Để dùng lại foreground mode sau này, chỉ cần bỏ comment ở onStart()
    private fun startVoipForegroundService() {
        val intent = Intent(this, VoipForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}
