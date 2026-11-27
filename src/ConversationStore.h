#import <Foundation/Foundation.h>

// Chat history, stored only on this device: one JSON file per conversation plus a small index.
// A conversation is an NSDictionary:
//   id, title, customTitle(BOOL), model, created, updated (unix time), messages: [ {role: "user"|"model", text, ts} ]
@interface ConversationStore : NSObject

+ (NSArray *)allEntries;                                   // index entries (id, title, updated), newest first
+ (NSMutableDictionary *)newConversationWithModel:(NSString *)model;
+ (NSMutableDictionary *)loadConversationWithId:(NSString *)cid;   // nil if missing/corrupt
+ (void)saveConversation:(NSDictionary *)conversation;
+ (void)deleteConversationWithId:(NSString *)cid;
+ (void)renameConversationWithId:(NSString *)cid title:(NSString *)title;
+ (void)deleteAll;
+ (NSArray *)entriesMatching:(NSString *)query;            // title or message text (case/diacritic-insensitive)

@end
