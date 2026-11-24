#import <UIKit/UIKit.h>

// "Sign in with Google" for Gemini, as an alternative to a pasted API key.
//
// How it works: OAuth 2.0 authorization-code flow with PKCE, run in the system web-auth sheet
// (ASWebAuthenticationSession). The person supplies their OWN OAuth client ID (type "iOS") from a Google Cloud
// project that has the Generative Language API enabled; no client secret is needed or stored. The refresh token is
// kept like the API keys (Keychain, with a 0600 file fallback). Requests then carry "Authorization: Bearer <token>"
// (and, if a Project ID was given, "x-goog-user-project") instead of the x-goog-api-key header.
//
// KeyStore hands the Gemini code a marker string (kGoogleOAuthKeyMarker) in place of a key while Google sign-in is the
// active method, so every existing "has a key / load the key" call keeps working. Anything that builds a Gemini request
// calls +authorizeRequest:key:completion: instead of setting the key header itself.

extern NSString *const kGoogleOAuthKeyMarker;
extern NSString *const GoogleAuthErrorDomain;

typedef NS_ENUM(NSInteger, GoogleAuthErrorCode) {
    GoogleAuthErrorSignInRequired = 1,   // no session, or Google rejected the refresh token (expired / revoked)
    GoogleAuthErrorNetwork = 2           // could not reach Google; the session itself may still be fine
};

@interface GoogleAuth : NSObject

// State (cheap: reads NSUserDefaults only).
+ (BOOL)isSignedIn;
+ (NSString *)accountEmail;          // may be empty
+ (NSString *)builtInClientID;      // client ID compiled into the app (empty = ask the person to paste one)
+ (NSString *)savedClientID;       // the pasted/last used one, else the built-in one
+ (NSString *)savedProjectID;
+ (BOOL)prefersGoogle;               // when a pasted API key AND a Google session both exist, which one is used
+ (void)setPrefersGoogle:(BOOL)prefers;
+ (BOOL)isValidClientID:(NSString *)clientID;

// Opens the Google sign-in page. `message` is nil when the person just closed the page (no error to show).
+ (void)signInWithClientID:(NSString *)clientID
                 projectID:(NSString *)projectID
                 presenter:(UIViewController *)presenter
                completion:(void (^)(BOOL ok, NSString *message))completion;

// Forgets the session on this device (and asks Google to revoke the refresh token, best effort).
+ (void)signOut;
// Drops the cached access token so the next request fetches a new one (used when Google answers 401/403).
+ (void)discardAccessToken;

// A valid access token, refreshed when needed. Completion runs on the main queue; error is non-nil when token is nil.
+ (void)accessTokenWithCompletion:(void (^)(NSString *token, NSError *error))completion;

// Puts the right credential on a Gemini request: the API key header for a normal key, or the Bearer token (+ project
// header) when `key` is kGoogleOAuthKeyMarker. For a normal key the completion runs immediately on the calling
// thread; for Google sign-in it runs on the main queue. `error` is nil on success.
+ (void)authorizeRequest:(NSMutableURLRequest *)request key:(NSString *)key completion:(void (^)(NSError *error))completion;

// Text for an auth error, in the app language.
+ (NSString *)messageForError:(NSError *)error;

@end
