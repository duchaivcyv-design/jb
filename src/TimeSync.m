#import "TimeSync.h"
#import "DiagnosticLog.h"

static NSTimeInterval gOffset = 0;
static BOOL gSynced = NO;
static NSDate *gLastSync = nil;
static BOOL gFetching = NO;
static NSString *const kLock = @"TimeSync.lock";

@implementation TimeSync

+ (NSDate *)now {
    NSTimeInterval offset;
    @synchronized (kLock) { offset = gOffset; }
    return [NSDate dateWithTimeIntervalSinceNow:offset];
}

+ (BOOL)isSynced { @synchronized (kLock) { return gSynced; } }
+ (NSTimeInterval)offset { @synchronized (kLock) { return gOffset; } }

+ (void)refresh { [self refreshForce:NO]; }

+ (void)refreshForce:(BOOL)force {
    @synchronized (kLock) {
        if (gFetching) return;
        if (!force && gLastSync && -[gLastSync timeIntervalSinceNow] < 600) return;
        gFetching = YES;
    }
    [self fetchFromHostIndex:0];
}

+ (NSDate *)dateFromHeader:(NSString *)value {
    static NSDateFormatter *formatter;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
        formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss zzz";
    });
    @synchronized (formatter) { return [formatter dateFromString:value]; }
}

+ (void)fetchFromHostIndex:(NSUInteger)index {
    NSArray<NSString *> *hosts = @[@"https://www.google.com/generate_204", @"https://www.cloudflare.com/cdn-cgi/trace", @"https://www.apple.com/"];
    if (index >= hosts.count) {
        @synchronized (kLock) { gFetching = NO; }
        [DiagnosticLog log:@"time sync: no server answered, using the phone's clock"];
        return;
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:hosts[index]]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                       timeoutInterval:6];
    request.HTTPMethod = @"HEAD";
    NSDate *sent = [NSDate date];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDate *received = [NSDate date];
        NSString *header = nil;
        if (!error && [response isKindOfClass:[NSHTTPURLResponse class]]) {
            NSDictionary *fields = [(NSHTTPURLResponse *)response allHeaderFields];
            for (NSString *key in fields) {
                if ([key caseInsensitiveCompare:@"Date"] == NSOrderedSame) { header = fields[key]; break; }
            }
        }
        NSDate *server = header.length ? [self dateFromHeader:header] : nil;
        if (!server) { [self fetchFromHostIndex:index + 1]; return; }
        // The server wrote its time about half a round trip after the request left.
        NSTimeInterval roundTrip = [received timeIntervalSinceDate:sent];
        NSTimeInterval offset = [server timeIntervalSinceDate:received] + roundTrip / 2.0;
        if (fabs(offset) > 20.0 * 365.0 * 86400.0) { [self fetchFromHostIndex:index + 1]; return; }   // nonsense: ignore
        @synchronized (kLock) {
            gOffset = fabs(offset) < 1.5 ? 0 : offset;   // under a second and a half the phone's clock is as good
            gSynced = YES;
            gLastSync = received;
            gFetching = NO;
        }
        [DiagnosticLog log:@"time sync: phone clock is off by %.1f s (server %@)", offset, hosts[index]];
    }] resume];
}

@end
