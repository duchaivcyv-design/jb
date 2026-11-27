#import <Foundation/Foundation.h>
#import "GeminiClient.h"   // shares GeminiCheckResult and the completion types

// Anthropic (Claude) API: key check and model list. Keys go in the x-api-key header, never in the URL.
// Completions run on the main queue.
@interface ClaudeClient : NSObject
+ (void)verifyKey:(NSString *)key completion:(GeminiVerifyCompletion)completion;
+ (void)fetchModelsWithKey:(NSString *)key completion:(GeminiModelsCompletion)completion;
@end
