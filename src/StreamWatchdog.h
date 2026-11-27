#import <Foundation/Foundation.h>

// Detects a reply stream that has gone silent (dead connection, Wi-Fi/cellular switch, app suspended in the background)
// so the chat does not sit on "thinking" until the URL loading system's long timeout finally fires.
//
// The owner calls -touch on every response/data event. When no event arrives for `idleLimit` seconds the watchdog calls
// `onStall` once (on the main queue). After the app comes back from the background the limit is temporarily shortened,
// because a socket that was open before the suspension is very often dead afterwards.
@interface StreamWatchdog : NSObject

@property (assign, nonatomic) NSTimeInterval idleLimit;   // seconds of silence allowed (changeable while running)
@property (copy, nonatomic) void (^onStall)(void);

- (void)start;
- (void)touch;
- (void)stop;

@end
