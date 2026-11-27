#import <UIKit/UIKit.h>

// Material 3 "gooey" attach menu: the + of the message box turns into an accent blob that stretches like a droplet and
// splits off into a fan of round buttons (and merges back into one when it closes). Based on the Lucian UX/UI element
// #460 (MIT). The necks between the blobs are metaball bridges drawn from the live positions of the blobs.

@interface GooFanItem : NSObject
@property (copy, nonatomic) NSString *title;      // accessibility label
@property (strong, nonatomic) UIImage *icon;      // template image
@property (assign, nonatomic) BOOL highlighted;   // drawn with a ring (e.g. web search is on)
@property (copy, nonatomic) void (^handler)(void);
+ (instancetype)itemWithTitle:(NSString *)title icon:(UIImage *)icon handler:(void (^)(void))handler;
@end

@interface GooFanView : UIView
// `anchor` is the centre of the + in this view's coordinates (the view normally covers the whole chat stage).
- (instancetype)initWithFrame:(CGRect)frame anchor:(CGPoint)anchor items:(NSArray<GooFanItem *> *)items;
@property (copy, nonatomic) void (^onClosed)(void);   // after the blobs are back in one (or at once without motion)
// Same, but the buttons open in a straight row at `rowY` (centre line, in this view's coordinates) starting right above the + and
// running along the message box; rowY <= 0 keeps the old fan.
- (instancetype)initWithFrame:(CGRect)frame anchor:(CGPoint)anchor rowY:(CGFloat)rowY items:(NSArray<GooFanItem *> *)items;
- (void)open;
- (void)closeWithCompletion:(void (^)(void))completion;
+ (UIImage *)glyph:(NSString *)name;   // photo, camera, file, search, dots, plus
@end
