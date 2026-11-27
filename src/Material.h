#import <UIKit/UIKit.h>

// Material 3 building blocks: tonal cards for list rows, section headers, switch, slider, the cookie-shaped mascot of
// the accent colour screen and the moving gradient used as chat wallpaper. Everything is drawn in code.

#pragma mark - Card behind a list row

@interface MaterialCardView : UIView
@property (strong, nonatomic) UIColor *fillColor;
@property (assign, nonatomic) CGFloat topRadius;
@property (assign, nonatomic) CGFloat bottomRadius;
@property (assign, nonatomic) UIEdgeInsets cardInsets;   // gap between the cards of two rows
- (void)setPressed:(BOOL)pressed animated:(BOOL)animated;   // Material 3 Expressive: the shape morphs to fully round and the card dips, with a spring
- (void)rippleFrom:(CGPoint)point;                          // ripple spreading from a touch point, clipped to the card
@end

#pragma mark - Switch (52 x 32, thumb grows when on)

@interface MaterialSwitch : UIControl
@property (assign, nonatomic, getter=isOn) BOOL on;
- (void)setOn:(BOOL)on animated:(BOOL)animated;
@end

#pragma mark - Slider with a gradient track and a big ring-shaped thumb (hue / saturation / brightness)

@interface MaterialSlider : UIControl
@property (assign, nonatomic) CGFloat value;                       // 0...1
@property (copy, nonatomic) NSArray<UIColor *> *trackColors;       // left to right
@property (strong, nonatomic) UIColor *thumbColor;
- (void)setValue:(CGFloat)value animated:(BOOL)animated;
@end

#pragma mark - Cookie-shaped mascot (the shape changes with the hue)

@interface MaterialMascotView : UIView
@property (strong, nonatomic) UIColor *shapeColor;
@property (assign, nonatomic) CGFloat hue;   // 0...1: picks the shape; the figure morphs to it
- (void)morphToNext;   // go to the next shape now (used on taps)
- (void)step:(CADisplayLink *)link;
@end

#pragma mark - Moving gradient made from the accent colour

@interface MaterialGradientView : UIView
- (void)refreshColors;   // read the colours from Theme again and (re)start the movement
@end

#pragma mark - Motion tokens (Material 3 / Expressive)

typedef NS_ENUM(NSInteger, MaterialMotionSpeed) { MaterialMotionFast, MaterialMotionDefault, MaterialMotionSlow };

// Durations in seconds (Material 3 duration tokens).
extern const NSTimeInterval MaterialDurationShort1;    // 0.05
extern const NSTimeInterval MaterialDurationShort2;    // 0.10
extern const NSTimeInterval MaterialDurationShort3;    // 0.15
extern const NSTimeInterval MaterialDurationShort4;    // 0.20
extern const NSTimeInterval MaterialDurationMedium1;   // 0.25
extern const NSTimeInterval MaterialDurationMedium2;   // 0.30
extern const NSTimeInterval MaterialDurationMedium4;   // 0.40
extern const NSTimeInterval MaterialDurationLong2;     // 0.50

#pragma mark - Helpers

@interface Material : NSObject
+ (BOOL)active;                                                    // Material 3 design is switched on
+ (UITableViewCellStyle)cellStyle:(UITableViewCellStyle)classic;   // Subtitle (text under the title) when active
+ (void)decorateTable:(UITableView *)table;                        // no separators, taller rows
+ (void)layoutTable:(UITableView *)table inBounds:(CGRect)bounds;  // side margins so the rows look like cards
+ (void)decorateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)table;
+ (CGFloat)classic:(CGFloat)classic material:(CGFloat)material;   // a size that is different in the two designs
+ (void)installTableEffects:(UITableView *)table;                // ripple under the finger on every row (Material only)
+ (void)installStretchOnScrollView:(UIScrollView *)scrollView;   // Material 3 stretch at the top and bottom instead of the rubber band (Material design only)
+ (void)markTableForEntrance:(UITableView *)table;               // the rows that show up in the next moment spring in one after another
+ (void)springAnimations:(void (^)(void))animations;             // the spatial spring of Material 3 Expressive (default speed)
// Springs of the Expressive scheme. Spatial = anything that moves, scales or changes shape (damping 0.6/0.8/0.8, stiffness 800/380/200);
// effects = colour and opacity (damping 1, stiffness 3800/1600/800). The duration is the time the spring needs to settle.
+ (void)animateSpatial:(MaterialMotionSpeed)speed animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (void)animateSpatial:(MaterialMotionSpeed)speed delay:(NSTimeInterval)delay animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (void)animateEffects:(MaterialMotionSpeed)speed animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (CASpringAnimation *)spatialSpringForKeyPath:(NSString *)keyPath from:(id)from to:(id)to speed:(MaterialMotionSpeed)speed;
+ (CASpringAnimation *)effectsSpringForKeyPath:(NSString *)keyPath from:(id)from to:(id)to speed:(MaterialMotionSpeed)speed;
// Easing curves of Material 3: entering things decelerate, leaving things accelerate.
+ (void)animateEmphasizedDecelerate:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (void)animateEmphasizedAccelerate:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (void)animateStandard:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;
+ (BOOL)reduceMotion;
// Dialog motion: the card scales up from 0.9 on the spatial spring and fades in on the effects spring; leaving, it shrinks
// to 0.94 and fades out in 150 ms with the emphasized accelerate curve. Does nothing outside Material 3.
+ (void)presentDialogCard:(UIView *)card;
+ (void)dismissDialogCard:(UIView *)card;
+ (CGFloat)headerHeight;
+ (UIView *)headerViewWithTitle:(NSString *)title collapsed:(BOOL)collapsed collapsible:(BOOL)collapsible tap:(void (^)(void))tap;
// Folds or unfolds a section with an animation (rows fade out / drop in, the chevron springs round).
+ (void)toggleSection:(NSInteger)section collapsed:(NSMutableSet<NSNumber *> *)collapsed inTable:(UITableView *)table header:(UIView *)header;
+ (void)styleTitleForController:(UIViewController *)controller;    // left-aligned bold title
+ (UIImage *)chevronImageRight;
+ (UIImage *)circleIconWithGlyph:(void (^)(CGContextRef ctx))glyph;   // 40 pt tonal circle; the glyph is drawn in a 30 x 30 box in the accent colour
@end

#define MR(c, m) [Material classic:(c) material:(m)]
