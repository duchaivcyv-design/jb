#import "GeminiClient.h"
#import "KeyStore.h"

static NSString *const kGeminiModelsURL = @"https://generativelanguage.googleapis.com/v1beta/models";
static const NSInteger kMaxModelPages = 10;

static NSString *NormalizedKey(NSString *key) {
    if (![key isKindOfClass:[NSString class]]) return nil;
    NSString *trimmed = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL asciiOnly = [trimmed canBeConvertedToEncoding:NSASCIIStringEncoding];
    BOOL hasInnerSpace = [trimmed rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound;
    if (trimmed.length == 0 || !asciiOnly || hasInnerSpace) return nil;
    return trimmed;
}

static GeminiCheckResult ResultForStatus(NSInteger status) {
    if (status == 200) return GeminiCheckOK;
    if (status == 400 || status == 401 || status == 403) return GeminiCheckInvalidKey;
    if (status == 429) return GeminiCheckRateLimited;
    if (status >= 500) return GeminiCheckNetworkError;
    return GeminiCheckUnknown;
}

static NSMutableURLRequest *ModelsRequest(NSString *key, NSString *pageToken) {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@?pageSize=1000", kGeminiModelsURL];
    if (pageToken.length > 0) {
        NSString *escaped = [pageToken stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"&pageToken=%@", escaped];
    }
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                            timeoutInterval:15.0];
    request.HTTPMethod = @"GET";
    [KeyStore applyGeminiCredential:key toRequest:request];
    return request;
}

@implementation GeminiClient

#pragma mark - Key check

+ (void)verifyKey:(NSString *)key completion:(GeminiVerifyCompletion)completion {
    NSString *cleanKey = NormalizedKey(key);
    if (!cleanKey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(GeminiCheckInvalidKey, 0, 0);
        });
        return;
    }
    [self verifyKey:cleanKey attempt:0 completion:completion];
}

+ (void)verifyKey:(NSString *)cleanKey attempt:(NSInteger)attempt completion:(GeminiVerifyCompletion)completion {
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:ModelsRequest(cleanKey, nil)
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        GeminiCheckResult result = GeminiCheckUnknown;
        NSInteger count = 0;
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;

        if (error != nil) {
            result = GeminiCheckNetworkError;
        } else {
            result = ResultForStatus(status);
            if (result == GeminiCheckOK) {
                id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                NSArray *models = [json isKindOfClass:[NSDictionary class]] ? json[@"models"] : nil;
                if ([models isKindOfClass:[NSArray class]]) {
                    for (id model in models) {
                        if (![model isKindOfClass:[NSDictionary class]]) continue;
                        NSString *name = [model[@"name"] isKindOfClass:[NSString class]] ? model[@"name"] : @"";
                        NSString *modelId = [name hasPrefix:@"models/"] ? [name substringFromIndex:7] : name;
                        NSArray *methods = model[@"supportedGenerationMethods"];
                        if ([methods isKindOfClass:[NSArray class]] &&
                            [methods containsObject:@"generateContent"] &&
                            [self isChatModelId:modelId]) {
                            count++;
                        }
                    }
                }
            }
        }

        BOOL shouldRetry = (result == GeminiCheckNetworkError || result == GeminiCheckRateLimited) && attempt < 2;
        if (shouldRetry) {
            NSTimeInterval delay = 0.4 * (attempt + 1);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self verifyKey:cleanKey attempt:attempt + 1 completion:completion];
            });
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completion(result, count, status);
        });
    }];
    [task resume];
}

#pragma mark - Model list

+ (BOOL)isChatModelId:(NSString *)modelId {
    if (![modelId hasPrefix:@"gemini"]) return NO;
    // These accept generateContent but produce images/audio or are not plain text chat.
    NSArray *blocked = @[@"tts", @"live", @"audio", @"embedding", @"robotics", @"computer-use", @"aqa"];
    for (NSString *token in blocked) {
        if ([modelId rangeOfString:token].location != NSNotFound) return NO;
    }
    return YES;
}

+ (void)fetchModelsWithKey:(NSString *)key completion:(GeminiModelsCompletion)completion {
    NSString *cleanKey = NormalizedKey(key);
    if (!cleanKey) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(@[], GeminiCheckInvalidKey);
        });
        return;
    }
    [self fetchPageWithToken:nil
                         key:cleanKey
                   collected:[NSMutableArray array]
                        seen:[NSMutableSet set]
                       depth:0
                     attempt:0
                  completion:completion];
}

+ (void)fetchPageWithToken:(NSString *)pageToken
                       key:(NSString *)key
                 collected:(NSMutableArray *)collected
                      seen:(NSMutableSet *)seen
                     depth:(NSInteger)depth
                   attempt:(NSInteger)attempt
                completion:(GeminiModelsCompletion)completion {
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:ModelsRequest(key, pageToken)
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
        GeminiCheckResult result = (error != nil) ? GeminiCheckNetworkError : ResultForStatus(status);

        if (result != GeminiCheckOK) {
            BOOL shouldRetry = (result == GeminiCheckNetworkError || result == GeminiCheckRateLimited) && attempt < 2;
            if (shouldRetry) {
                NSTimeInterval delay = 0.4 * (attempt + 1);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self fetchPageWithToken:pageToken
                                         key:key
                                   collected:collected
                                        seen:seen
                                       depth:depth
                                     attempt:attempt + 1
                                  completion:completion];
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{ completion(@[], result); });
            return;
        }

        id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSDictionary *root = [json isKindOfClass:[NSDictionary class]] ? json : @{};
        NSArray *models = [root[@"models"] isKindOfClass:[NSArray class]] ? root[@"models"] : @[];
        for (id item in models) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSString *name = item[@"name"];
            if (![name isKindOfClass:[NSString class]] || ![name hasPrefix:@"models/"]) continue;
            NSString *modelId = [name substringFromIndex:7];
            if ([seen containsObject:modelId]) continue;
            NSArray *methods = item[@"supportedGenerationMethods"];
            if (![methods isKindOfClass:[NSArray class]] || ![methods containsObject:@"generateContent"]) continue;
            if (![self isChatModelId:modelId]) continue;
            [seen addObject:modelId];

            NSString *display = [item[@"displayName"] isKindOfClass:[NSString class]] ? item[@"displayName"] : modelId;
            NSMutableDictionary *model = [@{ @"id": modelId, @"name": display } mutableCopy];
            id outputLimit = item[@"outputTokenLimit"];
            if ([outputLimit respondsToSelector:@selector(integerValue)] && [outputLimit integerValue] > 0) model[@"outputTokenLimit"] = outputLimit;
            id inputLimit = item[@"inputTokenLimit"];
            if ([inputLimit respondsToSelector:@selector(integerValue)] && [inputLimit integerValue] > 0) model[@"inputTokenLimit"] = inputLimit;
            [collected addObject:model];
        }

        NSString *next = [root[@"nextPageToken"] isKindOfClass:[NSString class]] ? root[@"nextPageToken"] : nil;
        if (next.length > 0 && depth < kMaxModelPages) {
            [self fetchPageWithToken:next
                                 key:key
                           collected:collected
                                seen:seen
                               depth:depth + 1
                             attempt:0
                          completion:completion];
            return;
        }

        NSArray *sorted = [collected sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [b[@"id"] compare:a[@"id"] options:NSNumericSearch];
        }];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(sorted, GeminiCheckOK); });
    }];
    [task resume];
}

@end
