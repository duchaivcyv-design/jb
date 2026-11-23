#import "DevAccess.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonKeyDerivation.h>
#import <Security/Security.h>
#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <sys/sysctl.h>
#import <time.h>
#import <unistd.h>

#ifndef P_TRACED
#define P_TRACED 0x00000800   // the process is being debugged (sys/proc.h is not in the iOS SDK)
#endif

// File format of an encrypted developer build:
//   "CMDEV1" (6) | salt (16) | iv (16) | AES-256-CBC ciphertext (PKCS7) | HMAC-SHA256 (32)
//   keys = PBKDF2-HMAC-SHA256(password, salt, 250000) -> 64 bytes: [0..31] AES key, [32..63] MAC key
//   tag  = HMAC-SHA256(macKey, "CMDEV1" | salt | iv | ciphertext)
static const char kMagic[6] = { 'C', 'M', 'D', 'E', 'V', '1' };
static const uint32_t kFileRounds = 250000;

// Verifiers made from the password (see tools/make_dev_gate.py in the developer's own notes; the password is not in the repo).
static NSString *const kSaltA = @"15e9ac0802fc1dc486d2556a4540720c";
static NSString *const kHashA = @"e67a5cb3acd2b349e6f7ac02c36d0785490a6a2b8ee6219379c27a9834932ef9";
static const uint32_t kRoundsA = 210000;
static NSString *const kSaltB = @"f208c99853a70867c460106fffd08bb6";
static NSString *const kHashB = @"06a32589cd21f939c2e802c481da698f0e750d763eec48f8735d6e471fd1e0a681212e6545459e10e68c94d5acfe44931dff71064f2ee2ca41f143bd32f93bd0";
static const uint32_t kRoundsB = 150000;
static NSString *const kSaltC = @"e564e71042c8776096e7c87c5b0b6eb1";
static NSString *const kSealIV = @"52daea1dc2f5111cd3446afdd066c597";
static NSString *const kSealCT = @"8e29f07f964a430c9c209d02f6fa4d24a63ab951e5597d4633ddb42081d906cf5b8062ce593821a91a8e6478a93708a9";
static NSString *const kSealTag = @"e2fe7ceab71fe8c9267f03f1bb1f6493ce8c75acea7dd7126f0b48a3f6490171";
static const uint32_t kRoundsC = 120000;
static const char kSealPrefix[] = "CMDEV-GATE-OPEN-";

static const NSUInteger kMaxPasswordBytes = 256;
static const NSTimeInterval kSessionLifetime = 15 * 60;
static NSString *const kKeychainService = @"com.claudemini.devgate";
static NSString *const kKeychainAccount = @"attempts";

#pragma mark - Helpers

static NSData *DataFromHex(NSString *hex) {
    NSMutableData *out = [NSMutableData dataWithCapacity:hex.length / 2];
    for (NSUInteger i = 0; i + 1 < hex.length; i += 2) {
        unsigned int v = 0;
        [[NSScanner scannerWithString:[hex substringWithRange:NSMakeRange(i, 2)]] scanHexInt:&v];
        uint8_t b = (uint8_t)v;
        [out appendBytes:&b length:1];
    }
    return out;
}

// Compares in constant time: the running time does not depend on where the bytes differ.
static BOOL ConstantTimeEqual(const uint8_t *a, const uint8_t *b, size_t len) {
    uint8_t diff = 0;
    for (size_t i = 0; i < len; i++) diff |= (uint8_t)(a[i] ^ b[i]);
    return diff == 0;
}

static BOOL Pbkdf2(const uint8_t *pw, size_t pwLen, const uint8_t *salt, size_t saltLen, CCPseudoRandomAlgorithm prf,
                   uint32_t rounds, uint8_t *out, size_t outLen) {
    return CCKeyDerivationPBKDF(kCCPBKDF2, (const char *)pw, pwLen, salt, saltLen, prf, rounds, out, outLen) == kCCSuccess;
}

#pragma mark - Attempt record (three sealed copies)

typedef struct {
    NSInteger fails;          // wrong passwords since the last success
    NSTimeInterval until;     // wall-clock time until which the gate is shut
    NSTimeInterval seen;      // latest wall-clock time ever observed here (the clock cannot be turned back)
    NSTimeInterval boot;      // boot time of the device when `mono` was written
    NSTimeInterval mono;      // monotonic-clock time (seconds) until which the gate is shut
    BOOL valid;
} AttemptRecord;

static NSString *const kInstallKeyAccount = @"installkey";
static NSString *const kDefaultsKey = @"cm.gate.v2";

static NSDictionary *KeychainQueryFor(NSString *account) {
    return @{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
              (__bridge id)kSecAttrService: kKeychainService,
              (__bridge id)kSecAttrAccount: account };
}

static NSData *KeychainRead(NSString *account) {
    NSMutableDictionary *q = [KeychainQueryFor(account) mutableCopy];
    q[(__bridge id)kSecReturnData] = @YES;
    q[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)q, &result) != errSecSuccess || !result) return nil;
    return (__bridge_transfer NSData *)result;
}

static void KeychainWrite(NSString *account, NSData *data) {
    if (!data) return;
    NSDictionary *query = KeychainQueryFor(account);
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)@{ (__bridge id)kSecValueData: data });
    if (status == errSecItemNotFound) {
        NSMutableDictionary *add = [query mutableCopy];
        add[(__bridge id)kSecValueData] = data;
        add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;
        SecItemAdd((__bridge CFDictionaryRef)add, NULL);
    }
}

// A random per-install key that seals the attempt records. It lives in the Keychain, this device only.
static NSData *InstallKey(void) {
    NSData *key = KeychainRead(kInstallKeyAccount);
    if (key.length == 32) return key;
    uint8_t bytes[32];
    if (SecRandomCopyBytes(kSecRandomDefault, sizeof(bytes), bytes) != errSecSuccess) return nil;
    key = [NSData dataWithBytes:bytes length:sizeof(bytes)];
    memset_s(bytes, sizeof(bytes), 0, sizeof(bytes));
    KeychainWrite(kInstallKeyAccount, key);
    return key;
}

static NSString *RecordFilePath(void) {
    NSString *dir = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject;
    if (dir.length == 0) return nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return [dir stringByAppendingPathComponent:@".cmgate"];
}

static NSTimeInterval MonotonicSeconds(void) {
    return (NSTimeInterval)clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) / 1e9;
}

static NSTimeInterval BootTime(void) {
    struct timeval boot;
    size_t size = sizeof(boot);
    int mib[2] = { CTL_KERN, KERN_BOOTTIME };
    if (sysctl(mib, 2, &boot, &size, NULL, 0) != 0) return 0;
    return (NSTimeInterval)boot.tv_sec;
}

static NSData *SealRecord(AttemptRecord r, NSData *key) {
    NSDictionary *dict = @{ @"f": @(r.fails), @"u": @(r.until), @"t": @(r.seen), @"b": @(r.boot), @"m": @(r.mono), @"v": @2 };
    NSData *json = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingSortedKeys error:nil];
    if (!json || key.length != 32) return nil;
    uint8_t mac[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, key.bytes, key.length, json.bytes, json.length, mac);
    NSMutableData *out = [json mutableCopy];
    [out appendBytes:mac length:sizeof(mac)];
    return out;
}

// valid = the seal is correct. `tampered` is set when data was there but the seal does not match.
static AttemptRecord OpenRecord(NSData *blob, NSData *key, BOOL *tampered) {
    AttemptRecord r = {0, 0, 0, 0, 0, NO};
    if (blob.length == 0) return r;
    if (blob.length <= CC_SHA256_DIGEST_LENGTH || key.length != 32) { if (tampered) *tampered = YES; return r; }
    NSData *json = [blob subdataWithRange:NSMakeRange(0, blob.length - CC_SHA256_DIGEST_LENGTH)];
    const uint8_t *tag = (const uint8_t *)blob.bytes + blob.length - CC_SHA256_DIGEST_LENGTH;
    uint8_t mac[CC_SHA256_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA256, key.bytes, key.length, json.bytes, json.length, mac);
    if (!ConstantTimeEqual(mac, tag, sizeof(mac))) { if (tampered) *tampered = YES; return r; }
    id obj = [NSJSONSerialization JSONObjectWithData:json options:0 error:nil];
    if (![obj isKindOfClass:[NSDictionary class]]) { if (tampered) *tampered = YES; return r; }
    r.fails = MAX(0, [obj[@"f"] integerValue]);
    r.until = [obj[@"u"] doubleValue];
    r.seen = [obj[@"t"] doubleValue];
    r.boot = [obj[@"b"] doubleValue];
    r.mono = [obj[@"m"] doubleValue];
    r.valid = YES;
    return r;
}

// (No longer used: the gate has no lock-out. Kept only so old attempt records can be wiped.)
__attribute__((unused)) static const NSInteger kHourLockFailures = 15;
__attribute__((unused)) static NSTimeInterval PenaltyForFailures(NSInteger fails) {
    if (fails < 3) return 0;
    if (fails >= kHourLockFailures) return 3600.0;
    return MIN(30.0 * pow(2.0, (double)(fails - 3)), 900.0);
}

// Reads the three copies, keeps the worst of them and restores the ones that are missing.
__attribute__((unused)) static AttemptRecord LoadAttempts(void) {
    NSData *key = InstallKey();
    NSString *path = RecordFilePath();
    NSData *copies[3] = { KeychainRead(kKeychainAccount),
                          path ? [NSData dataWithContentsOfFile:path] : nil,
                          [[NSUserDefaults standardUserDefaults] dataForKey:kDefaultsKey] };
    AttemptRecord worst = {0, 0, 0, 0, 0, NO};
    BOOL tampered = NO, anyMissing = NO, anyData = NO;
    NSTimeInterval bootNow = BootTime();
    for (int i = 0; i < 3; i++) {
        if (copies[i].length == 0) { anyMissing = YES; continue; }
        anyData = YES;
        BOOL bad = NO;
        AttemptRecord r = OpenRecord(copies[i], key, &bad);
        if (bad) {
            // The Keychain copy of an older build is plain JSON: accept it once and seal it again below.
            if (i == 0) {
                id legacy = [NSJSONSerialization JSONObjectWithData:copies[i] options:0 error:nil];
                if ([legacy isKindOfClass:[NSDictionary class]]) {
                    r.fails = MAX(0, [legacy[@"f"] integerValue]);
                    r.until = [legacy[@"u"] doubleValue];
                    r.valid = YES;
                    bad = NO;
                }
            }
            if (bad) tampered = YES;
        }
        if (!r.valid) continue;
        worst.valid = YES;
        worst.fails = MAX(worst.fails, r.fails);
        worst.until = MAX(worst.until, r.until);
        worst.seen = MAX(worst.seen, r.seen);
        if (r.mono > 0 && r.boot > 0 && fabs(r.boot - bootNow) < 3.0) {
            worst.mono = MAX(worst.mono, r.mono);
            worst.boot = r.boot;
        }
    }
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (tampered) {
        // A record that was edited by hand is not believed: a heavy fixed penalty instead.
        worst.valid = YES;
        worst.fails = MAX(worst.fails, 5);
        worst.until = MAX(worst.until, MAX(now, worst.seen) + 900);
    }
    (void)anyData;
    if (tampered || (worst.valid && anyMissing)) {
        // Self-heal: write the combined record back to every place.
        worst.seen = MAX(worst.seen, now);
        NSData *blob = SealRecord(worst, key);
        if (blob) {
            KeychainWrite(kKeychainAccount, blob);
            if (path) [blob writeToFile:path options:NSDataWritingAtomic error:nil];
            [[NSUserDefaults standardUserDefaults] setObject:blob forKey:kDefaultsKey];
        }
    }
    return worst;
}

static void SaveAttempts(NSInteger fails, NSTimeInterval wait) {
    NSData *key = InstallKey();
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    AttemptRecord r = {0, 0, 0, 0, 0, YES};
    r.fails = fails;
    r.seen = now;
    if (wait > 0) {
        r.until = now + wait;
        r.boot = BootTime();
        r.mono = MonotonicSeconds() + wait;
    }
    NSData *blob = SealRecord(r, key);
    if (!blob) return;
    KeychainWrite(kKeychainAccount, blob);
    NSString *path = RecordFilePath();
    if (path) [blob writeToFile:path options:NSDataWritingAtomic error:nil];
    [[NSUserDefaults standardUserDefaults] setObject:blob forKey:kDefaultsKey];
}

// Seconds the gate is still shut (0 = open). The longest of the wall-clock and the monotonic view counts, and the
// wall clock can never be behind the latest time that was seen.
__attribute__((unused)) static NSTimeInterval RemainingLock(AttemptRecord r) {
    NSTimeInterval now = MAX([[NSDate date] timeIntervalSince1970], r.seen);
    NSTimeInterval remaining = r.until > now ? r.until - now : 0;
    if (r.mono > 0 && r.boot > 0 && fabs(r.boot - BootTime()) < 3.0) {
        NSTimeInterval m = r.mono - MonotonicSeconds();
        if (m > remaining) remaining = m;
    }
    return remaining;
}

#pragma mark - Hostile environment

// A debugger on the process, or instrumentation frameworks loaded into it. A jailbreak itself is not a reason to refuse.
static BOOL HostileEnvironment(void) {
    struct kinfo_proc info;
    memset(&info, 0, sizeof(info));
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid() };
    size_t size = sizeof(info);
    if (sysctl(mib, 4, &info, &size, NULL, 0) == 0 && (info.kp_proc.p_flag & P_TRACED) != 0) return YES;
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (!name) continue;
        NSString *lower = [[NSString stringWithUTF8String:name] lowercaseString];
        if ([lower containsString:@"frida"] || [lower containsString:@"cycript"] || [lower containsString:@"gadget"]) return YES;
    }
    return NO;
}

#pragma mark - DevAccess

@interface DevAccess ()
@property (assign, nonatomic) BOOL unlocked;
@property (assign, nonatomic) BOOL busy;
@property (strong, nonatomic) NSMutableData *sessionPassword;   // only while unlocked
@property (strong, nonatomic) NSTimer *lockTimer;
@property (strong, nonatomic) dispatch_queue_t queue;
@end

@implementation DevAccess

+ (instancetype)shared {
    static DevAccess *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ instance = [[DevAccess alloc] init]; });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _queue = dispatch_queue_create("com.claudemini.devaccess", DISPATCH_QUEUE_SERIAL);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLeft) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appLeft) name:UIApplicationProtectedDataWillBecomeUnavailable object:nil];   // device locked
    }
    return self;
}

- (void)appLeft { [self lock]; }

- (void)lock {
    if (![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(), ^{ [self lock]; }); return; }
    [self.lockTimer invalidate];
    self.lockTimer = nil;
    @synchronized (self) {
        if (self.sessionPassword.length > 0) memset_s(self.sessionPassword.mutableBytes, self.sessionPassword.length, 0, self.sessionPassword.length);
        self.sessionPassword = nil;
    }
    self.unlocked = NO;
}

// The three independent checks. All of them always run; the verdict is combined at the end.
- (BOOL)verifyPasswordBytes:(const uint8_t *)pw length:(size_t)len {
    NSData *saltA = DataFromHex(kSaltA), *hashA = DataFromHex(kHashA);
    NSData *saltB = DataFromHex(kSaltB), *hashB = DataFromHex(kHashB);
    NSData *saltC = DataFromHex(kSaltC), *iv = DataFromHex(kSealIV), *ct = DataFromHex(kSealCT), *tag = DataFromHex(kSealTag);

    uint8_t outA[32], outB[64], keyC[64];
    BOOL okA = Pbkdf2(pw, len, saltA.bytes, saltA.length, kCCPRFHmacAlgSHA256, kRoundsA, outA, sizeof(outA));
    BOOL okB = Pbkdf2(pw, len, saltB.bytes, saltB.length, kCCPRFHmacAlgSHA512, kRoundsB, outB, sizeof(outB));
    BOOL okC = Pbkdf2(pw, len, saltC.bytes, saltC.length, kCCPRFHmacAlgSHA256, kRoundsC, keyC, sizeof(keyC));

    BOOL a = okA && hashA.length == sizeof(outA) && ConstantTimeEqual(outA, hashA.bytes, sizeof(outA));
    BOOL b = okB && hashB.length == sizeof(outB) && ConstantTimeEqual(outB, hashB.bytes, sizeof(outB));

    BOOL c = NO;
    if (okC && tag.length == CC_SHA256_DIGEST_LENGTH && iv.length == 16 && ct.length > 0) {
        uint8_t mac[CC_SHA256_DIGEST_LENGTH];
        CCHmacContext ctx;
        CCHmacInit(&ctx, kCCHmacAlgSHA256, keyC + 32, 32);
        CCHmacUpdate(&ctx, "CMDEV-SEAL", 10);
        CCHmacUpdate(&ctx, iv.bytes, iv.length);
        CCHmacUpdate(&ctx, ct.bytes, ct.length);
        CCHmacFinal(&ctx, mac);
        BOOL tagOK = ConstantTimeEqual(mac, tag.bytes, sizeof(mac));
        uint8_t plain[128];
        size_t plainLen = 0;
        CCCryptorStatus st = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding, keyC, 32, iv.bytes,
                                     ct.bytes, ct.length, plain, sizeof(plain), &plainLen);
        BOOL plainOK = st == kCCSuccess && plainLen >= strlen(kSealPrefix) && memcmp(plain, kSealPrefix, strlen(kSealPrefix)) == 0;
        c = tagOK && plainOK;
        memset_s(plain, sizeof(plain), 0, sizeof(plain));
        memset_s(mac, sizeof(mac), 0, sizeof(mac));
    }
    BOOL verdict = a & b & c;
    memset_s(outA, sizeof(outA), 0, sizeof(outA));
    memset_s(outB, sizeof(outB), 0, sizeof(outB));
    memset_s(keyC, sizeof(keyC), 0, sizeof(keyC));
    return verdict;
}

- (void)unlockWithPassword:(NSString *)password completion:(void (^)(DevAccessResult, NSTimeInterval))completion {
    if (![NSThread isMainThread]) { dispatch_async(dispatch_get_main_queue(), ^{ [self unlockWithPassword:password completion:completion]; }); return; }
    void (^finish)(DevAccessResult, NSTimeInterval) = ^(DevAccessResult r, NSTimeInterval w) { if (completion) completion(r, w); };
    if (self.busy) { finish(DevAccessResultBusy, 0); return; }

    NSMutableData *bytes = [[(password ?: @"") dataUsingEncoding:NSUTF8StringEncoding] mutableCopy];
    if (bytes.length == 0 || bytes.length > kMaxPasswordBytes) {
        if (bytes.length > 0) memset_s(bytes.mutableBytes, bytes.length, 0, bytes.length);
        finish(DevAccessResultInvalid, 0);
        return;
    }
    if (HostileEnvironment()) {
        memset_s(bytes.mutableBytes, bytes.length, 0, bytes.length);
        finish(DevAccessResultTampered, 0);
        return;
    }
    self.busy = YES;
    dispatch_async(self.queue, ^{
        CFAbsoluteTime started = CFAbsoluteTimeGetCurrent();
        // No lock-out: wrong passwords are never counted. Whatever an older build left behind (wrong-try counters, a
        // one-hour lock in the Keychain / file / defaults) is wiped here, so it can never refuse the right password.
        BOOL ok = [self verifyPasswordBytes:bytes.bytes length:bytes.length];
        SaveAttempts(0, 0);
        // Every attempt takes at least 1.5 s, right or wrong, so guessing through the interface is slow.
        NSTimeInterval spent = CFAbsoluteTimeGetCurrent() - started;
        if (spent < 1.5) usleep((useconds_t)((1.5 - spent) * 1e6));
        dispatch_async(dispatch_get_main_queue(), ^{
            self.busy = NO;
            if (ok) {
                [self.lockTimer invalidate];
                @synchronized (self) { self.sessionPassword = bytes; }
                self.unlocked = YES;
                __weak typeof(self) weakSelf = self;
                self.lockTimer = [NSTimer scheduledTimerWithTimeInterval:kSessionLifetime repeats:NO block:^(NSTimer *t) { [weakSelf lock]; }];
                finish(DevAccessResultOK, 0);
            } else {
                memset_s(bytes.mutableBytes, bytes.length, 0, bytes.length);
                finish(DevAccessResultWrong, 0);
            }
        });
    });
}

- (BOOL)decryptFileAtPath:(NSString *)source toPath:(NSString *)destination reason:(NSString **)reason {
    NSData *password;
    @synchronized (self) { password = [self.sessionPassword copy]; }
    if (password.length == 0) { if (reason) *reason = @"locked"; return NO; }
    if (HostileEnvironment()) { if (reason) *reason = @"instrumentation detected"; return NO; }

    NSError *error = nil;
    NSData *file = [NSData dataWithContentsOfFile:source options:NSDataReadingMappedIfSafe error:&error];
    const size_t header = sizeof(kMagic) + 16 + 16;
    if (!file || file.length < header + 16 + CC_SHA256_DIGEST_LENGTH) { if (reason) *reason = @"too short"; return NO; }
    const uint8_t *bytes = file.bytes;
    if (memcmp(bytes, kMagic, sizeof(kMagic)) != 0) { if (reason) *reason = @"bad magic"; return NO; }
    const uint8_t *salt = bytes + sizeof(kMagic);
    const uint8_t *iv = salt + 16;
    const uint8_t *ct = bytes + header;
    size_t ctLen = file.length - header - CC_SHA256_DIGEST_LENGTH;
    const uint8_t *tag = bytes + file.length - CC_SHA256_DIGEST_LENGTH;
    if (ctLen == 0 || ctLen % 16 != 0) { if (reason) *reason = @"bad length"; return NO; }

    uint8_t keys[64];
    if (!Pbkdf2(password.bytes, password.length, salt, 16, kCCPRFHmacAlgSHA256, kFileRounds, keys, sizeof(keys))) { if (reason) *reason = @"kdf"; return NO; }

    // Authenticate first, decrypt only a file that carries a valid tag.
    uint8_t mac[CC_SHA256_DIGEST_LENGTH];
    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA256, keys + 32, 32);
    CCHmacUpdate(&ctx, bytes, header + ctLen);
    CCHmacFinal(&ctx, mac);
    BOOL authentic = ConstantTimeEqual(mac, tag, sizeof(mac));
    if (!authentic) {
        memset_s(keys, sizeof(keys), 0, sizeof(keys));
        if (reason) *reason = @"authentication failed (wrong key or modified file)";
        return NO;
    }
    NSMutableData *plain = [NSMutableData dataWithLength:ctLen + kCCBlockSizeAES128];
    size_t plainLen = 0;
    CCCryptorStatus st = CCCrypt(kCCDecrypt, kCCAlgorithmAES, kCCOptionPKCS7Padding, keys, 32, iv, ct, ctLen,
                                 plain.mutableBytes, plain.length, &plainLen);
    memset_s(keys, sizeof(keys), 0, sizeof(keys));
    if (st != kCCSuccess) { if (reason) *reason = @"decrypt failed"; return NO; }
    plain.length = plainLen;
    BOOL wrote = [plain writeToFile:destination options:NSDataWritingAtomic | NSDataWritingFileProtectionComplete error:&error];
    if (plain.length > 0) memset_s(plain.mutableBytes, plain.length, 0, plain.length);
    if (!wrote) { if (reason) *reason = @"could not save"; return NO; }
    return YES;
}

@end
