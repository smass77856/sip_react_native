package com.anonymous.siprixreactnt

import android.util.Log
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod

class SiprixBridge(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String {
        return "SiprixBridge"
    }

    @ReactMethod
    fun openSiprixCall(phoneNumber: String, username: String, pass: String, promise: Promise) {
        val activity = reactApplicationContext.currentActivity
        if (activity == null) {
            promise.reject("NO_ACTIVITY", "Current activity is null")
            return
        }

        try {
            val flutterActivityClass = Class.forName("io.flutter.embedding.android.FlutterActivity")
            val withNewEngine = flutterActivityClass.getMethod("withNewEngine")
            val engineBuilder = withNewEngine.invoke(null)

            val buildMethod = engineBuilder.javaClass.getMethod("build", android.content.Context::class.java)
            val intent = buildMethod.invoke(engineBuilder, activity) as android.content.Intent

            intent.putExtra("phone", phoneNumber)
            intent.putExtra("user", username)
            activity.startActivity(intent)
            promise.resolve("presented")
        } catch (e: Exception) {
            Log.e("SiprixBridge", "Failed to open Flutter screen: ${e.message}")
            promise.reject("OPEN_CALL_FAILED", e.message, e)
        }
    }
}
