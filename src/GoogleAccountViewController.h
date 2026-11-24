#import <UIKit/UIKit.h>

// The "Google account" entry of the settings screen: a card with the Claude mark inside a ring of blue dots (as the
// account card of the system settings), and the screen it opens (sign in, check, sign out, use an API key instead).

#pragma mark - Ring of dots around a logo

@interface GoogleRingView : UIView
- (void)startSpinning;   // two dotted rings turn slowly in opposite directions; still under Reduce Motion
@end

#pragma mark - Card at the top of the settings list

@interface GoogleAccountCardView : UIControl
- (void)refresh;   // title and description follow the sign-in state
@end

#pragma mark - Account screen

@interface GoogleAccountViewController : UIViewController
@end
