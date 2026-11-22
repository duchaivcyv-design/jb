#import "KeyStore.h"
#import "KeyTier.h"
#import "GoogleAuth.h"
#import <Security/Security.h>

static NSString *const kKeyService = @"com.puc.claudemini";
// YES when Gemini should use the Google account (set by the person in the sign-in screen).
static NSString *const kGeminiGoogleModeKey = @"gemini.useGoogleSignIn";

// The Gemini names are the ones earlier versions used, so an existing key keeps working after an update.
static NSString *AccountFor(AIProvider provider) {
    return provider == AIProviderClaude ? @"claude-api-key" : @"gemini-api-key";
}

static NSString *FileNameFor(AIProvider provider) {
    return provider == AIProviderClaude ? @"key-claude.dat" : @"key.dat";
}

// The Keychain and the key files are slow (and loadKey is called from table cells and every screen that appears),
// so the answer is remembered in memory. NSNull = "no key". Cleared whenever a key is saved or deleted.
static NSMutableDictionary *gKeyCache;

static NSMutableDictionary *KeyCache(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{ gKeyCache = [NSMutableDictionary dictionary]; });
    return gKeyCache;
}

@implementation KeyStore

+ (NSMutableDictionary *)baseQueryFor:(AIProvider)provider {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeyService,
        (__bridge id)kSecAttrAccount: AccountFor(provider)
    } mutableCopy];
}

+ (NSString *)fallbackPathFor:(AIProvider)provider {
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    dir = [dir stringByAppendingPathComponent:@"ClaudeMini"];
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        [[NSFileManager defaultManager] createDirectoryAtPath:dir
                                  withIntermediateDirectories:YES
                                                   attributes:@{NSFilePosixPermissions: @0700}
                                                        error:nil];
    });
    return [dir stringByAppendingPathComponent:FileNameFor(provider)];
}

+ (NSString *)loadKeyForProvider:(AIProvider)provider {
    if (provider == AIProviderGemini && [self geminiUsesGoogleSignIn]) {
        return [GoogleAuth accessTokenNonBlocking];   // not cached: the token changes every hour
    }
    NSNumber *cacheKey = @(provider);
    @synchronized (KeyCache()) {
        id cached = KeyCache()[cacheKey];
        if (cached) return cached == [NSNull null] ? nil : cached;
    }
    NSString *loaded = [self loadKeyFromStorageForProvider:provider];
    @synchronized (KeyCache()) {
        KeyCache()[cacheKey] = loaded ?: [NSNull null];
    }
    return loaded;
}

+ (void)forgetCachedKeyForProvider:(AIProvider)provider {
    @synchronized (KeyCache()) { [KeyCache() removeObjectForKey:@(provider)]; }
}

+ (NSString *)loadKeyFromStorageForProvider:(AIProvider)provider {
    NSMutableDictionary *query = [self baseQueryFor:provider];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess && result != NULL) {
        NSData *data = (__bridge_transfer NSData *)result;
        NSString *key = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (key.length > 0) return key;
    }

    NSData *fileData = [NSData dataWithContentsOfFile:[self fallbackPathFor:provider]];
    if (fileData.length > 0) {
        NSString *key = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        if (key.length > 0) return key;
    }
    return nil;
}

+ (BOOL)saveKey:(NSString *)key forProvider:(AIProvider)provider {
    if (key.length == 0) return NO;
    [self forgetCachedKeyForProvider:provider];
    if (provider == AIProviderGemini) {
        [KeyTier invalidateGeminiDetection];   // a new key may be free or paid: detect again
        // Saving an API key means the person wants to use it now, not the Google account.
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kGeminiGoogleModeKey];
    }
    NSData *data = [key dataUsingEncoding:NSUTF8StringEncoding];

    SecItemDelete((__bridge CFDictionaryRef)[self baseQueryFor:provider]);
    NSMutableDictionary *add = [self baseQueryFor:provider];
    add[(__bridge id)kSecValueData] = data;
    add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
    [self forgetCachedKeyForProvider:provider];

    NSString *path = [self fallbackPathFor:provider];
    if (status == errSecSuccess) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return YES;
    }

    // Keychain refused: use the protected file instead.
    BOOL ok = [data writeToFile:path options:NSDataWritingAtomic error:nil];
    if (ok) {
        [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0600} ofItemAtPath:path error:nil];
    }
    return ok;
}

+ (void)deleteKeyForProvider:(AIProvider)provider {
    [self forgetCachedKeyForProvider:provider];
    if (provider == AIProviderGemini) [KeyTier invalidateGeminiDetection];
    SecItemDelete((__bridge CFDictionaryRef)[self baseQueryFor:provider]);
    [[NSFileManager defaultManager] removeItemAtPath:[self fallbackPathFor:provider] error:nil];
}

+ (BOOL)hasKeyForProvider:(AIProvider)provider {
    if (provider == AIProviderGemini && [self geminiUsesGoogleSignIn]) return YES;   // token may not be loaded yet
    return [self loadKeyForProvider:provider].length > 0;
}

+ (BOOL)geminiUsesGoogleSignIn {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kGeminiGoogleModeKey] && [GoogleAuth isSignedIn];
}

+ (void)setGeminiUsesGoogleSignIn:(BOOL)useGoogle {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:useGoogle forKey:kGeminiGoogleModeKey];
    [defaults synchronize];
    @synchronized (KeyCache()) { [KeyCache() removeAllObjects]; }
    [KeyTier invalidateGeminiDetection];   // the account may be free or paid: detect again
}

+ (NSString *)freshKeyForProvider:(AIProvider)provider {
    if (provider == AIProviderGemini && [self geminiUsesGoogleSignIn]) {
        return [GoogleAuth accessTokenBlocking];
    }
    return [self loadKeyForProvider:provider];
}

+ (void)applyGeminiCredential:(NSString *)credential toRequest:(NSMutableURLRequest *)request {
    // Gemini API keys always start with "AIza". Anything else is an OAuth access token from Google sign-in.
    BOOL isApiKey = [credential hasPrefix:@"AIza"];
    if (!isApiKey && credential.length > 0 && [GoogleAuth isSignedIn]) {
        [request setValue:[@"Bearer " stringByAppendingString:credential] forHTTPHeaderField:@"Authorization"];
        NSString *projectID = [GoogleAuth cloudProjectID];
        if (projectID.length > 0) [request setValue:projectID forHTTPHeaderField:@"x-goog-user-project"];
    } else {
        [request setValue:credential forHTTPHeaderField:@"x-goog-api-key"];
    }
}

+ (BOOL)hasAnyKey {
    return [self hasKeyForProvider:AIProviderGemini] || [self hasKeyForProvider:AIProviderClaude];
}

@end
