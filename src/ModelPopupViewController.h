#import <UIKit/UIKit.h>

// A small card over the chat that lists the few best models for the user's key(s).
// "Thêm model khác…" opens the full list. Nothing is pushed: it appears and disappears over the chat.
@interface ModelPopupViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate>
- (instancetype)initWithSelectedModel:(NSString *)modelId intro:(BOOL)intro;   // intro = shown right after a new key was recognised
@property (copy, nonatomic) void (^onSelect)(NSString *modelId);
@property (copy, nonatomic) void (^onMore)(void);
@end
