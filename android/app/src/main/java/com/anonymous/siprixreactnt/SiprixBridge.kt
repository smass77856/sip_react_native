package com.anonymous.siprixreactnt

import android.net.Uri
import android.util.Log
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import io.flutter.embedding.android.FlutterActivity

class SiprixBridge(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "SiprixBridge"
    }

    @ReactMethod
    fun openSiprixCall(phoneNumber: String, username: String, pass: String, promise: Promise) {
        val activity = currentActivity
        if (activity == null) {
            promise.reject("NO_ACTIVITY", "Current activity is null")
            return
        }

        try {
            // Encode call params into the initial route so Flutter can read them via
            // window.defaultRouteName on startup.
            val encodedPhone = Uri.encode(phoneNumber)
            val encodedUser = Uri.encode(username)
            val initialRoute = "/call?phone=$encodedPhone&user=$encodedUser"

            val intent = FlutterActivity
                .withNewEngine()
                .initialRoute(initialRoute)
                .build(activity)

            activity.startActivity(intent)
            promise.resolve("presented")
        } catch (e: Exception) {
            Log.e("SiprixBridge", "Failed to open Flutter screen: ${e.message}", e)
            promise.reject("OPEN_CALL_FAILED", e.message, e)
        }
    }
}
