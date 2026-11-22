#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Sign in with a Google account (OAuth 2.0, PKCE) as an alternative to a Gemini API key.
//
// The build needs an iOS OAuth client ID from Google Cloud. It is set at build time through the
// GOOGLE_OAUTH_CLIENT_ID environment variable (see build.sh); without it, the sign-in button stays hidden.
// Tokens are stored in the Keychain (the refresh token) and never written to logs.

extern NSString *const GoogleAuthErrorDomain;

typedef NS_ENUM(NSInteger, GoogleAuthErrorCode) {
    GoogleAuthErrorNotConfigured = 1,
    GoogleAuthErrorCancelled,
    GoogleAuthErrorStateMismatch,
    GoogleAuthErrorDenied,        // the person refused access, or Google returned an error
    GoogleAuthErrorNoToken,       // Google did not return the tokens we need
    GoogleAuthErrorNetwork,
    GoogleAuthErrorRevoked        // the stored sign-in was revoked; the person must sign in again
};

@interface GoogleAuth : NSObject

+ (BOOL)isConfigured;                 // this build has a client ID
+ (BOOL)isSignedIn;                   // a refresh token is stored on this device
+ (NSString *)accountEmail;           // email of the signed-in account, if Google told us

// Opens the Google sign-in page. Calls back on the main queue. Does not switch Gemini to Google by itself
// when it fails. On success the Gemini credential is switched to the Google account.
+ (void)signInFromViewController:(UIViewController *)presenter completion:(void (^)(NSError *error))completion;

// Removes the stored tokens and switches Gemini back to the API key (if one is saved).
+ (void)signOut;

// Last known access token, without waiting for the network. Starts a background refresh when the token is
// missing or about to expire. May return nil right after a fresh install.
+ (NSString *)accessTokenNonBlocking;

// A valid access token, refreshing it first if needed. It BLOCKS the calling thread for up to ~20 seconds,
// so call it only from a background queue. On the main thread it behaves like accessTokenNonBlocking.
+ (NSString *)accessTokenBlocking;

// Call on launch and whenever the app comes back to the foreground, so the token is fresh before it is needed.
+ (void)refreshIfNeeded;

@end
