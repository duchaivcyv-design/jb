#import "ClaudeStream.h"
#import "Strings.h"
#import "AppSettings.h"
#import "ModelStore.h"

static NSString *const kClaudeMessagesURL = @"https://api.anthropic.com/v1/messages";
static NSString *const kAnthropicVersion = @"2023-06-01";

@interface ClaudeStream () <NSURLSessionDataDelegate>
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
@property (copy, nonatomic) NSString *stopReason;
@property (copy, nonatomic) NSString *inStreamErrorType;
@property (copy, nonatomic) NSString *inStreamErrorMessage;
@property (assign, nonatomic) long long inputTokenUsage;
@property (assign, nonatomic) long long outputTokenUsage;

@property (assign, nonatomic) NSInteger sameKeyRetryCount;
@property (strong, nonatomic) NSMutableURLRequest *savedRequest;
@end

@implementation ClaudeStream

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
        _sameKeyRetryCount = 0;
    }
    return self;
}

#pragma mark - Request format

- (NSInteger)maxTokens {
    NSInteger requested = [AppSettings maxOutputTokens];
    NSInteger modelCap = [ModelStore maxOutputTokensForModelId:self.model provider:AIProviderClaude];
    if (modelCap <= 0) modelCap = [self.model hasPrefix:@"claude-3-"] ? 4096 : 16384;

    AIReasoningLevel level = [AppSettings reasoningLevel];
    NSInteger effectiveRequest = requested;
    if (!self.useFastSpeed && level >= AIReasoningLevelHigh) {
        effectiveRequest = MAX(requested, MIN(modelCap, 32768));
    }
    return effectiveRequest > 0 ? MIN(effectiveRequest, modelCap) : modelCap;
}

+ (NSArray *)messagesFromTurns:(NSArray *)turns {
    NSMutableArray *messages = [NSMutableArray arrayWithCapacity:turns.count];
    for (NSDictionary *turn in turns) {
        if (![turn isKindOfClass:[NSDictionary class]]) continue;
        NSArray *rawParts = [turn[@"parts"] isKindOfClass:[NSArray class]] ? turn[@"parts"] : @[];
        NSMutableArray *blocks = [NSMutableArray arrayWithCapacity:rawParts.count];
        for (NSDictionary *part in rawParts) {
            if (![part isKindOfClass:[NSDictionary class]]) continue;
            NSString *type = part[@"type"];
            if ([type isEqualToString:@"text"] && [part[@"text"] isKindOfClass:[NSString class]] && [part[@"text"] length] > 0) {
                [blocks addObject:@{ @"type": @"text", @"text": part[@"text"] }];
            } else if ([type isEqualToString:@"image"] && [part[@"data"] isKindOfClass:[NSString class]] && [part[@"data"] length] > 0) {
                [blocks addObject:@{ @"type": @"image",
                                     @"source": @{ @"type": @"base64", @"media_type": part[@"mime"] ?: @"image/jpeg", @"data": part[@"data"] } }];
            } else if ([type isEqualToString:@"pdf"] && [part[@"data"] isKindOfClass:[NSString class]] && [part[@"data"] length] > 0) {
                [blocks addObject:@{ @"type": @"document",
                                     @"source": @{ @"type": @"base64", @"media_type": @"application/pdf", @"data": part[@"data"] } }];
            }
        }
        if (blocks.count == 0) continue;
        NSString *role = [turn[@"role"] isEqualToString:@"assistant"] ? @"assistant" : @"user";
        [messages addObject:@{ @"role": role, @"content": blocks }];
    }
    return messages;
}

#pragma mark - Control

- (NSTimeInterval)effectiveTimeout {
    if (self.useFastSpeed) {
        return self.useStreaming ? 75.0 : 105.0;
    }
    return self.useStreaming ? 180.0 : 240.0;
}

- (NSMutableURLRequest *)buildRequestWithBody:(NSData *)body
                               supportsFast:(BOOL)supportsFast
                              needsFastBeta:(BOOL)needsFastBeta {
    NSTimeInterval timeout = [self effectiveTimeout];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kClaudeMessagesURL]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:timeout];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.useStreaming ? @"text/event-stream" : @"application/json" forHTTPHeaderField:@"Accept"];
    if (self.useStreaming) {
        [request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    }
    [request setValue:self.key forHTTPHeaderField:@"x-api-key"];
    [request setValue:kAnthropicVersion forHTTPHeaderField:@"anthropic-version"];
    if (self.useFastSpeed && supportsFast && needsFastBeta) {
        [request setValue:@"fast-mode-2026-02-01" forHTTPHeaderField:@"anthropic-beta"];
    }
    return request;
}

- (void)start {
    self.sameKeyRetryCount = 0;
    NSInteger maxTokens = [self maxTokens];
    NSMutableDictionary *payload = [@{ @"model": self.model ?: @"",
                                       @"max_tokens": @(maxTokens),
                                       @"messages": [ClaudeStream messagesFromTurns:self.turns] } mutableCopy];
    if (self.useStreaming) payload[@"stream"] = @YES;
    if (self.system.length > 0) payload[@"system"] = self.system;

    NSString *lowerModel = self.model.lowercaseString;
    BOOL supportsFast = ([lowerModel containsString:@"claude-opus-5-5"] ||
                         [lowerModel containsString:@"claude-fable-5-2"] ||
                         [lowerModel containsString:@"claude-mythos-5-2"] ||
                         [lowerModel isEqualToString:@"claude-opus-5"] ||
                         [lowerModel containsString:@"claude-opus-5-"] ||
                         [lowerModel containsString:@"claude-opus-4-8"]);
    BOOL isOpus5Preview = [lowerModel isEqualToString:@"claude-opus-5"] ||
                          ([lowerModel containsString:@"claude-opus-5-"] && ![lowerModel containsString:@"claude-opus-5-5"]);
    BOOL needsFastBeta = isOpus5Preview || [lowerModel containsString:@"claude-opus-4-8"];
    if (self.useFastSpeed && supportsFast) payload[@"speed"] = @"fast";

    AIReasoningLevel level = [AppSettings reasoningLevel];
    BOOL adaptiveThinking = ([lowerModel containsString:@"-4-6"] || [lowerModel containsString:@"-4-7"] ||
                             [lowerModel containsString:@"-4-8"] || [lowerModel containsString:@"-5-"] ||
                             [lowerModel containsString:@"-6-"]);
    BOOL legacyThinking = ([lowerModel containsString:@"-3-7"] || [lowerModel containsString:@"-4-0"] ||
                           [lowerModel containsString:@"-4-1"] || [lowerModel containsString:@"-4-2"] ||
                           [lowerModel containsString:@"-4-3"] || [lowerModel containsString:@"-4-4"] ||
                           [lowerModel containsString:@"-4-5"]);
    if (adaptiveThinking) {
        NSArray *efforts = self.useFastSpeed
            ? @[@"low", @"low", @"medium", @"high", @"high"]
            : @[@"low", @"medium", @"high", @"xhigh", @"max"];
        NSString *effort = efforts[(NSUInteger)level];
        if ([lowerModel containsString:@"-4-6"] && [effort isEqualToString:@"xhigh"]) effort = @"high";
        NSMutableDictionary *thinking = [@{ @"type": @"adaptive" } mutableCopy];
        if ([lowerModel containsString:@"-4-7"] || [lowerModel containsString:@"-4-8"] ||
            [lowerModel containsString:@"-5-"] || [lowerModel containsString:@"-6-"]) {
            thinking[@"display"] = @"summarized";
        }
        payload[@"thinking"] = thinking;
        payload[@"output_config"] = @{ @"effort": effort };
    } else if (legacyThinking && level > AIReasoningLevelLow) {
        NSArray *budgets = @[@0, @1024, @2048, @4096, @8192];
        NSInteger budget = [budgets[(NSUInteger)level] integerValue];
        if (self.useFastSpeed) {
            budget = budget / 2;
        }
        budget = MIN(budget, MAX(0, maxTokens - 1024));
        if (budget >= 1024) {
            payload[@"thinking"] = @{ @"type": @"enabled", @"budget_tokens": @(budget) };
        }
    }

    if ([AppSettings webSearchEnabled]) {
        payload[@"tools"] = @[@{ @"type": @"web_search_20250305", @"name": @"web_search", @"max_uses": @3 }];
    }

    NSJSONWritingOptions opts = 0;
    if (@available(iOS 13.0, *)) {
        opts = NSJSONWritingWithoutEscapingSlashes;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        ClaudeStream *bgMe = weakSelf;
        if (!bgMe || bgMe.cancelled || bgMe.finished) return;
        NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:opts error:nil];
        if (!body) body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

        dispatch_async(dispatch_get_main_queue(), ^{
            ClaudeStream *mainMe = weakSelf;
            if (!mainMe || mainMe.cancelled || mainMe.finished) return;
            NSMutableURLRequest *request = [mainMe buildRequestWithBody:body
                                                         supportsFast:supportsFast
                                                        needsFastBeta:needsFastBeta];
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
    self.inStreamErrorType = nil;
    self.inStreamErrorMessage = nil;
    self.stopReason = nil;
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
            NSString *headerName = [[key description] lowercaseString];
            id rawValue = headers[key];
            NSTimeInterval delay = 0;
            if ([headerName isEqualToString:@"retry-after"]) {
                delay = [rawValue respondsToSelector:@selector(doubleValue)] ? [rawValue doubleValue] : 0;
                if (delay <= 0) {
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
                    formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss z";
                    NSDate *retryDate = [formatter dateFromString:[rawValue description]];
                    if (retryDate) delay = [retryDate timeIntervalSinceNow];
                }
            } else if ([headerName isEqualToString:@"anthropic-ratelimit-requests-reset"] ||
                       [headerName isEqualToString:@"anthropic-ratelimit-tokens-reset"]) {
                if (@available(iOS 10.0, *)) {
                    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
                    NSDate *resetDate = [formatter dateFromString:[rawValue description]];
                    if (resetDate) delay = [resetDate timeIntervalSinceNow];
                }
            }
            if (delay > self.retryAfterSeconds) self.retryAfterSeconds = MIN(900.0, MAX(0.0, delay));
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

    BOOL isRateLimitOrOverload = (self.status == 429 || self.status == 529 || self.status >= 500 ||
                                  [self.inStreamErrorType isEqualToString:@"overloaded_error"] ||
                                  [self.inStreamErrorType isEqualToString:@"rate_limit_error"]);

    if (!self.cancelled && error == nil && !isRateLimitOrOverload && self.status == 200 && (self.inStreamErrorType.length == 0)) {
        self.finished = YES;
        if (!self.useStreaming) [self processWholeBody];
        [self.session finishTasksAndInvalidate];
        self.session = nil;
        self.task = nil;

        if (!self.gotText) {
            GeminiStreamError result = [self.stopReason isEqualToString:@"refusal"] ? GeminiStreamErrorBlocked : GeminiStreamErrorEmptyReply;
            NSString *detail = self.stopReason;
            if (self.onUsage && (self.inputTokenUsage > 0 || self.outputTokenUsage > 0)) {
                self.onUsage(self.inputTokenUsage, self.outputTokenUsage);
            }
            void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
            self.onDelta = nil;
            self.onUsage = nil;
            self.onFinish = nil;
            if (finish) finish(result, self.status, detail);
            return;
        }

        if (self.onUsage && (self.inputTokenUsage > 0 || self.outputTokenUsage > 0)) {
            self.onUsage(self.inputTokenUsage, self.outputTokenUsage);
        }
        NSString *okDetail = [self.stopReason isEqualToString:@"max_tokens"] ? @"__OUTPUT_LIMIT_REACHED__" : nil;
        void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
        self.onDelta = nil;
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
        self.onUsage = nil;
        self.onFinish = nil;
        if (finish) finish(GeminiStreamErrorCancelled, self.status, nil);
        return;
    }

    NSInteger maxRetries = self.useFastSpeed ? 8 : 12;
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
                ClaudeStream *me = weakSelf;
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
        NSString *type = nil, *message = nil;
        [self readErrorBody:self.errorBody type:&type message:&message];
        detail = (type.length && message.length)
            ? [NSString stringWithFormat:@"%@ | %@", type, message]
            : (message.length ? message : type);
        result = [ClaudeStream errorForStatus:self.status type:type message:message];
    } else if ((self.inStreamErrorType.length > 0 || self.inStreamErrorMessage.length > 0) && !self.gotText) {
        detail = self.inStreamErrorMessage;
        result = [ClaudeStream errorForStatus:0 type:self.inStreamErrorType message:self.inStreamErrorMessage];
    } else if (!self.gotText) {
        result = [self.stopReason isEqualToString:@"refusal"] ? GeminiStreamErrorBlocked : GeminiStreamErrorEmptyReply;
        detail = self.stopReason;
    } else if ([self.stopReason isEqualToString:@"max_tokens"] && self.onDelta) {
        self.onDelta([NSString stringWithFormat:@"\n\n%@", L(@"reply_truncated")]);
    }

    if (self.onUsage && (self.inputTokenUsage > 0 || self.outputTokenUsage > 0)) {
        self.onUsage(self.inputTokenUsage, self.outputTokenUsage);
    }
    void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
    NSInteger reportedStatus = self.status;
    if (reportedStatus == 200 && [self.inStreamErrorType isEqualToString:@"overloaded_error"]) reportedStatus = 529;
    else if (reportedStatus == 200 && [self.inStreamErrorType isEqualToString:@"rate_limit_error"]) reportedStatus = 429;
    else if (reportedStatus == 200 && [self.inStreamErrorType isEqualToString:@"not_found_error"]) reportedStatus = 404;
    else if (reportedStatus == 200 && [self.inStreamErrorType isEqualToString:@"authentication_error"]) reportedStatus = 401;
    else if (reportedStatus == 200 && [self.inStreamErrorType isEqualToString:@"permission_error"]) reportedStatus = 403;
    else if (reportedStatus == 200 && [self.inStreamErrorType isEqualToString:@"request_too_large"]) reportedStatus = 413;
    else if (reportedStatus == 200 && [self.inStreamErrorType isEqualToString:@"api_error"]) reportedStatus = 500;
    NSInteger status = reportedStatus;
    self.onDelta = nil;
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
    if (payload.length == 0) return;

    NSData *payloadData = [payload dataUsingEncoding:NSUTF8StringEncoding];
    if (!payloadData) return;
    id json = [NSJSONSerialization JSONObjectWithData:payloadData options:0 error:nil];
    if (![json isKindOfClass:[NSDictionary class]]) return;
    [self processEvent:json];
}

- (void)processEvent:(NSDictionary *)event {
    NSString *type = [event[@"type"] isKindOfClass:[NSString class]] ? event[@"type"] : @"";

    if ([type isEqualToString:@"message_start"]) {
        NSDictionary *message = [event[@"message"] isKindOfClass:[NSDictionary class]] ? event[@"message"] : nil;
        NSDictionary *usage = [message[@"usage"] isKindOfClass:[NSDictionary class]] ? message[@"usage"] : nil;
        long long input = [usage[@"input_tokens"] longLongValue]
                        + [usage[@"cache_creation_input_tokens"] longLongValue]
                        + [usage[@"cache_read_input_tokens"] longLongValue];
        self.inputTokenUsage = MAX(self.inputTokenUsage, input);
        self.outputTokenUsage = MAX(self.outputTokenUsage, [usage[@"output_tokens"] longLongValue]);
    } else if ([type isEqualToString:@"content_block_delta"]) {
        NSDictionary *delta = [event[@"delta"] isKindOfClass:[NSDictionary class]] ? event[@"delta"] : nil;
        NSString *text = [delta[@"text"] isKindOfClass:[NSString class]] ? delta[@"text"] : nil;
        if ([delta[@"type"] isEqualToString:@"text_delta"] && text.length > 0) {
            self.gotText = YES;
            if (self.onDelta) self.onDelta(text);
        }
    } else if ([type isEqualToString:@"message_delta"]) {
        NSDictionary *delta = [event[@"delta"] isKindOfClass:[NSDictionary class]] ? event[@"delta"] : nil;
        NSDictionary *usage = [event[@"usage"] isKindOfClass:[NSDictionary class]] ? event[@"usage"] : nil;
        if ([delta[@"stop_reason"] isKindOfClass:[NSString class]]) self.stopReason = delta[@"stop_reason"];
        self.outputTokenUsage = MAX(self.outputTokenUsage, [usage[@"output_tokens"] longLongValue]);
    } else if ([type isEqualToString:@"error"]) {
        NSDictionary *err = [event[@"error"] isKindOfClass:[NSDictionary class]] ? event[@"error"] : nil;
        self.inStreamErrorType = [err[@"type"] isKindOfClass:[NSString class]] ? err[@"type"] : @"api_error";
        if ([err[@"message"] isKindOfClass:[NSString class]]) self.inStreamErrorMessage = err[@"message"];
    }
}

- (void)processWholeBody {
    if (self.buffer.length == 0) return;
    id json = [NSJSONSerialization JSONObjectWithData:self.buffer options:0 error:nil];
    if (![json isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *root = json;
    NSDictionary *usage = [root[@"usage"] isKindOfClass:[NSDictionary class]] ? root[@"usage"] : nil;
    long long input = [usage[@"input_tokens"] longLongValue]
                    + [usage[@"cache_creation_input_tokens"] longLongValue]
                    + [usage[@"cache_read_input_tokens"] longLongValue];
    self.inputTokenUsage = MAX(self.inputTokenUsage, input);
    self.outputTokenUsage = MAX(self.outputTokenUsage, [usage[@"output_tokens"] longLongValue]);
    if ([root[@"stop_reason"] isKindOfClass:[NSString class]]) self.stopReason = root[@"stop_reason"];
    if ([root[@"type"] isEqualToString:@"error"]) { [self processEvent:root]; return; }

    NSMutableString *all = [NSMutableString string];
    NSArray *blocks = [root[@"content"] isKindOfClass:[NSArray class]] ? root[@"content"] : @[];
    for (id block in blocks) {
        if (![block isKindOfClass:[NSDictionary class]] || ![block[@"type"] isEqualToString:@"text"]) continue;
        if ([block[@"text"] isKindOfClass:[NSString class]]) [all appendString:block[@"text"]];
    }
    if (all.length > 0) {
        self.gotText = YES;
        if (self.onDelta) self.onDelta(all);
    }
}

#pragma mark - Errors

- (void)readErrorBody:(NSData *)body type:(NSString **)type message:(NSString **)message {
    if (body.length == 0) return;
    id json = [NSJSONSerialization JSONObjectWithData:body options:0 error:nil];
    if (![json isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *err = [json[@"error"] isKindOfClass:[NSDictionary class]] ? json[@"error"] : nil;
    if ([err[@"type"] isKindOfClass:[NSString class]]) *type = err[@"type"];
    if ([err[@"message"] isKindOfClass:[NSString class]]) *message = err[@"message"];
}

+ (GeminiStreamError)errorForStatus:(NSInteger)status type:(NSString *)type message:(NSString *)message {
    NSString *lower = [message lowercaseString];
    if (lower.length > 0 && [lower rangeOfString:@"credit balance"].location != NSNotFound) return GeminiStreamErrorNoCredit;

    if ([type isEqualToString:@"authentication_error"]) return GeminiStreamErrorInvalidKey;
    if ([type isEqualToString:@"permission_error"]) return GeminiStreamErrorPermissionDenied;
    if ([type isEqualToString:@"not_found_error"]) return GeminiStreamErrorModelNotFound;
    if ([type isEqualToString:@"rate_limit_error"]) return GeminiStreamErrorRateLimited;
    if ([type isEqualToString:@"request_too_large"]) return GeminiStreamErrorTooLarge;
    if ([type isEqualToString:@"overloaded_error"] || [type isEqualToString:@"api_error"]) return GeminiStreamErrorServer;

    if (status == 413) return GeminiStreamErrorTooLarge;
    if (status == 400) {
        if (lower.length > 0 && ([lower rangeOfString:@"too long"].location != NSNotFound ||
                                 [lower rangeOfString:@"too large"].location != NSNotFound ||
                                 [lower rangeOfString:@"exceeds"].location != NSNotFound)) {
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
