#import <Foundation/Foundation.h>

// Limits (kept below Google's request-size cap, with room for base64 growth and the chat text).
extern const NSInteger  kMaxAttachmentsPerMessage;   // files per message
extern const NSUInteger kMaxInlineBytesPerMessage;   // raw bytes of images + PDFs sent in one request
extern const NSUInteger kMaxTextFileBytes;         // max raw bytes for text/code/log files (~1M+ lines)
extern const NSUInteger kMaxTextChars;             // max characters stored for text attachments

// Attachments are stored on this device only, in one folder per conversation.
// An attachment is an NSDictionary:
//   id, kind ("image" | "pdf" | "text" | "video"), name (shown to the user), mime, file (stored file name), thumb (images only), bytes
@interface AttachmentStore : NSObject

+ (void)deleteDirectoryForConversation:(NSString *)conversationId;
+ (void)deleteAll;
+ (void)removeOrphansKeepingConversationIds:(NSSet *)conversationIds;

// Import. On failure these return nil and set *errorKey to a Localizable.strings key. Safe to call off the main thread.
+ (NSDictionary *)importImageData:(NSData *)data name:(NSString *)name conversation:(NSString *)conversationId errorKey:(NSString **)errorKey;
+ (NSDictionary *)importDocumentAtURL:(NSURL *)url conversation:(NSString *)conversationId errorKey:(NSString **)errorKey;

+ (void)deleteAttachment:(NSDictionary *)attachment conversation:(NSString *)conversationId;
+ (NSString *)pathForFile:(NSString *)file conversation:(NSString *)conversationId;      // nil if the name is not safe
+ (NSString *)thumbnailDataURIForAttachment:(NSDictionary *)attachment conversation:(NSString *)conversationId;

@end
