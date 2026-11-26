#import "ConversationStore.h"
#import "AttachmentStore.h"

static NSString *ChatsDir(void) {
    static NSString *dir = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *base = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        dir = [[base stringByAppendingPathComponent:@"ClaudeMini"] stringByAppendingPathComponent:@"chats"];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    });
    return dir;
}

static NSString *IndexPath(void) {
    return [ChatsDir() stringByAppendingPathComponent:@"index.json"];
}

// Ids become file names, so refuse anything that could escape the folder.
static BOOL ValidId(id value) {
    if (![value isKindOfClass:[NSString class]]) return NO;
    NSString *cid = value;
    return cid.length > 0 && [cid rangeOfString:@"/"].location == NSNotFound && [cid rangeOfString:@".."].location == NSNotFound;
}

static NSString *FilePath(NSString *cid) {
    return [ChatsDir() stringByAppendingPathComponent:[cid stringByAppendingString:@".json"]];
}

// Disk writes run on one serial background queue so a save never stalls the UI thread.
// Everything that reads or deletes files first waits for the writes already queued (DrainIO).
static dispatch_queue_t IOQueue(void) {
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("com.puc.claudemini.store", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0));
        // Leaving the foreground: finish pending writes before iOS may suspend the app.
        [[NSNotificationCenter defaultCenter] addObserverForName:@"UIApplicationDidEnterBackgroundNotification"
                                                          object:nil queue:nil
                                                      usingBlock:^(NSNotification *note) { dispatch_sync(queue, ^{}); }];
    });
    return queue;
}

static void DrainIO(void) {
    dispatch_sync(IOQueue(), ^{});
}

static void WriteAsync(NSData *data, NSString *path) {
    if (!data || !path) return;
    dispatch_async(IOQueue(), ^{ [data writeToFile:path options:NSDataWritingAtomic error:nil]; });
}

@implementation ConversationStore

#pragma mark - Index

// The index is read by every screen that lists chats: keep it in memory (this app is the only writer).
static NSArray *gIndexCache;

+ (void)writeIndex:(NSArray *)entries {
    @synchronized (self) { gIndexCache = [entries copy]; }
    NSData *data = [NSJSONSerialization dataWithJSONObject:entries options:0 error:nil];
    WriteAsync(data, IndexPath());
}

+ (NSArray *)rebuildIndex {
    NSMutableArray *entries = [NSMutableArray array];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:ChatsDir() error:nil];
    for (NSString *file in files) {
        if (![file hasSuffix:@".json"] || [file isEqualToString:@"index.json"]) continue;
        NSString *cid = [file stringByDeletingPathExtension];
        NSDictionary *conv = [self loadConversationWithId:cid];
        if (!conv) continue;
        [entries addObject:@{ @"id": cid,
                              @"title": conv[@"title"] ?: @"",
                              @"updated": conv[@"updated"] ?: @0 }];
    }
    if (entries.count > 0) [self writeIndex:entries];
    return entries;
}

+ (NSArray *)rawIndex {
    @synchronized (self) { if (gIndexCache) return gIndexCache; }
    NSArray *loaded = [self readIndexFromDisk];
    @synchronized (self) { gIndexCache = [loaded copy]; }
    return loaded;
}

+ (NSArray *)readIndexFromDisk {
    DrainIO();
    NSData *data = [NSData dataWithContentsOfFile:IndexPath()];
    if (data.length == 0) return [self rebuildIndex];
    id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if (![obj isKindOfClass:[NSArray class]]) return [self rebuildIndex];
    NSMutableArray *out = [NSMutableArray array];
    for (id entry in (NSArray *)obj) {
        if ([entry isKindOfClass:[NSDictionary class]] && ValidId(entry[@"id"])) [out addObject:entry];
    }
    return out;
}

+ (NSArray *)allEntries {
    return [[self rawIndex] sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        double ua = [a[@"updated"] doubleValue], ub = [b[@"updated"] doubleValue];
        if (ua == ub) return NSOrderedSame;
        return ua > ub ? NSOrderedAscending : NSOrderedDescending;   // newest first
    }];
}

#pragma mark - Conversations

+ (NSMutableDictionary *)newConversationWithModel:(NSString *)model {
    NSNumber *now = @([[NSDate date] timeIntervalSince1970]);
    return [@{ @"id": [[NSUUID UUID] UUIDString],
               @"title": @"",
               @"customTitle": @NO,
               @"model": model ?: @"",
               @"created": now,
               @"updated": now,
               @"messages": [NSMutableArray array] } mutableCopy];
}

+ (NSMutableDictionary *)loadConversationWithId:(NSString *)cid {
    if (!ValidId(cid)) return nil;
    DrainIO();
    NSData *data = [NSData dataWithContentsOfFile:FilePath(cid)];
    if (data.length == 0) return nil;
    id obj = [NSJSONSerialization JSONObjectWithData:data
                                             options:NSJSONReadingMutableContainers | NSJSONReadingMutableLeaves
                                               error:nil];
    if (![obj isKindOfClass:[NSMutableDictionary class]]) return nil;
    NSMutableDictionary *conv = obj;
    if (![conv[@"messages"] isKindOfClass:[NSMutableArray class]]) conv[@"messages"] = [NSMutableArray array];
    return conv;
}

+ (void)saveConversation:(NSDictionary *)conv {
    NSString *cid = conv[@"id"];
    if (!ValidId(cid)) return;
    NSData *data = [NSJSONSerialization dataWithJSONObject:conv options:0 error:nil];
    if (!data) return;
    WriteAsync(data, FilePath(cid));

    NSMutableArray *entries = [[self rawIndex] mutableCopy];
    for (NSInteger i = (NSInteger)entries.count - 1; i >= 0; i--) {
        if ([entries[i][@"id"] isEqualToString:cid]) [entries removeObjectAtIndex:i];
    }
    [entries addObject:@{ @"id": cid,
                          @"title": conv[@"title"] ?: @"",
                          @"updated": conv[@"updated"] ?: @0 }];
    [self writeIndex:entries];
}

+ (void)deleteConversationWithId:(NSString *)cid {
    if (!ValidId(cid)) return;
    DrainIO();
    [[NSFileManager defaultManager] removeItemAtPath:FilePath(cid) error:nil];
    [AttachmentStore deleteDirectoryForConversation:cid];
    NSMutableArray *entries = [[self rawIndex] mutableCopy];
    for (NSInteger i = (NSInteger)entries.count - 1; i >= 0; i--) {
        if ([entries[i][@"id"] isEqualToString:cid]) [entries removeObjectAtIndex:i];
    }
    [self writeIndex:entries];
}

+ (void)renameConversationWithId:(NSString *)cid title:(NSString *)title {
    NSMutableDictionary *conv = [self loadConversationWithId:cid];
    if (!conv) return;
    conv[@"title"] = title ?: @"";
    conv[@"customTitle"] = @YES;
    [self saveConversation:conv];
}

+ (void)deleteAll {
    @synchronized (self) { gIndexCache = nil; }
    DrainIO();
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *file in [fm contentsOfDirectoryAtPath:ChatsDir() error:nil]) {
        [fm removeItemAtPath:[ChatsDir() stringByAppendingPathComponent:file] error:nil];
    }
    [AttachmentStore deleteAll];
}

+ (NSArray *)entriesMatching:(NSString *)query {
    NSString *q = [query stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (q.length == 0) return [self allEntries];

    NSStringCompareOptions opts = NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch;
    NSMutableArray *matches = [NSMutableArray array];
    for (NSDictionary *entry in [self allEntries]) {
        NSString *title = entry[@"title"];
        if ([title isKindOfClass:[NSString class]] && [title rangeOfString:q options:opts].location != NSNotFound) {
            [matches addObject:entry];
            continue;
        }
        NSDictionary *conv = [self loadConversationWithId:entry[@"id"]];
        for (NSDictionary *message in conv[@"messages"]) {
            NSString *text = message[@"text"];
            if ([text isKindOfClass:[NSString class]] && [text rangeOfString:q options:opts].location != NSNotFound) {
                [matches addObject:entry];
                break;
            }
        }
    }
    return matches;
}

@end
