#import <UIKit/UIKit.h>

// Full-screen photo with pinch zoom and double-tap zoom. Tap once, or press the close button, to dismiss.
@interface ImageViewerViewController : UIViewController <UIScrollViewDelegate>
- (instancetype)initWithImagePath:(NSString *)path;
@end
