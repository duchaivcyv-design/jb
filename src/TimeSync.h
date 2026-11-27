#import <Foundation/Foundation.h>

// The current time, taken from the internet instead of trusting the phone's clock alone: the answer to "what year is it"
// must not depend on a clock that was set wrong. A few HTTPS servers are asked for their Date header; the difference to the
// phone's clock is remembered and applied to every later +now. Until the first answer arrives (or if there is none, for
// instance offline) +now is simply the phone's clock.
@interface TimeSync : NSObject
+ (NSDate *)now;                    // the synced time, read fresh on every call
+ (BOOL)isSynced;
+ (NSTimeInterval)offset;           // seconds added to the phone's clock
+ (void)refresh;                    // asks the internet again when the last answer is older than 10 minutes
+ (void)refreshForce:(BOOL)force;
@end
