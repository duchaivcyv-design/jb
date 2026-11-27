#import <Foundation/Foundation.h>
#import "Provider.h"

// Remembers each provider's model list (fetched live with the user's key) and the chosen model.
// Model names are never hard-coded: they change over time and differ per account.
@interface ModelStore : NSObject

+ (NSArray *)cachedModelsForProvider:(AIProvider)provider;          // @[ @{ @"id":..., @"name":... } ]
+ (void)saveModels:(NSArray *)models forProvider:(AIProvider)provider;
+ (NSInteger)maxOutputTokensForModelId:(NSString *)modelId provider:(AIProvider)provider; // 0 if the provider did not report a cap
+ (NSInteger)maxInputTokensForModelId:(NSString *)modelId provider:(AIProvider)provider;   // 0 if the provider did not report a cap

+ (NSString *)selectedModelId;                                      // nil if the user never chose one
+ (void)setSelectedModelId:(NSString *)modelId;                     // the user's own choice
+ (void)setAutomaticSelectedModelId:(NSString *)modelId;            // chosen by the app (a default): may be replaced when the key kind is detected
+ (BOOL)selectionIsAutomatic;

// The list the user sees: for a Gemini key that is free (or not yet known), paid-family models (Pro...) are left out.
+ (NSArray *)visibleModelsForProvider:(AIProvider)provider;
+ (BOOL)isModelAvailableNow:(NSString *)modelId;                    // false for a paid Gemini model on a free key

// A short, ordered list for the pop-up: free key -> Flash-Lite and Flash first; paid key -> Pro first; Claude -> Sonnet, Opus, Haiku.
+ (NSArray *)recommendedModels;                                     // across providers that have a key
+ (NSArray *)recommendedModelsForProvider:(AIProvider)provider;

// Friendly text for lists.
+ (NSString *)friendlyNameForModel:(NSDictionary *)model;
// Short two-part name for the title bar: @[ main, detail ], for example @[ @"FlashLite", @"Latest" ] for
// "gemini-flash-lite-latest" (the "gemini-" prefix and dates are dropped, Flash + Lite join up, a version moves after the family).
+ (NSArray<NSString *> *)titlePartsForModelId:(NSString *)modelId;
+ (NSString *)tagForModelId:(NSString *)modelId;                    // "Nhẹ & nhanh", "Cân bằng", "Mạnh nhất"...

// Hint by model family, not by version: Gemini's Flash / Flash-Lite families are the ones on Google's free tier;
// Pro, Argon and similar usually need billing. The API does not report this, so it is a hint, not a guarantee.
+ (BOOL)isLikelyFreeModelId:(NSString *)modelId;

// A sensible default for one provider. Gemini: the newest stable "gemini-X.Y-flash", else a non-preview Flash,
// else any Flash, else the first. Claude: the newest Sonnet, else the first.
+ (NSString *)defaultModelIdForProvider:(AIProvider)provider models:(NSArray *)models;

// A default across providers: Gemini first (it has a free tier), then Claude; only providers that have a key and a cached list.
+ (NSString *)defaultModelIdAcrossProviders;

@end
