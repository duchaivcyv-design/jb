#import <Foundation/Foundation.h>
#import "Provider.h"

// Whether a Gemini API key is on the free tier or has billing. Google's API does not say, so the app finds out the way
// the API itself shows it: a Pro model answers a tiny request (1 token) for a paid key and refuses a free key
// (quota 0 / free tier). The result is kept on the device; the user can always override it in Settings.
typedef NS_ENUM(NSInteger, KeyTierLevel) {
    KeyTierUnknown = 0,   // not detected yet (treated like free: paid models stay hidden until we know)
    KeyTierFree,
    KeyTierPaid
};

@interface KeyTier : NSObject

// What the app uses now: the manual override if set, else the detected value. Claude keys are always paid (no free tier).
+ (KeyTierLevel)tierForProvider:(AIProvider)provider;
+ (BOOL)hidesPaidModelsForProvider:(AIProvider)provider;   // Gemini key that is free or not yet known

// Manual choice in Settings: 0 = automatic, 1 = always free, 2 = always paid.
+ (NSInteger)geminiOverride;
+ (void)setGeminiOverride:(NSInteger)override;
+ (KeyTierLevel)detectedGeminiTier;

// Detection is needed when there is a Gemini key, no manual override and nothing detected yet.
+ (BOOL)needsGeminiDetection;
+ (void)invalidateGeminiDetection;   // the key was replaced or deleted

// Runs the probe in the background when needed. The completion runs on the main queue once, with the detected tier
// (KeyTierUnknown if the probe could not tell, for example without network). `models` is the key's full model list.
+ (void)detectGeminiTierIfNeededWithModels:(NSArray *)models completion:(void (^)(KeyTierLevel tier))completion;
+ (void)forceDetectGeminiTierWithModels:(NSArray *)models completion:(void (^)(KeyTierLevel tier))completion;

// A freshly detected key shows the model pop-up once.
+ (BOOL)consumePopupPending;

@end
