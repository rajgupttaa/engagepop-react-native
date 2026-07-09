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
