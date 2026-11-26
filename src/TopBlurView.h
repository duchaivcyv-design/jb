#import <UIKit/UIKit.h>

// The see-through top bar: the page runs under the navigation bar and what is behind it is blurred progressively, strong
// at the top edge and fading away downwards (no colour band, only blur). The glass round buttons for the bar sit here too.

// Switches off the colour wash of a blur view so that only the blur stays.
FOUNDATION_EXPORT void TopBlurStripTint(UIVisualEffectView *view);

@interface TopBlurView : UIView
- (void)refreshStyle;   // after the light/dark mode changed
@end

// A round frosted-glass button (blur + a thin light edge), the look of the back button of the reference design.
@interface GlassBarButton : UIControl
+ (instancetype)buttonWithIcon:(UIImage *)icon label:(NSString *)label target:(id)target action:(SEL)action;
- (void)refresh;
@end
