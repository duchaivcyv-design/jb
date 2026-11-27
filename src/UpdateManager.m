#import "UpdateManager.h"
#import "Strings.h"
#import "Theme.h"
#import "DiagnosticLog.h"
#import "DevAccess.h"
#import "AppSettings.h"

NSString *const kNotifUpdateChanged = @"ClaudeMiniUpdateChanged";

static NSString *const kLastCheckKey = @"updateLastCheck";
static const NSTimeInterval kCheckThrottle = 600;
static NSString *const kRelaunchMarker = @"/var/mobile/Library/Caches/ClaudeMiniUpdate/relaunch";

#pragma mark - Version helpers

// "0.7.3" -> @[0,7,3]; a beta revision after a dash counts as a further part: "0.7.4-1" -> @[0,7,4,1]
static NSArray<NSNumber *> *VersionParts(NSString *version) {
    NSMutableArray *parts = [NSMutableArray array];
    for (NSString *piece in [version componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@".-"]]) {
        if (piece.length == 0) continue;
        [parts addObject:@([piece integerValue])];
    }
    return parts;
}

static NSComparisonResult CompareVersions(NSString *a, NSString *b) {
    NSArray *pa = VersionParts(a), *pb = VersionParts(b);
    NSUInteger count = MAX(pa.count, pb.count);
    for (NSUInteger i = 0; i < count; i++) {
        NSInteger x = i < pa.count ? [pa[i] integerValue] : 0;
        NSInteger y = i < pb.count ? [pb[i] integerValue] : 0;
        if (x < y) return NSOrderedAscending;
        if (x > y) return NSOrderedDescending;
    }
    return NSOrderedSame;
}

// Finds the version ("0.7.3", or "0.7.4-1" with a beta revision) and an optional CI build number in a tag or a file name:
//   v0.7.3-b46   0.7.3-46_iphoneos-arm.deb   v0.7.4-1-b9   0.7.4-1-9_iphoneos-arm.deb   ClaudeMini_0.7.4-1.ipa
static BOOL ParseVersion(NSString *text, NSString **version, NSInteger *build) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) return NO;
    NSRegularExpression *re = [NSRegularExpression regularExpressionWithPattern:@"(\\d+(?:\\.\\d+){1,3})" options:0 error:nil];
    NSTextCheckingResult *m = [re firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (!m) return NO;
    NSString *base = [text substringWithRange:[m rangeAtIndex:1]];
    NSInteger b = 0, revision = 0;
    NSString *rest = [text substringFromIndex:NSMaxRange(m.range)];
    NSRange whole = NSMakeRange(0, rest.length);

    // revision followed by a build: "-1-b9", "-1-9_"
    NSRegularExpression *rRevBuild = [NSRegularExpression regularExpressionWithPattern:@"^-(\\d+)[-_+](?:b|build|r)?[-_]?(\\d+)(?!\\d|\\.\\d)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *mrb = [rRevBuild firstMatchInString:rest options:0 range:whole];
    if (mrb) {
        revision = [[rest substringWithRange:[mrb rangeAtIndex:1]] integerValue];
        b = [[rest substringWithRange:[mrb rangeAtIndex:2]] integerValue];
    } else {
        // revision only, in a local (non-CI) file name: "ClaudeMini_0.7.4-1.ipa"
        NSRegularExpression *rRev = [NSRegularExpression regularExpressionWithPattern:@"^-(\\d+)(?=\\.(?:ipa|deb)(?:\\.enc)?$)" options:NSRegularExpressionCaseInsensitive error:nil];
        NSTextCheckingResult *mr = [rRev firstMatchInString:rest options:0 range:whole];
        if (mr) {
            revision = [[rest substringWithRange:[mr rangeAtIndex:1]] integerValue];
        } else {
            NSRegularExpression *rb = [NSRegularExpression regularExpressionWithPattern:@"^[-_+]?(?:b|build|r)[-_]?(\\d+)|^\\+(\\d+)|^-(\\d+)(?![\\d.])" options:NSRegularExpressionCaseInsensitive error:nil];
            NSTextCheckingResult *mb = [rb firstMatchInString:rest options:0 range:whole];
            if (mb) {
                for (NSUInteger i = 1; i < mb.numberOfRanges; i++) {
                    NSRange r = [mb rangeAtIndex:i];
                    if (r.location != NSNotFound) { b = [[rest substringWithRange:r] integerValue]; break; }
                }
            }
        }
    }
    if (version) *version = revision > 0 ? [NSString stringWithFormat:@"%@-%ld", base, (long)revision] : base;
    if (build) *build = b;
    return YES;
}

static NSString *SafeFileName(NSString *name) {
    NSString *last = name.lastPathComponent;
    NSMutableString *clean = [NSMutableString string];
    for (NSUInteger i = 0; i < last.length; i++) {
        unichar c = [last characterAtIndex:i];
        if ([[NSCharacterSet alphanumericCharacterSet] characterIsMember:c] || c == '.' || c == '-' || c == '_') [clean appendFormat:@"%C", c];
        else [clean appendString:@"_"];
    }
    return clean.length > 0 ? clean : @"ClaudeMini-update";
}

#pragma mark - UpdateManager

@interface UpdateManager () <NSURLSessionDownloadDelegate>
@property (assign, nonatomic) UpdateState state;
@property (assign, nonatomic) BOOL devChannel;
@property (copy, nonatomic) NSString *repo;
@property (copy, nonatomic) NSString *currentVersion;
@property (assign, nonatomic) NSInteger currentBuild;
@property (copy, nonatomic) NSString *latestVersion;
@property (assign, nonatomic) NSInteger latestBuild;
@property (copy, nonatomic) NSString *releaseNotes;
@property (copy, nonatomic) NSString *assetName;
@property (assign, nonatomic) long long assetSize;
@property (copy, nonatomic) NSString *assetURL;
@property (assign, nonatomic) double progress;
@property (assign, nonatomic) long long receivedBytes;
@property (copy, nonatomic) NSString *downloadedPath;
@property (copy, nonatomic) NSString *errorMessage;
@property (strong, nonatomic) NSURLSession *apiSession;
@property (strong, nonatomic) NSURLSession *downloadSession;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic) NSURLSessionDataTask *checkTask;
@property (assign, nonatomic) NSUInteger generation;          // a result of an old check / download is ignored
@property (copy, nonatomic) NSString *promptedKey;
@property (strong, nonatomic) UIDocumentInteractionController *docController;
@end

@implementation UpdateManager

+ (instancetype)shared {
    static UpdateManager *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[UpdateManager alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *info = [NSBundle mainBundle].infoDictionary;
        NSString *repo = [info[@"ClaudeMiniUpdateRepo"] isKindOfClass:[NSString class]] ? info[@"ClaudeMiniUpdateRepo"] : @"";
        repo = [repo stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *override = [[NSUserDefaults standardUserDefaults] stringForKey:@"updateRepoOverride"];
        if (override.length > 0) repo = override;
        _repo = [self validRepo:repo] ? repo : @"";
        NSString *version = [info[@"CFBundleShortVersionString"] isKindOfClass:[NSString class]] ? info[@"CFBundleShortVersionString"] : @"0";
        _currentVersion = version;
        _currentBuild = [[info[@"CFBundleVersion"] description] integerValue];
        _state = UpdateStateIdle;
    }
    return self;
}

- (BOOL)validRepo:(NSString *)repo {
    if (repo.length == 0) return NO;
    NSArray *parts = [repo componentsSeparatedByString:@"/"];
    if (parts.count != 2 || [parts[0] length] == 0 || [parts[1] length] == 0) return NO;
    NSCharacterSet *bad = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_./"] invertedSet];
    return [repo rangeOfCharacterFromSet:bad].location == NSNotFound;
}

#pragma mark Install kind

// Apps installed by a .deb live in the system Applications folder; sideloaded apps live in the user containers.
- (UpdateInstallKind)installKind {
    NSString *path = [NSBundle mainBundle].bundlePath ?: @"";
    if ([path hasPrefix:@"/Applications/"] || [path hasPrefix:@"/var/jb/Applications/"] || [path hasPrefix:@"/private/var/jb/Applications/"] ||
        [path rangeOfString:@"/procursus/Applications/"].location != NSNotFound) return UpdateInstallKindDEB;
    if ([path rangeOfString:@"/containers/Bundle/Application/"].location != NSNotFound) return UpdateInstallKindIPA;
    return [Theme iconHelperAvailable] ? UpdateInstallKindDEB : UpdateInstallKindIPA;
}

- (NSString *)installKindName {
    return self.installKind == UpdateInstallKindDEB ? @"DEB" : @"IPA";
}

- (NSString *)latestLabel {
    if (self.latestVersion.length == 0) return @"";
    if (CompareVersions(self.latestVersion, self.currentVersion) == NSOrderedSame && self.latestBuild > 0) {
        return [NSString stringWithFormat:@"%@ (build %ld)", self.latestVersion, (long)self.latestBuild];
    }
    return self.latestVersion;
}

- (BOOL)updateAvailable {
    return self.state == UpdateStateAvailable || self.state == UpdateStateDownloading || self.state == UpdateStateDownloaded;
}

- (BOOL)isNewerVersion:(NSString *)version build:(NSInteger)build {
    NSComparisonResult c = CompareVersions(version, self.currentVersion);
    if (c == NSOrderedDescending) return YES;
    if (c == NSOrderedAscending) return NO;
    return build > self.currentBuild;   // same version: a later CI build counts as an update
}

- (void)publishState:(UpdateState)state {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.state = state;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
    });
}

- (void)failWithMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.errorMessage = message;
        self.state = UpdateStateFailed;
        [DiagnosticLog log:@"update: %@", message];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
    });
}

- (BOOL)consumePromptForCurrentVersion {
    if (self.state != UpdateStateAvailable) return NO;
    NSString *key = [NSString stringWithFormat:@"%@#%ld", self.latestVersion ?: @"", (long)self.latestBuild];
    if ([key isEqualToString:self.promptedKey]) return NO;
    self.promptedKey = key;
    return YES;
}

#pragma mark Channel

// The developer session must still be unlocked at every step (check, download, install), not only when the channel was
// entered. If it ran out (time, background, device lock), the channel is left, the decrypted file is removed and the
// person has to enter the password again. Returns YES when it did that.
- (BOOL)dropLockedDevChannel {
    if (!self.devChannel || [DevAccess shared].unlocked) return NO;
    [self switchToDevChannel:NO];
    [self failWithMessage:L(@"dev_err_locked")];
    return YES;
}

- (void)switchToDevChannel:(BOOL)dev {
    if (![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(), ^{ [self switchToDevChannel:dev]; }); return; }
    if (dev == self.devChannel) return;
    if (dev && ![DevAccess shared].unlocked) return;
    self.generation++;
    [self.checkTask cancel];
    self.checkTask = nil;
    [self.downloadTask cancel];
    self.downloadTask = nil;
    self.devChannel = dev;
    self.latestVersion = nil;
    self.latestBuild = 0;
    self.assetName = nil;
    self.assetURL = nil;
    self.assetSize = 0;
    self.releaseNotes = nil;
    self.progress = 0;
    self.receivedBytes = 0;
    self.errorMessage = nil;
    self.promptedKey = nil;
    // Never keep a decrypted developer build around once the channel is left.
    if (self.downloadedPath.length > 0) [[NSFileManager defaultManager] removeItemAtPath:self.downloadedPath error:nil];
    self.downloadedPath = nil;
    self.state = UpdateStateIdle;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
}

#pragma mark Check

- (NSURLSession *)apiSession {
    if (!_apiSession) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 15;
        config.timeoutIntervalForResource = 30;
        config.HTTPAdditionalHeaders = @{ @"Accept": @"application/vnd.github+json", @"User-Agent": @"ClaudeMini-Updater" };
        _apiSession = [NSURLSession sessionWithConfiguration:config];
    }
    return _apiSession;
}

- (void)checkForUpdateForce:(BOOL)force {
    if (![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(), ^{ [self checkForUpdateForce:force]; }); return; }
    if (self.state == UpdateStateChecking || self.state == UpdateStateDownloading) return;
    if (!force && self.devChannel) return;   // background checks only ever look at the normal releases
    if (!force && ![AppSettings autoUpdateCheckEnabled]) return;   // "Tự động cập nhật" is off
    if (self.repo.length == 0) {
        [self failWithMessage:L(@"update_no_repo")];
        return;
    }
    if (self.devChannel && ![DevAccess shared].unlocked) {
        [self switchToDevChannel:NO];
        [self failWithMessage:L(@"dev_err_locked")];
        return;
    }
    NSDate *last = [[NSUserDefaults standardUserDefaults] objectForKey:kLastCheckKey];
    BOOL fresh = !self.devChannel && last && [[NSDate date] timeIntervalSinceDate:last] < kCheckThrottle;
    if (!force && fresh && (self.state == UpdateStateAvailable || self.state == UpdateStateUpToDate || self.state == UpdateStateDownloaded)) return;

    self.generation++;
    NSUInteger gen = self.generation;
    self.errorMessage = nil;
    self.state = UpdateStateChecking;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/releases?per_page=20", self.repo]];
    UpdateInstallKind kind = self.installKind;
    __weak typeof(self) weakSelf = self;
    [self.checkTask cancel];
    self.checkTask = [self.apiSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UpdateManager *me = weakSelf;
        if (!me) return;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (gen != me.generation) return;
            if (error) {
                if (error.code == NSURLErrorCancelled) return;
                [me failWithMessage:[NSString stringWithFormat:@"%@ (%@)", L(@"update_err_network"), error.localizedDescription]];
                return;
            }
            NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
            if (status == 403 || status == 429) { [me failWithMessage:L(@"update_err_rate")]; return; }
            NSDictionary *found = nil;
            if (status == 200 && data) {
                id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                if ([json isKindOfClass:[NSArray class]]) found = [me bestCandidateInReleases:json kind:kind];
            } else if (status != 404) {
                [me failWithMessage:[NSString stringWithFormat:@"%@ (HTTP %ld)", L(@"update_err_network"), (long)status]];
                return;
            }
            if (found) { [me finishCheckWithCandidate:found generation:gen]; return; }
            [me checkRepositoryFilesKind:kind generation:gen];   // no usable release: look for files committed in the repository
        });
    }];
    [self.checkTask resume];
}

// The newest release that carries a file for this install kind.
- (NSDictionary *)bestCandidateInReleases:(NSArray *)releases kind:(UpdateInstallKind)kind {
    BOOL dev = self.devChannel;
    NSString *ext = kind == UpdateInstallKindDEB ? @".deb" : @".ipa";
    if (dev) ext = [ext stringByAppendingString:@".enc"];   // developer builds are encrypted
    NSDictionary *best = nil;
    for (id item in releases) {
        if (![item isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *release = item;
        if ([release[@"draft"] boolValue]) continue;
        NSString *releaseTag = [release[@"tag_name"] isKindOfClass:[NSString class]] ? release[@"tag_name"] : @"";
        BOOL isDevTag = [releaseTag.lowercaseString hasPrefix:@"dev-"] || [release[@"prerelease"] boolValue];
        if (dev != isDevTag) continue;   // normal channel never sees developer builds and the other way round
        NSArray *assets = [release[@"assets"] isKindOfClass:[NSArray class]] ? release[@"assets"] : @[];
        NSDictionary *asset = nil;
        for (id a in assets) {
            if (![a isKindOfClass:[NSDictionary class]]) continue;
            NSString *name = [a[@"name"] isKindOfClass:[NSString class]] ? a[@"name"] : @"";
            if (![name.lowercaseString hasSuffix:ext]) continue;
            if (![a[@"browser_download_url"] isKindOfClass:[NSString class]]) continue;
            if (!asset || [name.lowercaseString containsString:@"claudemini"]) asset = a;
        }
        if (!asset) continue;
        NSString *version = nil; NSInteger build = 0;
        NSString *tag = [release[@"tag_name"] isKindOfClass:[NSString class]] ? release[@"tag_name"] : @"";
        if (!ParseVersion(tag, &version, &build) && !ParseVersion(asset[@"name"], &version, &build)) continue;
        if (build == 0) { NSInteger fileBuild = 0; ParseVersion(asset[@"name"], NULL, &fileBuild); build = fileBuild; }
        NSString *body = [release[@"body"] isKindOfClass:[NSString class]] ? release[@"body"] : @"";
        NSDictionary *candidate = @{ @"version": version, @"build": @(build), @"name": asset[@"name"],
                                     @"url": asset[@"browser_download_url"], @"size": asset[@"size"] ?: @0, @"notes": body };
        if (!best) { best = candidate; continue; }
        NSComparisonResult c = CompareVersions(version, best[@"version"]);
        if (c == NSOrderedDescending || (c == NSOrderedSame && build > [best[@"build"] integerValue])) best = candidate;
    }
    return best;
}

// Fallback: .deb / .ipa files that were committed straight into the repository.
- (void)checkRepositoryFilesKind:(UpdateInstallKind)kind generation:(NSUInteger)gen {
    if (self.devChannel) { [self failWithMessage:L(@"update_err_nofile")]; return; }   // developer builds only come from releases
    NSString *ext = kind == UpdateInstallKindDEB ? @".deb" : @".ipa";
    NSURL *repoURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@", self.repo]];
    __weak typeof(self) weakSelf = self;
    self.checkTask = [self.apiSession dataTaskWithURL:repoURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        UpdateManager *me = weakSelf;
        if (!me) return;
        NSString *branch = nil;
        id json = (data && !error) ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        if ([json isKindOfClass:[NSDictionary class]] && [json[@"default_branch"] isKindOfClass:[NSString class]]) branch = json[@"default_branch"];
        if (branch.length == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (gen != me.generation) return;
                [me failWithMessage:error ? [NSString stringWithFormat:@"%@ (%@)", L(@"update_err_network"), error.localizedDescription] : L(@"update_err_repo")];
            });
            return;
        }
        NSString *encodedBranch = [branch stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        NSURL *treeURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.github.com/repos/%@/git/trees/%@?recursive=1", me.repo, encodedBranch]];
        me.checkTask = [me.apiSession dataTaskWithURL:treeURL completionHandler:^(NSData *treeData, NSURLResponse *treeResponse, NSError *treeError) {
            NSDictionary *best = nil;
            id tree = (treeData && !treeError) ? [NSJSONSerialization JSONObjectWithData:treeData options:0 error:nil] : nil;
            NSArray *entries = [tree isKindOfClass:[NSDictionary class]] && [tree[@"tree"] isKindOfClass:[NSArray class]] ? tree[@"tree"] : @[];
            for (id entry in entries) {
                if (![entry isKindOfClass:[NSDictionary class]]) continue;
                NSString *path = [entry[@"path"] isKindOfClass:[NSString class]] ? entry[@"path"] : @"";
                if (![[entry[@"type"] description] isEqualToString:@"blob"] || ![path.lowercaseString hasSuffix:ext]) continue;
                NSString *version = nil; NSInteger build = 0;
                if (!ParseVersion(path.lastPathComponent, &version, &build)) continue;
                NSMutableCharacterSet *allowed = [[NSCharacterSet URLPathAllowedCharacterSet] mutableCopy];
                NSString *encodedPath = [path stringByAddingPercentEncodingWithAllowedCharacters:allowed];
                NSString *url = [NSString stringWithFormat:@"https://raw.githubusercontent.com/%@/%@/%@", me.repo, encodedBranch, encodedPath];
                NSDictionary *candidate = @{ @"version": version, @"build": @(build), @"name": path.lastPathComponent,
                                             @"url": url, @"size": entry[@"size"] ?: @0, @"notes": @"" };
                if (!best) { best = candidate; continue; }
                NSComparisonResult c = CompareVersions(version, best[@"version"]);
                if (c == NSOrderedDescending || (c == NSOrderedSame && build > [best[@"build"] integerValue])) best = candidate;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (gen != me.generation) return;
                if (best) [me finishCheckWithCandidate:best generation:gen];
                else [me failWithMessage:L(@"update_err_nofile")];
            });
        }];
        [me.checkTask resume];
    }];
    [self.checkTask resume];
}

- (void)finishCheckWithCandidate:(NSDictionary *)candidate generation:(NSUInteger)gen {
    if (gen != self.generation) return;
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kLastCheckKey];
    NSString *version = candidate[@"version"];
    NSInteger build = [candidate[@"build"] integerValue];
    if (![self isNewerVersion:version build:build]) {
        self.latestVersion = nil;
        self.state = UpdateStateUpToDate;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
        return;
    }
    // Keep a finished download of the very same version.
    BOOL same = [self.latestVersion isEqualToString:version] && self.latestBuild == build && self.downloadedPath.length > 0 &&
                [[NSFileManager defaultManager] fileExistsAtPath:self.downloadedPath];
    self.latestVersion = version;
    self.latestBuild = build;
    self.assetName = candidate[@"name"];
    self.assetURL = candidate[@"url"];
    self.assetSize = [candidate[@"size"] longLongValue];
    NSString *notes = [candidate[@"notes"] isKindOfClass:[NSString class]] ? candidate[@"notes"] : @"";
    notes = [notes stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (notes.length > 600) {
        NSRange safe = [notes rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 600)];
        notes = [[notes substringWithRange:safe] stringByAppendingString:@"…"];
    }
    self.releaseNotes = notes;
    if (!same) { self.downloadedPath = nil; self.progress = 0; self.receivedBytes = 0; }
    self.state = same ? UpdateStateDownloaded : UpdateStateAvailable;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
}

#pragma mark Download

- (NSString *)downloadFolder {
    NSString *base;
    if (self.installKind == UpdateInstallKindIPA) {
        // Documents is shown in the Files app (UIFileSharingEnabled), which is where the .ipa is opened from.
        base = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        base = [base stringByAppendingPathComponent:@"Updates"];
    } else {
        base = @"/var/mobile/Library/Caches/ClaudeMiniUpdate";
    }
    return base;
}

- (void)startDownload {
    if (![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(), ^{ [self startDownload]; }); return; }
    if (self.state == UpdateStateDownloading) return;
    if ([self dropLockedDevChannel]) return;
    NSURL *url = [NSURL URLWithString:self.assetURL ?: @""];
    if (!url || ![url.scheme isEqualToString:@"https"]) { [self failWithMessage:L(@"update_err_nofile")]; return; }
    if (self.downloadedPath.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:self.downloadedPath]) {
        self.state = UpdateStateDownloaded;
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
        return;
    }
    self.generation++;
    self.errorMessage = nil;
    self.progress = 0;
    self.receivedBytes = 0;
    self.state = UpdateStateDownloading;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];

    if (!self.downloadSession) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        config.timeoutIntervalForRequest = 30;
        config.timeoutIntervalForResource = 20 * 60;
        config.HTTPAdditionalHeaders = @{ @"User-Agent": @"ClaudeMini-Updater" };
        self.downloadSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    self.downloadTask = [self.downloadSession downloadTaskWithURL:url];
    [self.downloadTask resume];
}

- (void)cancelDownload {
    if (![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(), ^{ [self cancelDownload]; }); return; }
    if (self.state != UpdateStateDownloading) return;
    self.generation++;
    [self.downloadTask cancel];
    self.downloadTask = nil;
    self.progress = 0;
    self.receivedBytes = 0;
    self.state = UpdateStateAvailable;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    if (task != self.downloadTask) return;
    long long total = totalBytesExpectedToWrite > 0 ? totalBytesExpectedToWrite : self.assetSize;
    self.receivedBytes = totalBytesWritten;
    self.progress = total > 0 ? MIN(1.0, (double)totalBytesWritten / (double)total) : 0;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)task didFinishDownloadingToURL:(NSURL *)location {
    if (task != self.downloadTask) return;
    NSInteger status = [task.response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)task.response statusCode] : 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (status != 200) { [self failWithMessage:[NSString stringWithFormat:@"%@ (HTTP %ld)", L(@"update_err_download"), (long)status]]; return; }

    NSString *folder = [self downloadFolder];
    NSError *error = nil;
    [fm removeItemAtPath:folder error:nil];   // only the newest download is kept
    if (![fm createDirectoryAtPath:folder withIntermediateDirectories:YES attributes:nil error:&error]) {
        [self failWithMessage:[NSString stringWithFormat:@"%@ (%@)", L(@"update_err_save"), error.localizedDescription]];
        return;
    }
    BOOL dev = self.devChannel;
    NSString *name = SafeFileName(self.assetName);
    if (dev && [name.lowercaseString hasSuffix:@".enc"]) name = [name substringToIndex:name.length - 4];
    NSString *dest = [folder stringByAppendingPathComponent:name];
    // The temporary file is deleted when this method returns, so it is moved first. A developer build stays encrypted
    // on disk until it has been decrypted and checked in the background.
    NSString *moved = dev ? [folder stringByAppendingPathComponent:@".dev-download.enc"] : dest;
    if (![fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:moved] error:&error]) {
        [self failWithMessage:[NSString stringWithFormat:@"%@ (%@)", L(@"update_err_save"), error.localizedDescription]];
        return;
    }
    NSUInteger gen = self.generation;
    UpdateInstallKind kind = self.installKind;
    self.downloadTask = nil;
    if (!dev) {
        if (![self fileLooksValid:moved kind:kind]) { [fm removeItemAtPath:moved error:nil]; [self failWithMessage:L(@"update_err_corrupt")]; return; }
        [self finishDownloadWithPath:dest];
        return;
    }
    self.progress = 1;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *reason = nil;
        BOOL ok = [[DevAccess shared] decryptFileAtPath:moved toPath:dest reason:&reason];
        [[NSFileManager defaultManager] removeItemAtPath:moved error:nil];   // the encrypted copy is not needed any more
        dispatch_async(dispatch_get_main_queue(), ^{
            UpdateManager *me = weakSelf;
            if (!me || gen != me.generation || !me.devChannel) { [[NSFileManager defaultManager] removeItemAtPath:dest error:nil]; return; }
            if (!ok) {
                [DiagnosticLog log:@"update: developer build rejected (%@)", reason];
                [me failWithMessage:L(@"dev_err_decrypt")];
                return;
            }
            if (![me fileLooksValid:dest kind:kind]) { [[NSFileManager defaultManager] removeItemAtPath:dest error:nil]; [me failWithMessage:L(@"update_err_corrupt")]; return; }
            [me finishDownloadWithPath:dest];
        });
    });
}

// The file must really be what it claims to be, otherwise an HTML error page would be handed to the installer.
- (BOOL)fileLooksValid:(NSString *)path kind:(UpdateInstallKind)kind {
    NSData *head = nil;
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (handle) { head = [handle readDataOfLength:8]; [handle closeFile]; }
    NSString *prefix = head.length >= 4 ? [[NSString alloc] initWithData:head encoding:NSISOLatin1StringEncoding] : @"";
    BOOL ok = kind == UpdateInstallKindDEB ? [prefix hasPrefix:@"!<arch>"] : [prefix hasPrefix:@"PK"];
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return ok && [attrs fileSize] >= 50 * 1024;
}

- (void)finishDownloadWithPath:(NSString *)dest {
    self.downloadedPath = dest;
    self.progress = 1;
    self.state = UpdateStateDownloaded;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifUpdateChanged object:self];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (task != self.downloadTask || !error) return;
    if (error.code == NSURLErrorCancelled) return;
    self.downloadTask = nil;
    [self failWithMessage:[NSString stringWithFormat:@"%@ (%@)", L(@"update_err_download"), error.localizedDescription]];
}

#pragma mark Install

- (void)installFromViewController:(UIViewController *)from anchor:(UIView *)anchor {
    if ([self dropLockedDevChannel]) return;
    if (self.downloadedPath.length == 0 || ![[NSFileManager defaultManager] fileExistsAtPath:self.downloadedPath]) {
        [self failWithMessage:L(@"update_err_nofile")];
        return;
    }
    if (self.installKind == UpdateInstallKindIPA) {
        // Straight to the Files app, at the folder that holds the .ipa: tap it there and pick the app that signs / installs it.
        NSString *folder = [self.downloadedPath stringByDeletingLastPathComponent];
        NSString *encoded = [folder stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        NSURL *url = [NSURL URLWithString:[@"shareddocuments://" stringByAppendingString:encoded ?: @""]];
        UIApplication *app = [UIApplication sharedApplication];
        __weak typeof(self) weakSelf = self;
        __weak UIViewController *weakFrom = from;
        __weak UIView *weakAnchor = anchor;
        if (url && [app canOpenURL:url]) {
            [app openURL:url options:@{} completionHandler:^(BOOL success) {
                if (!success) [weakSelf presentOpenInFromViewController:weakFrom anchor:weakAnchor];
            }];
        } else {
            [self presentOpenInFromViewController:from anchor:anchor];
        }
        return;
    }
    // .deb: remember to reopen the app once the package manager has installed it (the package's postinst reads this file).
    NSString *marker = kRelaunchMarker;
    [[NSFileManager defaultManager] createDirectoryAtPath:[marker stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
    [@"1" writeToFile:marker atomically:YES encoding:NSUTF8StringEncoding error:nil];
    [self presentOpenInFromViewController:from anchor:anchor];
}

- (void)presentOpenInFromViewController:(UIViewController *)from anchor:(UIView *)anchor {
    if ([self dropLockedDevChannel]) return;
    if (self.downloadedPath.length == 0) return;
    UIView *host = anchor ?: from.view;
    if (!host.window) return;
    self.docController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:self.downloadedPath]];
    self.docController.delegate = self;
    CGRect rect = anchor ? anchor.bounds : CGRectMake(host.bounds.size.width / 2.0, host.bounds.size.height - 1, 1, 1);
    BOOL shown = [self.docController presentOpenInMenuFromRect:rect inView:host animated:YES];
    if (shown) return;
    // Nothing on the device claims the file: for a .deb try Filza, otherwise the plain share sheet.
    if (self.installKind == UpdateInstallKindDEB) {
        NSString *encoded = [self.downloadedPath stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
        NSURL *filza = [NSURL URLWithString:[@"filza://view" stringByAppendingString:encoded ?: @""]];
        if (filza && [[UIApplication sharedApplication] canOpenURL:filza]) {
            [[UIApplication sharedApplication] openURL:filza options:@{} completionHandler:nil];
            return;
        }
    }
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:self.downloadedPath]] applicationActivities:nil];
    share.popoverPresentationController.sourceView = host;
    share.popoverPresentationController.sourceRect = rect;
    UIViewController *top = from ?: host.window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:share animated:YES completion:nil];
}

@end
