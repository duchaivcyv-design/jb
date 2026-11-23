#import <UIKit/UIKit.h>

// A list of choices in the ClaudeMini pop-up style (rounded card, dimmed background, accent buttons), used in place of the
// iOS action sheets. It is built like UIAlertController: add actions, then present. Tapping outside the card cancels.
@interface ChoiceAction : NSObject
+ (instancetype)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(id action))handler;
@end

@interface ChoicePopupViewController : UIViewController <UIGestureRecognizerDelegate, UITextFieldDelegate>
// A list of choices (replaces an action sheet).
+ (instancetype)popupWithTitle:(NSString *)title message:(NSString *)message;
// A message with buttons and, if you like, text fields (replaces an alert): the buttons sit at the bottom of the card,
// the cancel action is the outlined one. Read the text fields from -textFields inside a handler.
+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message;
- (void)addTextFieldWithConfigurationHandler:(void (^)(UITextField *field))configure;
@property (strong, nonatomic, readonly) NSMutableArray<UITextField *> *textFields;
- (void)addAction:(ChoiceAction *)action;
- (void)presentFromViewController:(UIViewController *)host;
@end
