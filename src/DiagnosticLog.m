#import "DiagnosticLog.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import "Loc.h"

static const NSUInteger kMaxLogBytes = 160 * 1024;   // when the file grows past this, the older half is dropped

static NSString *LogPath(void) {
    static NSString *path = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *base = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        NSString *dir = [base stringByAppendingPathComponent:@"ClaudeMini"];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
        path = [dir stringByAppendingPathComponent:@"diagnostic.log"];
    });
    return path;
}

static dispatch_queue_t LogQueue(void) {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ queue = dispatch_queue_create("com.puc.claudemini.log", DISPATCH_QUEUE_SERIAL); });
    return queue;
}

@implementation DiagnosticLog

+ (void)log:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSDate *now = [NSDate date];

    dispatch_async(LogQueue(), ^{
        static NSDateFormatter *formatter = nil;
        if (!formatter) {
            formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
            formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss.SSS";
        }
        NSString *line = [NSString stringWithFormat:@"%@ %@\n", [formatter stringFromDate:now], message];
        NSData *lineData = [line dataUsingEncoding:NSUTF8StringEncoding];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *path = LogPath();
        if (![fm fileExistsAtPath:path]) [fm createFileAtPath:path contents:nil attributes:@{NSFilePosixPermissions: @0600}];

        NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:path];
        [handle seekToEndOfFile];
        [handle writeData:lineData];
        unsigned long long size = [handle offsetInFile];
        [handle closeFile];

        if (size > kMaxLogBytes) {   // keep the newer half, starting at a line boundary
            NSData *all = [NSData dataWithContentsOfFile:path];
            NSUInteger cut = all.length / 2;
            const uint8_t *bytes = all.bytes;
            while (cut < all.length && bytes[cut] != '\n') cut++;
            if (cut < all.length) cut++;
            [[all subdataWithRange:NSMakeRange(cut, all.length - cut)] writeToFile:path atomically:YES];
        }
    });
}

+ (void)logLaunch {
    struct utsname info;
    uname(&info);
    NSString *model = [NSString stringWithUTF8String:info.machine] ?: @"?";
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
    NSString *language = [[NSLocale preferredLanguages] firstObject] ?: @"?";
    [self log:@"--- launch: ClaudeMini %@ | iOS %@ | %@ | system language %@ | app language %@",
              version, [[UIDevice currentDevice] systemVersion], model, language, [Loc preference]];
}

+ (NSString *)contents {
    __block NSString *text = @"";
    dispatch_sync(LogQueue(), ^{
        NSData *data = [NSData dataWithContentsOfFile:LogPath()];
        if (data.length > 0) text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] ?: @"";
    });
    return text;
}

+ (void)clear {
    dispatch_sync(LogQueue(), ^{ [[NSFileManager defaultManager] removeItemAtPath:LogPath() error:nil]; });
}

@end
