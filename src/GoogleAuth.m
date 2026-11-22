#import "GoogleAuth.h"
#import "KeyStore.h"
#import "Strings.h"
#import "DiagnosticLog.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import <CommonCrypto/CommonDigest.h>

NSString *const GoogleAuthErrorDomain = @"GoogleAuthError";

static NSString *const kAuthEndpoint     = @"https://accounts.google.com/o/oauth2/v2/auth";
static NSString *const kTokenEndpoint    = @"https://oauth2.googleapis.com/token";
static NSString *const kUserInfoEndpoint = @"https://openidconnect.googleapis.com/v1/userinfo";
static NSString *const kClientSuffix     = @".apps.googleusercontent.com";

// Identity (to show which account is in use) plus the Gemini API scope.
// If sign-in succeeds but Gemini answers 403 "permission denied", this Gemini scope is the first thing to check.
static NSString *const kScopes = @"openid email https://www.googleapis.com/auth/generative-language.peruserdata";

static NSString *const kKeychainService   = @"com.puc.claudemini";
static NSString *const kAccountRefresh    = @"google-refresh-token";
static NSString *const kAccountAccess     = @"google-access-token";   // stored as "expiryEpoch|token"
static NSString *const kEmailPrefKey      = @"googleAccountEmail";
static const NSTimeInterval kRefreshMargin = 300;   // refresh when less than 5 minutes of validity are left
static const NSTimeInterval kRetryBackoff  = 30;    // do not retry a failed background refresh more often than this

// In-memory state, guarded by @synchronized([GoogleAuth class]).
static NSString *gRefreshToken;
static BOOL gRefreshLoaded;
static NSString *gAccessToken;
static NSTimeInterval gAccessExpiry;
static BOOL gAccessLoaded;
static BOOL gRefreshing;
static NSTimeInterval gLastRefreshAttempt;
static id gAuthSession;     // ASWebAuthenticationSession, kept alive while the sign-in page is open
static id gAuthAnchor;      // presentation anchor for the sign-in page, kept alive with the session

#pragma mark - Presentation anchor

@interface GoogleAuthPresenter : NSObject <ASWebAuthenticationPresentationContextProviding>
@property (weak, nonatomic) UIWindow *window;
@end

@implementation GoogleAuthPresenter
- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    return self.window ?: [UIApplication sharedApplication].keyWindow;
}
@end

#pragma mark - Helpers

static NSString *ClientID(void) {
    id value = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GoogleOAuthClientID"];
    if (![value isKindOfClass:[NSString class]]) return @"";
    return [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

// Google's iOS client IDs look like "123-abc.apps.googleusercontent.com"; the redirect uses the reversed form.
static NSString *RedirectScheme(void) {
    NSString *clientID = ClientID();
    NSString *prefix = [clientID hasSuffix:kClientSuffix] ? [clientID substringToIndex:clientID.length - kClientSuffix.length] : clientID;
    return [@"com.googleusercontent.apps." stringByAppendingString:prefix];
}

static NSString *RedirectURI(void) {
    return [RedirectScheme() stringByAppendingString:@":/oauth2redirect"];
}

static NSString *StringValue(id value) {
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSError *GAError(GoogleAuthErrorCode code, NSString *message) {
    return [NSError errorWithDomain:GoogleAuthErrorDomain code:code
                           userInfo:message ? @{ NSLocalizedDescriptionKey: message } : nil];
}

static NSString *Base64URL(NSData *data) {
    NSString *s = [data base64EncodedStringWithOptions:0];
    s = [s stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    s = [s stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    return [s stringByReplacingOccurrencesOfString:@"=" withString:@""];
}

static NSString *RandomURLSafeString(size_t bytes) {
    NSMutableData *data = [NSMutableData dataWithLength:bytes];
    arc4random_buf(data.mutableBytes, bytes);
    return Base64URL(data);
}

static NSData *SHA256Data(NSString *text) {
    NSData *input = [text dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(input.bytes, (CC_LONG)input.length, digest);
    return [NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}

static NSTimeInterval NowEpoch(void) {
    return [[NSDate date] timeIntervalSince1970];
}

static NSTimeInterval LifetimeFrom(NSDictionary *json) {
    id value = json[@"expires_in"];
    NSTimeInterval seconds = [value respondsToSelector:@selector(doubleValue)] ? [value doubleValue] : 0;
    return seconds > 60 ? seconds : 3600;
}

// Form-encoding for application/x-www-form-urlencoded bodies (unreserved characters only).
static NSString *FormEncode(NSString *value) {
    NSMutableCharacterSet *allowed = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowed addCharactersInString:@"-._~"];
    return [value stringByAddingPercentEncodingWithAllowedCharacters:allowed];
}

static NSURLRequest *FormRequest(NSString *urlString, NSDictionary *params) {
    NSMutableArray *pairs = [NSMutableArray arrayWithCapacity:params.count];
    for (NSString *name in params) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", FormEncode(name), FormEncode(params[name])]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:20];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = [[pairs componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
    return request;
}

#pragma mark - Keychain (with a 0600 file fallback, like KeyStore)

static NSMutableDictionary *SecretQuery(NSString *account) {
    return [@{ (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
               (__bridge id)kSecAttrService: kKeychainService,
               (__bridge id)kSecAttrAccount: account } mutableCopy];
}

static NSString *SecretFilePath(NSString *account) {
    NSString *dir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    dir = [dir stringByAppendingPathComponent:@"ClaudeMini"];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES
                                              attributes:@{ NSFilePosixPermissions: @0700 } error:nil];
    return [dir stringByAppendingPathComponent:[account stringByAppendingString:@".dat"]];
}

static void SecretSave(NSString *account, NSString *value) {
    SecItemDelete((__bridge CFDictionaryRef)SecretQuery(account));
    NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableDictionary *add = SecretQuery(account);
    add[(__bridge id)kSecValueData] = data;
    add[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)add, NULL);
    NSString *path = SecretFilePath(account);
    if (status == errSecSuccess) {
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        return;
    }
    if ([data writeToFile:path options:NSDataWritingAtomic error:nil]) {
        [[NSFileManager defaultManager] setAttributes:@{ NSFilePosixPermissions: @0600 } ofItemAtPath:path error:nil];
    }
}

static NSString *SecretLoad(NSString *account) {
    NSMutableDictionary *query = SecretQuery(account);
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;
    CFTypeRef result = NULL;
    if (SecItemCopyMatching((__bridge CFDictionaryRef)query, &result) == errSecSuccess && result != NULL) {
        NSData *data = (__bridge_transfer NSData *)result;
        NSString *value = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (value.length > 0) return value;
    }
    NSData *fileData = [NSData dataWithContentsOfFile:SecretFilePath(account)];
    if (fileData.length > 0) {
        NSString *value = [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
        if (value.length > 0) return value;
    }
    return nil;
}

static void SecretDelete(NSString *account) {
    SecItemDelete((__bridge CFDictionaryRef)SecretQuery(account));
    [[NSFileManager defaultManager] removeItemAtPath:SecretFilePath(account) error:nil];
}

// Call with the lock held: reads the saved access token once, the first time it is needed.
static void LoadAccessLocked(void) {
    if (gAccessLoaded) return;
    gAccessLoaded = YES;
    NSString *stored = SecretLoad(kAccountAccess);
    NSRange bar = [stored rangeOfString:@"|"];
    if (bar.location == NSNotFound) return;
    gAccessExpiry = [[stored substringToIndex:bar.location] doubleValue];
    NSString *token = [stored substringFromIndex:bar.location + 1];
    if (token.length > 0) gAccessToken = token;
}

#pragma mark - GoogleAuth

@implementation GoogleAuth

#pragma mark State

+ (BOOL)isConfigured {
    NSString *clientID = ClientID();
    return [clientID hasSuffix:kClientSuffix] && clientID.length > kClientSuffix.length;
}

+ (NSString *)refreshTokenValue {
    @synchronized (self) {
        if (!gRefreshLoaded) {
            gRefreshToken = SecretLoad(kAccountRefresh);
            gRefreshLoaded = YES;
        }
        return gRefreshToken;
    }
}

+ (BOOL)isSignedIn {
    return [self refreshTokenValue].length > 0;
}

+ (NSString *)accountEmail {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kEmailPrefKey];
}

+ (void)storeAccessToken:(NSString *)token lifetime:(NSTimeInterval)lifetime {
    NSTimeInterval expiry = NowEpoch() + lifetime;
    @synchronized (self) {
        gAccessToken = [token copy];
        gAccessExpiry = expiry;
        gAccessLoaded = YES;
        SecretSave(kAccountAccess, [NSString stringWithFormat:@"%.0f|%@", expiry, token]);
    }
}

// Forgets the sign-in (sign-out, or Google revoked it). Safe to call from any thread.
+ (void)forgetSignInAndNotify:(BOOL)notify {
    @synchronized (self) {
        gRefreshToken = nil;
        gRefreshLoaded = YES;
        gAccessToken = nil;
        gAccessExpiry = 0;
        gAccessLoaded = YES;
    }
    SecretDelete(kAccountRefresh);
    SecretDelete(kAccountAccess);
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kEmailPrefKey];
    [KeyStore setGeminiUsesGoogleSignIn:NO];
    if (notify) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
        });
    }
}

+ (void)signOut {
    [self forgetSignInAndNotify:YES];
}

#pragma mark Token requests

// Completion runs on a background queue.
+ (void)postForm:(NSDictionary *)params completion:(void (^)(NSDictionary *json, NSInteger status, NSError *error))completion {
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:FormRequest(kTokenEndpoint, params)
                                                                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
        id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        completion([json isKindOfClass:[NSDictionary class]] ? json : nil, status, error);
    }];
    [task resume];
}

// Completion runs on a background queue.
+ (void)refreshWithCompletion:(void (^)(NSString *token, NSError *error))completion {
    NSString *refresh = [self refreshTokenValue];
    if (refresh.length == 0) {
        completion(nil, GAError(GoogleAuthErrorRevoked, @"not signed in"));
        return;
    }
    NSDictionary *params = @{ @"client_id": ClientID(),
                              @"grant_type": @"refresh_token",
                              @"refresh_token": refresh };
    [self postForm:params completion:^(NSDictionary *json, NSInteger status, NSError *error) {
        NSString *token = StringValue(json[@"access_token"]);
        if (token.length > 0 && status == 200) {
            [self storeAccessToken:token lifetime:LifetimeFrom(json)];
            completion(token, nil);
            return;
        }
        if (status == 400 && [StringValue(json[@"error"]) isEqualToString:@"invalid_grant"]) {
            // Revoked in the Google account settings, or the refresh token expired: the person has to sign in again.
            [self forgetSignInAndNotify:YES];
            completion(nil, GAError(GoogleAuthErrorRevoked, @"sign-in revoked"));
            return;
        }
        if (error != nil) {
            completion(nil, GAError(GoogleAuthErrorNetwork, error.localizedDescription));
        } else {
            completion(nil, GAError(GoogleAuthErrorNoToken, [NSString stringWithFormat:@"token HTTP %ld", (long)status]));
        }
    }];
}

+ (void)startBackgroundRefresh {
    @synchronized (self) {
        NSTimeInterval now = NowEpoch();
        if (gRefreshing || now - gLastRefreshAttempt < kRetryBackoff) return;
        gRefreshing = YES;
        gLastRefreshAttempt = now;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [self refreshWithCompletion:^(NSString *token, NSError *error) {
            @synchronized (self) { gRefreshing = NO; }
            if (error != nil) [DiagnosticLog log:@"google token refresh failed: %@", error.localizedDescription];
        }];
    });
}

+ (NSString *)accessTokenNonBlocking {
    NSString *token = nil;
    BOOL needsRefresh = NO;
    @synchronized (self) {
        LoadAccessLocked();
        token = gAccessToken;
        needsRefresh = token.length == 0 || gAccessExpiry - NowEpoch() < kRefreshMargin;
    }
    if (needsRefresh && [self isSignedIn]) [self startBackgroundRefresh];
    return token;
}

+ (NSString *)accessTokenBlocking {
    if ([NSThread isMainThread]) return [self accessTokenNonBlocking];   // never freeze the UI

    NSString *token = nil;
    NSTimeInterval expiry = 0;
    @synchronized (self) {
        LoadAccessLocked();
        token = gAccessToken;
        expiry = gAccessExpiry;
    }
    NSTimeInterval now = NowEpoch();
    if (token.length > 0 && expiry - now > 60) return token;
    if (![self isSignedIn]) return nil;

    __block NSString *fresh = nil;
    dispatch_semaphore_t done = dispatch_semaphore_create(0);
    [self refreshWithCompletion:^(NSString *newToken, NSError *error) {
        fresh = newToken;
        dispatch_semaphore_signal(done);
    }];
    dispatch_semaphore_wait(done, dispatch_time(DISPATCH_TIME_NOW, 20 * NSEC_PER_SEC));
    if (fresh.length > 0) return fresh;
    // Could not refresh now, but a token that has not run out yet still works.
    return (token.length > 0 && expiry > now) ? token : nil;
}

+ (void)refreshIfNeeded {
    [self accessTokenNonBlocking];
}

#pragma mark Sign-in

+ (void)fetchEmailWithToken:(NSString *)token completion:(void (^)(NSString *email))completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:kUserInfoEndpoint]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:15];
    [request setValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        id json = data.length > 0 ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
        completion(StringValue([json isKindOfClass:[NSDictionary class]] ? json[@"email"] : nil));
    }] resume];
}

// Runs on a background queue. Calls finish on the main queue.
+ (void)exchangeCode:(NSString *)code verifier:(NSString *)verifier finish:(void (^)(NSError *error))finish {
    NSDictionary *params = @{ @"client_id": ClientID(),
                              @"code": code,
                              @"code_verifier": verifier,
                              @"grant_type": @"authorization_code",
                              @"redirect_uri": RedirectURI() };
    [self postForm:params completion:^(NSDictionary *json, NSInteger status, NSError *error) {
        NSString *access = StringValue(json[@"access_token"]);
        NSString *refresh = StringValue(json[@"refresh_token"]);
        if (access.length == 0) {
            NSError *failure = error != nil
                ? GAError(GoogleAuthErrorNetwork, error.localizedDescription)
                : GAError(GoogleAuthErrorNoToken, [NSString stringWithFormat:@"token HTTP %ld", (long)status]);
            dispatch_async(dispatch_get_main_queue(), ^{ finish(failure); });
            return;
        }
        // Without a refresh token the app could not keep the sign-in alive after an hour.
        if (refresh.length == 0 && ![self isSignedIn]) {
            dispatch_async(dispatch_get_main_queue(), ^{ finish(GAError(GoogleAuthErrorNoToken, @"no refresh token")); });
            return;
        }
        @synchronized (self) {
            if (refresh.length > 0) {
                gRefreshToken = refresh;
                gRefreshLoaded = YES;
                SecretSave(kAccountRefresh, refresh);
            }
        }
        [self storeAccessToken:access lifetime:LifetimeFrom(json)];

        [self fetchEmailWithToken:access completion:^(NSString *email) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if (email.length > 0) [defaults setObject:email forKey:kEmailPrefKey];
            else [defaults removeObjectForKey:kEmailPrefKey];
            [KeyStore setGeminiUsesGoogleSignIn:YES];
            dispatch_async(dispatch_get_main_queue(), ^{ finish(nil); });
        }];
    }];
}

+ (void)signInFromViewController:(UIViewController *)presenter completion:(void (^)(NSError *error))completion {
    void (^finish)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{ completion(error); });
    };
    if (![self isConfigured]) {
        finish(GAError(GoogleAuthErrorNotConfigured, @"this build has no Google client ID"));
        return;
    }

    // PKCE: the verifier never leaves the device; only its SHA-256 goes into the sign-in URL.
    NSString *verifier = RandomURLSafeString(32);      // 43 characters, the minimum PKCE length
    NSString *challenge = Base64URL(SHA256Data(verifier));
    NSString *state = RandomURLSafeString(16);

    NSURLComponents *components = [NSURLComponents componentsWithString:kAuthEndpoint];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"client_id" value:ClientID()],
        [NSURLQueryItem queryItemWithName:@"redirect_uri" value:RedirectURI()],
        [NSURLQueryItem queryItemWithName:@"response_type" value:@"code"],
        [NSURLQueryItem queryItemWithName:@"scope" value:kScopes],
        [NSURLQueryItem queryItemWithName:@"code_challenge" value:challenge],
        [NSURLQueryItem queryItemWithName:@"code_challenge_method" value:@"S256"],
        [NSURLQueryItem queryItemWithName:@"access_type" value:@"offline"],
        [NSURLQueryItem queryItemWithName:@"prompt" value:@"consent"],
        [NSURLQueryItem queryItemWithName:@"state" value:state]
    ];

    GoogleAuthPresenter *anchor = [[GoogleAuthPresenter alloc] init];
    anchor.window = presenter.view.window ?: [UIApplication sharedApplication].keyWindow;

    ASWebAuthenticationSession *session = [[ASWebAuthenticationSession alloc]
        initWithURL:components.URL
  callbackURLScheme:RedirectScheme()
  completionHandler:^(NSURL *callbackURL, NSError *error) {
        gAuthSession = nil;
        gAuthAnchor = nil;

        if (callbackURL == nil) {
            BOOL cancelled = [error.domain isEqualToString:ASWebAuthenticationSessionErrorDomain] &&
                             error.code == ASWebAuthenticationSessionErrorCodeCanceledLogin;
            finish(cancelled ? GAError(GoogleAuthErrorCancelled, nil)
                             : GAError(GoogleAuthErrorDenied, error.localizedDescription));
            return;
        }

        NSURLComponents *callback = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
        NSString *code = nil, *returnedState = nil, *oauthError = nil;
        for (NSURLQueryItem *item in callback.queryItems) {
            if ([item.name isEqualToString:@"code"]) code = item.value;
            else if ([item.name isEqualToString:@"state"]) returnedState = item.value;
            else if ([item.name isEqualToString:@"error"]) oauthError = item.value;
        }
        if (oauthError.length > 0) {
            finish(GAError(GoogleAuthErrorDenied, oauthError));
            return;
        }
        if (![returnedState isEqualToString:state]) {
            finish(GAError(GoogleAuthErrorStateMismatch, @"state mismatch"));
            return;
        }
        if (code.length == 0) {
            finish(GAError(GoogleAuthErrorNoToken, @"no authorization code"));
            return;
        }
        [self exchangeCode:code verifier:verifier finish:finish];
    }];

    if (@available(iOS 13.0, *)) {
        session.presentationContextProvider = anchor;   // iOS 12 picks the top screen by itself
    }
    gAuthSession = session;
    gAuthAnchor = anchor;
    if (![session start]) {
        gAuthSession = nil;
        gAuthAnchor = nil;
        finish(GAError(GoogleAuthErrorNetwork, @"could not open the sign-in page"));
    }
}

@end
