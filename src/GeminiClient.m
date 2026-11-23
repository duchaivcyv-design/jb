#import "GeminiClient.h"
#import "KeyStore.h"
#import "DiagnosticLog.h"

static NSString *gLastVerifyError = nil;

static NSString *const kGeminiModelsURL = @"https://generativelanguage.googleapis.com/v1beta/models";

static BOOL KeyLooksUsable(NSString *key) {
    // A header value must be plain visible ASCII; anything else cannot be a real key.
    BOOL asciiOnly = [key canBeConvertedToEncoding:NSASCIIStringEncoding];
    BOOL hasSpace = [key rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound;
    return key.length > 0 && asciiOnly && !hasSpace;
}

static GeminiCheckResult ResultForStatus(NSInteger status) {
    if (status == 200) return GeminiCheckOK;
    if (status == 400 || status == 401 || status == 403) return GeminiCheckInvalidKey;
    if (status == 429) return GeminiCheckRateLimited;
    return GeminiCheckUnknown;
}

@implementation GeminiClient

+ (NSString *)lastVerifyErrorMessage {
    return gLastVerifyError;
}

#pragma mark - Key check

+ (void)verifyKey:(NSString *)key completion:(GeminiVerifyCompletion)completion {
    if (!KeyLooksUsable(key)) {
        gLastVerifyError = @"Key còn chứa khoảng trắng hoặc ký tự lạ nên chưa gửi lên Google. Xóa ô nhập rồi dán lại key.";
        [DiagnosticLog log:@"gemini key rejected locally: contains non-ASCII or spaces (length %lu)", (unsigned long)key.length];
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(GeminiCheckInvalidKey, 0, 0);
        });
        return;
    }

    NSString *urlString = [kGeminiModelsURL stringByAppendingString:@"?pageSize=200"];
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                            timeoutInterval:20];
    request.HTTPMethod = @"GET";
    [KeyStore applyGeminiCredential:key toRequest:request];

    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        GeminiCheckResult result = GeminiCheckUnknown;
        NSInteger count = 0;
        NSInteger status = 0;

        if (error != nil) {
            result = GeminiCheckNetworkError;
        } else {
            status = [(NSHTTPURLResponse *)response statusCode];
            result = ResultForStatus(status);
            if (result == GeminiCheckOK) {
                id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
                NSArray *models = [json isKindOfClass:[NSDictionary class]] ? json[@"models"] : nil;
                if ([models isKindOfClass:[NSArray class]]) {
                    for (id model in models) {
                        if (![model isKindOfClass:[NSDictionary class]]) continue;
                        NSArray *methods = model[@"supportedGenerationMethods"];
                        if ([methods isKindOfClass:[NSArray class]] && [methods containsObject:@"generateContent"]) count++;
                    }
                }
            }
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            gLastVerifyError = nil;
            if (result != GeminiCheckOK && data.length > 0) {
                id body = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                NSDictionary *errorInfo = [body isKindOfClass:[NSDictionary class]] ? body[@"error"] : nil;
                NSString *message = [errorInfo isKindOfClass:[NSDictionary class]] ? errorInfo[@"message"] : nil;
                if ([message isKindOfClass:[NSString class]]) gLastVerifyError = [message copy];
                [DiagnosticLog log:@"gemini key check failed: http=%ld message=%@", (long)status, message ?: @"-"];
            }
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
    if (!KeyLooksUsable(key)) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(@[], GeminiCheckInvalidKey);
        });
        return;
    }
    [self fetchPageWithToken:nil key:key collected:[NSMutableArray array] depth:0 completion:completion];
}

+ (void)fetchPageWithToken:(NSString *)pageToken
                       key:(NSString *)key
                 collected:(NSMutableArray *)collected
                     depth:(NSInteger)depth
                completion:(GeminiModelsCompletion)completion {
    NSMutableString *urlString = [NSMutableString stringWithString:[kGeminiModelsURL stringByAppendingString:@"?pageSize=200"]];
    if (pageToken.length > 0) {
        NSString *escaped = [pageToken stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"&pageToken=%@", escaped];
    }
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                            timeoutInterval:20];
    request.HTTPMethod = @"GET";
    [KeyStore applyGeminiCredential:key toRequest:request];

    NSURLSessionDataTask *task =
        [[NSURLSession sharedSession] dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(@[], GeminiCheckNetworkError); });
            return;
        }
        NSInteger status = [(NSHTTPURLResponse *)response statusCode];
        GeminiCheckResult result = ResultForStatus(status);
        if (result != GeminiCheckOK) {
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
            NSArray *methods = item[@"supportedGenerationMethods"];
            if (![methods isKindOfClass:[NSArray class]] || ![methods containsObject:@"generateContent"]) continue;
            if (![self isChatModelId:modelId]) continue;
            NSString *display = [item[@"displayName"] isKindOfClass:[NSString class]] ? item[@"displayName"] : modelId;
            NSMutableDictionary *model = [@{ @"id": modelId, @"name": display } mutableCopy];
            id outputLimit = item[@"outputTokenLimit"];
            if ([outputLimit respondsToSelector:@selector(integerValue)] && [outputLimit integerValue] > 0) model[@"outputTokenLimit"] = outputLimit;
            id inputLimit = item[@"inputTokenLimit"];
            if ([inputLimit respondsToSelector:@selector(integerValue)] && [inputLimit integerValue] > 0) model[@"inputTokenLimit"] = inputLimit;
            [collected addObject:model];
        }

        NSString *next = [root[@"nextPageToken"] isKindOfClass:[NSString class]] ? root[@"nextPageToken"] : nil;
        if (next.length > 0 && depth < 4) {
            [self fetchPageWithToken:next key:key collected:collected depth:depth + 1 completion:completion];
            return;
        }

        NSArray *sorted = [collected sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
            return [b[@"id"] compare:a[@"id"] options:NSNumericSearch];   // newest/highest first
        }];
        dispatch_async(dispatch_get_main_queue(), ^{ completion(sorted, GeminiCheckOK); });
    }];
    [task resume];
}

@end
