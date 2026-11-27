#import <UIKit/UIKit.h>

// Lets the user pick a Gemini model from the live list available to their key.
@interface ModelPickerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (instancetype)initWithSelectedModel:(NSString *)modelId;
@property (copy, nonatomic) void (^onSelect)(NSString *modelId);

// The instructions of the open conversation (empty = it uses the general ones). The first row of the screen edits them.
@property (copy, nonatomic) NSString *chatPrompt;
@property (copy, nonatomic) void (^onChatPromptChange)(NSString *text);
@end
