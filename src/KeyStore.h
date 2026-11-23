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

@end
