#import <UIKit/UIKit.h>

// Settings > Appearance. The first page has light / dark and three entries; each entry opens its own page:
// App icon (light or dark pictures), Chat theme (wallpaper), Accent colour (the skins) and iPhone Duo (two-pane layout).
typedef NS_ENUM(NSInteger, AppearancePage) {
    AppearancePageRoot = 0,
    AppearancePageIcon,
    AppearancePageChatTheme,
    AppearancePageAccent,
    AppearancePageDuo
};

@interface AppearanceViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
- (instancetype)initWithPage:(AppearancePage)page;
@end
