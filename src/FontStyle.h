#import <UIKit/UIKit.h>

// Global font look. Every [UIFont systemFontOfSize:...] in the app goes through here: with the "SF Rounded" choice the
// rounded design of the system font is returned (iOS 13+; iOS 12 has no rounded system font and keeps the normal one),
// and the weight chosen in Settings (-3...+3) is added to whatever weight the screen asked for.
@interface UIFont (ClaudeMiniStyle)
@end

// "ui-rounded, ..." / "-apple-system, ..." stack for the web view, and the numeric CSS weight for the chosen step.
NSString *CMWebFontStack(void);
NSInteger CMWebFontWeight(void);

// @font-face rules for iOS 12 (no ui-rounded there); empty on iOS 13+.
NSString *CMRoundedFontFaceCSS(void);
