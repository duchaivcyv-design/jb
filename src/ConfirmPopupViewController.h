#import <UIKit/UIKit.h>

// A small confirmation card over the chat, styled like the model pop-up (rounded card, dimmed background,
// accent buttons). Used before starting a new chat. Tapping outside the card cancels.
@interface ConfirmPopupViewController : UIViewController <UIGestureRecognizerDelegate>
- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle;
@property (copy, nonatomic) void (^onConfirm)(void);
@end
