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
@property (strong, nonatomic) NSMutableData *errorBody;
@property (assign, nonatomic) NSInteger status;
@property (assign, nonatomic) BOOL cancelled;
@property (assign, nonatomic) BOOL finished;
@property (assign, nonatomic) BOOL gotText;
@property (assign, nonatomic) BOOL sawMessageStop;   // the provider's last event; without it a live stream was cut short
@property (copy, nonatomic) NSString *stopReason;
@property (copy, nonatomic) NSString *inStreamErrorType;
@property (copy, nonatomic) NSString *inStreamErrorMessage;
@property (assign, nonatomic) long long inputTokenUsage;
@property (assign, nonatomic) long long outputTokenUsage;

@property (assign, nonatomic) NSInteger sameKeyRetryCount;
// Watchdog: a live stream that goes quiet is cut and retried instead of leaving the chat waiting for minutes.
@property (strong, nonatomic) NSTimer *watchdog;
@property (assign, nonatomic) CFTimeInterval lastActivity;
@property (assign, nonatomic) BOOL gotResponse;
@property (assign, nonatomic) BOOL stallFired;
@property (assign, nonatomic) NSInteger stallRetryCount;
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
        _buffer = [NSMutableData data];
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
    if (modelCap <= 0) modelCap = [self.model hasPrefix:@"claude-3-"] ? 4096 : 8192;
    return requested > 0 ? MIN(requested, modelCap) : modelCap;
}

+ (NSArray *)messagesFromTurns:(NSArray *)turns {
    NSMutableArray *messages = [NSMutableArray array];
    for (NSDictionary *turn in turns) {
        NSMutableArray *blocks = [NSMutableArray array];
        for (NSDictionary *part in turn[@"parts"]) {
            NSString *type = part[@"type"];
            if ([type isEqualToString:@"text"] && [part[@"text"] length] > 0) {
                [blocks addObject:@{ @"type": @"text", @"text": part[@"text"] }];
            } else if ([type isEqualToString:@"image"] && [part[@"data"] length] > 0) {
                [blocks addObject:@{ @"type": @"image",
                                     @"source": @{ @"type": @"base64", @"media_type": part[@"mime"] ?: @"image/jpeg", @"data": part[@"data"] } }];
            } else if ([type isEqualToString:@"pdf"] && [part[@"data"] length] > 0) {
                [blocks addObject:@{ @"type": @"document",
                                     @"source": @{ @"type": @"base64", @"media_type": @"application/pdf", @"data": part[@"data"] } }];
            }
        }
        if (blocks.count == 0) continue;
        [messages addObject:@{ @"role": [turn[@"role"] isEqualToString:@"assistant"] ? @"assistant" : @"user", @"content": blocks }];
    }
    return messages;
}

// Seconds of silence tolerated before the connection counts as dead. Long replies, deep reasoning and web searches can stay
// quiet for a while, and a single (non-live) request sends nothing until the whole answer is ready.
+ (NSTimeInterval)idleTimeoutFast:(BOOL)fast streaming:(BOOL)streaming {
    if (!streaming) return fast ? 180 : 360;
    return fast ? 100 : 160;
}

#pragma mark - Control

- (void)start {
    self.sameKeyRetryCount = 0;
    self.stallRetryCount = 0;
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
        NSArray *efforts = @[@"low", @"medium", @"high", @"xhigh", @"max"];
        NSString *effort = efforts[(NSUInteger)level];
        if ([lowerModel containsString:@"-4-6"] && level == AIReasoningLevelVeryHigh) effort = @"high";
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
        budget = MIN(budget, MAX(0, maxTokens - 1024));
        if (budget >= 1024) payload[@"thinking"] = @{ @"type": @"enabled", @"budget_tokens": @(budget) };
    }

    if ([AppSettings webSearchEnabled]) {
        payload[@"tools"] = @[@{ @"type": @"web_search_20250305", @"name": @"web_search", @"max_uses": @3 }];
    }
    NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

    NSTimeInterval timeout = [ClaudeStream idleTimeoutFast:self.useFastSpeed streaming:self.useStreaming];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kClaudeMessagesURL]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:timeout];
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:self.useStreaming ? @"text/event-stream" : @"application/json" forHTTPHeaderField:@"Accept"];
    if (self.useStreaming) [request setValue:@"identity" forHTTPHeaderField:@"Accept-Encoding"];
    [request setValue:self.key forHTTPHeaderField:@"x-api-key"];
    [request setValue:kAnthropicVersion forHTTPHeaderField:@"anthropic-version"];
    if (self.useFastSpeed && supportsFast && needsFastBeta) {
        [request setValue:@"fast-mode-2026-02-01" forHTTPHeaderField:@"anthropic-beta"];
    }

    self.savedRequest = request;
    [self executeForcedRequest:request];
}

- (void)executeForcedRequest:(NSMutableURLRequest *)request {
    if (self.finished || self.cancelled || !request) return;

    if (self.session) {
        [self.session invalidateAndCancel];
        self.session = nil;
    }
    self.task = nil;

    [self.buffer setLength:0];
    [self.errorBody setLength:0];
    self.status = 0;
    self.gotText = NO;
    self.sawMessageStop = NO;
    self.inStreamErrorType = nil;
    self.inStreamErrorMessage = nil;
    self.stopReason = nil;
    self.inputTokenUsage = 0;
    self.outputTokenUsage = 0;

    NSTimeInterval timeout = [ClaudeStream idleTimeoutFast:self.useFastSpeed streaming:self.useStreaming];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    config.timeoutIntervalForRequest = timeout;
    config.timeoutIntervalForResource = 3600;
    self.session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    self.stallFired = NO;
    self.task = [self.session dataTaskWithRequest:request];
    [self.task resume];
    [self startWatchdog];
}

#pragma mark - Watchdog

- (NSTimeInterval)firstByteDeadline {
    NSString *m = self.model.lowercaseString ?: @"";
    return self.useFastSpeed ? 30 : 45;
}

- (NSTimeInterval)midStreamDeadline {
    NSString *m = self.model.lowercaseString ?: @"";
    return 60;   // pings keep a healthy stream busy; a web search can pause the text for a while
}

- (void)startWatchdog {
    [self.watchdog invalidate];
    self.watchdog = nil;
    self.gotResponse = NO;
    self.lastActivity = CACurrentMediaTime();
    if (!self.useStreaming) return;   // a single request is silent until the whole answer is ready
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
        ClaudeStream *me = weakSelf;
        if (!me || me.finished || me.cancelled) { [t invalidate]; return; }
        [me checkWatchdog];
    }];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    self.watchdog = timer;
}

- (void)stopWatchdog {
    [self.watchdog invalidate];
    self.watchdog = nil;
}

- (void)checkWatchdog {
    if (!self.task || self.stallFired) return;   // between retries, or already being cut
    NSTimeInterval limit = self.gotResponse ? [self midStreamDeadline] : [self firstByteDeadline];
    if (CACurrentMediaTime() - self.lastActivity < limit) return;
    self.stallFired = YES;
    [self.task cancel];   // didCompleteWithError follows and decides: silent retry, or finish with what arrived
}

- (void)dealloc {
    [self.watchdog invalidate];
}


- (void)cancel {
    if (self.finished) return;
    self.cancelled = YES;
    [self stopWatchdog];
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
    self.gotResponse = YES;
    self.lastActivity = CACurrentMediaTime();
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
    self.lastActivity = CACurrentMediaTime();
    if (self.status != 200) {
        [self.errorBody appendData:data];
        return;
    }
    [self.buffer appendData:data];
    if (self.useStreaming) [self drainBufferFinal:NO];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (self.finished) return;
    if (self.session && session != self.session) return;   // late callback of a session that was already replaced
    [self stopWatchdog];
    BOOL stallGaveUp = NO;
    if (self.stallFired && !self.cancelled) {
        self.stallFired = NO;
        if (!self.gotText && self.stallRetryCount < 2) {
            // Nothing useful arrived: start over on a fresh connection right away, without bothering the user.
            self.stallRetryCount++;
            [self.session invalidateAndCancel];
            self.session = nil;
            self.task = nil;
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                ClaudeStream *me = weakSelf;
                if (me && !me.finished && !me.cancelled) [me executeForcedRequest:me.savedRequest];
            });
            return;
        }
        stallGaveUp = YES;
        error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut
                                userInfo:@{ NSLocalizedDescriptionKey: @"The connection stopped responding" }];
    }

    if (self.useStreaming) {
        [self drainBufferFinal:YES];
    }

    BOOL isRateLimitOrOverload = (self.status == 429 || self.status == 529 ||
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
            self.onThought = nil;
            self.onUsage = nil;
            self.onFinish = nil;
            if (finish) finish(result, self.status, detail);
            return;
        }

        if (self.onUsage && (self.inputTokenUsage > 0 || self.outputTokenUsage > 0)) {
            self.onUsage(self.inputTokenUsage, self.outputTokenUsage);
        }
        void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
        self.onDelta = nil;
        self.onThought = nil;
        self.onUsage = nil;
        self.onFinish = nil;
        // A live stream that closed without the provider's final event was cut short (the connection was closed quietly):
        // the chat continues the reply instead of presenting half an answer as finished.
        BOOL cutShort = self.useStreaming && !self.sawMessageStop && self.stopReason.length == 0;
        // The reply stopped because of the length limit (or the provider paused a long turn): the chat asks for the rest.
        BOOL hitLimit = [self.stopReason isEqualToString:@"max_tokens"] || [self.stopReason isEqualToString:@"pause_turn"] ||
                        [self.stopReason isEqualToString:@"model_context_window_exceeded"];
        if (cutShort) {
            if (finish) finish(GeminiStreamErrorNetwork, self.status, kStreamEndedEarlyMarker);
        } else if (hitLimit) {
            if (finish) finish(GeminiStreamErrorNone, self.status, kStreamOutputLimitMarker);
        } else {
            if (finish) finish(GeminiStreamErrorNone, self.status, nil);
        }
        return;
    }

    if (self.cancelled) {
        self.finished = YES;
        [self.session invalidateAndCancel];
        self.session = nil;
        self.task = nil;
        void (^finish)(GeminiStreamError, NSInteger, NSString *) = self.onFinish;
        self.onDelta = nil;
        self.onThought = nil;
        self.onUsage = nil;
        self.onFinish = nil;
        if (finish) finish(GeminiStreamErrorCancelled, self.status, nil);
        return;
    }

    NSInteger maxRetries = self.useFastSpeed ? 6 : 10;
    double maxBackoff = self.useFastSpeed ? 6.0 : 10.0;
    if (!stallGaveUp && !self.gotText && (isRateLimitOrOverload || (error != nil && self.status == 0 && error.code != NSURLErrorCancelled))) {
        if (self.sameKeyRetryCount < maxRetries) {
            self.sameKeyRetryCount++;
            NSTimeInterval backoffDelay = MIN(pow(1.6, self.sameKeyRetryCount), maxBackoff);
            NSTimeInterval jitter = (double)(arc4random_uniform(500)) / 1000.0;
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

    if (error != nil) {
        // Also when text already arrived: the chat keeps the partial reply and continues it (a dropped connection must
        // never look like a finished answer).
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
    } else if ((self.inStreamErrorType.length > 0 || self.inStreamErrorMessage.length > 0) && self.gotText) {
        detail = self.inStreamErrorMessage ?: self.inStreamErrorType;   // overloaded / server error after part of the reply
        result = GeminiStreamErrorServer;
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
    self.onThought = nil;
    self.onUsage = nil;
    self.onFinish = nil;
    if (finish) finish(result, status, detail);
}

#pragma mark - SSE parsing

- (void)drainBufferFinal:(BOOL)final {
    NSData *newline = [NSData dataWithBytes:"\n" length:1];
    while (YES) {
        NSRange range = [self.buffer rangeOfData:newline options:0 range:NSMakeRange(0, self.buffer.length)];
        if (range.location == NSNotFound) break;
        NSData *lineData = [self.buffer subdataWithRange:NSMakeRange(0, range.location)];
        [self.buffer replaceBytesInRange:NSMakeRange(0, range.location + 1) withBytes:NULL length:0];
        [self processLineData:lineData];
    }
    if (final && self.buffer.length > 0) {
        [self processLineData:[self.buffer copy]];
        self.buffer.length = 0;
    }
}

- (void)processLineData:(NSData *)lineData {
    NSString *line = [[NSString alloc] initWithData:lineData encoding:NSUTF8StringEncoding];
    if (line == nil) return;
    line = [line stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\r"]];
    if (![line hasPrefix:@"data:"]) return;
    NSString *payload = [[line substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (payload.length == 0) return;

    id json = [NSJSONSerialization JSONObjectWithData:[payload dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
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
        NSString *thought = [delta[@"thinking"] isKindOfClass:[NSString class]] ? delta[@"thinking"] : nil;
        if ([delta[@"type"] isEqualToString:@"thinking_delta"] && thought.length > 0) {
            if (self.onThought) self.onThought(thought);   // the reasoning summary (the page shows it under "Thinking")
        }
    } else if ([type isEqualToString:@"message_stop"]) {
        self.sawMessageStop = YES;
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
        if ([block isKindOfClass:[NSDictionary class]] && [block[@"type"] isEqualToString:@"thinking"] &&
            [block[@"thinking"] isKindOfClass:[NSString class]] && [block[@"thinking"] length] > 0 && self.onThought) {
            self.onThought(block[@"thinking"]);
        }
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
