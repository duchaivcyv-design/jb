#import "TopBlurView.h"
#import "Theme.h"
#import "Strings.h"

// A blur view normally paints a colour wash (the "tint" of the style) over the blurred picture. Only the blur is wanted, so
// the wash layers are switched off; the layer that really samples and blurs what is behind (the backdrop) and the content
// view stay. Called again after anything that may rebuild the layers.
void TopBlurStripTint(UIVisualEffectView *view) {
    for (UIView *sub in view.subviews) {
        if (sub == view.contentView) continue;
        NSString *name = NSStringFromClass([sub class]);
        if ([name rangeOfString:@"Backdrop"].location != NSNotFound) continue;
        sub.hidden = YES;
        sub.alpha = 0;
    }
}

static UIBlurEffect *CurrentBlur(void) {
    return [UIBlurEffect effectWithStyle:[Theme darkMode] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight];
}

#pragma mark - Progressive blur

// A real blur whose strength changes with the height: the bar is cut into thin strips, every strip is a live
// UIVisualEffectView, and the strength of its blur is set with a paused UIViewPropertyAnimator (fractionComplete 1 = the
// full blur of the style, 0 = none). The strongest strip is at the top edge and the strength goes down strip by strip.
// (No colour gradient and no mask: a mask over a blur view makes the blur disappear and leaves only a tint.)
static const NSInteger kStrips = 6;   // few strips: every strip is a live blur of what scrolls behind it, 28 of them made the app crawl

// The strength profile of the web design (PucBloxWeb "pbs"): five blurs of 4, 10, 20, 40 and 80 px, each solid down to a
// depth and fading out by a deeper one; the blurs add up (as variances), so the strongest sits at the top edge and the
// weakest one reaches the bottom. Returns 0...1 for a position 0 (top) ... 1 (bottom).
static CGFloat BlurStrengthAt(CGFloat p) {
    static const CGFloat r[5]  = {4, 10, 20, 40, 80};
    static const CGFloat m1[5] = {0.62, 0.52, 0.42, 0.32, 0.24};
    static const CGFloat m2[5] = {1.00, 0.86, 0.72, 0.58, 0.44};
    CGFloat sum = 0, top = 0;
    for (int k = 0; k < 5; k++) {
        CGFloat a = p <= m1[k] ? 1 : (p >= m2[k] ? 0 : (m2[k] - p) / (m2[k] - m1[k]));
        sum += r[k] * a * r[k] * a;
        top += r[k] * r[k];
    }
    return pow(sqrt(sum) / sqrt(top), 0.55);   // blur radius does not grow linearly with the animator fraction
}

@interface TopBlurView ()
@property (strong, nonatomic) NSMutableArray<UIVisualEffectView *> *strips;
@property (strong, nonatomic) NSMutableArray<UIViewPropertyAnimator *> *animators;
@property (assign, nonatomic) BOOL darkBuilt;
@end

@implementation TopBlurView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        _strips = [NSMutableArray array];
        _animators = [NSMutableArray array];
        // The blur of a view is reset by the system when the app comes back from the background: build it again.
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuild) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self tearDown];
}

- (void)tearDown {
    for (UIViewPropertyAnimator *animator in self.animators) [animator stopAnimation:YES];
    [self.animators removeAllObjects];
    for (UIView *strip in self.strips) [strip removeFromSuperview];
    [self.strips removeAllObjects];
}

- (void)rebuild {
    [self tearDown];
    if (self.bounds.size.height < 2) return;
    self.darkBuilt = [Theme darkMode];
    UIBlurEffect *blur = CurrentBlur();
    for (NSInteger i = 0; i < kStrips; i++) {
        UIVisualEffectView *strip = [[UIVisualEffectView alloc] initWithEffect:nil];
        [self addSubview:strip];
        [self.strips addObject:strip];
        __weak UIVisualEffectView *weakStrip = strip;
        UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:1 curve:UIViewAnimationCurveLinear animations:^{
            weakStrip.effect = blur;
        }];
        animator.pausesOnCompletion = YES;
        // strength: full at the top edge, then falling off smoothly to almost nothing at the bottom
        CGFloat x = ((CGFloat)i + 0.5) / kStrips;
        animator.fractionComplete = MAX(0.0, MIN(1.0, BlurStrengthAt(x)));
        [self.animators addObject:animator];
    }
    [self setNeedsLayout];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) [self rebuild];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (self.strips.count != kStrips || self.darkBuilt != [Theme darkMode]) { [self rebuild]; }
    CGFloat height = self.bounds.size.height, width = self.bounds.size.width;
    CGFloat step = height / kStrips;
    for (NSInteger i = 0; i < (NSInteger)self.strips.count; i++) {
        // each strip reaches a little into the next one so that no seam shows
        self.strips[i].frame = CGRectMake(0, floor(i * step), width, ceil(step) + 1);
        TopBlurStripTint(self.strips[i]);
    }
}

- (void)refreshStyle { [self rebuild]; }

@end

#pragma mark - Glass button

@interface GlassBarButton ()
@property (strong, nonatomic) UIVisualEffectView *glass;
@property (strong, nonatomic) UIView *tint;
@property (strong, nonatomic) UIImageView *iconView;
@end

@implementation GlassBarButton

+ (instancetype)buttonWithIcon:(UIImage *)icon label:(NSString *)label target:(id)target action:(SEL)action {
    GlassBarButton *button = [[GlassBarButton alloc] initWithFrame:CGRectMake(0, 0, 38, 38)];
    button.iconView.image = [icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    button.accessibilityLabel = label;
    [button addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.accessibilityTraits = UIAccessibilityTraitButton;
        _glass = [[UIVisualEffectView alloc] initWithEffect:CurrentBlur()];
        _glass.userInteractionEnabled = NO;
        _glass.clipsToBounds = YES;
        self.layer.shadowColor = [UIColor blackColor].CGColor;   // soft drop shadow like the web buttons
        self.layer.shadowOpacity = 0.14;
        self.layer.shadowRadius = 5;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        [self addSubview:_glass];
        _tint = [[UIView alloc] init];
        _tint.userInteractionEnabled = NO;
        [_glass.contentView addSubview:_tint];
        _iconView = [[UIImageView alloc] init];
        _iconView.contentMode = UIViewContentModeCenter;
        _iconView.userInteractionEnabled = NO;
        [self addSubview:_iconView];
        self.layer.borderWidth = 1;
        [self addTarget:self action:@selector(down) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [self addTarget:self action:@selector(up) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNotifThemeChanged object:nil];
        [self refresh];
    }
    return self;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (CGSize)intrinsicContentSize { return CGSizeMake(38, 38); }

- (void)layoutSubviews {
    [super layoutSubviews];
    self.glass.frame = self.bounds;
    TopBlurStripTint(self.glass);
    self.tint.frame = self.glass.bounds;
    self.iconView.frame = self.bounds;
    self.layer.cornerRadius = self.bounds.size.height / 2;
    self.glass.layer.cornerRadius = self.bounds.size.height / 2;
}

- (void)refresh {
    BOOL dark = [Theme darkMode];
    self.glass.effect = CurrentBlur();
    self.tint.backgroundColor = [UIColor clearColor];   // no colour over the glass: only the blur
    TopBlurStripTint(self.glass);
    self.layer.borderColor = (dark ? [UIColor colorWithWhite:1 alpha:0.20] : [UIColor colorWithWhite:0 alpha:0.10]).CGColor;
    self.layer.shadowOpacity = dark ? 0.30 : 0.14;
    self.iconView.tintColor = [Theme accent];
}

- (void)down {
    [UIView animateWithDuration:0.12 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:nil];
}

- (void)up {
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.55 initialSpringVelocity:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}

@end
