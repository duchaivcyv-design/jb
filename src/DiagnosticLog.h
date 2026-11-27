#import <Foundation/Foundation.h>

// A small text log kept on this device, so a problem can be reported with real facts instead of guesses.
// It records events and error codes only: never API keys, never message text, never file names.
@interface DiagnosticLog : NSObject

+ (void)log:(NSString *)format, ... NS_FORMAT_FUNCTION(1, 2);
+ (void)logLaunch;                    // app version, iOS version, device model, language
+ (NSString *)contents;               // the whole log ("" when empty)
+ (void)clear;

@end
