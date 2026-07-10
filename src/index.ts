import { NativeModules, NativeEventEmitter, EmitterSubscription } from "react-native";

/** A captured notification, for the in-app inbox / bell. */
export interface EngagePopMessage {
  id: string;
  title: string;
  body: string;
  url: string | null;
  /** Seconds since epoch (iOS) / millis since epoch (Android) — treat as a sort key. */
  receivedAt: number;
  read: boolean;
}

/** The native module surface, implemented by the iOS + Android bridges. */
interface EngagePopNative {
  configure(siteKey: string, appKey: string, options: object): void;
  requestPushPermission(): Promise<boolean>;
  identify(attributes: Record<string, string>): void;
  track(event: string, properties: Record<string, string>): void;
  convert(value: number, order: string | null, campaignId: number): void;
  reset(): void;
  refreshInAppMessages(): void;
  getInbox(): Promise<EngagePopMessage[]>;
  unreadCount(): Promise<number>;
  markRead(id: string): void;
  markAllRead(): void;
  removeMessage(id: string): void;
  clearInbox(): void;
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
  /** When true (default), show an eligible in-app popup on launch. Set false to
   *  control placement via refreshInAppMessages(). */
  autoShowInAppMessages?: boolean;
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
function events(): NativeEventEmitter {
  if (!emitter) emitter = new NativeEventEmitter(Native as unknown as object);
  return emitter;
}

export function onDeepLink(handler: (url: string) => void): EmitterSubscription {
  return events().addListener("EngagePopDeepLink", (url: string) => handler(url));
}

// --- Notification inbox / bell ---

/** All captured notifications, newest first. */
export function getInbox(): Promise<EngagePopMessage[]> {
  return native().getInbox();
}

/** Unread count — bind to your bell badge. */
export function unreadCount(): Promise<number> {
  return native().unreadCount();
}

export function markRead(id: string): void {
  native().markRead(id);
}

export function markAllRead(): void {
  native().markAllRead();
}

export function removeMessage(id: string): void {
  native().removeMessage(id);
}

export function clearInbox(): void {
  native().clearInbox();
}

/** Fires when the inbox changes — refresh your bell. Returns a subscription. */
export function onInboxChange(handler: () => void): EmitterSubscription {
  return events().addListener("EngagePopInboxChange", () => handler());
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
  getInbox,
  unreadCount,
  markRead,
  markAllRead,
  removeMessage,
  clearInbox,
  onInboxChange,
};
