#import "ComposerViews.h"
#import "Theme.h"
#import "Material.h"

#pragma mark - Model pill

static UIImage *PillChevron(void) {
    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(14, 14)];
        image = [[renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
            UIBezierPath *p = [UIBezierPath bezierPath];
            [p moveToPoint:CGPointMake(3.5, 5.2)];
            [p addLineToPoint:CGPointMake(7, 8.8)];
            [p addLineToPoint:CGPointMake(10.5, 5.2)];
            p.lineWidth = 1.8; p.lineCapStyle = kCGLineCapRound; p.lineJoinStyle = kCGLineJoinRound;
            [[UIColor blackColor] setStroke];
            [p stroke];
        }] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

static const CGFloat kPillHeight = 34, kPillLeft = 11, kPillRight = 8, kPillGap = 3, kPillChevron = 14, kPillLine = 18;

@interface ComposerModelPill ()
@property (strong, nonatomic) UIView *window_;          // clips the name: it rolls inside it
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIImageView *chevron;
@property (copy, nonatomic, readwrite) NSString *title;
@property (assign, nonatomic) CGFloat shownWidth;
@end

@implementation ComposerModelPill

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _textColor = [Theme secondaryText];
        _title = @"";
        _window_ = [[UIView alloc] init];
        _window_.clipsToBounds = YES;
        _window_.userInteractionEnabled = NO;
        [self addSubview:_window_];
        _label = [self makeLabel];
        [_window_ addSubview:_label];
        _chevron = [[UIImageView alloc] initWithImage:PillChevron()];
        _chevron.alpha = 0.75;
        _chevron.userInteractionEnabled = NO;
        [self addSubview:_chevron];
        [self addTarget:self action:@selector(down) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [self addTarget:self action:@selector(up) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        self.accessibilityTraits = UIAccessibilityTraitButton;
        self.clipsToBounds = NO;
    }
    return self;
}

- (UILabel *)makeLabel {
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    label.textColor = self.textColor ?: [Theme secondaryText];
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    return label;
}

- (void)setTextColor:(UIColor *)textColor {
    _textColor = textColor;
    self.label.textColor = textColor;
    self.chevron.tintColor = textColor;
}

- (void)down {
    self.backgroundColor = [[Theme text] colorWithAlphaComponent:0.08];
    if ([Material active] && ![Material reduceMotion]) [Material animateSpatial:MaterialMotionFast animations:^{ self.transform = CGAffineTransformMakeScale(0.94, 0.94); } completion:nil];
}

- (void)up {
    [UIView animateWithDuration:0.2 animations:^{ self.backgroundColor = [UIColor clearColor]; }];
    if (!CGAffineTransformIsIdentity(self.transform)) [Material animateSpatial:MaterialMotionFast animations:^{ self.transform = CGAffineTransformIdentity; } completion:nil];
}

- (BOOL)isRolling { return self.shownWidth < 0; }

- (CGFloat)textWidthFor:(NSString *)title {
    return ceil([title sizeWithAttributes:@{ NSFontAttributeName: self.label.font }].width);
}

- (CGFloat)preferredWidthWithMax:(CGFloat)maxWidth {
    CGFloat width = kPillLeft + [self textWidthFor:self.title] + kPillGap + kPillChevron + kPillRight;
    return MIN(width, MAX(80, maxWidth));
}

// Frames of the name window and the chevron for a pill that is `width` wide.
- (void)placeInWidth:(CGFloat)width {
    CGFloat room = MAX(10, width - kPillLeft - kPillGap - kPillChevron - kPillRight);
    CGFloat text = MIN(room, [self textWidthFor:self.title]);
    self.window_.frame = CGRectMake(kPillLeft, (kPillHeight - kPillLine) / 2, text, kPillLine);
    self.chevron.frame = CGRectMake(kPillLeft + text + kPillGap, (kPillHeight - kPillChevron) / 2, kPillChevron, kPillChevron);
    for (UILabel *label in self.window_.subviews) {
        if (![label isKindOfClass:[UILabel class]]) continue;
        CGRect f = label.frame;
        f.size = CGSizeMake(MAX(text, [self textWidthFor:label.text]), kPillLine);
        label.frame = f;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.layer.cornerRadius = kPillHeight / 2;
    if (self.window_.layer.animationKeys.count > 0 || self.shownWidth < 0) return;   // a roll is running: it places things itself
    [self placeInWidth:self.bounds.size.width];
}

- (void)setTitle:(NSString *)title animated:(BOOL)animated {
    title = title ?: @"";
    if ([title isEqualToString:self.title]) return;
    NSString *old = self.title;
    self.title = title;
    self.accessibilityLabel = title;
    BOOL roll = animated && old.length > 0 && self.window && ![Material reduceMotion];
    if (!roll) {
        self.label.text = title;
        [self placeInWidth:self.bounds.size.width];
        [self setNeedsLayout];
        return;
    }
    UILabel *outgoing = self.label;
    UILabel *incoming = [self makeLabel];
    incoming.text = title;
    incoming.textColor = self.textColor;
    incoming.frame = CGRectMake(0, kPillLine, [self textWidthFor:title], kPillLine);   // waits below the window
    incoming.alpha = 0;
    [self.window_ addSubview:incoming];
    self.label = incoming;
    CGFloat newWidth = [self preferredWidthWithMax:self.superview ? self.superview.bounds.size.width : 400];
    CGRect frame = self.frame;
    // the pill and its window resize on the spatial spring while the two names roll
    CGFloat text = MIN(MAX(10, newWidth - kPillLeft - kPillGap - kPillChevron - kPillRight), [self textWidthFor:title]);
    self.shownWidth = -1;
    [Material animateSpatial:MaterialMotionDefault animations:^{
        self.frame = CGRectMake(frame.origin.x, frame.origin.y, newWidth, frame.size.height);
        self.window_.frame = CGRectMake(kPillLeft, (kPillHeight - kPillLine) / 2, text, kPillLine);
        self.chevron.frame = CGRectMake(kPillLeft + text + kPillGap, (kPillHeight - kPillLine + 4) / 2, kPillChevron, kPillChevron);
        incoming.frame = CGRectMake(0, 0, MAX(text, [self textWidthFor:title]), kPillLine);
        outgoing.frame = CGRectMake(0, -kPillLine, outgoing.frame.size.width, kPillLine);
    } completion:^(BOOL finished) {
        [outgoing removeFromSuperview];
        self.shownWidth = 0;
        [self setNeedsLayout];
    }];
    [Material animateEffects:MaterialMotionDefault animations:^{
        incoming.alpha = 1;
        outgoing.alpha = 0;
    } completion:nil];
}

@end

#pragma mark - Send button

@interface ComposerSendButton ()
@property (strong, nonatomic) CAShapeLayer *arrow;
@property (strong, nonatomic) CALayer *stop;
@property (assign, nonatomic) BOOL ready;
@property (assign, nonatomic) BOOL generating;
@property (assign, nonatomic) BOOL configured;
@end

@implementation ComposerSendButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _arrow = [CAShapeLayer layer];
        _arrow.bounds = CGRectMake(0, 0, 18, 18);
        UIBezierPath *p = [UIBezierPath bezierPath];   // M12 19V5.5 M6 11l6-6 6 6 (on a 24 grid, drawn at 18 pt)
        CGFloat k = 18.0 / 24.0;
        [p moveToPoint:CGPointMake(12 * k, 19 * k)]; [p addLineToPoint:CGPointMake(12 * k, 5.5 * k)];
        [p moveToPoint:CGPointMake(6 * k, 11 * k)]; [p addLineToPoint:CGPointMake(12 * k, 5 * k)]; [p addLineToPoint:CGPointMake(18 * k, 11 * k)];
        _arrow.path = p.CGPath;
        _arrow.fillColor = nil;
        _arrow.lineWidth = 2.3 * k;
        _arrow.lineCap = kCALineCapRound;
        _arrow.lineJoin = kCALineJoinRound;
        [self.layer addSublayer:_arrow];
        _stop = [CALayer layer];
        _stop.bounds = CGRectMake(0, 0, 11, 11);
        _stop.cornerRadius = 3;
        _stop.opacity = 0;
        _stop.transform = CATransform3DConcat(CATransform3DMakeScale(0.2, 0.2, 1), CATransform3DMakeRotation(-M_PI_2, 0, 0, 1));
        [self.layer addSublayer:_stop];
        self.adjustsImageWhenHighlighted = NO;
    }
    return self;
}

- (void)setMaterialStyle:(BOOL)materialStyle {
    if (_materialStyle == materialStyle) return;
    _materialStyle = materialStyle;
    self.arrow.hidden = !materialStyle;
    self.stop.hidden = !materialStyle;
    if (materialStyle) self.configured = NO;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.arrow.position = center;
    self.stop.position = center;
    [CATransaction commit];
    self.layer.cornerRadius = self.bounds.size.height / 2;
    self.arrow.hidden = !self.materialStyle;
    self.stop.hidden = !self.materialStyle;
}

- (void)moveLayer:(CALayer *)layer toTransform:(CATransform3D)transform opacity:(float)opacity animated:(BOOL)animated {
    CALayer *shown = layer.presentationLayer ?: layer;
    CATransform3D fromTransform = shown.transform;
    float fromOpacity = shown.opacity;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [layer removeAnimationForKey:@"move"];
    [layer removeAnimationForKey:@"fade"];
    layer.transform = transform;
    layer.opacity = opacity;
    [CATransaction commit];
    if (!animated || [Material reduceMotion]) return;
    [layer addAnimation:[Material spatialSpringForKeyPath:@"transform" from:[NSValue valueWithCATransform3D:fromTransform] to:[NSValue valueWithCATransform3D:transform] speed:MaterialMotionDefault] forKey:@"move"];
    [layer addAnimation:[Material effectsSpringForKeyPath:@"opacity" from:@(fromOpacity) to:@(opacity) speed:MaterialMotionDefault] forKey:@"fade"];
}

- (void)applyReady:(BOOL)ready generating:(BOOL)generating animated:(BOOL)animated {
    if (!self.materialStyle) return;
    BOOL first = !self.configured;
    BOOL wasReady = self.ready, wasGenerating = self.generating;
    self.configured = YES;
    self.ready = ready;
    self.generating = generating;
    animated = animated && !first;

    UIColor *background, *glyph;
    if (generating || ready) {
        background = [Theme accent];
        glyph = [Theme onAccent];
    } else {
        background = [[Theme text] colorWithAlphaComponent:0.08];
        glyph = [[Theme text] colorWithAlphaComponent:0.32];
    }
    void (^paint)(void) = ^{ self.backgroundColor = background; };
    if (animated) [UIView animateWithDuration:0.2 animations:paint]; else paint();
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.arrow.strokeColor = glyph.CGColor;
    self.stop.backgroundColor = glyph.CGColor;
    [CATransaction commit];

    if (first || wasGenerating != generating) {
        if (generating) {   // the arrow flies up and shrinks; the square turns in
            [self moveLayer:self.arrow toTransform:CATransform3DConcat(CATransform3DMakeScale(0.3, 0.3, 1), CATransform3DMakeTranslation(0, -7, 0)) opacity:0 animated:animated];
            [self moveLayer:self.stop toTransform:CATransform3DIdentity opacity:1 animated:animated];
        } else {
            [self moveLayer:self.arrow toTransform:CATransform3DIdentity opacity:1 animated:animated];
            [self moveLayer:self.stop toTransform:CATransform3DConcat(CATransform3DMakeScale(0.2, 0.2, 1), CATransform3DMakeRotation(-M_PI_2, 0, 0, 1)) opacity:0 animated:animated];
        }
    }
    if (animated && !generating && ready && !wasReady) [self bump:0.86];   // it wakes up
    self.accessibilityTraits = UIAccessibilityTraitButton | ((ready || generating) ? 0 : UIAccessibilityTraitNotEnabled);
}

- (void)bump:(CGFloat)depth {
    if ([Material reduceMotion] || !self.window) return;
    CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    a.values = @[@1, @(depth), @1.06, @1];
    a.keyTimes = @[@0, @0.35, @0.7, @1];
    a.duration = 0.46;
    a.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.layer addAnimation:a forKey:@"bump"];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    if (!self.materialStyle || [Material reduceMotion] || !(self.ready || self.generating)) return;
    CGFloat target = highlighted ? 0.88 : 1;
    [Material animateSpatial:MaterialMotionFast animations:^{ self.transform = CGAffineTransformMakeScale(target, target); } completion:nil];
}

@end

#pragma mark - Running light

@interface ComposerGlowView ()
@property (strong, nonatomic) CALayer *ringHolder;       // masked to the border ring
@property (strong, nonatomic) CAGradientLayer *sweep;    // conic gradient that turns
@property (strong, nonatomic) CAShapeLayer *ringMask;
@property (assign, nonatomic) BOOL active;
@end

@implementation ComposerGlowView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.alpha = 0;
        _ringHolder = [CALayer layer];
        [self.layer addSublayer:_ringHolder];
        _ringMask = [CAShapeLayer layer];
        _ringMask.fillColor = nil;
        _ringMask.strokeColor = [UIColor blackColor].CGColor;
        _ringMask.lineWidth = 3;   // 1.5 pt each side of the border line is kept by the mask
        _ringHolder.mask = _ringMask;
        _sweep = [CAGradientLayer layer];
        if (@available(iOS 12.0, *)) _sweep.type = kCAGradientLayerConic;
        _sweep.startPoint = CGPointMake(0.5, 0.5);
        _sweep.endPoint = CGPointMake(0.5, 0);
        _sweep.locations = @[@0, @0.58, @0.76, @0.88, @1];
        [_ringHolder addSublayer:_sweep];
        [self refreshColors];
    }
    return self;
}

- (void)refreshColors {
    UIColor *accent = [Theme accent];
    CGFloat h = 0, s = 0, b = 0, a = 0;
    [accent getHue:&h saturation:&s brightness:&b alpha:&a];
    UIColor *other = [UIColor colorWithHue:fmod(h + 0.08, 1.0) saturation:MIN(1, s * 0.9 + 0.05) brightness:MIN(1, b + 0.1) alpha:1];
    UIColor *clear = [accent colorWithAlphaComponent:0];
    self.sweep.colors = @[(id)clear.CGColor, (id)clear.CGColor, (id)other.CGColor, (id)accent.CGColor, (id)clear.CGColor];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGRect bounds = self.bounds;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.ringHolder.frame = bounds;
    self.ringMask.frame = bounds;
    self.ringMask.path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(bounds, 1.5, 1.5) cornerRadius:MAX(0, self.cornerRadiusValue - 1.5)].CGPath;
    CGFloat side = hypot(bounds.size.width, bounds.size.height);
    self.sweep.bounds = CGRectMake(0, 0, side, side);
    self.sweep.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    [CATransaction commit];
}

- (void)startTurning {
    if ([self.sweep animationForKey:@"turn"]) return;
    CABasicAnimation *turn = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    turn.fromValue = @0;
    turn.toValue = @(2 * M_PI);
    turn.duration = 2.4;
    turn.repeatCount = HUGE_VALF;
    turn.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    turn.removedOnCompletion = NO;
    [self.sweep addAnimation:turn forKey:@"turn"];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && self.active && ![Material reduceMotion]) [self startTurning];   // the system drops animations of views that left the screen
}

- (void)setActive:(BOOL)active animated:(BOOL)animated {
    if (_active == active && (active == (self.alpha > 0.5))) return;
    _active = active;
    if (active && ![Material reduceMotion]) [self startTurning];
    CGFloat alpha = active ? 1 : 0;
    // under Reduce Motion the ring is a still, soft border instead of a turning light
    if (active && [Material reduceMotion]) alpha = 0.5;
    void (^change)(void) = ^{ self.alpha = alpha; };
    if (animated && !([Material reduceMotion])) {
        [UIView animateWithDuration:0.45 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:change completion:^(BOOL finished) {
            if (!self.active) [self.sweep removeAnimationForKey:@"turn"];
        }];
    } else {
        change();
        if (!active) [self.sweep removeAnimationForKey:@"turn"];
    }
}

@end
