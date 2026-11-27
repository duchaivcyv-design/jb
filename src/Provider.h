#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AIProvider) {
    AIProviderGemini = 0,
    AIProviderClaude = 1
};

@interface Provider : NSObject
+ (AIProvider)forModelId:(NSString *)modelId;     // ids starting with "claude" belong to Claude, everything else to Gemini
+ (NSString *)nameFor:(AIProvider)provider;        // "Gemini" / "Claude"
+ (NSArray *)all;                                  // @[ @(AIProviderGemini), @(AIProviderClaude) ]
@end
