#import <UIKit/UIKit.h>

// Parts of the Material 3 message box (see ChatViewController): the model pill whose name rolls over when the model
// changes, the send button whose arrow turns into a stop square, and the thin light that runs round the box while a
// reply is being written.

#pragma mark - Model pill

@interface ComposerModelPill : UIControl
@property (strong, nonatomic) UIColor *textColor;
// The width the pill wants for its title (label + chevron + padding), at most `maxWidth`.
- (CGFloat)preferredWidthWithMax:(CGFloat)maxWidth;
// Changes the name; animated = the old name rolls up and out while the new one rolls in from below and the pill resizes.
- (void)setTitle:(NSString *)title animated:(BOOL)animated;
@property (copy, nonatomic, readonly) NSString *title;
@property (assign, nonatomic, readonly, getter=isRolling) BOOL rolling;   // a name change is animating
@end

#pragma mark - Send button

@interface ComposerSendButton : UIButton
@property (assign, nonatomic) BOOL materialStyle;   // YES: filled circle with a drawn arrow / stop square; NO: plain image button
// ready = there is something to send. generating = a reply is being written (the arrow becomes a stop square).
- (void)applyReady:(BOOL)ready generating:(BOOL)generating animated:(BOOL)animated;
- (void)bump:(CGFloat)depth;   // little squash and rebound (depth 0.82...0.9)
@end

#pragma mark - Running light

@interface ComposerGlowView : UIView
@property (assign, nonatomic) CGFloat cornerRadiusValue;
- (void)setActive:(BOOL)active animated:(BOOL)animated;
- (void)refreshColors;
@end
