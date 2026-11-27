#import "ModelStore.h"
#import "KeyStore.h"
#import "KeyTier.h"
#import "Strings.h"

static NSString *const kSelectedModelKey = @"selectedModel";
static NSString *const kAutoSelectedKey = @"selectedModelIsAutomatic";

// The Gemini key is the one earlier versions used, so a cached list survives an update.
static NSString *CacheKeyFor(AIProvider provider) {
    return provider == AIProviderClaude ? @"cachedModels.claude" : @"cachedModels";
}

@implementation ModelStore

+ (NSArray *)cachedModelsForProvider:(AIProvider)provider {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:CacheKeyFor(provider)];
    if (![value isKindOfClass:[NSArray class]]) return @[];
    NSMutableArray *out = [NSMutableArray array];
    for (id item in (NSArray *)value) {
        if ([item isKindOfClass:[NSDictionary class]] && [item[@"id"] isKindOfClass:[NSString class]]) [out addObject:item];
    }
    return out;
}

+ (void)saveModels:(NSArray *)models forProvider:(AIProvider)provider {
    [[NSUserDefaults standardUserDefaults] setObject:models forKey:CacheKeyFor(provider)];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSInteger)maxOutputTokensForModelId:(NSString *)modelId provider:(AIProvider)provider {
    if (modelId.length == 0) return 0;
    NSString *field = provider == AIProviderClaude ? @"max_tokens" : @"outputTokenLimit";
    for (NSDictionary *model in [self cachedModelsForProvider:provider]) {
        if (![model[@"id"] isEqualToString:modelId]) continue;
        id value = model[field];
        if ([value respondsToSelector:@selector(integerValue)]) {
            NSInteger cap = [value integerValue];
            return cap > 0 ? cap : 0;
        }
        return 0;
    }
    return 0;
}

+ (NSInteger)maxInputTokensForModelId:(NSString *)modelId provider:(AIProvider)provider {
    if (modelId.length == 0) return 0;
    NSString *field = provider == AIProviderClaude ? @"max_input_tokens" : @"inputTokenLimit";
    for (NSDictionary *model in [self cachedModelsForProvider:provider]) {
        if (![model[@"id"] isEqualToString:modelId]) continue;
        id value = model[field];
        if ([value respondsToSelector:@selector(integerValue)]) {
            NSInteger cap = [value integerValue];
            return cap > 0 ? cap : 0;
        }
        return 0;
    }
    return 0;
}

+ (NSString *)selectedModelId {
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:kSelectedModelKey];
    return value.length > 0 ? value : nil;
}

+ (void)setSelectedModelId:(NSString *)modelId {
    [self storeSelectedModelId:modelId automatic:NO];
}

+ (void)setAutomaticSelectedModelId:(NSString *)modelId {
    [self storeSelectedModelId:modelId automatic:YES];
}

+ (void)storeSelectedModelId:(NSString *)modelId automatic:(BOOL)automatic {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (modelId.length > 0) {
        [defaults setObject:modelId forKey:kSelectedModelKey];
        [defaults setBool:automatic forKey:kAutoSelectedKey];
    } else {
        [defaults removeObjectForKey:kSelectedModelKey];
        [defaults removeObjectForKey:kAutoSelectedKey];
    }
    [defaults synchronize];
}

+ (BOOL)selectionIsAutomatic {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kAutoSelectedKey];
}

+ (BOOL)isLikelyFreeModelId:(NSString *)modelId {
    if ([modelId rangeOfString:@"flash"].location == NSNotFound) return NO;
    // Flash-branded variants that Google lists as not available on the free tier.
    NSArray *paidVariants = @[@"omni", @"cyber"];
    for (NSString *token in paidVariants) {
        if ([modelId rangeOfString:token].location != NSNotFound) return NO;
    }
    return YES;
}

+ (NSString *)defaultGeminiModelIdFrom:(NSArray *)models {
    // Tier-aware first choice: free key -> gemini-flash-lite-latest (or the newest Flash-Lite); paid key -> the newest Pro.
    NSArray *recommended = [self recommendedModelsForProvider:AIProviderGemini];
    if (recommended.count > 0) {
        NSString *first = recommended.firstObject[@"id"];
        for (NSDictionary *model in models) if ([model[@"id"] isEqualToString:first]) return first;
    }
    return [self legacyDefaultGeminiModelIdFrom:models];
}

+ (NSString *)legacyDefaultGeminiModelIdFrom:(NSArray *)models {
    // 1) newest stable "gemini-<version>-flash"
    NSRegularExpression *stable =
        [NSRegularExpression regularExpressionWithPattern:@"^gemini-(\\d+(?:\\.\\d+)?)-flash$" options:0 error:nil];
    NSString *bestId = nil;
    double bestVersion = -1;
    for (NSDictionary *model in models) {
        NSString *modelId = model[@"id"];
        NSTextCheckingResult *match = [stable firstMatchInString:modelId options:0 range:NSMakeRange(0, modelId.length)];
        if (match) {
            double version = [[modelId substringWithRange:[match rangeAtIndex:1]] doubleValue];
            if (version > bestVersion) { bestVersion = version; bestId = modelId; }
        }
    }
    if (bestId) return bestId;

    // 2) any free-tier-family model that is not a preview/experimental/lite variant
    NSArray *avoid = @[@"lite", @"preview", @"exp", @"8b", @"thinking"];
    for (NSDictionary *model in models) {
        NSString *modelId = model[@"id"];
        if (![self isLikelyFreeModelId:modelId]) continue;
        BOOL skip = NO;
        for (NSString *token in avoid) {
            if ([modelId rangeOfString:token].location != NSNotFound) { skip = YES; break; }
        }
        if (!skip) return modelId;
    }

    // 3) any model from the free-tier families, even a lite/preview variant: better than a paid one
    for (NSDictionary *model in models) {
        if ([self isLikelyFreeModelId:model[@"id"]]) return model[@"id"];
    }

    // 4) nothing recognizable: whatever comes first
    return models.firstObject[@"id"];
}

+ (NSString *)defaultClaudeModelIdFrom:(NSArray *)models {
    // The API lists the newest models first, so the first Sonnet is the newest Sonnet.
    for (NSDictionary *model in models) {
        if ([model[@"id"] rangeOfString:@"sonnet"].location != NSNotFound) return model[@"id"];
    }
    return models.firstObject[@"id"];
}

+ (NSString *)defaultModelIdForProvider:(AIProvider)provider models:(NSArray *)models {
    if (models.count == 0) return nil;
    return provider == AIProviderClaude ? [self defaultClaudeModelIdFrom:models] : [self defaultGeminiModelIdFrom:models];
}

+ (NSString *)defaultModelIdAcrossProviders {
    for (NSNumber *value in [Provider all]) {
        AIProvider provider = (AIProvider)value.integerValue;
        if (![KeyStore hasKeyForProvider:provider]) continue;
        NSString *modelId = [self defaultModelIdForProvider:provider models:[self visibleModelsForProvider:provider]];
        if (modelId.length > 0) return modelId;
    }
    return nil;
}

#pragma mark - Free / paid visibility

+ (NSArray *)visibleModelsForProvider:(AIProvider)provider {
    NSArray *models = [self cachedModelsForProvider:provider];
    if (![KeyTier hidesPaidModelsForProvider:provider]) return models;
    NSMutableArray *free = [NSMutableArray array];
    for (NSDictionary *model in models) {
        if ([self isLikelyFreeModelId:model[@"id"]]) [free addObject:model];
    }
    return free;
}

+ (BOOL)isModelAvailableNow:(NSString *)modelId {
    if (modelId.length == 0) return NO;
    AIProvider provider = [Provider forModelId:modelId];
    if (![KeyStore hasKeyForProvider:provider]) return NO;
    // Only a key KNOWN to be free blocks a paid model; while the kind is still unknown the current choice is kept.
    if ([KeyTier tierForProvider:provider] == KeyTierFree) return [self isLikelyFreeModelId:modelId];
    return YES;
}

#pragma mark - Recommended models

static NSDictionary *ModelWithId(NSArray *models, NSString *modelId) {
    for (NSDictionary *model in models) if ([model[@"id"] isEqualToString:modelId]) return model;
    return nil;
}

// Highest version among ids like "gemini-2.5-flash-lite" (no preview/exp suffix); suffix is "flash", "flash-lite" or "pro".
static NSDictionary *NewestStable(NSArray *models, NSString *suffix) {
    NSString *pattern = [NSString stringWithFormat:@"^gemini-(\\d+(?:\\.\\d+)?)-%@$", suffix];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSDictionary *best = nil;
    double bestVersion = -1;
    for (NSDictionary *model in models) {
        NSString *modelId = model[@"id"];
        NSTextCheckingResult *match = [regex firstMatchInString:modelId options:0 range:NSMakeRange(0, modelId.length)];
        if (!match) continue;
        double version = [[modelId substringWithRange:[match rangeAtIndex:1]] doubleValue];
        if (version > bestVersion) { bestVersion = version; best = model; }
    }
    return best;
}

+ (NSArray *)recommendedModelsForProvider:(AIProvider)provider {
    NSArray *models = [self visibleModelsForProvider:provider];
    NSMutableArray *out = [NSMutableArray array];
    void (^add)(NSDictionary *) = ^(NSDictionary *model) {
        if (model && ![out containsObject:model]) [out addObject:model];
    };
    if (provider == AIProviderClaude) {
        for (NSString *family in @[@"sonnet", @"opus", @"haiku"]) {
            for (NSDictionary *model in models) {
                if ([model[@"id"] rangeOfString:family].location != NSNotFound) { add(model); break; }   // list is newest first
            }
        }
        return out;
    }
    if ([KeyTier tierForProvider:AIProviderGemini] == KeyTierPaid) {
        add(ModelWithId(models, @"gemini-pro-latest"));
        add(NewestStable(models, @"pro"));
        add(ModelWithId(models, @"gemini-flash-latest"));
        add(NewestStable(models, @"flash"));
        add(ModelWithId(models, @"gemini-flash-lite-latest"));
        add(NewestStable(models, @"flash-lite"));
    } else {
        add(ModelWithId(models, @"gemini-flash-lite-latest"));
        add(ModelWithId(models, @"gemini-flash-latest"));
        add(NewestStable(models, @"flash-lite"));
        add(NewestStable(models, @"flash"));
    }
    // Make sure there is always something to show, even if none of the usual names exist for this key.
    if (out.count == 0) {
        for (NSDictionary *model in models) {
            add(model);
            if (out.count >= 4) break;
        }
    }
    return out;
}

+ (NSArray *)recommendedModels {
    NSMutableArray *all = [NSMutableArray array];
    for (NSNumber *value in [Provider all]) {
        AIProvider provider = (AIProvider)value.integerValue;
        if (![KeyStore hasKeyForProvider:provider]) continue;
        [all addObjectsFromArray:[self recommendedModelsForProvider:provider]];
    }
    return all;
}

#pragma mark - Friendly text

+ (NSString *)friendlyNameForModel:(NSDictionary *)model {
    NSString *modelId = model[@"id"] ?: @"";
    NSString *name = [model[@"name"] isKindOfClass:[NSString class]] ? model[@"name"] : @"";
    if (name.length > 0 && ![name isEqualToString:modelId]) return name;
    NSString *spaced = [modelId stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    return [spaced capitalizedString];
}

+ (NSArray<NSString *> *)titlePartsForModelId:(NSString *)modelId {
    NSString *lower = [(modelId ?: @"") lowercaseString];
    if ([lower hasPrefix:@"models/"]) lower = [lower substringFromIndex:7];
    if ([lower hasPrefix:@"gemini-"]) lower = [lower substringFromIndex:7];
    else if ([lower hasPrefix:@"claude-"]) lower = [lower substringFromIndex:7];
    if (lower.length == 0) return @[ @"", @"" ];

    NSCharacterSet *digits = [NSCharacterSet decimalDigitCharacterSet];
    NSCharacterSet *notNumber = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789."] invertedSet];
    NSMutableArray *words = [NSMutableArray array];     // family and labels: flash, lite, latest, preview...
    NSMutableArray *numbers = [NSMutableArray array];   // version parts: 2.5, 4, 5...
    NSSet *dateLabels = [NSSet setWithObjects:@"preview", @"exp", @"experimental", @"latest", nil];   // numbers after these are dates / builds
    BOOL versionEnded = NO;
    for (NSString *token in [lower componentsSeparatedByString:@"-"]) {
        if (token.length == 0) continue;
        BOOL numeric = [token rangeOfCharacterFromSet:notNumber].location == NSNotFound && [token rangeOfCharacterFromSet:digits].location != NSNotFound;
        if (numeric) {
            // Only the first run of numbers is the version (4-5 -> 4.5). Dates (20250929, 06-17) and build numbers (001) are dropped.
            NSString *previous = words.lastObject;
            if (token.length >= 8 || versionEnded || (previous && [dateLabels containsObject:previous])) continue;
            [numbers addObject:token];
        } else {
            if (numbers.count > 0) versionEnded = YES;
            [words addObject:token];
        }
    }

    // "flash" + "lite" read better as one word: FlashLite.
    NSMutableArray *display = [NSMutableArray array];
    for (NSUInteger i = 0; i < words.count; i++) {
        NSString *word = words[i];
        if ([word isEqualToString:@"flash"] && i + 1 < words.count && [words[i + 1] isEqualToString:@"lite"]) {
            [display addObject:@"FlashLite"];
            i++;
            continue;
        }
        [display addObject:[[[word substringToIndex:1] uppercaseString] stringByAppendingString:[word substringFromIndex:1]]];
    }
    NSString *version = numbers.count > 0 ? [numbers componentsJoinedByString:@"."] : @"";

    NSString *primary = display.count > 0 ? display[0] : version;
    NSMutableArray *rest = [NSMutableArray array];
    if (display.count > 0 && version.length > 0) [rest addObject:version];
    if (display.count > 1) [rest addObjectsFromArray:[display subarrayWithRange:NSMakeRange(1, display.count - 1)]];
    return @[ primary ?: @"", [rest componentsJoinedByString:@" "] ];
}

+ (NSString *)tagForModelId:(NSString *)modelId {
    NSString *lower = modelId.lowercaseString;
    if ([lower rangeOfString:@"preview"].location != NSNotFound || [lower rangeOfString:@"exp"].location != NSNotFound) return L(@"tag_experiment");
    if ([lower rangeOfString:@"flash-lite"].location != NSNotFound) return L(@"tag_light");
    if ([lower rangeOfString:@"flash"].location != NSNotFound) return L(@"tag_balanced");
    if ([lower rangeOfString:@"pro"].location != NSNotFound || [lower rangeOfString:@"opus"].location != NSNotFound) return L(@"tag_strong");
    if ([lower rangeOfString:@"sonnet"].location != NSNotFound) return L(@"tag_balanced");
    if ([lower rangeOfString:@"haiku"].location != NSNotFound) return L(@"tag_fast");
    return @"";
}

@end
