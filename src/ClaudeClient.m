#import "ClaudeClient.h"

static NSString *const kClaudeModelsURL = @"https://api.anthropic.com/v1/models";
static NSString *const kAnthropicVersion = @"2023-06-01";

static BOOL KeyLooksUsable(NSString *key) {
    BOOL asciiOnly = [key canBeConvertedToEncoding:NSASCIIStringEncoding];
    BOOL hasSpace = [key rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound;
    return key.length > 0 && asciiOnly && !hasSpace;
}

static GeminiCheckResult ResultForStatus(NSInteger status) {
    if (status == 200) return GeminiCheckOK;
    if (status == 401 || status == 403) return GeminiCheckInvalidKey;
    if (status == 429) return GeminiCheckRateLimited;
    return GeminiCheckUnknown;
}

static NSMutableURLRequest *ModelsRequest(NSString *key, NSString *afterId) {
    NSMutableString *urlString = [NSMutableString stringWithFormat:@"%@?limit=1000", kClaudeModelsURL];
    if (afterId.length > 0) {
        NSString *escaped = [afterId stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"&after_id=%@", escaped];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:20];
    request.HTTPMethod = @"GET";
    [request setValue:key forHTTPHeaderField:@"x-api-key"];
    [request setValue:kAnthropicVersion forHTTPHeaderField:@"anthropic-version"];
    return request;
}

@implementation ClaudeClient

+ (void)verifyKey:(NSString *)key completion:(GeminiVerifyCompletion)completion {
    if (!KeyLooksUsable(key)) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(GeminiCheckInvalidKey, 0, 0); });
        return;
    }
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:ModelsRequest(key, nil)
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        GeminiCheckResult result = GeminiCheckUnknown;
        NSInteger count = 0, status = 0;
        if (error != nil) {
            result = GeminiCheckNetworkError;
        } else {
            status = [(NSHTTPURLResponse *)response statusCode];
            result = ResultForStatus(status);
            if (result == GeminiCheckOK) {
                id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                NSArray *models = [json isKindOfClass:[NSDictionary class]] ? json[@"data"] : nil;
                count = [models isKindOfClass:[NSArray class]] ? (NSInteger)models.count : 0;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{ completion(result, count, status); });
    }];
    [task resume];
}

+ (void)fetchModelsWithKey:(NSString *)key completion:(GeminiModelsCompletion)completion {
    if (!KeyLooksUsable(key)) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(@[], GeminiCheckInvalidKey); });
        return;
    }
    [self fetchPageAfter:nil key:key collected:[NSMutableArray array] depth:0 completion:completion];
}

+ (void)fetchPageAfter:(NSString *)afterId
                   key:(NSString *)key
             collected:(NSMutableArray *)collected
                 depth:(NSInteger)depth
            completion:(GeminiModelsCompletion)completion {
    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:ModelsRequest(key, afterId)
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(@[], GeminiCheckNetworkError); });
            return;
        }
        GeminiCheckResult result = ResultForStatus([(NSHTTPURLResponse *)response statusCode]);
        if (result != GeminiCheckOK) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(@[], result); });
            return;
        }

        id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        NSDictionary *root = [json isKindOfClass:[NSDictionary class]] ? json : @{};
        NSArray *items = [root[@"data"] isKindOfClass:[NSArray class]] ? root[@"data"] : @[];
        for (id item in items) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSString *modelId = item[@"id"];
            if (![modelId isKindOfClass:[NSString class]] || ![modelId hasPrefix:@"claude"]) continue;
            NSString *display = [item[@"display_name"] isKindOfClass:[NSString class]] ? item[@"display_name"] : modelId;
            NSMutableDictionary *model = [@{ @"id": modelId, @"name": display } mutableCopy];
            id maxTokens = item[@"max_tokens"];
            if ([maxTokens respondsToSelector:@selector(integerValue)] && [maxTokens integerValue] > 0) model[@"max_tokens"] = maxTokens;
            id maxInputTokens = item[@"max_input_tokens"];
            if ([maxInputTokens respondsToSelector:@selector(integerValue)] && [maxInputTokens integerValue] > 0) model[@"max_input_tokens"] = maxInputTokens;
            [collected addObject:model];
        }

        BOOL hasMore = [root[@"has_more"] respondsToSelector:@selector(boolValue)] && [root[@"has_more"] boolValue];
        NSString *lastId = [root[@"last_id"] isKindOfClass:[NSString class]] ? root[@"last_id"] : nil;
        if (hasMore && lastId.length > 0 && depth < 4) {
            [self fetchPageAfter:lastId key:key collected:collected depth:depth + 1 completion:completion];
            return;
        }
        NSArray *result_ = [collected copy];   // the API already lists the newest models first
        dispatch_async(dispatch_get_main_queue(), ^{ completion(result_, GeminiCheckOK); });
    }];
    [task resume];
}

@end
