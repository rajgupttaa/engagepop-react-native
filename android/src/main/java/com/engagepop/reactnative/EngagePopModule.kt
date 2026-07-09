package com.engagepop.reactnative

import com.engagepop.EngagePop
import com.engagepop.EngagePopConfig
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.modules.core.DeviceEventManagerModule

/** React Native bridge over the native EngagePop Android SDK. */
class EngagePopModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "EngagePopReactNative"

    @ReactMethod
    fun configure(siteKey: String, appKey: String, options: ReadableMap) {
        val base = if (options.hasKey("apiBaseUrl")) options.getString("apiBaseUrl") else null
        val debug = options.hasKey("debugLogging") && options.getBoolean("debugLogging")
        EngagePop.configure(
            reactContext.applicationContext,
            EngagePopConfig(siteKey, appKey, base ?: "https://edge.engagepop.com", debug),
        )
        EngagePop.deepLinkHandler = { url ->
            reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("EngagePopDeepLink", url)
        }
    }

    @ReactMethod
    fun requestPushPermission(promise: Promise) {
        currentActivity?.let { EngagePop.requestNotificationPermission(it) }
        promise.resolve(true)
    }

    @ReactMethod
    fun identify(attributes: ReadableMap) {
        EngagePop.identify(attributes.toStringMap())
    }

    @ReactMethod
    fun track(event: String, properties: ReadableMap?) {
        EngagePop.track(event, properties?.toStringMap())
    }

    @ReactMethod
    fun convert(value: Double, order: String?, campaignId: Double) {
        EngagePop.convert(value, order, if (campaignId > 0) campaignId.toLong() else null)
    }

    @ReactMethod
    fun reset() = EngagePop.reset()

    @ReactMethod
    fun refreshInAppMessages() = EngagePop.refreshInAppMessages()

    // Required so the JS-side NativeEventEmitter has these to call.
    @ReactMethod
    fun addListener(eventName: String) {}

    @ReactMethod
    fun removeListeners(count: Int) {}

    private fun ReadableMap.toStringMap(): Map<String, String> {
        val out = HashMap<String, String>()
        val it = keySetIterator()
        while (it.hasNextKey()) {
            val k = it.nextKey()
            getString(k)?.let { v -> out[k] = v }
        }
        return out
    }
}
