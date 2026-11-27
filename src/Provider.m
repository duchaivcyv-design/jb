#import "Provider.h"

@implementation Provider

+ (AIProvider)forModelId:(NSString *)modelId {
    return [modelId hasPrefix:@"claude"] ? AIProviderClaude : AIProviderGemini;
}

+ (NSString *)nameFor:(AIProvider)provider {
    return provider == AIProviderClaude ? @"Claude" : @"Gemini";
}

+ (NSArray *)all {
    return @[@(AIProviderGemini), @(AIProviderClaude)];
}

@end
