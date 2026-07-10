package com.engagepop.reactnative

import com.engagepop.EngagePop
import com.engagepop.EngagePopConfig
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.bridge.ReadableMap
import com.facebook.react.bridge.WritableArray
import com.facebook.react.modules.core.DeviceEventManagerModule

/** React Native bridge over the native EngagePop Android SDK. */
class EngagePopModule(private val reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName() = "EngagePopReactNative"

    @ReactMethod
    fun configure(siteKey: String, appKey: String, options: ReadableMap) {
        val base = if (options.hasKey("apiBaseUrl")) options.getString("apiBaseUrl") else null
        val debug = options.hasKey("debugLogging") && options.getBoolean("debugLogging")
        val autoShow = if (options.hasKey("autoShowInAppMessages")) options.getBoolean("autoShowInAppMessages") else true
        EngagePop.configure(
            reactContext.applicationContext,
            EngagePopConfig(siteKey, appKey, base ?: "https://edge.engagepop.com", debug, autoShow),
        )
        EngagePop.deepLinkHandler = { url ->
            emit("EngagePopDeepLink", url)
        }
        EngagePop.inbox?.onChanged = { emit("EngagePopInboxChange", null) }
    }

    private fun emit(name: String, body: Any?) {
        reactContext
            .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
            .emit(name, body)
    }

    // MARK: - Inbox

    @ReactMethod
    fun getInbox(promise: Promise) {
        val arr: WritableArray = Arguments.createArray()
        EngagePop.inbox?.messages()?.forEach { m ->
            val map = Arguments.createMap()
            map.putString("id", m.id)
            map.putString("title", m.title)
            map.putString("body", m.body)
            if (m.url != null) map.putString("url", m.url) else map.putNull("url")
            map.putDouble("receivedAt", m.receivedAt.toDouble())
            map.putBoolean("read", m.read)
            arr.pushMap(map)
        }
        promise.resolve(arr)
    }

    @ReactMethod
    fun unreadCount(promise: Promise) {
        promise.resolve(EngagePop.inbox?.unreadCount() ?: 0)
    }

    @ReactMethod
    fun markRead(id: String) { EngagePop.inbox?.markRead(id) }

    @ReactMethod
    fun markAllRead() { EngagePop.inbox?.markAllRead() }

    @ReactMethod
    fun removeMessage(id: String) { EngagePop.inbox?.remove(id) }

    @ReactMethod
    fun clearInbox() { EngagePop.inbox?.clear() }

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
