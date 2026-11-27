#import "Loc.h"

static NSString *const kLanguagePreferenceKey = @"appLanguage";

@implementation Loc

+ (NSString *)preference {
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:kLanguagePreferenceKey];
    return ([value isEqualToString:@"vi"] || [value isEqualToString:@"en"]) ? value : @"auto";
}

+ (void)setPreference:(NSString *)preference {
    if ([preference isEqualToString:@"vi"] || [preference isEqualToString:@"en"]) {
        [[NSUserDefaults standardUserDefaults] setObject:preference forKey:kLanguagePreferenceKey];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kLanguagePreferenceKey];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSBundle *)bundle {
    NSString *preference = [self preference];
    if ([preference isEqualToString:@"auto"]) return [NSBundle mainBundle];   // the system picks the best match
    NSString *path = [[NSBundle mainBundle] pathForResource:preference ofType:@"lproj"];
    NSBundle *bundle = path ? [NSBundle bundleWithPath:path] : nil;
    return bundle ?: [NSBundle mainBundle];
}

+ (NSString *)string:(NSString *)key {
    return [[self bundle] localizedStringForKey:key value:key table:nil];
}

@end
