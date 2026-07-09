import { NativeModules, NativeEventEmitter, EmitterSubscription } from "react-native";

/** The native module surface, implemented by the iOS + Android bridges. */
interface EngagePopNative {
  configure(siteKey: string, appKey: string, options: object): void;
  requestPushPermission(): Promise<boolean>;
  identify(attributes: Record<string, string>): void;
  track(event: string, properties: Record<string, string>): void;
  convert(value: number, order: string | null, campaignId: number): void;
  reset(): void;
  refreshInAppMessages(): void;
}

const Native = NativeModules.EngagePopReactNative as EngagePopNative | undefined;

function native(): EngagePopNative {
  if (!Native) {
    throw new Error(
      "@engagepop/react-native: native module not found. Rebuild the app (pod install / gradle sync).",
    );
  }
  return Native;
}

export interface EngagePopOptions {
  /** Override the delivery-plane base URL (defaults to production). */
  apiBaseUrl?: string;
  /** Log SDK network calls to the native console. */
  debugLogging?: boolean;
}

/** Configure the SDK. Call once, as early as possible. */
export function configure(siteKey: string, appKey: string, options: EngagePopOptions = {}): void {
  native().configure(siteKey, appKey, options);
}

/** Ask for notification permission; resolves true if granted. */
export function requestPushPermission(): Promise<boolean> {
  return native().requestPushPermission();
}

/** Identify the current user for targeting + `{{merge tags}}`. */
export function identify(attributes: Record<string, string>): void {
  native().identify(attributes);
}

/** Record a custom event (e.g. a purchase). */
export function track(event: string, properties: Record<string, string> = {}): void {
  native().track(event, properties);
}

/** Record a purchase; pass `campaignId` to attribute it to a campaign. */
export function convert(value: number, order?: string, campaignId?: number): void {
  native().convert(value, order ?? null, campaignId ?? 0);
}

/** Forget the current user's identify attributes (e.g. on logout). */
export function reset(): void {
  native().reset();
}

/** Re-check for in-app popups to show. */
export function refreshInAppMessages(): void {
  native().refreshInAppMessages();
}

let emitter: NativeEventEmitter | null = null;

/**
 * Subscribe to deep links carried by tapped pushes / popups. Returns a
 * subscription — call `.remove()` to unsubscribe.
 */
export function onDeepLink(handler: (url: string) => void): EmitterSubscription {
  if (!emitter) emitter = new NativeEventEmitter(Native as unknown as object);
  return emitter.addListener("EngagePopDeepLink", (url: string) => handler(url));
}

export default {
  configure,
  requestPushPermission,
  identify,
  track,
  convert,
  reset,
  refreshInAppMessages,
  onDeepLink,
};
