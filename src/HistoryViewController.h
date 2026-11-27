#import <UIKit/UIKit.h>

// List of saved conversations with search, rename and delete.
@interface HistoryViewController : UIViewController
@property (copy, nonatomic) void (^onSelect)(NSString *conversationId);
@end
