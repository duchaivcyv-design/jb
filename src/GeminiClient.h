#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GeminiCheckResult) {
    GeminiCheckOK = 0,
    GeminiCheckInvalidKey,
    GeminiCheckRateLimited,
    GeminiCheckNetworkError,
    GeminiCheckUnknown
};

typedef void (^GeminiVerifyCompletion)(GeminiCheckResult result, NSInteger usableModelCount, NSInteger httpStatus);
typedef void (^GeminiModelsCompletion)(NSArray *models, GeminiCheckResult result);

@interface GeminiClient : NSObject

// Verifies a key by listing models and counting those that support generateContent.
// The key goes in the x-goog-api-key header, never in the URL. Completion runs on the main queue.
+ (void)verifyKey:(NSString *)key completion:(GeminiVerifyCompletion)completion;
// The message Google returned with the last failed key check (empty when there is none).
+ (NSString *)lastVerifyErrorMessage;

// Fetches the chat-capable Gemini models available to this key, as @[ @{ @"id": ..., @"name": ... } ],
// newest first. Audio/live/embedding variants are filtered out; image-generation chat models remain selectable. Completion runs on the main queue.
+ (void)fetchModelsWithKey:(NSString *)key completion:(GeminiModelsCompletion)completion;

@end
