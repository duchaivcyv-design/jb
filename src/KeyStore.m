#import "KeyStore.h"
#import "KeyTier.h"
#import "GoogleAuth.h"
#import <Security/Security.h>

static NSString *const kKeyService = @"com.puc.claudemini";

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
    NSString *stored = [self loadRawKeyForProvider:provider];
    if (provider == AIProviderGemini && [GoogleAuth isSignedIn]) {
        // Both a key and a Google sign-in: the one set up most recently wins (see GoogleAuth prefersGoogle).
        if (stored.length == 0 || [GoogleAuth prefersGoogle]) return kGoogleOAuthKeyMarker;
    }
    return stored;
}

+ (BOOL)geminiUsesGoogleAccount {
    return [[self loadKeyForProvider:AIProviderGemini] isEqualToString:kGoogleOAuthKeyMarker];
}

+ (NSString *)loadRawKeyForProvider:(AIProvider)provider {
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
    if (key.length == 0 || [key isEqualToString:kGoogleOAuthKeyMarker]) return NO;
    [self forgetCachedKeyForProvider:provider];
    if (provider == AIProviderGemini) {
        [GoogleAuth setPrefersGoogle:NO];   // the person just entered a key: use it
        [KeyTier invalidateGeminiDetection];
    }   // a new key may be free or paid: detect again
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
    return [self loadKeyForProvider:provider].length > 0;
}

+ (BOOL)hasAnyKey {
    return [self hasKeyForProvider:AIProviderGemini] || [self hasKeyForProvider:AIProviderClaude];
}

#pragma mark - Named secrets

+ (NSMutableDictionary *)secretQueryNamed:(NSString *)name {
    return [@{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: kKeyService,
        (__bridge id)kSecAttrAccount: name
    } mutableCopy];
}

+ (NSString *)secretPathNamed:(NSString *)name {
    NSString *dir = [[self fallbackPathFor:AIProviderGemini] stringByDeletingLastPathComponent];   // also makes sure the folder exists
    return [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"secret-%@.dat", name]];
}

+ (NSString *)loadSecretNamed:(NSString *)name {
    if (name.length == 0) return nil;
    NSMutableDictionary *query = [self secretQueryNamed:name];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecSuccess && result != NULL) {
        NSData *data = (__bridge_transfer NSData *)result;
        NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (value.length > 0) return value;
    }
    NSData *fileData = [NSData dataWithContentsOfFile:[self secretPathNamed:name]];
    if (fileData.length > 0) {
        NSString *value = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        if (value.length > 0) return value;
    }
    return nil;
}

+ (BOOL)saveSecret:(NSString *)secret named:(NSString *)name {
    if (secret.length == 0 || name.length == 0) return NO;
    NSData *data = [secret dataUsingEncoding:NSUTF8StringEncoding];
    SecItemDelete((__bridge CFDictionaryRef)[self secretQueryNamed:name]);
    NSMutableDictionary *add = [self secretQueryNamed:name];
    add[(__bridge id)kSecValueData] = data;
    add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
    NSString *path = [self secretPathNamed:name];
    if (status == errSecSuccess) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return YES;
    }
    BOOL ok = [data writeToFile:path options:NSDataWritingAtomic error:nil];
    if (ok) [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0600} ofItemAtPath:path error:nil];
    return ok;
}

+ (void)deleteSecretNamed:(NSString *)name {
    if (name.length == 0) return;
    SecItemDelete((__bridge CFDictionaryRef)[self secretQueryNamed:name]);
    [[NSFileManager defaultManager] removeItemAtPath:[self secretPathNamed:name] error:nil];
}

@end
