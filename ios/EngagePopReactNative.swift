import Foundation
import React
import EngagePop

/// React Native bridge over the native EngagePop iOS SDK. Thin: it forwards JS
/// calls to the Swift SDK and re-emits deep links to JS.
@objc(EngagePopReactNative)
class EngagePopReactNative: RCTEventEmitter {

    private var hasListeners = false

    override static func requiresMainQueueSetup() -> Bool { true }

    override func supportedEvents() -> [String]! { ["EngagePopDeepLink", "EngagePopInboxChange"] }

    override func startObserving() { hasListeners = true }
    override func stopObserving() { hasListeners = false }

    @objc(configure:appKey:options:)
    func configure(_ siteKey: String, appKey: String, options: NSDictionary) {
        let base = (options["apiBaseUrl"] as? String).flatMap { URL(string: $0) }
            ?? URL(string: "https://edge.engagepop.com")!
        let debug = options["debugLogging"] as? Bool ?? false
        let autoShow = options["autoShowInAppMessages"] as? Bool ?? true
        EngagePop.configure(EngagePopConfig(
            siteKey: siteKey, appKey: appKey, apiBaseURL: base,
            debugLogging: debug, autoShowInAppMessages: autoShow
        ))
        EngagePop.shared.deepLinkHandler = { [weak self] url in
            guard let self = self, self.hasListeners else { return }
            self.sendEvent(withName: "EngagePopDeepLink", body: url.absoluteString)
        }
        // Re-emit inbox changes to JS.
        NotificationCenter.default.addObserver(
            forName: Inbox.didChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self = self, self.hasListeners else { return }
            self.sendEvent(withName: "EngagePopInboxChange", body: nil)
        }
    }

    // MARK: - Inbox

    @objc(getInbox:rejecter:)
    func getInbox(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        let messages = EngagePop.shared.inbox?.messages ?? []
        resolve(messages.map { [
            "id": $0.id, "title": $0.title, "body": $0.body,
            "url": $0.url ?? NSNull(), "receivedAt": $0.receivedAt.timeIntervalSince1970, "read": $0.read,
        ] })
    }

    @objc(unreadCount:rejecter:)
    func unreadCount(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        resolve(EngagePop.shared.inbox?.unreadCount ?? 0)
    }

    @objc(markRead:)
    func markRead(_ id: String) { EngagePop.shared.inbox?.markRead(id) }

    @objc(markAllRead)
    func markAllRead() { EngagePop.shared.inbox?.markAllRead() }

    @objc(removeMessage:)
    func removeMessage(_ id: String) { EngagePop.shared.inbox?.remove(id) }

    @objc(clearInbox)
    func clearInbox() { EngagePop.shared.inbox?.clear() }

    @objc(requestPushPermission:rejecter:)
    func requestPushPermission(_ resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) {
        EngagePop.requestPushAuthorization { granted in resolve(granted) }
    }

    @objc(identify:)
    func identify(_ attributes: NSDictionary) {
        EngagePop.identify((attributes as? [String: String]) ?? [:])
    }

    @objc(track:properties:)
    func track(_ event: String, properties: NSDictionary) {
        EngagePop.track(event, properties: attributes(properties))
    }

    @objc(convert:order:campaignId:)
    func convert(_ value: Double, order: NSString?, campaignId: NSNumber?) {
        let id = campaignId.flatMap { $0.int64Value > 0 ? $0.int64Value : nil }
        EngagePop.convert(value: value, order: order as String?, campaignID: id)
    }

    @objc(reset)
    func reset() { EngagePop.reset() }

    @objc(refreshInAppMessages)
    func refreshInAppMessages() { EngagePop.refreshInAppMessages() }

    private func attributes(_ dict: NSDictionary) -> [String: String]? {
        let map = (dict as? [String: String]) ?? [:]
        return map.isEmpty ? nil : map
    }
}
