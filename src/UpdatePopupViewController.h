#import <UIKit/UIKit.h>

// The update card (same look as the model and confirmation pop-ups): shows the state kept by UpdateManager —
// checking, up to date, new version found, downloading with a progress bar, downloaded, error — and the buttons for it.
@interface UpdatePopupViewController : UIViewController <UIGestureRecognizerDelegate>
@end
