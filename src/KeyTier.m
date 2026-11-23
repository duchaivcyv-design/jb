#import "KeyTier.h"
#import "KeyStore.h"
#import "DiagnosticLog.h"

static NSString *const kDetectedKey = @"keytier.gemini.detected";
static NSString *const kOverrideKey = @"keytier.gemini.override";
static NSString *const kPopupKey = @"keytier.gemini.popupPending";
static NSString *const kProbeBase = @"https://generativelanguage.googleapis.com/v1beta/models/";

static BOOL gDetecting = NO;

@implementation KeyTier

#pragma mark - State

+ (KeyTierLevel)detectedGeminiTier {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kDetectedKey];
    return (value == KeyTierFree || value == KeyTierPaid) ? (KeyTierLevel)value : KeyTierUnknown;
}

+ (NSInteger)geminiOverride {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kOverrideKey];
    return (value == 1 || value == 2) ? value : 0;
}

+ (void)setGeminiOverride:(NSInteger)override {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (override == 1 || override == 2) [defaults setInteger:override forKey:kOverrideKey];
    else [defaults removeObjectForKey:kOverrideKey];
    [defaults synchronize];
}

+ (KeyTierLevel)tierForProvider:(AIProvider)provider {
    if (provider == AIProviderClaude) return KeyTierPaid;
    NSInteger override = [self geminiOverride];
    if (override == 1) return KeyTierFree;
    if (override == 2) return KeyTierPaid;
    return [self detectedGeminiTier];
}

+ (BOOL)hidesPaidModelsForProvider:(AIProvider)provider {
    return [self tierForProvider:provider] != KeyTierPaid && provider == AIProviderGemini;
}

+ (BOOL)needsGeminiDetection {
    if (![KeyStore hasKeyForProvider:AIProviderGemini]) return NO;
    if ([self geminiOverride] != 0) return NO;
    return [self detectedGeminiTier] == KeyTierUnknown;
}

+ (void)invalidateGeminiDetection {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:kDetectedKey];
    [defaults removeObjectForKey:kPopupKey];
    [defaults synchronize];
}

+ (BOOL)consumePopupPending {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults boolForKey:kPopupKey]) return NO;
    [defaults removeObjectForKey:kPopupKey];
    [defaults synchronize];
    return YES;
}

#pragma mark - Detection

// Pro models a free key cannot use. Prefer a stable one (no preview/experimental), then any Pro; at most two probes.
+ (NSArray *)probeCandidatesFromModels:(NSArray *)models {
    NSMutableArray *stable = [NSMutableArray array], *other = [NSMutableArray array];
    for (NSDictionary *model in models) {
        NSString *modelId = [model[@"id"] isKindOfClass:[NSString class]] ? model[@"id"] : @"";
        if ([modelId rangeOfString:@"pro"].location == NSNotFound || [modelId rangeOfString:@"flash"].location != NSNotFound) continue;
        if ([modelId rangeOfString:@"image"].location != NSNotFound) continue;
        BOOL experimental = [modelId rangeOfString:@"preview"].location != NSNotFound || [modelId rangeOfString:@"exp"].location != NSNotFound;
        if (experimental) [other addObject:modelId]; else [stable addObject:modelId];
    }
    NSMutableArray *out = [NSMutableArray arrayWithArray:stable];
    [out addObjectsFromArray:other];
    return out.count > 2 ? [out subarrayWithRange:NSMakeRange(0, 2)] : out;
}

+ (void)detectGeminiTierIfNeededWithModels:(NSArray *)models completion:(void (^)(KeyTierLevel))completion {
    if (![self needsGeminiDetection]) return;
    [self forceDetectGeminiTierWithModels:models completion:completion];
}

+ (void)forceDetectGeminiTierWithModels:(NSArray *)models completion:(void (^)(KeyTierLevel))completion {
    if (gDetecting) return;
    NSString *key = [KeyStore loadKeyForProvider:AIProviderGemini];
    if (key.length == 0) return;

    NSArray *candidates = [self probeCandidatesFromModels:models];
    if (candidates.count == 0) {
        // The key's list has no Pro model at all: it cannot be a key with paid access.
        [self finishWithTier:KeyTierFree completion:completion];
        return;
    }
    gDetecting = YES;
    [self probeCandidates:candidates index:0 key:key sawDenied:NO completion:completion];
}

+ (void)finishWithTier:(KeyTierLevel)tier completion:(void (^)(KeyTierLevel))completion {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (tier == KeyTierFree || tier == KeyTierPaid) {
        [defaults setInteger:tier forKey:kDetectedKey];
        [defaults setBool:YES forKey:kPopupKey];
        [defaults synchronize];
    }
    [DiagnosticLog log:@"key tier: %@", tier == KeyTierPaid ? @"paid" : (tier == KeyTierFree ? @"free" : @"unknown")];
    dispatch_async(dispatch_get_main_queue(), ^{
        gDetecting = NO;
        if (completion) completion(tier);
    });
}

+ (void)probeCandidates:(NSArray *)candidates index:(NSUInteger)index key:(NSString *)key sawDenied:(BOOL)sawDenied
             completion:(void (^)(KeyTierLevel))completion {
    if (index >= candidates.count) {
        // Every Pro model was refused or missing: a free key. If we only got odd errors, stay undecided.
        [self finishWithTier:(sawDenied ? KeyTierFree : KeyTierUnknown) completion:completion];
        return;
    }
    NSString *escaped = [candidates[index] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@:generateContent", kProbeBase, escaped]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:25];
    request.HTTPMethod = @"POST";
    [request setValue:key forHTTPHeaderField:@"x-goog-api-key"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSDictionary *body = @{ @"contents": @[ @{ @"parts": @[ @{ @"text": @"." } ] } ],
                            @"generationConfig": @{ @"maxOutputTokens": @1 } };
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:0 error:nil];

    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            [self finishWithTier:KeyTierUnknown completion:completion];   // no network: try again next time
            return;
        }
        NSInteger status = [(NSHTTPURLResponse *)response statusCode];
        NSString *text = data.length ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        NSString *lower = (text ?: @"").lowercaseString;

        if (status == 200) {
            [self finishWithTier:KeyTierPaid completion:completion];
        } else if (status == 429) {
            BOOL freeMarker = [lower containsString:@"free_tier"] || [lower containsString:@"free tier"] ||
                              [lower containsString:@"freetier"] || [lower containsString:@"limit: 0"];
            BOOL paidMarker = [lower containsString:@"paid_tier"] || [lower containsString:@"paid tier"];
            if (freeMarker) [self finishWithTier:KeyTierFree completion:completion];
            else if (paidMarker) [self finishWithTier:KeyTierPaid completion:completion];
            else [self finishWithTier:KeyTierUnknown completion:completion];
        } else if (status == 403 || status == 404) {
            [self probeCandidates:candidates index:index + 1 key:key sawDenied:(sawDenied || status == 403) completion:completion];
        } else if (status == 400 && [lower rangeOfString:@"api key"].location == NSNotFound) {
            [self probeCandidates:candidates index:index + 1 key:key sawDenied:sawDenied completion:completion];
        } else {
            [self finishWithTier:KeyTierUnknown completion:completion];   // bad key, server trouble...
        }
    }] resume];
}

@end
