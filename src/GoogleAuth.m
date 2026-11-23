#import "GoogleAuth.h"
#import "KeyStore.h"
#import "KeyTier.h"
#import "DiagnosticLog.h"
#import "Strings.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import <CommonCrypto/CommonDigest.h>
#import <Security/Security.h>

NSString *const kGoogleOAuthKeyMarker = @"GOOGLE_OAUTH_SESSION";
NSString *const GoogleAuthErrorDomain = @"GoogleAuth";

static NSString *const kAuthEndpoint   = @"https://accounts.google.com/o/oauth2/v2/auth";
static NSString *const kTokenEndpoint  = @"https://oauth2.googleapis.com/token";
static NSString *const kRevokeEndpoint = @"https://oauth2.googleapis.com/revoke";

// Scopes the Gemini API documents for OAuth (ai.google.dev "Authentication with OAuth quickstart").
static NSString *const kScopes =
    @"openid email https://www.googleapis.com/auth/cloud-platform https://www.googleapis.com/auth/generative-language.retriever";

static NSString *const kDefClientID    = @"googleOAuthClientID";
static NSString *const kDefProjectID   = @"googleOAuthProjectID";
static NSString *const kDefEmail       = @"googleOAuthEmail";
static NSString *const kDefSignedIn    = @"googleOAuthSignedIn";
static NSString *const kDefPrefer      = @"geminiPrefersGoogle";
static NSString *const kRefreshSecret  = @"google-refresh-token";
static NSString *const kClientSuffix   = @".apps.googleusercontent.com";

#pragma mark - Small helpers

static NSString *Trimmed(NSString *s) {
    if (![s isKindOfClass:[NSString class]]) return @"";
    return [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *Base64URL(NSData *data) {
    NSString *s = [data base64EncodedStringWithOptions:0];
    s = [s stringByReplacingOccurrencesOfString:@"+" withString:@"-"];
    s = [s stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    s = [s stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return s;
}

static NSData *DataFromBase64URL(NSString *s) {
    NSMutableString *b = [[s stringByReplacingOccurrencesOfString:@"-" withString:@"+"] mutableCopy];
    [b replaceOccurrencesOfString:@"_" withString:@"/" options:0 range:NSMakeRange(0, b.length)];
    while (b.length % 4 != 0) [b appendString:@"="];
    return [[NSData alloc] initWithBase64EncodedString:b options:0];
}

static NSString *RandomURLSafe(NSUInteger byteCount) {
    NSMutableData *data = [NSMutableData dataWithLength:byteCount];
    if (SecRandomCopyBytes(kSecRandomDefault, byteCount, data.mutableBytes) != errSecSuccess) {
        arc4random_buf(data.mutableBytes, byteCount);
    }
    return Base64URL(data);
}

static NSString *FormEncode(NSString *s) {
    NSMutableCharacterSet *allowed = [NSMutableCharacterSet alphanumericCharacterSet];
    [allowed addCharactersInString:@"-._~"];
    return [s stringByAddingPercentEncodingWithAllowedCharacters:allowed] ?: @"";
}

static NSData *FormBody(NSDictionary<NSString *, NSString *> *fields) {
    NSMutableArray *pairs = [NSMutableArray array];
    for (NSString *key in fields) {
        [pairs addObject:[NSString stringWithFormat:@"%@=%@", FormEncode(key), FormEncode(fields[key])]];
    }
    return [[pairs componentsJoinedByString:@"&"] dataUsingEncoding:NSUTF8StringEncoding];
}

static NSMutableURLRequest *FormPost(NSString *url, NSDictionary *fields) {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:20];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    request.HTTPBody = FormBody(fields);
    return request;
}

static NSError *AuthError(GoogleAuthErrorCode code, NSString *message) {
    return [NSError errorWithDomain:GoogleAuthErrorDomain code:code
                           userInfo:@{ NSLocalizedDescriptionKey: message ?: @"" }];
}

static NSString *EmailFromIDToken(NSString *idToken) {
    NSArray *parts = [idToken componentsSeparatedByString:@"."];
    if (parts.count < 2) return @"";
    NSData *payload = DataFromBase64URL(parts[1]);
    id json = payload.length ? [NSJSONSerialization JSONObjectWithData:payload options:0 error:nil] : nil;
    NSString *email = [json isKindOfClass:[NSDictionary class]] ? json[@"email"] : nil;
    return [email isKindOfClass:[NSString class]] ? email : @"";
}

#pragma mark - Presentation anchor (iOS 13+)

API_AVAILABLE(ios(13.0))
@interface GoogleAuthPresenter : NSObject <ASWebAuthenticationPresentationContextProviding>
@property (weak, nonatomic) UIWindow *window;
@end

@implementation GoogleAuthPresenter
- (UIWindow *)presentationAnchorForWebAuthenticationSession:(ASWebAuthenticationSession *)session {
    UIWindow *window = self.window;
    if (!window) window = [UIApplication sharedApplication].keyWindow;
    return window ?: [[UIWindow alloc] init];
}
@end

#pragma mark - State kept in memory (main thread only)

static ASWebAuthenticationSession *gSession;
static id gPresenter;   // GoogleAuthPresenter (iOS 13+), kept alive while the sign-in sheet is open

static NSString *gAccessToken;
static NSDate *gAccessExpiry;
static BOOL gRefreshing;
static NSMutableArray *gWaiters;   // blocks waiting for the refresh that is in flight

@implementation GoogleAuth

#pragma mark - State

+ (BOOL)isSignedIn { return [[NSUserDefaults standardUserDefaults] boolForKey:kDefSignedIn]; }
+ (NSString *)accountEmail { return [[NSUserDefaults standardUserDefaults] stringForKey:kDefEmail] ?: @""; }
+ (NSString *)savedClientID { return [[NSUserDefaults standardUserDefaults] stringForKey:kDefClientID] ?: @""; }
+ (NSString *)savedProjectID { return [[NSUserDefaults standardUserDefaults] stringForKey:kDefProjectID] ?: @""; }
+ (BOOL)prefersGoogle { return [[NSUserDefaults standardUserDefaults] boolForKey:kDefPrefer]; }

+ (void)setPrefersGoogle:(BOOL)prefers {
    [[NSUserDefaults standardUserDefaults] setBool:prefers forKey:kDefPrefer];
}

+ (BOOL)isValidClientID:(NSString *)clientID {
    NSString *id_ = Trimmed(clientID);
    if (![id_ hasSuffix:kClientSuffix]) return NO;
    NSString *prefix = [id_ substringToIndex:id_.length - kClientSuffix.length];
    if (prefix.length < 3) return NO;
    NSCharacterSet *bad = [[NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"] invertedSet];
    return [prefix rangeOfCharacterFromSet:bad].location == NSNotFound;
}

+ (NSString *)redirectSchemeForClientID:(NSString *)clientID {
    NSString *prefix = [clientID substringToIndex:clientID.length - kClientSuffix.length];
    return [@"com.googleusercontent.apps." stringByAppendingString:prefix];
}

#pragma mark - Sign in

+ (void)signInWithClientID:(NSString *)clientID
                 projectID:(NSString *)projectID
                 presenter:(UIViewController *)presenter
                completion:(void (^)(BOOL, NSString *))completion {
    clientID = Trimmed(clientID);
    projectID = Trimmed(projectID);
    if (![self isValidClientID:clientID]) {
        completion(NO, L(@"google_err_client_id"));
        return;
    }
    if (gSession) {   // a sign-in page is already open
        completion(NO, nil);
        return;
    }

    NSString *verifier = RandomURLSafe(48);
    NSString *challenge = ({
        NSData *vData = [verifier dataUsingEncoding:NSUTF8StringEncoding];
        uint8_t digest[CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(vData.bytes, (CC_LONG)vData.length, digest);
        Base64URL([NSData dataWithBytes:digest length:CC_SHA256_DIGEST_LENGTH]);
    });
    NSString *state = RandomURLSafe(18);
    NSString *scheme = [self redirectSchemeForClientID:clientID];
    NSString *redirect = [scheme stringByAppendingString:@":/oauth2redirect"];

    NSURLComponents *components = [NSURLComponents componentsWithString:kAuthEndpoint];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"client_id" value:clientID],
        [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirect],
        [NSURLQueryItem queryItemWithName:@"response_type" value:@"code"],
        [NSURLQueryItem queryItemWithName:@"scope" value:kScopes],
        [NSURLQueryItem queryItemWithName:@"code_challenge" value:challenge],
        [NSURLQueryItem queryItemWithName:@"code_challenge_method" value:@"S256"],
        [NSURLQueryItem queryItemWithName:@"state" value:state],
        [NSURLQueryItem queryItemWithName:@"access_type" value:@"offline"],
        [NSURLQueryItem queryItemWithName:@"prompt" value:@"consent"]   // makes Google return a refresh token every time
    ];

    ASWebAuthenticationSession *session =
        [[ASWebAuthenticationSession alloc] initWithURL:components.URL
                                      callbackURLScheme:scheme
                                      completionHandler:^(NSURL *callbackURL, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            gSession = nil;
            gPresenter = nil;
            if (error != nil || callbackURL == nil) {
                BOOL closed = (error.code == ASWebAuthenticationSessionErrorCodeCanceledLogin);
                [DiagnosticLog log:@"google sign-in ended: %@ [%ld]", error.domain ?: @"-", (long)error.code];
                completion(NO, closed ? nil : L(@"google_err_start"));
                return;
            }
            NSURLComponents *back = [NSURLComponents componentsWithURL:callbackURL resolvingAgainstBaseURL:NO];
            NSString *code = nil, *returnedState = nil, *oauthError = nil;
            for (NSURLQueryItem *item in back.queryItems) {
                if ([item.name isEqualToString:@"code"]) code = item.value;
                else if ([item.name isEqualToString:@"state"]) returnedState = item.value;
                else if ([item.name isEqualToString:@"error"]) oauthError = item.value;
            }
            if (oauthError.length > 0) {
                completion(NO, [NSString stringWithFormat:L(@"google_err_exchange"), oauthError]);
                return;
            }
            if (code.length == 0 || ![returnedState isEqualToString:state]) {
                completion(NO, L(@"google_err_state"));
                return;
            }
            [self exchangeCode:code verifier:verifier clientID:clientID redirect:redirect
                     projectID:projectID completion:completion];
        });
    }];

    if (@available(iOS 13.0, *)) {
        GoogleAuthPresenter *provider = [[GoogleAuthPresenter alloc] init];
        provider.window = presenter.view.window;
        gPresenter = provider;
        session.presentationContextProvider = provider;
        session.prefersEphemeralWebBrowserSession = NO;
    }
    gSession = session;
    if (![session start]) {
        gSession = nil;
        gPresenter = nil;
        completion(NO, L(@"google_err_start"));
    }
}

+ (void)exchangeCode:(NSString *)code
            verifier:(NSString *)verifier
            clientID:(NSString *)clientID
            redirect:(NSString *)redirect
           projectID:(NSString *)projectID
          completion:(void (^)(BOOL, NSString *))completion {
    NSMutableURLRequest *request = FormPost(kTokenEndpoint, @{
        @"client_id": clientID,
        @"code": code,
        @"code_verifier": verifier,
        @"redirect_uri": redirect,
        @"grant_type": @"authorization_code"
    });
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != nil) { completion(NO, L(@"google_err_network")); return; }
            id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSDictionary *body = [json isKindOfClass:[NSDictionary class]] ? json : @{};
            NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
            NSString *access = [body[@"access_token"] isKindOfClass:[NSString class]] ? body[@"access_token"] : nil;
            if (status != 200 || access.length == 0) {
                NSString *why = body[@"error_description"] ?: body[@"error"] ?: [NSString stringWithFormat:@"HTTP %ld", (long)status];
                [DiagnosticLog log:@"google token exchange failed: http=%ld", (long)status];
                completion(NO, [NSString stringWithFormat:L(@"google_err_exchange"), why]);
                return;
            }
            NSString *refresh = [body[@"refresh_token"] isKindOfClass:[NSString class]] ? body[@"refresh_token"] : nil;
            if (refresh.length == 0) { completion(NO, L(@"google_err_no_refresh")); return; }

            if (![KeyStore saveSecret:refresh named:kRefreshSecret]) { completion(NO, L(@"status_save_failed")); return; }
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:clientID forKey:kDefClientID];
            [defaults setObject:projectID forKey:kDefProjectID];
            [defaults setObject:EmailFromIDToken(body[@"id_token"]) forKey:kDefEmail];
            [defaults setBool:YES forKey:kDefSignedIn];
            [defaults setBool:YES forKey:kDefPrefer];
            [defaults synchronize];

            double lifetime = [body[@"expires_in"] respondsToSelector:@selector(doubleValue)] ? [body[@"expires_in"] doubleValue] : 3600;
            gAccessToken = access;
            gAccessExpiry = [NSDate dateWithTimeIntervalSinceNow:MAX(60.0, lifetime)];
            [KeyTier invalidateGeminiDetection];
            [DiagnosticLog log:@"google sign-in OK"];
            completion(YES, nil);
        });
    }] resume];
}

#pragma mark - Sign out

+ (void)signOut {
    NSString *refresh = [KeyStore loadSecretNamed:kRefreshSecret];
    if (refresh.length > 0) {
        NSMutableURLRequest *request = FormPost(kRevokeEndpoint, @{ @"token": refresh });
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {}] resume];
    }
    [self forgetSession];
}

// Drops everything about the session on this device. The client ID and project ID stay so signing in again is quick.
+ (void)forgetSession {
    [KeyStore deleteSecretNamed:kRefreshSecret];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:NO forKey:kDefSignedIn];
    [defaults setBool:NO forKey:kDefPrefer];
    [defaults removeObjectForKey:kDefEmail];
    [defaults synchronize];
    dispatch_async(dispatch_get_main_queue(), ^{
        gAccessToken = nil;
        gAccessExpiry = nil;
    });
    [KeyTier invalidateGeminiDetection];
}

#pragma mark - Access token

+ (void)accessTokenWithCompletion:(void (^)(NSString *, NSError *))completion {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{ [self accessTokenWithCompletion:completion]; });
        return;
    }
    if (gAccessToken.length > 0 && gAccessExpiry.timeIntervalSinceNow > 90) {
        completion(gAccessToken, nil);
        return;
    }
    if (!gWaiters) gWaiters = [NSMutableArray array];
    [gWaiters addObject:[completion copy]];
    if (gRefreshing) return;
    gRefreshing = YES;
    [self refreshAttempt:0];
}

+ (void)finishRefreshWithToken:(NSString *)token error:(NSError *)error {
    gRefreshing = NO;
    NSArray *waiters = [gWaiters copy];
    [gWaiters removeAllObjects];
    for (void (^block)(NSString *, NSError *) in waiters) block(token, error);
}

+ (void)refreshAttempt:(NSInteger)attempt {
    NSString *refresh = [KeyStore loadSecretNamed:kRefreshSecret];
    NSString *clientID = [self savedClientID];
    if (![self isSignedIn] || refresh.length == 0 || clientID.length == 0) {
        [self finishRefreshWithToken:nil error:AuthError(GoogleAuthErrorSignInRequired, L(@"google_err_expired"))];
        return;
    }
    NSMutableURLRequest *request = FormPost(kTokenEndpoint, @{
        @"client_id": clientID,
        @"refresh_token": refresh,
        @"grant_type": @"refresh_token"
    });
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error != nil) {
                if (attempt < 1) {   // one quick retry for a network blip
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [self refreshAttempt:attempt + 1];
                    });
                    return;
                }
                [self finishRefreshWithToken:nil error:AuthError(GoogleAuthErrorNetwork, L(@"google_err_network"))];
                return;
            }
            NSInteger status = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 0;
            id json = data.length ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
            NSDictionary *body = [json isKindOfClass:[NSDictionary class]] ? json : @{};
            NSString *access = [body[@"access_token"] isKindOfClass:[NSString class]] ? body[@"access_token"] : nil;

            if (status == 200 && access.length > 0) {
                double lifetime = [body[@"expires_in"] respondsToSelector:@selector(doubleValue)] ? [body[@"expires_in"] doubleValue] : 3600;
                gAccessToken = access;
                gAccessExpiry = [NSDate dateWithTimeIntervalSinceNow:MAX(60.0, lifetime)];
                [self finishRefreshWithToken:access error:nil];
                return;
            }
            NSString *code = [body[@"error"] isKindOfClass:[NSString class]] ? body[@"error"] : @"";
            [DiagnosticLog log:@"google token refresh failed: http=%ld error=%@", (long)status, code];
            if (status == 400 || status == 401) {
                // invalid_grant = expired (7 days for an app still in "Testing") or revoked: a new sign-in is needed.
                // The session stays listed (with its client ID) so the person can sign in again from the key screen
                // without the chat being thrown away.
                [self finishRefreshWithToken:nil error:AuthError(GoogleAuthErrorSignInRequired, L(@"google_err_expired"))];
            } else {
                [self finishRefreshWithToken:nil error:AuthError(GoogleAuthErrorNetwork, L(@"google_err_network"))];
            }
        });
    }] resume];
}

#pragma mark - Requests

+ (void)authorizeRequest:(NSMutableURLRequest *)request key:(NSString *)key completion:(void (^)(NSError *))completion {
    if (![key isEqualToString:kGoogleOAuthKeyMarker]) {
        [request setValue:nil forHTTPHeaderField:@"Authorization"];
        [request setValue:nil forHTTPHeaderField:@"x-goog-user-project"];
        [request setValue:key forHTTPHeaderField:@"x-goog-api-key"];
        completion(nil);
        return;
    }
    [self accessTokenWithCompletion:^(NSString *token, NSError *error) {
        if (token.length == 0) { completion(error ?: AuthError(GoogleAuthErrorSignInRequired, L(@"google_err_expired"))); return; }
        [request setValue:nil forHTTPHeaderField:@"x-goog-api-key"];
        [request setValue:[@"Bearer " stringByAppendingString:token] forHTTPHeaderField:@"Authorization"];
        NSString *project = [self savedProjectID];
        if (project.length > 0) [request setValue:project forHTTPHeaderField:@"x-goog-user-project"];
        completion(nil);
    }];
}

+ (NSString *)messageForError:(NSError *)error {
    if ([error.domain isEqualToString:GoogleAuthErrorDomain]) {
        if (error.code == GoogleAuthErrorSignInRequired) return L(@"google_err_expired");
        if (error.code == GoogleAuthErrorNetwork) return L(@"google_err_network");
    }
    return error.localizedDescription ?: L(@"google_err_network");
}

@end
