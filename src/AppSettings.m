#import "AppSettings.h"
#import <limits.h>

const NSUInteger kMaxSystemPromptChars = 1000000;
static NSString *const kSystemPromptKey = @"systemPrompt";
static NSString *const kAttachmentMemoryKey = @"attachmentMemory";
static NSString *const kMaxOutputTokensKey = @"maxOutputTokens";
static NSString *const kContextLimitCharsKey = @"contextLimitChars";
static NSString *const kReasoningLevelKey = @"reasoningLevel";
static NSString *const kFastModeKey = @"fastMode";
static NSString *const kWebSearchKey = @"webSearchEnabled";
static NSString *const kDailyUsageKey = @"dailyTokenUsage";
static NSString *const kDailyDateKey = @"dailyTokenUsageDate";
static NSString *const kDailyBudgetKey = @"dailyTokenBudget";
static NSString *const kUiScaleKey = @"uiScale";
static NSString *const kFontStyleKey = @"fontStyle";
static NSString *const kFontWeightKey = @"fontWeightStep";
static NSString *const kVoiceAutoPlayKey = @"voiceAutoPlay";
static NSString *const kAutoUpdateKey = @"autoUpdateCheck";
static NSString *const kLayoutModeKey = @"layoutMode";
static NSString *const kDuoSidebarSizeKey = @"duoSidebarSize";
static NSString *const kDuoSidebarCollapsedKey = @"duoSidebarCollapsed";

static NSString *gPromptTextCache = nil;
static BOOL gPromptTextCacheLoaded = NO;
static NSString *gPromptChunkSource = nil;
static NSArray<NSDictionary *> *gPromptChunkCache = nil;

static NSString *PromptFilePath(void) {
    static NSString *path = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *base = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        NSString *directory = [base stringByAppendingPathComponent:@"ClaudeMini"];
        [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
        path = [directory stringByAppendingPathComponent:@"system-instructions.txt"];
    });
    return path;
}

static NSString *TodayKey(void) {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd";
    });
    @synchronized (formatter) {
        formatter.timeZone = [NSTimeZone localTimeZone];
        return [formatter stringFromDate:[NSDate date]];
    }
}

static NSArray<NSDictionary *> *PromptChunkRecords(NSString *prompt) {
    @synchronized ([AppSettings class]) {
        if (gPromptChunkCache && gPromptChunkSource == prompt) return gPromptChunkCache;
    }

    NSMutableArray<NSDictionary *> *records = [NSMutableArray array];
    NSArray<NSString *> *paragraphs = [prompt componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableString *current = [NSMutableString string];
    const NSUInteger maxChunk = 4096;
    void (^appendChunk)(NSString *) = ^(NSString *piece) {
        if (piece.length == 0) return;
        NSString *copy = [piece copy];
        [records addObject:@{@"text": copy, @"lower": copy.lowercaseString, @"length": @(copy.length)}];
    };

    for (NSString *line in paragraphs) {
        NSString *piece = line ?: @"";
        if (current.length > 0 && current.length + piece.length + 1 > maxChunk) {
            appendChunk(current);
            [current setString:@""];
        }
        while (piece.length > maxChunk) {
            NSRange safe = [piece rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, maxChunk)];
            appendChunk([piece substringWithRange:safe]);
            piece = [piece substringFromIndex:NSMaxRange(safe)];
        }
        if (piece.length > 0) {
            if (current.length > 0) [current appendString:@"\n"];
            [current appendString:piece];
        }
    }
    appendChunk(current);

    NSArray *result = [records copy];
    @synchronized ([AppSettings class]) {
        gPromptChunkSource = prompt;
        gPromptChunkCache = result;
    }
    return result;
}

@implementation AppSettings

+ (NSString *)cleanedPrompt:(NSString *)text {
    NSString *trimmed = [(text ?: @"") stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > kMaxSystemPromptChars) {
        NSRange safe = [trimmed rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, kMaxSystemPromptChars)];
        trimmed = [trimmed substringWithRange:safe];
    }
    return trimmed;
}

+ (NSString *)systemPrompt {
    @synchronized ([AppSettings class]) {
        if (gPromptTextCacheLoaded) return gPromptTextCache ?: @"";
        NSString *path = PromptFilePath();
        NSString *fromFile = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
        if (fromFile.length > 0) {
            gPromptTextCache = [[self cleanedPrompt:fromFile] copy];
        } else {
            NSString *legacy = [[NSUserDefaults standardUserDefaults] stringForKey:kSystemPromptKey];
            if (legacy.length > 0) {
                gPromptTextCache = [[self cleanedPrompt:legacy] copy];
                [gPromptTextCache writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSystemPromptKey];
            } else {
                gPromptTextCache = @"";
            }
        }
        gPromptTextCacheLoaded = YES;
        return gPromptTextCache ?: @"";
    }
}

+ (void)setSystemPrompt:(NSString *)prompt {
    NSString *cleaned = [self cleanedPrompt:prompt];
    @synchronized ([AppSettings class]) {
        gPromptTextCache = [cleaned copy];
        gPromptTextCacheLoaded = YES;
        gPromptChunkSource = nil;
        gPromptChunkCache = nil;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (cleaned.length == 0) {
        [[NSFileManager defaultManager] removeItemAtPath:PromptFilePath() error:nil];
        [defaults removeObjectForKey:kSystemPromptKey];
    } else {
        NSError *error = nil;
        BOOL saved = [cleaned writeToFile:PromptFilePath() atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (saved) [defaults removeObjectForKey:kSystemPromptKey];
        else [defaults setObject:cleaned forKey:kSystemPromptKey];
    }
    [defaults synchronize];
}

+ (NSString *)systemPromptForQuery:(NSString *)query characterBudget:(NSUInteger)budget {
    NSString *base = [self promptText:[self systemPrompt] forQuery:query characterBudget:budget];
    NSString *suffix = @"\n\n---\nQUY TẮC BẮT BUỘC: Bạn CÓ thể tạo ảnh và tạo file. Khi người dùng yêu cầu tạo ảnh, hãy trả về ảnh bằng Markdown ![](url) (dùng URL ảnh placeholder hợp lệ hoặc mô tả hình ảnh chi tiết bằng văn bản). Khi yêu cầu tạo file, hãy trả về toàn bộ nội dung file trong khối code (```) kèm tên file. TUYỆT ĐỐI KHÔNG được trả lời \"tôi không thể tạo ảnh/file\" hay bất kỳ lời từ chối tương tự nào. Luôn tạo ra nội dung cụ thể, hữu ích.";
    return [base stringByAppendingString:suffix];
}

+ (NSString *)promptText:(NSString *)prompt forQuery:(NSString *)query characterBudget:(NSUInteger)budget {
    prompt = [prompt isKindOfClass:[NSString class]] ? prompt : @"";
    if (prompt.length > kMaxSystemPromptChars) prompt = [self cleanedPrompt:prompt];
    if (prompt.length == 0 || budget == 0) return @"";
    if (prompt.length <= budget) return prompt;

    NSArray<NSDictionary *> *chunks = PromptChunkRecords(prompt);
    if (chunks.count == 0) return @"";
    NSMutableArray<NSString *> *terms = [NSMutableArray array];
    NSCharacterSet *separators = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    static NSSet<NSString *> *stopWords;
    static dispatch_once_t stopWordsOnce;
    dispatch_once(&stopWordsOnce, ^{
        stopWords = [NSSet setWithArray:@[@"the", @"and", @"for", @"with", @"that", @"this", @"from", @"you", @"your", @"cua", @"cho", @"voi", @"mot", @"nhung", @"cac", @"hay", @"la", @"va", @"duoc", @"giup"]];
    });
    for (NSString *term in [[query lowercaseString] componentsSeparatedByCharactersInSet:separators]) {
        if (term.length >= 3 && ![stopWords containsObject:term] && ![terms containsObject:term]) [terms addObject:term];
        if (terms.count >= 32) break;
    }

    NSMutableIndexSet *selected = [NSMutableIndexSet indexSet];
    NSMutableArray<NSDictionary *> *ranked = [NSMutableArray array];
    NSUInteger used = 0;

    [selected addIndex:0];
    used = [chunks[0][@"length"] unsignedIntegerValue];
    if (chunks.count > 1) {
        NSUInteger lastLength = [chunks.lastObject[@"length"] unsignedIntegerValue];
        if (lastLength + used + 96 <= budget) {
            [selected addIndex:chunks.count - 1];
            used += lastLength + 2;
        }
    }

    for (NSUInteger i = 0; i < chunks.count; i++) {
        if ([selected containsIndex:i]) continue;
        NSString *lower = chunks[i][@"lower"];
        NSUInteger score = 0;
        for (NSString *term in terms) {
            if ([lower rangeOfString:term].location != NSNotFound) score += term.length >= 6 ? 3 : 1;
        }
        if (score > 0) [ranked addObject:@{@"index": @(i), @"score": @(score), @"length": chunks[i][@"length"]}];
    }
    [ranked sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSInteger sa = [a[@"score"] integerValue], sb = [b[@"score"] integerValue];
        if (sa != sb) return sa > sb ? NSOrderedAscending : NSOrderedDescending;
        return [a[@"index"] compare:b[@"index"]];
    }];

    for (NSDictionary *item in ranked) {
        NSUInteger index = [item[@"index"] unsignedIntegerValue];
        NSUInteger length = [item[@"length"] unsignedIntegerValue] + 2;
        if (used + length > budget) continue;
        [selected addIndex:index];
        used += length;
    }

    for (NSInteger i = (NSInteger)chunks.count - 2; i >= 1; i--) {
        if ([selected containsIndex:(NSUInteger)i]) continue;
        NSUInteger length = [chunks[(NSUInteger)i][@"length"] unsignedIntegerValue] + 2;
        if (used + length > budget) continue;
        [selected addIndex:(NSUInteger)i];
        used += length;
    }

    NSMutableString *result = [NSMutableString string];
    [selected enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        NSString *chunkText = chunks[idx][@"text"];
        if (result.length + chunkText.length + 2 > budget) return;
        [result appendString:chunkText];
        [result appendString:@"\n\n"];
    }];
    if (result.length > budget) {
        NSRange safe = [result rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, budget)];
        result = [[result substringWithRange:safe] mutableCopy];
    }
    return result;
}

+ (NSInteger)attachmentMemory {
    NSNumber *value = [[NSUserDefaults standardUserDefaults] objectForKey:kAttachmentMemoryKey];
    if (![value isKindOfClass:[NSNumber class]]) return 3;
    NSInteger count = value.integerValue;
    return (count == 0 || count == 1 || count == 3) ? count : 3;
}
+ (void)setAttachmentMemory:(NSInteger)count {
    if (count != 0 && count != 1 && count != 3) count = 3;
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kAttachmentMemoryKey];
}
+ (NSInteger)maxOutputTokens {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kMaxOutputTokensKey];
    return value == 0 ? 0 : ((value == 2048 || value == 4096 || value == 8192 || value == 16384 || value == 32768 || value == 65536 || value == 128000) ? value : 0);
}
+ (void)setMaxOutputTokens:(NSInteger)count {
    if (count != 0 && count != 2048 && count != 4096 && count != 8192 && count != 16384 && count != 32768 && count != 65536 && count != 128000) count = 0;
    [[NSUserDefaults standardUserDefaults] setInteger:count forKey:kMaxOutputTokensKey];
}
+ (NSUInteger)contextLimitChars {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kContextLimitCharsKey];
    switch (value) {
        case 1000000: case 5000000: case 10000000: case 25000000: case 50000000: case 100000000:
            return (NSUInteger)value;
        default: return 10000000;
    }
}
+ (void)setContextLimitChars:(NSUInteger)count {
    switch (count) {
        case 1000000: case 5000000: case 10000000: case 25000000: case 50000000: case 100000000: break;
        default: count = 10000000; break;
    }
    [[NSUserDefaults standardUserDefaults] setInteger:(NSInteger)count forKey:kContextLimitCharsKey];
}

+ (AIReasoningLevel)reasoningLevel {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kReasoningLevelKey];
    return (value >= AIReasoningLevelLow && value <= AIReasoningLevelMax) ? (AIReasoningLevel)value : AIReasoningLevelHigh;
}
+ (void)setReasoningLevel:(AIReasoningLevel)level {
    if (level < AIReasoningLevelLow || level > AIReasoningLevelMax) level = AIReasoningLevelHigh;
    [[NSUserDefaults standardUserDefaults] setInteger:level forKey:kReasoningLevelKey];
}
+ (BOOL)fastModeEnabled { return [[NSUserDefaults standardUserDefaults] boolForKey:kFastModeKey]; }
+ (void)setFastModeEnabled:(BOOL)enabled { [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kFastModeKey]; }
+ (BOOL)webSearchEnabled { return [[NSUserDefaults standardUserDefaults] boolForKey:kWebSearchKey]; }
+ (void)setWebSearchEnabled:(BOOL)enabled { [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kWebSearchKey]; }

+ (CGFloat)uiScale {
    double v = [[NSUserDefaults standardUserDefaults] doubleForKey:kUiScaleKey];
    if (v < 0.7 || v > 1.4) v = 1.0;
    return (CGFloat)v;
}
+ (void)setUiScale:(CGFloat)scale {
    if (scale < 0.7) scale = 0.7;
    if (scale > 1.4) scale = 1.4;
    [[NSUserDefaults standardUserDefaults] setDouble:(double)scale forKey:kUiScaleKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIScaleDidChangeNotification" object:nil userInfo:@{@"uiScale": @(scale)}];
}

+ (BOOL)autoUpdateCheckEnabled {
    id v = [[NSUserDefaults standardUserDefaults] objectForKey:kAutoUpdateKey];
    return v ? [v boolValue] : YES;
}
+ (void)setAutoUpdateCheckEnabled:(BOOL)enabled { [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kAutoUpdateKey]; }

+ (NSInteger)layoutMode {
    NSInteger mode = [[NSUserDefaults standardUserDefaults] integerForKey:kLayoutModeKey];
    return (mode >= 0 && mode <= 2) ? mode : 0;
}
+ (void)setLayoutMode:(NSInteger)mode {
    [[NSUserDefaults standardUserDefaults] setInteger:(mode >= 0 && mode <= 2) ? mode : 0 forKey:kLayoutModeKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ClaudeMiniLayoutChanged" object:nil];
}

+ (NSInteger)duoSidebarSize {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:kDuoSidebarSizeKey];
    NSInteger size = value ? [value integerValue] : 1;
    return (size >= 0 && size <= 2) ? size : 1;
}
+ (void)setDuoSidebarSize:(NSInteger)size {
    [[NSUserDefaults standardUserDefaults] setInteger:(size >= 0 && size <= 2) ? size : 1 forKey:kDuoSidebarSizeKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ClaudeMiniLayoutChanged" object:nil];
}
+ (CGFloat)duoSidebarBaseWidth {
    switch ([self duoSidebarSize]) {
        case 0: return 260;
        case 2: return 380;
        default: return 320;
    }
}

+ (BOOL)duoSidebarCollapsed { return [[NSUserDefaults standardUserDefaults] boolForKey:kDuoSidebarCollapsedKey]; }
+ (void)setDuoSidebarCollapsed:(BOOL)collapsed { [[NSUserDefaults standardUserDefaults] setBool:collapsed forKey:kDuoSidebarCollapsedKey]; }

+ (BOOL)duoActiveForSize:(CGSize)size {
    switch ([self layoutMode]) {
        case 1: return NO;
        case 2: return size.width >= 520 && size.width > size.height;   // iPhone Duo: any landscape screen
        default: return size.width >= 700 && size.height >= 500;         // automatic: only a really wide screen (tablet, Duo)
    }
}

// Phone mode keeps the app upright; the other modes also allow landscape (never upside down).
+ (UIInterfaceOrientationMask)allowedOrientations {
    return [self layoutMode] == 1 ? UIInterfaceOrientationMaskPortrait : UIInterfaceOrientationMaskAllButUpsideDown;
}

+ (NSInteger)fontStyle {
    NSInteger style = [[NSUserDefaults standardUserDefaults] integerForKey:kFontStyleKey];
    return (style == 1 || style == 2) ? style : 0;
}
+ (void)setFontStyle:(NSInteger)style {
    NSInteger norm = (style == 1 || style == 2) ? style : 0;
    [[NSUserDefaults standardUserDefaults] setInteger:norm forKey:kFontStyleKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIScaleDidChangeNotification" object:nil userInfo:@{@"fontStyle": @(norm)}];
}
+ (NSInteger)fontWeightStep {
    NSInteger step = [[NSUserDefaults standardUserDefaults] integerForKey:kFontWeightKey];
    return MAX(-3, MIN(3, step));
}
+ (void)setFontWeightStep:(NSInteger)step {
    NSInteger norm = MAX(-3, MIN(3, step));
    [[NSUserDefaults standardUserDefaults] setInteger:norm forKey:kFontWeightKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIScaleDidChangeNotification" object:nil userInfo:@{@"fontWeight": @(norm)}];
}

+ (BOOL)voiceAutoPlayEnabled { id v = [[NSUserDefaults standardUserDefaults] objectForKey:kVoiceAutoPlayKey]; return v ? [v boolValue] : YES; }
+ (void)setVoiceAutoPlayEnabled:(BOOL)enabled { [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:kVoiceAutoPlayKey]; }

+ (long long)dailyTokenUsage {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *today = TodayKey();

    if (![[defaults stringForKey:kDailyDateKey] isEqualToString:today]) {
        [defaults setObject:today forKey:kDailyDateKey];
        [defaults setObject:@0 forKey:kDailyUsageKey];
        return 0;
    }

    id usageObject = [defaults objectForKey:kDailyUsageKey];
    return usageObject ? [usageObject longLongValue] : 0;
}

+ (void)addDailyTokenUsage:(long long)count {
    if (count <= 0) return;

    long long current = [self dailyTokenUsage];

    if (LLONG_MAX - current < count)
        current = LLONG_MAX;
    else
        current += count;

    [[NSUserDefaults standardUserDefaults] setObject:@(current) forKey:kDailyUsageKey];
}

+ (long long)dailyTokenBudget {
    id budgetObject = [[NSUserDefaults standardUserDefaults] objectForKey:kDailyBudgetKey];
    long long value = [budgetObject longLongValue];

    return value > 0 ? value : 24000000000LL;
}

+ (void)setDailyTokenBudget:(long long)count {
    if (count < 1) count = 24000000000LL;

    [[NSUserDefaults standardUserDefaults] setObject:@(count) forKey:kDailyBudgetKey];
}

@end
