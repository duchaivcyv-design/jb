#import <Foundation/Foundation.h>

// Localized strings with an in-app language choice: "auto" (follow the device), "vi" or "en".
@interface Loc : NSObject
+ (NSString *)string:(NSString *)key;
+ (NSString *)preference;                 // @"auto" | @"vi" | @"en"
+ (void)setPreference:(NSString *)preference;
@end
