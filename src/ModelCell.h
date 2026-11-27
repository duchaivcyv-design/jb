#import <UIKit/UIKit.h>

// One model row, shared by the model pop-up and the full model list: round badge, friendly name,
// a small tag ("Nhẹ & nhanh", "Mạnh nhất"...), the technical id, and a check mark for the chosen one.
@interface ModelCell : UITableViewCell
+ (CGFloat)rowHeight;
- (void)configureWithModel:(NSDictionary *)model selected:(BOOL)selected;
@end
