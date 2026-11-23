#import "StreamWatchdog.h"
#import <UIKit/UIKit.h>

// How long a stream that was open when the app went to the background may stay silent after coming back.
static const NSTimeInterval kResumeGraceMidStream = 12.0;
static const NSTimeInterval kResumeGraceBeforeData = 30.0;
static const NSTimeInterval kTickSeconds = 2.0;

@interface StreamWatchdog ()
@property (strong, nonatomic) dispatch_source_t timer;
@property (assign, nonatomic) CFAbsoluteTime lastEvent;
@property (assign, nonatomic) BOOL wentToBackground;
@property (assign, nonatomic) NSTimeInterval graceLimit;   // 0 = use idleLimit
@property (assign, nonatomic) BOOL running;
@property (assign, nonatomic) BOOL fired;
@end

@implementation StreamWatchdog

- (instancetype)init {
    self = [super init];
    if (self) _idleLimit = 60;
    return self;
}

- (void)dealloc {
    [self stop];
}

- (void)start {
    if (self.running) return;
    self.running = YES;
    self.fired = NO;
    self.graceLimit = 0;
    self.wentToBackground = NO;
    self.lastEvent = CFAbsoluteTimeGetCurrent();

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(didBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];

    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTickSeconds * NSEC_PER_SEC)),
                              (uint64_t)(kTickSeconds * NSEC_PER_SEC), (uint64_t)(0.5 * NSEC_PER_SEC));
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{ [weakSelf tick]; });
    self.timer = timer;
    dispatch_resume(timer);
}

- (void)touch {
    self.lastEvent = CFAbsoluteTimeGetCurrent();
    self.graceLimit = 0;   // data is flowing again: back to the normal limit
}

- (void)stop {
    if (!self.running) return;
    self.running = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
}

- (void)didEnterBackground {
    self.wentToBackground = YES;
}

- (void)didBecomeActive {
    if (!self.wentToBackground) return;   // e.g. only the notification shade was pulled down: the connection is fine
    self.wentToBackground = NO;
    self.lastEvent = CFAbsoluteTimeGetCurrent();
    // Short window to hear from the server again; a live stream sends something within it.
    self.graceLimit = (self.idleLimit <= 60) ? kResumeGraceMidStream : kResumeGraceBeforeData;
}

- (void)tick {
    if (!self.running || self.fired) return;
    NSTimeInterval limit = self.graceLimit > 0 ? MIN(self.graceLimit, self.idleLimit) : self.idleLimit;
    if (CFAbsoluteTimeGetCurrent() - self.lastEvent < limit) return;
    self.fired = YES;
    void (^handler)(void) = self.onStall;
    [self stop];
    if (handler) handler();
}

@end
