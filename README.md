# @engagepop/react-native

EngagePop for React Native — native push notifications and in-app messages,
bridging the native EngagePop iOS + Android SDKs.

## Install

```sh
npm install @engagepop/react-native
cd ios && pod install
```

Autolinking wires up both platforms. You still need the platform prerequisites:
**iOS** — Push Notifications capability; **Android** — Firebase
(`google-services.json` + the Google Services plugin).

## Usage

```ts
import EngagePop from "@engagepop/react-native";

EngagePop.configure("ep_…", "epm_…");

const granted = await EngagePop.requestPushPermission();

EngagePop.identify({ name: "Sarah", plan: "Pro" });
EngagePop.track("purchase", { product: "Blue Sneakers" });
EngagePop.convert(49.99, "order-1234", 12);

const sub = EngagePop.onDeepLink((url) => {
  // navigate to url
});
// later: sub.remove();

EngagePop.refreshInAppMessages();
```

## Targeting

Attributes passed to `identify()` drive targeting across EngagePop:

- **Push audience filters** — in the dashboard push composer, add a filter like
  `plan is Pro`: the notification only reaches devices whose identify
  attributes match every filter.
- **Popup "User attribute" conditions** *(0.2.4+)* — popup campaigns can target
  the same attributes (e.g. show an offer only when `plan is Pro`). Older SDK
  versions skip the condition, so update before gating exclusive content on it.
- **`{{merge tags}}`** in popups.

## Delivery receipts

The dashboard's Sent → Delivered → Opened funnel needs a "delivered" signal
from the device:

- **Android** — automatic (reported when the FCM handler runs; pure
  background `notification`-type messages are counted when tapped).
- **iOS** — add a **Notification Service Extension** target in Xcode whose
  class subclasses `EngagePopNotificationService` (the same extension that
  enables rich push images — see the
  [iOS SDK README](https://github.com/rajgupttaa/engagepop-ios-SDK#delivery-receipts)
  for the two-line subclass).

## Native glue

A little native wiring is still required (same as any RN push library):

### iOS — forward the APNs token (AppDelegate)

```objc
- (void)application:(UIApplication *)application
    didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  [EngagePop setDeviceToken:deviceToken];
}
```

Or in Swift: `EngagePop.setDeviceToken(deviceToken)`.

### Android — register the package + forward taps

```kotlin
// MainApplication.getPackages()
packages.add(EngagePopPackage())

// MainActivity
override fun onCreate(savedInstanceState: Bundle?) {
  super.onCreate(savedInstanceState)
  EngagePop.handleNotificationOpen(intent)
}
override fun onNewIntent(intent: Intent) {
  super.onNewIntent(intent)
  EngagePop.handleNotificationOpen(intent)
}
```

## Notes

- This wrapper contains no delivery logic — it delegates entirely to the native
  cores, so push, targeting, A/B, and in-app rendering behave identically to the
  native SDKs (and to web).
- Published from the monorepo (`sdks/react-native`) to npm.
