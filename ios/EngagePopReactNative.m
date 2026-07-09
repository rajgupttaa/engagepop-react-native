#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>

// Exposes the Swift module's methods to the React Native bridge.
@interface RCT_EXTERN_MODULE(EngagePopReactNative, RCTEventEmitter)

RCT_EXTERN_METHOD(configure:(NSString *)siteKey
                  appKey:(NSString *)appKey
                  options:(NSDictionary *)options)

RCT_EXTERN_METHOD(requestPushPermission:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(identify:(NSDictionary *)attributes)

RCT_EXTERN_METHOD(track:(NSString *)event properties:(NSDictionary *)properties)

RCT_EXTERN_METHOD(convert:(double)value
                  order:(NSString *)order
                  campaignId:(nonnull NSNumber *)campaignId)

RCT_EXTERN_METHOD(reset)

RCT_EXTERN_METHOD(refreshInAppMessages)

@end
