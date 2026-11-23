#import <Foundation/Foundation.h>
#import "Provider.h"

// Stores the user's own API keys (one per provider) on this device only.
// Primary storage: Keychain. If the Keychain refuses (it can on some jailbreak setups when the app is only
// pseudo-signed), falls back to a 0600 file in Application Support.
@interface KeyStore : NSObject

// The credential the app uses for this provider. For Gemini it is kGoogleOAuthKeyMarker (see GoogleAuth.h) while a
// Google sign-in is the active method; otherwise the pasted API key. nil if none.
+ (NSString *)loadKeyForProvider:(AIProvider)provider;
// Only the pasted API key (never the Google marker). Used by the key-entry screen.
+ (NSString *)loadRawKeyForProvider:(AIProvider)provider;
+ (BOOL)geminiUsesGoogleAccount;
+ (BOOL)saveKey:(NSString *)key forProvider:(AIProvider)provider;
+ (void)deleteKeyForProvider:(AIProvider)provider;
+ (BOOL)hasKeyForProvider:(AIProvider)provider;
+ (BOOL)hasAnyKey;

// Small named secrets (e.g. the Google refresh token), stored the same way as the keys.
+ (NSString *)loadSecretNamed:(NSString *)name;
+ (BOOL)saveSecret:(NSString *)secret named:(NSString *)name;
+ (void)deleteSecretNamed:(NSString *)name;

@end
