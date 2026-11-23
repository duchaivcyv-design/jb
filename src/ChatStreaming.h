#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, GeminiStreamError) {   // (name kept from the first version; it now covers every provider)
    GeminiStreamErrorNone = 0,
    GeminiStreamErrorCancelled,
    GeminiStreamErrorInvalidKey,
    GeminiStreamErrorPermissionDenied,
    GeminiStreamErrorModelNotFound,
    GeminiStreamErrorRateLimited,
    GeminiStreamErrorNetwork,
    GeminiStreamErrorBlocked,
    GeminiStreamErrorServer,
    GeminiStreamErrorEmptyReply,
    GeminiStreamErrorTooLarge,
    GeminiStreamErrorNoCredit,      // Claude: the account has no credit left
    GeminiStreamErrorUnknown
};

// Markers a stream puts in `detail` for the chat to act on (the chat continues the reply by itself).
static NSString *const kStreamOutputLimitMarker = @"__OUTPUT_LIMIT_REACHED__";   // the length limit cut the reply (error None)
static NSString *const kStreamEndedEarlyMarker  = @"__STREAM_ENDED_EARLY__";     // the stream closed without its final event (error Network)

// One request to a chat model (live stream, or a single request as a fallback). All callbacks run on the main queue.
//
// The conversation is passed as provider-neutral "turns", each converted to the provider's JSON by the stream itself:
//   @{ @"role": @"user" | @"assistant",
//      @"parts": @[ @{ @"type": @"text",  @"text": ... },
//                   @{ @"type": @"image", @"mime": @"image/jpeg", @"data": <base64> },
//                   @{ @"type": @"pdf",   @"data": <base64> } ] }
@protocol ChatStreaming <NSObject>

// YES (default): live stream (Server-Sent Events). NO: one normal request/response, delivered as a single delta.
@property (assign, nonatomic) BOOL useStreaming;
@property (assign, nonatomic) NSTimeInterval retryAfterSeconds; // HTTP Retry-After, when supplied by the provider

@property (copy, nonatomic) void (^onDelta)(NSString *text);
@property (copy, nonatomic) void (^onImage)(NSData *data, NSString *mimeType);
@property (copy, nonatomic) void (^onUsage)(long long inputTokens, long long outputTokens);
@property (copy, nonatomic) void (^onFinish)(GeminiStreamError error, NSInteger httpStatus, NSString *detail);

- (void)start;
- (void)cancel;

@end
