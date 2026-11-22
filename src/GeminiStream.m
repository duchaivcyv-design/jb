#import "GeminiStream.h"
#import "AppSettings.h"
#import "ModelStore.h"
#import "Provider.h"
#import "KeyStore.h"

@interface GeminiStream () <NSURLSessionDataDelegate>
@property (copy, nonatomic) NSString *key;
@property (copy, nonatomic) NSString *model;
@property (copy, nonatomic) NSArray *turns;
@property (copy, nonatomic) NSString *system;
@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSessionDataTask *task;
@property (strong, nonatomic) NSMutableData *buffer;
@property (assign, nonatomic) NSUInteger bufferReadOffset;
@property (strong, nonatomic) NSMutableData *errorBody;
@property (assign, nonatomic) NSInteger status;
@property (assign, nonatomic) BOOL cancelled;
@property (assign, nonatomic) BOOL finished;
@property (assign, nonatomic) BOOL gotText;
@property (assign, nonatomic) BOOL hitMaxTokens;
@property (copy, nonatomic) NSString *blockReason;
@property (assign, nonatomic) NSInteger inStreamErrorStatus;
@property (copy, nonatomic) NSString *inStreamErrorMessage;
@property (assign, nonatomic) long long inputTokenUsage;
@property (assign, nonatomic) long long outputTokenUsage;

@property (assign, nonatomic) NSInteger sameKeyRetryCount;
@property (strong, nonatomic) NSMutableURLRequest *savedRequest;
@end

@implementation GeminiStream
@synthesize retryAfterSeconds = _retryAfterSeconds;

- (instancetype)initWithKey:(NSString *)key model:(NSString *)model turns:(NSArray *)turns system:(NSString *)system {
    self = [super init];
    if (self) {
        _key = [key copy];
        _model = [model copy];
        _turns = [turns copy];
        _system = [system copy];
        _buffer = [NSMutableData dataWithCapacity:65536];
        _bufferReadOffset = 0;
        _errorBody = [NSMutableData data];
        _useStreaming = YES;
        _useFastSpeed = NO;
        _sameKeyRetryCount = 0;
    }
    return self;
}

#pragma mark - Request format

+ (NSArray *)contentsFromTurns:(NSArray *)turns {
    NSMutableArray *contents = [NSMutableArray arrayWithCapacity:turns.count];
    for (NSDictionary *turn in turns) {
        if (![turn isKindOfClass:[NSDictionary class]]) continue;
        NSArray *rawParts = [turn[@"parts"] isKindOfClass:[NSArray class]] ? turn[@"parts"] : @[];
        NSMutableArray *parts = [NSMutableArray arrayWithCapacity:rawParts.count];
        for (NSDictionary *part in rawParts) {
            if (![part isKindOfClass:[NSDictionary class]]) continue;
            NSString *type = part[@"type"];
            if ([type isEqualToString:@"text"] && [part[@"text"] isKindOfClass:[NSString class]] && [part[@"text"] length] > 0) {
                [parts addObject:@{ @"text": part[@"text"] }];
            } else if ([type isEqualToString:@"image"] && [part[@"data"] isKindOfClass:[NSString class]] && [part[@"data"] length] > 0) {
                [parts addObject:@{ @"inline_data": @{ @"mime_type": part[@"mime"] ?: @"image/jpeg", @"data": part[@"data"] } }];
            } else if ([type isEqualToString:@"pdf"] && [part[@"data"] isKindOfClass:[NSString class]] && [part[@"data"] length] > 0) {
                [parts addObject:@{ @"inline_data": @{ @"mime_type": @"application/pdf", @"data": part[@"data"] } }];
            }
        }
        if (parts.count == 0) continue;
        NSString *role = [turn[@"role"] isEqualToString:@"assistant"] ? @"model" : @"user";
        [contents addObject:@{ @"role": role, @"parts": parts }];
    }
    return contents;
}

#pragma mark - Control

- (NSTimeInterval)effectiveTimeout {
    if (self.useFastSpeed) {
        return self.useStreaming ? 75.0 : 105.0;
    }
    return self.useStreaming ? 180.0 : 240.0;
}

- (NSMutableURLRequest *)buildRequestWithBody:(NSData *)body {
    NSString *escapedModel = [self.model stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *method = self.useStreaming ? @"streamGenerateContent?alt=sse" : @"generateContent";
    NSString *urlString = [NSString stringWithFormat:
        @"https://generativelanguage.googleapis.com/v1beta/models/%@:%@", escapedModel, method];

    NSTimeInterval timeout = [self effectiveTimeout];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:timeout];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.useStreaming ? @"text/event-stream" : @"application/json" forHTTPHeaderField:@"Accept"];
    if (self.useStreaming) {
        [request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    }
    [KeyStore applyGeminiCredential:self.key toRequest:request];
    return request;
}

- (void)start {
    self.sameKeyRetryCount = 0;

    NSInteger requestedOutputTokens = [AppSettings maxOutputTokens];
    NSInteger modelCap = [ModelStore maxOutputTokensForModelId:self.model provider:AIProviderGemini];
    if (modelCap <= 0) modelCap = 8192;
    AIReasoningLevel reasoning = [AppSettings reasoningLevel];

    // Ép trần output cao hơn khi bật suy luận sâu/MAX để không bị cụt giữa chừng
    NSInteger effectiveRequest = requestedOutputTokens;
    if (!self.useFastSpeed && reasoning >= AIReasoningLevelHigh) {
        effectiveRequest = MAX(requestedOutputTokens, MIN(modelCap, 65536));
    }
    NSInteger outputCeiling = effectiveRequest > 0 ? MIN(effectiveRequest, modelCap) : modelCap;
    NSString *lowerModel = self.model.lowercaseString;

    NSMutableDictionary *generationConfig = [NSMutableDictionary dictionary];
    BOOL supportsThinking = [lowerModel containsString:@"gemini-2.5"] ||
                            [lowerModel containsString:@"gemini-3"] ||
                            [lowerModel containsString:@"gemini-4"];
    NSInteger maxThinkingAllowed = supportsThinking ? MAX(0, outputCeiling - 512) : 0;

    if ([lowerModel containsString:@"gemini-4"]) {
        NSArray *levels = self.useFastSpeed
            ? @[@"minimal", @"low", @"low", @"medium", @"high"]
            : @[@"low", @"low", @"medium", @"high", @"high"];
        generationConfig[@"thinkingConfig"] = @{ @"thinkingLevel": levels[(NSUInteger)reasoning] };
    } else if ([lowerModel containsString:@"gemini-3"]) {
        NSArray *levels = [lowerModel containsString:@"pro"]
            ? (self.useFastSpeed ? @[@"low", @"low", @"low", @"medium", @"high"] : @[@"low", @"low", @"medium", @"high", @"high"])
            : (self.useFastSpeed ? @[@"minimal", @"minimal", @"low", @"medium", @"high"] : @[@"minimal", @"low", @"medium", @"high", @"high"]);
        generationConfig[@"thinkingConfig"] = @{ @"thinkingLevel": levels[(NSUInteger)reasoning] };
    } else if ([lowerModel containsString:@"gemini-2.5"]) {
        BOOL proModel = [lowerModel containsString:@"pro"];
        NSArray *budgets = proModel
            ? @[@128, @1024, @8192, @24576, @32768]
            : @[@0, @1024, @4096, @16384, @24576];
        NSInteger desiredBudget = [budgets[(NSUInteger)reasoning] integerValue];
        if (self.useFastSpeed) {
            desiredBudget = desiredBudget / 4;
        }
        NSInteger thinkingBudget = MIN(desiredBudget, maxThinkingAllowed);
        if (proModel && thinkingBudget > 0 && thinkingBudget < 128) thinkingBudget = 0;
        if (!proModel || thinkingBudget >= 128) {
            generationConfig[@"thinkingConfig"] = @{ @"thinkingBudget": @(thinkingBudget) };
        }
    }

    generationConfig[@"maxOutputTokens"] = @(MAX(1, outputCeiling));
    if (self.useFastSpeed) {
        generationConfig[@"temperature"] = @0.35;
    } else if (reasoning >= AIReasoningLevelVeryHigh) {
        generationConfig[@"temperature"] = @0.7;
    }

    BOOL imageGenerationModel = [lowerModel containsString:@"image"] || [lowerModel containsString:@"nano-banana"];
    if (imageGenerationModel) {
        generationConfig[@"responseModalities"] = @[@"TEXT", @"IMAGE"];
    }

    NSMutableDictionary *payload = [@{ @"contents": [GeminiStream contentsFromTurns:self.turns],
                                       @"generationConfig": generationConfig } mutableCopy];
    if (self.system.length > 0) {
        payload[@"systemInstruction"] = @{ @"parts": @[ @{ @"text": self.system } ] };
    }
    if ([AppSettings webSearchEnabled] && !imageGenerationModel) {
        payload[@"tools"] = @[@{ @"google_search": @{} }];
    }

    NSJSONWritingOptions opts = 0;
    if (@available(iOS 13.0, *)) {
        opts = NSJSONWritingWithoutEscapingSlashes;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        GeminiStream *bgMe = weakSelf;
        if (!bgMe || bgMe.cancelled || bgMe.finished) return;
        NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:opts error:nil];
        if (!body) body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            GeminiStream *mainMe = weakSelf;
            if (!mainMe || mainMe.cancelled || mainMe.finished) return;
            NSMutableURLRequest *request = [mainMe buildRequestWithBody:body];
            mainMe.savedRequest = request;
            [mainMe executeForcedRequest:request];
        });
    });
}

- (void)executeForcedRequest:(NSMutableURLRequest *)request {
    if (self.finished || self.cancelled || !request) return;

    if (self.session) {
        [self.session invalidateAndCancel];
        self.session = nil;
    }
    self.task = nil;

    [self.buffer setLength:0];
    self.bufferReadOffset = 0;
    [self.errorBody setLength:0];
    self.status = 0;
    self.gotText = NO;
    self.hitMaxTokens = NO;
    self.inStreamErrorStatus = 0;
    self.inStreamErrorMessage = nil;
    self.blockReason = nil;
    self.inputTokenUsage = 0;
    self.outputTokenUsage = 0;

    NSTimeInterval timeout = [self effectiveTimeout];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = timeout;
    config.timeoutIntervalForResource = 7200;
    config.HTTPMaximumConnectionsPerHost = 6;
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
}

- (void)cancel {
    if (self.finished) return;
    self.cancelled = YES;
    [self.task cancel];
    [self.session invalidateAndCancel];
    self.session = nil;
    self.task = nil;
}

#pragma mark - NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    self.status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
    self.retryAfterSeconds = 0;
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSDictionary *headers = [(NSHTTPURLResponse *)response allHeaderFields];
        for (id key in headers) {
            if ([[key description] caseInsensitiveCompare:@"Retry-After"] != NSOrderedSame) continue;
            id rawValue = headers[key];
            NSTimeInterval delay = [rawValue respondsToSelector:@selector(doubleValue)] ? [rawValue doubleValue] : 0;
            if (delay <= 0) {
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
                formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss z";
                NSDate *retryDate = [formatter dateFromString:[rawValue description]];
                if (retryDate) delay = [retryDate timeIntervalSinceNow];
            }
            self.retryAfterSeconds = MIN(900.0, MAX(0.0, delay));
            break;
        }
    }
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    if (self.status != 200) {
        [self.errorBody appendData:data];
        return;
    }
    [self.buffer appendData:data];
    if (self.useStreaming) [self drainBufferFinal:NO];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.finished) return;

    if (self.useStreaming) {
        [self drainBufferFinal:YES];
    }

    BOOL isRateLimitOrOverload = (self.status == 429 || self.status >= 500 ||
                                  self.inStreamErrorStatus == 429 || self.inStreamErrorStatus >= 500);

    if (!self.cancelled && error == nil && !isRateLimitOrOverload && self.status == 200 && (self.inStreamErrorStatus == 0)) {
        self.finished = YES;
        if (!self.useStreaming) [self processWholeBody];
        [self.session finishTasksAndInvalidate];
        self.session = nil;
        self.task = nil;

        if (!self.gotText) {
            GeminiStreamError result = self.blockReason.length > 0 ? GeminiStreamErrorBlocked : GeminiStreamErrorEmptyReply;
            NSString *detail = self.blockReason;
            if (self.onUsage && (self.inputTokenUsage > 0 || self.outputTokenUsage > 0)) {
                self.onUsage(self.inputTokenUsage, self.outputTokenUsage);
            }
            void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
            self.onDelta = nil;
            self.onImage = nil;
            self.onUsage = nil;
            self.onFinish = nil;
            if (finish) finish(result, self.status, detail);
            return;
        }

        if (self.onUsage && (self.inputTokenUsage > 0 || self.outputTokenUsage > 0)) {
            self.onUsage(self.inputTokenUsage, self.outputTokenUsage);
        }
        NSString *okDetail = self.hitMaxTokens ? @"__OUTPUT_LIMIT_REACHED__" : nil;
        void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
        self.onDelta = nil;
        self.onImage = nil;
        self.onUsage = nil;
        self.onFinish = nil;
        if (finish) finish(GeminiStreamErrorNone, self.status, okDetail);
        return;
    }

    if (self.cancelled) {
        self.finished = YES;
        [self.session invalidateAndCancel];
        self.session = nil;
        self.task = nil;
        void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
        self.onDelta = nil;
        self.onImage = nil;
        self.onUsage = nil;
        self.onFinish = nil;
        if (finish) finish(GeminiStreamErrorCancelled, self.status, nil);
        return;
    }

    // Ép retry mạnh hơn khi chưa có text để vượt quá tải tạm thời / rớt kết nối
    NSInteger maxRetries = self.useFastSpeed ? 10 : 14;
    double maxBackoff = self.useFastSpeed ? 5.0 : 10.0;
    // A timeout means no bytes arrived for the whole idle window (common while the model is still thinking).
    // Retrying it silently only repeats the same long wait, so it fails at once with a clear message instead.
    BOOL timedOut = (error != nil && error.code == NSURLErrorTimedOut);
    BOOL networkDrop = (error != nil && self.status == 0 && error.code != NSURLErrorCancelled && !timedOut);
    NSInteger retryLimit = isRateLimitOrOverload ? maxRetries : MIN(maxRetries, 3);
    if (!self.gotText && (isRateLimitOrOverload || networkDrop)) {
        if (self.sameKeyRetryCount < retryLimit) {
            self.sameKeyRetryCount++;
            NSTimeInterval backoffDelay = MIN(pow(1.45, self.sameKeyRetryCount), maxBackoff);
            NSTimeInterval jitter = (double)(arc4random_uniform(350)) / 1000.0;
            NSTimeInterval totalWait = backoffDelay + jitter;

            [self.session invalidateAndCancel];
            self.session = nil;
            self.task = nil;

            __weak typeof(self) weakSelf = self;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(totalWait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                GeminiStream *me = weakSelf;
                if (me && !me.finished && !me.cancelled) {
                    [me executeForcedRequest:me.savedRequest];
                }
            });
            return;
        }
    }

    self.finished = YES;
    [self.session invalidateAndCancel];
    self.session = nil;
    self.task = nil;

    GeminiStreamError result = GeminiStreamErrorNone;
    NSString *detail = nil;

    if (error != nil && !self.gotText) {
        result = GeminiStreamErrorNetwork;
        detail = [NSString stringWithFormat:@"%@ [%@ %ld]", error.localizedDescription, error.domain, (long)error.code];
    } else if (self.status != 200 && !self.gotText) {
        NSString *message = [self messageFromErrorBody:self.errorBody];
        detail = message;
        NSTimeInterval bodyRetryDelay = [self retryDelayFromErrorBody:self.errorBody];
        if (bodyRetryDelay > self.retryAfterSeconds) self.retryAfterSeconds = bodyRetryDelay;
        result = [GeminiStream errorForStatus:self.status message:message];
    } else if (self.inStreamErrorStatus != 0 && !self.gotText) {
        detail = self.inStreamErrorMessage;
        result = [GeminiStream errorForStatus:self.inStreamErrorStatus message:self.inStreamErrorMessage];
    } else if (!self.gotText) {
        result = self.blockReason.length > 0 ? GeminiStreamErrorBlocked : GeminiStreamErrorEmptyReply;
        detail = self.blockReason;
    }

    if (self.onUsage && (self.inputTokenUsage > 0 || self.outputTokenUsage > 0)) {
        self.onUsage(self.inputTokenUsage, self.outputTokenUsage);
    }
    void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
    NSInteger status = self.inStreamErrorStatus > 0 ? self.inStreamErrorStatus : self.status;
    self.onDelta = nil;
    self.onImage = nil;
    self.onUsage = nil;
    self.onFinish = nil;
    if (finish) finish(result, status, detail);
}

#pragma mark - SSE parsing

- (void)compactReadBufferIfNeeded:(BOOL)force {
    if (self.bufferReadOffset == 0) return;
    if (force || self.bufferReadOffset >= 65536 || self.bufferReadOffset >= self.buffer.length / 2) {
        NSUInteger remaining = self.buffer.length > self.bufferReadOffset ? (self.buffer.length - self.bufferReadOffset) : 0;
        if (remaining > 0) {
            memmove(self.buffer.mutableBytes, (const uint8_t *)self.buffer.bytes + self.bufferReadOffset, remaining);
        }
        self.buffer.length = remaining;
        self.bufferReadOffset = 0;
    }
}

- (void)drainBufferFinal:(BOOL)final {
    if (self.buffer.length <= self.bufferReadOffset) {
        if (final) {
            self.buffer.length = 0;
            self.bufferReadOffset = 0;
        }
        return;
    }
    const uint8_t *bytes = self.buffer.bytes;
    NSUInteger totalLen = self.buffer.length;
    NSUInteger pos = self.bufferReadOffset;

    while (pos < totalLen) {
        const uint8_t *found = memchr(bytes + pos, '\n', totalLen - pos);
        if (!found) break;
        NSUInteger lineEnd = (NSUInteger)(found - bytes);
        NSUInteger lineLen = lineEnd > pos ? (lineEnd - pos) : 0;
        NSData *lineData = [NSData dataWithBytesNoCopy:(void *)(bytes + pos) length:lineLen freeWhenDone:NO];
        [self processLineData:lineData];
        pos = lineEnd + 1;
    }

    self.bufferReadOffset = pos;
    if (final && self.bufferReadOffset < self.buffer.length) {
        NSData *tailData = [NSData dataWithBytesNoCopy:(void *)(bytes + self.bufferReadOffset)
                                                length:(self.buffer.length - self.bufferReadOffset)
                                          freeWhenDone:NO];
        [self processLineData:tailData];
        self.buffer.length = 0;
        self.bufferReadOffset = 0;
    } else {
        [self compactReadBufferIfNeeded:final];
    }
}

- (void)processLineData:(NSData *)lineData {
    if (lineData.length < 6) return;
    NSString *line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
    if (line == nil) return;
    line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r"]];
    if (![line hasPrefix:@"data:"]) return;

    NSString *payload = [[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (payload.length == 0 || [payload isEqualToString:@"[DONE]"]) return;

    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    if (!payloadData) return;
    id json = [NSJSONSerialization JSONObjectWithData:payloadData options:0 error:nil];
    if (![json isKindOfClass:[NSDictionary class]]) return;
    [self processChunk:json];
}

- (void)processChunk:(NSDictionary *)chunk {
    NSDictionary *usage = [chunk[@"usageMetadata"] isKindOfClass:[NSDictionary class]] ? chunk[@"usageMetadata"] : nil;
    if (usage) {
        self.inputTokenUsage = MAX(self.inputTokenUsage, [usage[@"promptTokenCount"] longLongValue]);
        long long output = [usage[@"candidatesTokenCount"] longLongValue] + [usage[@"thoughtsTokenCount"] longLongValue];
        self.outputTokenUsage = MAX(self.outputTokenUsage, output);
    }
    NSDictionary *errorObject = [chunk[@"error"] isKindOfClass:[NSDictionary class]] ? chunk[@"error"] : nil;
    if (errorObject) {
        NSInteger code = [errorObject[@"code"] respondsToSelector:@selector(integerValue)] ? [errorObject[@"code"] integerValue] : 500;
        self.inStreamErrorStatus = code > 0 ? code : 500;
        if ([errorObject[@"message"] isKindOfClass:[NSString class]]) self.inStreamErrorMessage = errorObject[@"message"];
        return;
    }

    NSDictionary *feedback = [chunk[@"promptFeedback"] isKindOfClass:[NSDictionary class]] ? chunk[@"promptFeedback"] : nil;
    if ([feedback[@"blockReason"] isKindOfClass:[NSString class]]) self.blockReason = feedback[@"blockReason"];

    NSArray *candidates = [chunk[@"candidates"] isKindOfClass:[NSArray class]] ? chunk[@"candidates"] : @[];
    NSDictionary *candidate = [candidates.firstObject isKindOfClass:[NSDictionary class]] ? candidates.firstObject : nil;
    if (!candidate) return;

    NSDictionary *content = [candidate[@"content"] isKindOfClass:[NSDictionary class]] ? candidate[@"content"] : nil;
    NSArray *parts = [content[@"parts"] isKindOfClass:[NSArray class]] ? content[@"parts"] : @[];
    for (id part in parts) {
        if (![part isKindOfClass:[NSDictionary class]]) continue;
        BOOL isThought = [part[@"thought"] respondsToSelector:@selector(boolValue)] && [part[@"thought"] boolValue];
        NSString *text = part[@"text"];
        if (!isThought && [text isKindOfClass:[NSString class]] && text.length > 0) {
            self.gotText = YES;
            if (self.onDelta) self.onDelta(text);
        }
        NSDictionary *inlineData = [part[@"inlineData"] isKindOfClass:[NSDictionary class]] ? part[@"inlineData"] : nil;
        NSString *mime = [inlineData[@"mimeType"] isKindOfClass:[NSString class]] ? inlineData[@"mimeType"] : @"";
        NSString *encoded = [inlineData[@"data"] isKindOfClass:[NSString class]] ? inlineData[@"data"] : nil;
        if ([mime hasPrefix:@"image/"] && encoded.length > 0) {
            NSData *imageData = [[NSData alloc] initWithBase64EncodedString:encoded options:NSDataBase64DecodingIgnoreUnknownCharacters];
            if (imageData.length > 0) {
                self.gotText = YES;
                if (self.onImage) self.onImage(imageData, mime);
            }
        }
    }

    NSString *finishReason = [candidate[@"finishReason"] isKindOfClass:[NSString class]] ? candidate[@"finishReason"] : nil;
    if ([finishReason isEqualToString:@"MAX_TOKENS"]) {
        self.hitMaxTokens = YES;
    }
    if (finishReason.length > 0 && !self.gotText) {
        NSArray *blocking = @[@"SAFETY", @"PROHIBITED_CONTENT", @"BLOCKLIST", @"SPII", @"RECITATION", @"IMAGE_SAFETY"];
        if ([blocking containsObject:finishReason]) self.blockReason = finishReason;
    }
}

- (void)processWholeBody {
    if (self.buffer.length == 0) return;
    id json = [NSJSONSerialization JSONObjectWithData:self.buffer options:0 error:nil];
    if ([json isKindOfClass:[NSDictionary class]]) {
        [self processChunk:json];
    } else if ([json isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)json) {
            if ([item isKindOfClass:[NSDictionary class]]) [self processChunk:item];
        }
    }
}

#pragma mark - Errors

- (NSString *)messageFromErrorBody:(NSData *)body {
    if (body.length == 0) return nil;
    id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
    if ([json isKindOfClass:[NSArray class]]) json = [(NSArray *)json firstObject];
    if (![json isKindOfClass:[NSDictionary class]]) return nil;

    NSDictionary *err = [json[@"error"] isKindOfClass:[NSDictionary class]] ? json[@"error"] : nil;
    if (!err) return nil;
    NSMutableArray<NSString *> *diagnostics = [NSMutableArray array];
    NSString *message = [err[@"message"] isKindOfClass:[NSString class]] ? err[@"message"] : nil;
    NSString *status = [err[@"status"] isKindOfClass:[NSString class]] ? err[@"status"] : nil;
    if (message.length) [diagnostics addObject:message];
    if (status.length) [diagnostics addObject:[NSString stringWithFormat:@"providerStatus=%@", status]];

    NSArray *details = [err[@"details"] isKindOfClass:[NSArray class]] ? err[@"details"] : @[];
    for (id item in details) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *reason = [item[@"reason"] isKindOfClass:[NSString class]] ? item[@"reason"] : nil;
        NSDictionary *metadata = [item[@"metadata"] isKindOfClass:[NSDictionary class]] ? item[@"metadata"] : nil;
        NSString *quotaMetric = [metadata[@"quotaMetric"] isKindOfClass:[NSString class]] ? metadata[@"quotaMetric"] : nil;
        NSString *quotaId = [metadata[@"quotaId"] isKindOfClass:[NSString class]] ? metadata[@"quotaId"] : nil;
        NSString *retryDelay = [item[@"retryDelay"] isKindOfClass:[NSString class]] ? item[@"retryDelay"] : nil;
        if (reason.length) [diagnostics addObject:[NSString stringWithFormat:@"reason=%@", reason]];
        if (quotaMetric.length) [diagnostics addObject:[NSString stringWithFormat:@"quotaMetric=%@", quotaMetric]];
        if (quotaId.length) [diagnostics addObject:[NSString stringWithFormat:@"quotaId=%@", quotaId]];
        if (retryDelay.length) [diagnostics addObject:[NSString stringWithFormat:@"retryDelay=%@", retryDelay]];
    }
    return diagnostics.count ? [diagnostics componentsJoinedByString:@" | "] : nil;
}

- (NSTimeInterval)retryDelayFromErrorBody:(NSData *)body {
    if (body.length == 0) return 0;
    id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
    if ([json isKindOfClass:[NSArray class]]) json = [(NSArray *)json firstObject];
    NSDictionary *errorObject = [json isKindOfClass:[NSDictionary class]] && [json[@"error"] isKindOfClass:[NSDictionary class]] ? json[@"error"] : nil;
    NSArray *details = [errorObject[@"details"] isKindOfClass:[NSArray class]] ? errorObject[@"details"] : @[];
    for (id item in details) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSString *type = [item[@"@type"] isKindOfClass:[NSString class]] ? item[@"@type"] : @"";
        NSString *retryDelay = [item[@"retryDelay"] isKindOfClass:[NSString class]] ? item[@"retryDelay"] : nil;
        if ([type containsString:@"RetryInfo"] && retryDelay.length > 1 && [retryDelay hasSuffix:@"s"]) {
            double seconds = [[retryDelay substringToIndex:retryDelay.length - 1] doubleValue];
            if (seconds > 0) return MIN(900.0, seconds);
        }
    }
    return 0;
}

+ (GeminiStreamError)errorForStatus:(NSInteger)status message:(NSString *)message {
    NSString *lower = [message lowercaseString];
    if (status == 413) return GeminiStreamErrorTooLarge;
    if (status == 400) {
        if (lower.length > 0 && [lower rangeOfString:@"api key"].location != NSNotFound) return GeminiStreamErrorInvalidKey;
        if (lower.length > 0 && ([lower rangeOfString:@"payload size"].location != NSNotFound ||
                                 [lower rangeOfString:@"too large"].location != NSNotFound ||
                                 [lower rangeOfString:@"exceeds the limit"].location != NSNotFound)) {
            return GeminiStreamErrorTooLarge;
        }
        return GeminiStreamErrorUnknown;
    }
    if (status == 401) return GeminiStreamErrorInvalidKey;
    if (status == 403) return GeminiStreamErrorPermissionDenied;
    if (status == 404) return GeminiStreamErrorModelNotFound;
    if (status == 429) return GeminiStreamErrorRateLimited;
    if (status >= 500) return GeminiStreamErrorServer;
    return GeminiStreamErrorUnknown;
}

@end
