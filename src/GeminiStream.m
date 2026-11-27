#include <string.h>
#import "GeminiStream.h"
#import "AppSettings.h"
#import "ModelStore.h"
#import "Provider.h"
#import "GoogleAuth.h"

@interface GeminiStream () <NSURLSessionDataDelegate>
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
@property (copy, nonatomic) NSString *lastFinishReason;   // set by the final chunk; without it a live stream was cut short
@property (copy, nonatomic) NSString *blockReason;
@property (assign, nonatomic) NSInteger inStreamErrorStatus;
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

@implementation GeminiStream
@synthesize retryAfterSeconds = _retryAfterSeconds;

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
        _useFastSpeed = NO;
        _sameKeyRetryCount = 0;
    }
    return self;
}

#pragma mark - Request format

+ (NSArray *)contentsFromTurns:(NSArray *)turns {
    NSMutableArray *contents = [NSMutableArray array];
    for (NSDictionary *turn in turns) {
        NSMutableArray *parts = [NSMutableArray array];
        for (NSDictionary *part in turn[@"parts"]) {
            NSString *type = part[@"type"];
            if ([type isEqualToString:@"text"] && [part[@"text"] length] > 0) {
                [parts addObject:@{ @"text": part[@"text"] }];
            } else if ([type isEqualToString:@"image"] && [part[@"data"] length] > 0) {
                [parts addObject:@{ @"inline_data": @{ @"mime_type": part[@"mime"] ?: @"image/jpeg", @"data": part[@"data"] } }];
            } else if ([type isEqualToString:@"pdf"] && [part[@"data"] length] > 0) {
                [parts addObject:@{ @"inline_data": @{ @"mime_type": @"application/pdf", @"data": part[@"data"] } }];
            }
        }
        if (parts.count == 0) continue;
        [contents addObject:@{ @"role": [turn[@"role"] isEqualToString:@"assistant"] ? @"model" : @"user", @"parts": parts }];
    }
    return contents;
}

// Seconds of silence tolerated before the connection counts as dead. Reasoning models can stay quiet for a long time, and a
// single (non-live) request sends nothing until the whole answer is ready.
+ (NSTimeInterval)idleTimeoutFast:(BOOL)fast streaming:(BOOL)streaming {
    if (!streaming) return fast ? 180 : 360;
    return fast ? 100 : 160;
}

#pragma mark - Control

- (void)start {
    self.sameKeyRetryCount = 0;
    self.stallRetryCount = 0;
    NSString *escapedModel = [self.model stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *method = self.useStreaming ? @"streamGenerateContent?alt=sse" : @"generateContent";
    NSString *urlString = [NSString stringWithFormat:
        @"https://generativelanguage.googleapis.com/v1beta/models/%@:%@", escapedModel, method];

    NSInteger requestedOutputTokens = [AppSettings maxOutputTokens];
    NSInteger modelCap = [ModelStore maxOutputTokensForModelId:self.model provider:AIProviderGemini];
    if (modelCap <= 0) modelCap = 8192;
    NSInteger outputCeiling = requestedOutputTokens > 0 ? MIN(requestedOutputTokens, modelCap) : modelCap;
    NSString *lowerModel = self.model.lowercaseString;
    AIReasoningLevel reasoning = [AppSettings reasoningLevel];

    NSMutableDictionary *generationConfig = [NSMutableDictionary dictionary];
    BOOL supportsThinking = [lowerModel containsString:@"gemini-2.5"] ||
                            [lowerModel containsString:@"gemini-3"] ||
                            [lowerModel containsString:@"gemini-4"];
    NSInteger answerReserve = supportsThinking
        ? MIN(outputCeiling, MAX(1024, (outputCeiling * 2) / 3))
        : outputCeiling;
    NSInteger availableThinking = supportsThinking ? MAX(0, outputCeiling - answerReserve) : 0;

    if ([lowerModel containsString:@"gemini-4"]) {
        NSArray *levels = self.useFastSpeed
            ? @[@"minimal", @"low", @"low", @"medium", @"high"]
            : @[@"low", @"low", @"medium", @"high", @"high"];
        generationConfig[@"thinkingConfig"] = @{ @"thinkingLevel": levels[(NSUInteger)reasoning], @"includeThoughts": @YES };
    } else if ([lowerModel containsString:@"gemini-3"]) {
        NSArray *levels = [lowerModel containsString:@"pro"]
            ? (self.useFastSpeed ? @[@"low", @"low", @"low", @"medium", @"high"] : @[@"low", @"low", @"medium", @"high", @"high"])
            : (self.useFastSpeed ? @[@"minimal", @"minimal", @"low", @"medium", @"high"] : @[@"minimal", @"low", @"medium", @"high", @"high"]);
        generationConfig[@"thinkingConfig"] = @{ @"thinkingLevel": levels[(NSUInteger)reasoning], @"includeThoughts": @YES };
    } else if ([lowerModel containsString:@"gemini-2.5"]) {
        BOOL proModel = [lowerModel containsString:@"pro"];
        NSArray *budgets = proModel
            ? @[@128, @1024, @8192, @24576, @32768]
            : @[@0, @1024, @4096, @16384, @24576];
        NSInteger desiredBudget = [budgets[(NSUInteger)reasoning] integerValue];
        if (self.useFastSpeed) {
            desiredBudget = desiredBudget / 2;
        }
        NSInteger thinkingBudget = MIN(desiredBudget, availableThinking);
        if (proModel && thinkingBudget > 0 && thinkingBudget < 128) thinkingBudget = 0;
        if (!proModel || thinkingBudget >= 128) {
            generationConfig[@"thinkingConfig"] = @{ @"thinkingBudget": @(thinkingBudget), @"includeThoughts": @YES };
        }
    }

    generationConfig[@"maxOutputTokens"] = @(MAX(1, outputCeiling));
    if (self.useFastSpeed) {
        generationConfig[@"temperature"] = @0.4;
    }

    if ([lowerModel containsString:@"image"] || [lowerModel containsString:@"nano-banana"]) {
        generationConfig[@"responseModalities"] = @[@"TEXT", @"IMAGE"];
    }
    BOOL imageGenerationModel = [lowerModel containsString:@"image"] || [lowerModel containsString:@"nano-banana"];
    NSMutableDictionary *payload = [@{ @"contents": [GeminiStream contentsFromTurns:self.turns],
                                       @"generationConfig": generationConfig } mutableCopy];
    if (self.system.length > 0) payload[@"systemInstruction"] = @{ @"parts": @[ @{ @"text": self.system } ] };
    if ([AppSettings webSearchEnabled] && !imageGenerationModel && !self.skipSearchTool) payload[@"tools"] = @[@{ @"google_search": @{} }];
    NSData *body = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];

    NSTimeInterval timeout = [GeminiStream idleTimeoutFast:self.useFastSpeed streaming:self.useStreaming];
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
    [request setValue:self.key forHTTPHeaderField:@"x-goog-api-key"];

    self.savedRequest = request;
    [self executeForcedRequest:request];
}

- (void)executeForcedRequest:(NSMutableURLRequest *)request {
    if (self.finished || self.cancelled || !request) return;
    __weak typeof(self) weakSelf = self;
    [GoogleAuth authorizeRequest:request key:self.key completion:^(NSError *authError) {
        GeminiStream *strongSelf = weakSelf;
        if (!strongSelf || strongSelf.finished || strongSelf.cancelled) return;
        if (strongSelf.skipUserProject) [request setValue:nil forHTTPHeaderField:@"x-goog-user-project"];
        if (authError != nil) {
            strongSelf.finished = YES;
            [strongSelf stopWatchdog];
            [strongSelf.session invalidateAndCancel];
            strongSelf.session = nil;
            strongSelf.task = nil;
            BOOL signInNeeded = [authError.domain isEqualToString:GoogleAuthErrorDomain] &&
                                authError.code == GoogleAuthErrorSignInRequired;
            void (^finish)(GeminiStreamError, NSInteger, NSString *) = strongSelf.onFinish;
            NSString *detail = [GoogleAuth messageForError:authError];
            strongSelf.onDelta = nil;
            strongSelf.onImage = nil;
            strongSelf.onUsage = nil;
            strongSelf.onFinish = nil;
            if (finish) finish(signInNeeded ? GeminiStreamErrorInvalidKey : GeminiStreamErrorNetwork,
                               signInNeeded ? 401 : 0, detail);
            return;
        }
        [strongSelf executeAuthorizedRequest:request];
    }];
}

- (void)executeAuthorizedRequest:(NSMutableURLRequest *)request {
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
    self.lastFinishReason = nil;
    self.inStreamErrorStatus = 0;
    self.inStreamErrorMessage = nil;
    self.blockReason = nil;
    self.inputTokenUsage = 0;
    self.outputTokenUsage = 0;

    NSTimeInterval timeout = [GeminiStream idleTimeoutFast:self.useFastSpeed streaming:self.useStreaming];
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
    if (self.useFastSpeed) return 45;
    if ([m containsString:@"pro"]) return 120;
    return 60;
}

- (NSTimeInterval)midStreamDeadline {
    NSString *m = self.model.lowercaseString ?: @"";
    if ([m containsString:@"pro"]) return 150;
    return 90;
}

- (void)startWatchdog {
    [self.watchdog invalidate];
    self.watchdog = nil;
    self.gotResponse = NO;
    self.lastActivity = CACurrentMediaTime();
    if (!self.useStreaming) return;   // a single request is silent until the whole answer is ready
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer timerWithTimeInterval:1.0 repeats:YES block:^(NSTimer *t) {
        GeminiStream *me = weakSelf;
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
                GeminiStream *me = weakSelf;
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
            self.onThought = nil;
            self.onImage = nil;
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
        self.onImage = nil;
        self.onUsage = nil;
        self.onFinish = nil;
        // A live stream that closed without a final chunk (finishReason) was cut short: the chat continues the reply.
        BOOL cutShort = self.useStreaming && self.lastFinishReason.length == 0;
        // The length limit stopped the reply: the chat asks for the rest.
        BOOL hitLimit = [self.lastFinishReason isEqualToString:@"MAX_TOKENS"];
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
        self.onImage = nil;
        self.onUsage = nil;
        self.onFinish = nil;
        if (finish) finish(GeminiStreamErrorCancelled, self.status, nil);
        return;
    }

    // Chỉ retry tự động khi chưa nhận được chữ (`!self.gotText`) để tránh lặp lại đoạn đã stream
    NSInteger maxRetries = self.useFastSpeed ? 8 : 12;
    double maxBackoff = self.useFastSpeed ? 6.0 : 12.0;
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

    if (error != nil) {
        // Also when text already arrived: the chat keeps the partial reply and continues it.
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
    } else if (self.inStreamErrorStatus != 0 && self.gotText) {
        detail = self.inStreamErrorMessage;   // error after part of the reply: the chat keeps it and continues
        result = GeminiStreamErrorServer;
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
    self.onThought = nil;
    self.onImage = nil;
    self.onUsage = nil;
    self.onFinish = nil;
    if (finish) finish(result, status, detail);
}

#pragma mark - SSE parsing

- (void)drainBufferFinal:(BOOL)final {
    // Walks the buffer once with memchr and drops the consumed part at the end (taking a line off the front of the buffer
    // for every line made a burst of events cost time proportional to its size squared).
    NSUInteger start = 0;
    while (!self.finished) {
        NSUInteger length = self.buffer.length;
        if (start >= length) break;
        const uint8_t *bytes = self.buffer.bytes;
        const uint8_t *newline = memchr(bytes + start, '\n', length - start);
        if (!newline) break;
        NSUInteger end = (NSUInteger)(newline - bytes);
        NSData *lineData = [NSData dataWithBytes:bytes + start length:end - start];
        start = end + 1;
        [self processLineData:lineData];
    }
    if (start > 0 && start <= self.buffer.length) [self.buffer replaceBytesInRange:NSMakeRange(0, start) withBytes:NULL length:0];
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
    if (payload.length == 0 || [payload isEqualToString:@"[DONE]"]) return;

    id json = [NSJSONSerialization JSONObjectWithData:[payload dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
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
        } else if (isThought && [text isKindOfClass:[NSString class]] && text.length > 0) {
            if (self.onThought) self.onThought(text);   // the reasoning summary (the page shows it under "Thinking")
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
    if (finishReason.length > 0) self.lastFinishReason = finishReason;
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
