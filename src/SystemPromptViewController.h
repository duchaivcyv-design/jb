#import <UIKit/UIKit.h>

// Edits the instructions sent to the model with every message (the "system prompt"). Saved automatically.
@interface SystemPromptViewController : UIViewController <UITextViewDelegate>

// Per-conversation mode: edits `initialText` and reports the result through onSave (an empty string means
// "use the general instructions"). When perConversation is NO (the default) it edits the general instructions.
@property (assign, nonatomic) BOOL perConversation;
@property (copy, nonatomic) NSString *initialText;
@property (copy, nonatomic) void (^onSave)(NSString *text);

// Puts the text of an instruction file (.clmn or .txt) into the editor (asks to replace or add when there is text already).
- (void)importFromURL:(NSURL *)url;

@end
