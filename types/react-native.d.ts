// Minimal ambient declarations for the React Native surface this wrapper uses,
// so the package type-checks standalone (the real types come from the host app's
// react-native install at build time).
declare module "react-native" {
  export const NativeModules: { [name: string]: any };

  export interface EmitterSubscription {
    remove(): void;
  }

  export class NativeEventEmitter {
    constructor(nativeModule?: any);
    addListener(eventType: string, listener: (event: any) => void): EmitterSubscription;
  }

  export const Platform: { OS: "ios" | "android" | string };
}
