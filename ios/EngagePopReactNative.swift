import Foundation
import React
import EngagePop

/// React Native bridge over the native EngagePop iOS SDK. Thin: it forwards JS
/// calls to the Swift SDK and re-emits deep links to JS.
@objc(EngagePopReactNative)
class EngagePopReactNative: RCTEventEmitter {

    private var hasListeners = false

    override static func requiresMainQueueSetup() -> Bool { true }

    override func supportedEvents() -> [String]! { ["EngagePopDeepLink"] }

    override func startObserving() { hasListeners = true }
    override func stopObserving() { hasListeners = false }

    @objc(configure:appKey:options:)
    func configure(_ siteKey: String, appKey: String, options: NSDictionary) {
        let base = (options["apiBaseUrl"] as? String).flatMap { URL(string: $0) }
            ?? URL(string: "https://edge.engagepop.com")!
        let debug = options["debugLogging"] as? Bool ?? false
        EngagePop.configure(EngagePopConfig(siteKey: siteKey, appKey: appKey, apiBaseURL: base, debugLogging: debug))
        EngagePop.shared.deepLinkHandler = { [weak self] url in
            guard let self = self, self.hasListeners else { return }
            self.sendEvent(withName: "EngagePopDeepLink", body: url.absoluteString)
        }
    }

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
