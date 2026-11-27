#import <Foundation/Foundation.h>
#import "ChatStreaming.h"

NS_ASSUME_NONNULL_BEGIN

// Google Gemini: streamGenerateContent (SSE) or generateContent.
@interface GeminiStream : NSObject <ChatStreaming>

- (instancetype)initWithKey:(NSString *)key model:(NSString *)model turns:(NSArray *)turns system:(nullable NSString *)system;

@property (assign, nonatomic) BOOL useStreaming;
@property (assign, nonatomic) BOOL useFastSpeed;
@property (assign, nonatomic) BOOL skipSearchTool;      // 403 recovery: send the request without the Google Search tool
@property (assign, nonatomic) BOOL skipUserProject;     // 403 recovery: send it without the x-goog-user-project header
@property (assign, nonatomic) NSTimeInterval retryAfterSeconds;
@property (copy, nonatomic, nullable) void (^onDelta)(NSString *text);
@property (copy, nonatomic, nullable) void (^onThought)(NSString *text);
@property (copy, nonatomic, nullable) void (^onImage)(NSData *data, NSString *mimeType);
@property (copy, nonatomic, nullable) void (^onUsage)(long long inputTokens, long long outputTokens);
@property (copy, nonatomic, nullable) void (^onFinish)(GeminiStreamError error, NSInteger httpStatus, NSString * _Nullable detail);

- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
