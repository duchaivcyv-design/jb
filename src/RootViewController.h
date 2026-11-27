#import <UIKit/UIKit.h>
#import "Provider.h"

// Enter / verify / save / delete the user's own Gemini API key.
// Used at first launch (onboarding) and, with embedded = YES, from Settings.
@interface RootViewController : UIViewController <UITextFieldDelegate>
@property (assign, nonatomic) BOOL embedded;
// Which provider's key this screen edits. At first launch (embedded = NO) the person picks it with a switch at the top.
@property (assign, nonatomic) AIProvider provider;
@end
