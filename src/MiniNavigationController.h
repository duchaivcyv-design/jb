#import <UIKit/UIKit.h>

// A screen can opt out of the edge-swipe "back" (the history list closes with its own animation).
@protocol MiniBackSwipeControl <NSObject>
@optional
- (BOOL)allowsBackSwipe;
@end

// The app's navigation controller. It makes "back" dependable:
//  - every pushed screen gets its own plain back button (a normal bar button, not the system back item that
//    can stop responding after the bar is restyled),
//  - the edge-swipe can only start when there is a screen to go back to and no transition is running,
//  - a push that arrives in the middle of another transition is not animated (UIKit would drop or corrupt it),
//  - if a transition is ever left half-finished, the bar and the gesture are reset when the next screen shows.
@interface MiniNavigationController : UINavigationController <UINavigationControllerDelegate, UIGestureRecognizerDelegate>
- (void)restyleBarWhenIdle;   // applies Theme's bar style now, or right after the running transition
@end
