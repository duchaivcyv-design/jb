#import <Foundation/Foundation.h>
#import "Provider.h"

// Stores the user's own API keys (one per provider) on this device only.
// Primary storage: Keychain. If the Keychain refuses (it can on some jailbreak setups when the app is only
// pseudo-signed), falls back to a 0600 file in Application Support.
@interface KeyStore : NSObject

+ (NSString *)loadKeyForProvider:(AIProvider)provider;      // nil if none
+ (BOOL)saveKey:(NSString *)key forProvider:(AIProvider)provider;
+ (void)deleteKeyForProvider:(AIProvider)provider;
+ (BOOL)hasKeyForProvider:(AIProvider)provider;
+ (BOOL)hasAnyKey;

// Gemini can use a Google account instead of an API key. This is the person's choice. It only takes effect
// while the Google sign-in is still valid; otherwise the saved API key is used.
+ (BOOL)geminiUsesGoogleSignIn;
+ (void)setGeminiUsesGoogleSignIn:(BOOL)useGoogle;

// Like loadKeyForProvider, but refreshes a Google access token first. BLOCKS: call it only from a background queue.
+ (NSString *)freshKeyForProvider:(AIProvider)provider;

// Puts the Gemini credential on a request: an API key goes in x-goog-api-key, a Google token as a Bearer header.
+ (void)applyGeminiCredential:(NSString *)credential toRequest:(NSMutableURLRequest *)request;

@end
