package com.anonymous.siprixreactnt

import android.content.Intent
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

// Note: To make FlutterActivity available, you MUST add the Flutter module to your build.gradle
// import io.flutter.embedding.android.FlutterActivity

class SiprixBridge(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "SiprixBridge"
    }

    @ReactMethod
    fun openSiprixCall(phoneNumber: String, username: String, pass: String) {
        val currentActivity = currentActivity
        if (currentActivity != null) {
            try {
                val intent = io.flutter.embedding.android.FlutterActivity
                    .withNewEngine()
                    .initialRoute("/call_screen?phone=$phoneNumber")
                    .build(currentActivity)
                
                // You can still pass extras if you want to extract them via MethodChannels later
                intent.putExtra("phone", phoneNumber)
                intent.putExtra("user", username)
                
                currentActivity.startActivity(intent)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }
}
