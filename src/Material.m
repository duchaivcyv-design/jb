#import "Material.h"
#import "Theme.h"
#import "Strings.h"
#import <objc/runtime.h>

static UIColor *Mix(UIColor *a, UIColor *b, CGFloat t) {
    CGFloat ar = 0, ag = 0, ab = 0, aa = 0, br = 0, bg = 0, bb = 0, ba = 0;
    [a getRed:&ar green:&ag blue:&ab alpha:&aa];
    [b getRed:&br green:&bg blue:&bb alpha:&ba];
    return [UIColor colorWithRed:ar + (br - ar) * t green:ag + (bg - ag) * t blue:ab + (bb - ab) * t alpha:1];
}

static UIBezierPath *RoundedPath(CGRect r, CGFloat top, CGFloat bottom) {
    top = MAX(0, MIN(top, r.size.height / 2.0));
    bottom = MAX(0, MIN(bottom, r.size.height / 2.0));
    CGFloat minX = CGRectGetMinX(r), maxX = CGRectGetMaxX(r), minY = CGRectGetMinY(r), maxY = CGRectGetMaxY(r);
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(minX + top, minY)];
    [p addLineToPoint:CGPointMake(maxX - top, minY)];
    [p addArcWithCenter:CGPointMake(maxX - top, minY + top) radius:top startAngle:-M_PI_2 endAngle:0 clockwise:YES];
    [p addLineToPoint:CGPointMake(maxX, maxY - bottom)];
    [p addArcWithCenter:CGPointMake(maxX - bottom, maxY - bottom) radius:bottom startAngle:0 endAngle:M_PI_2 clockwise:YES];
    [p addLineToPoint:CGPointMake(minX + bottom, maxY)];
    [p addArcWithCenter:CGPointMake(minX + bottom, maxY - bottom) radius:bottom startAngle:M_PI_2 endAngle:M_PI clockwise:YES];
    [p addLineToPoint:CGPointMake(minX, minY + top)];
    [p addArcWithCenter:CGPointMake(minX + top, minY + top) radius:top startAngle:M_PI endAngle:1.5 * M_PI clockwise:YES];
    [p closePath];
    return p;
}

#pragma mark - MaterialCardView

// The press morph is computed here, frame by frame, with the closed-form solution of the spring
// (damping ratio zeta, stiffness k): the corner radii are numbers, so they can never overshoot into a bent shape,
// and the shape layer and the ripple mask always get exactly the same path.
@interface MaterialCardLinkProxy : NSObject
@property (weak, nonatomic) MaterialCardView *card;
- (void)tick:(CADisplayLink *)link;
@end

@interface MaterialCardView ()
@property (strong, nonatomic) CAShapeLayer *shape;
@property (strong, nonatomic) CALayer *overlay;          // ripples live here, clipped by `maskShape`
@property (strong, nonatomic) CAShapeLayer *maskShape;
@property (assign, nonatomic) BOOL pressedState;
@property (strong, nonatomic) CADisplayLink *link;
@property (assign, nonatomic) CFTimeInterval springStart;
@property (assign, nonatomic) CGFloat curTop, curBottom, fromTop, fromBottom, toTop, toBottom;
- (void)tickSpring:(CADisplayLink *)link;
@end

@implementation MaterialCardLinkProxy
- (void)tick:(CADisplayLink *)link { [self.card tickSpring:link]; }
@end

@implementation MaterialCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _shape = [CAShapeLayer layer];
        [self.layer addSublayer:_shape];
        _overlay = [CALayer layer];
        _maskShape = [CAShapeLayer layer];
        _overlay.mask = _maskShape;
        [self.layer addSublayer:_overlay];
        _topRadius = 6;
        _bottomRadius = 6;
        _curTop = 6;
        _curBottom = 6;
        _cardInsets = UIEdgeInsetsMake(1.5, 0, 1.5, 0);
    }
    return self;
}

- (void)dealloc { [self.link invalidate]; }

- (CGRect)cardRect { return UIEdgeInsetsInsetRect(self.bounds, self.cardInsets); }

// Fully round while pressed (Material 3 Expressive): capped at 28 and at half the height.
- (CGFloat)fullRadius { return MIN(28, [self cardRect].size.height / 2.0); }

- (void)applyRadii {
    UIBezierPath *path = RoundedPath([self cardRect], self.curTop, self.curBottom);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.shape.path = path.CGPath;
    self.maskShape.path = path.CGPath;   // the ripple is cut by the very same outline
    [CATransaction commit];
}

- (void)stopSpring {
    [self.link invalidate];
    self.link = nil;
}

- (void)setPressed:(BOOL)pressed animated:(BOOL)animated {
    if (pressed == self.pressedState) return;
    self.pressedState = pressed;
    self.fromTop = self.curTop;
    self.fromBottom = self.curBottom;
    self.toTop = pressed ? [self fullRadius] : self.topRadius;
    self.toBottom = pressed ? [self fullRadius] : self.bottomRadius;

    if (!pressed) [self fadeRipples];

    if (animated && !UIAccessibilityIsReduceMotionEnabled() && self.window) {
        // the card dips on the spatial spring; the corners are driven below
        double current = [[self.layer.presentationLayer valueForKeyPath:@"transform.scale"] doubleValue];
        CASpringAnimation *dip = [Material spatialSpringForKeyPath:@"transform.scale" from:@(current > 0.5 ? current : 1) to:@(pressed ? 0.975 : 1.0) speed:MaterialMotionFast];
        [self.layer addAnimation:dip forKey:@"dip"];
        self.layer.transform = pressed ? CATransform3DMakeScale(0.975, 0.975, 1) : CATransform3DIdentity;

        self.springStart = CACurrentMediaTime();
        if (!self.link) {
            MaterialCardLinkProxy *proxy = [[MaterialCardLinkProxy alloc] init];
            proxy.card = self;
            self.link = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(tick:)];
            [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        }
    } else {
        [self stopSpring];
        self.curTop = self.toTop;
        self.curBottom = self.toBottom;
        self.layer.transform = pressed ? CATransform3DMakeScale(0.975, 0.975, 1) : CATransform3DIdentity;
        [self applyRadii];
    }
}

// Spatial fast spring of the Expressive scheme: damping ratio 0.6, stiffness 800.
- (void)tickSpring:(CADisplayLink *)link {
    const CGFloat zeta = 0.6, omega = sqrt(800.0);
    CGFloat t = CACurrentMediaTime() - self.springStart;
    CGFloat settle = 6.9 / (zeta * omega);
    CGFloat s;
    if (t >= settle) {
        s = 1;
    } else {
        CGFloat wd = omega * sqrt(1 - zeta * zeta);
        s = 1 - exp(-zeta * omega * t) * (cos(wd * t) + (zeta * omega / wd) * sin(wd * t));
    }
    CGFloat maxRadius = [self cardRect].size.height / 2.0;
    self.curTop = MAX(0, MIN(maxRadius, self.fromTop + (self.toTop - self.fromTop) * s));
    self.curBottom = MAX(0, MIN(maxRadius, self.fromBottom + (self.toBottom - self.fromBottom) * s));
    [self applyRadii];
    if (t >= settle || self.window == nil) {
        self.curTop = self.toTop;
        self.curBottom = self.toBottom;
        [self applyRadii];
        [self stopSpring];
    }
}

// The ripple (Material 3: 10 % of the text colour) grows from the touch to the farthest corner and stays while the
// finger is down; it fades when the finger leaves.
- (void)rippleFrom:(CGPoint)point {
    CGRect rect = [self cardRect];
    if (rect.size.width < 2 || [Material reduceMotion]) return;
    self.overlay.frame = self.bounds;
    self.maskShape.frame = self.bounds;
    [self applyRadii];
    CGFloat maxDistance = 0;
    CGPoint corners[4] = { rect.origin, CGPointMake(CGRectGetMaxX(rect), rect.origin.y), CGPointMake(rect.origin.x, CGRectGetMaxY(rect)), CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect)) };
    for (int i = 0; i < 4; i++) maxDistance = MAX(maxDistance, hypot(corners[i].x - point.x, corners[i].y - point.y));
    maxDistance += 2;

    CAShapeLayer *circle = [CAShapeLayer layer];
    circle.name = @"ripple";
    circle.fillColor = [([Theme darkMode] ? [UIColor whiteColor] : [UIColor blackColor]) colorWithAlphaComponent:0.10].CGColor;   // neutral, no coloured flash
    UIBezierPath *start = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - 1, point.y - 1, 2, 2)];
    UIBezierPath *end = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(point.x - maxDistance, point.y - maxDistance, maxDistance * 2, maxDistance * 2)];
    circle.path = end.CGPath;
    [self.overlay addSublayer:circle];
    CABasicAnimation *grow = [CABasicAnimation animationWithKeyPath:@"path"];
    grow.fromValue = (__bridge id)start.CGPath;
    grow.toValue = (__bridge id)end.CGPath;
    grow.duration = 0.45;
    grow.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.05 :0.7 :0.1 :1.0];   // emphasized decelerate
    [circle addAnimation:grow forKey:@"grow"];
}

- (void)fadeRipples {
    for (CALayer *layer in [self.overlay.sublayers copy]) {
        if (![layer.name isEqualToString:@"ripple"] || [layer animationForKey:@"fade"]) continue;
        CABasicAnimation *fade = [CABasicAnimation animationWithKeyPath:@"opacity"];
        fade.fromValue = @(layer.presentationLayer ? layer.presentationLayer.opacity : 1);
        fade.toValue = @0;
        fade.duration = 0.30;
        fade.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.2 :0 :0 :1];   // standard
        layer.opacity = 0;
        [layer addAnimation:fade forKey:@"fade"];
        __weak CALayer *weakLayer = layer;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.34 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [weakLayer removeFromSuperlayer]; });
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.shape.frame = self.bounds;
    self.shape.fillColor = (self.fillColor ?: [Theme surface]).CGColor;
    self.overlay.frame = self.bounds;
    self.maskShape.frame = self.bounds;
    [CATransaction commit];
    if (!self.link) {   // not in the middle of a spring: the radii are the resting ones (or the pressed ones)
        self.curTop = self.pressedState ? [self fullRadius] : self.topRadius;
        self.curBottom = self.pressedState ? [self fullRadius] : self.bottomRadius;
    }
    [self applyRadii];
}

@end

#pragma mark - MaterialSwitch

@interface MaterialSwitch ()
@property (strong, nonatomic) UIView *track;
@property (strong, nonatomic) UIView *thumb;
@end

@implementation MaterialSwitch

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, 52, 32)];
    if (self) {
        _track = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 52, 32)];
        _track.layer.cornerRadius = 16;
        _track.userInteractionEnabled = NO;
        [self addSubview:_track];
        _thumb = [[UIView alloc] init];
        _thumb.userInteractionEnabled = NO;
        [self addSubview:_thumb];
        [self addTarget:self action:@selector(tapped) forControlEvents:UIControlEventTouchUpInside];
        [self applyState];
    }
    return self;
}

- (CGSize)intrinsicContentSize { return CGSizeMake(52, 32); }
- (CGSize)sizeThatFits:(CGSize)size { return CGSizeMake(52, 32); }

- (void)tapped { [self setOn:!self.on animated:YES]; [self sendActionsForControlEvents:UIControlEventValueChanged]; }

- (void)setOn:(BOOL)on { [self setOn:on animated:NO]; }

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _on = on;
    if (animated) [Material animateSpatial:MaterialMotionFast animations:^{ [self applyState]; } completion:nil];
    else [self applyState];
}

- (void)applyState {
    UIColor *accent = [Theme accent];
    CGFloat d = self.on ? 24 : 16;
    CGFloat x = self.on ? 52 - 4 - d : 8;
    self.thumb.frame = CGRectMake(x, (32 - d) / 2.0, d, d);
    self.thumb.layer.cornerRadius = d / 2.0;
    if (self.on) {
        self.track.backgroundColor = accent;
        self.track.layer.borderWidth = 2;
        self.track.layer.borderColor = accent.CGColor;
        self.thumb.backgroundColor = [Theme background];
        self.thumb.layer.borderWidth = 2;
        self.thumb.layer.borderColor = Mix(accent, [UIColor whiteColor], 0.45).CGColor;
    } else {
        self.track.backgroundColor = [UIColor clearColor];
        self.track.layer.borderWidth = 2;
        self.track.layer.borderColor = [Theme secondaryText].CGColor;
        self.thumb.backgroundColor = [Theme secondaryText];
        self.thumb.layer.borderWidth = 0;
    }
}

@end

#pragma mark - MaterialSlider

static const CGFloat kSliderThumb = 40;
static const CGFloat kSliderTrackHeight = 28;

@interface MaterialSlider ()
@property (strong, nonatomic) CAGradientLayer *trackLayer;
@property (strong, nonatomic) UIView *thumbView;
@end

@implementation MaterialSlider

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _trackLayer = [CAGradientLayer layer];
        _trackLayer.startPoint = CGPointMake(0, 0.5);
        _trackLayer.endPoint = CGPointMake(1, 0.5);
        _trackLayer.cornerRadius = kSliderTrackHeight / 2.0;
        [self.layer addSublayer:_trackLayer];
        _thumbView = [[UIView alloc] init];
        _thumbView.userInteractionEnabled = NO;
        _thumbView.layer.cornerRadius = kSliderThumb / 2.0;
        _thumbView.layer.borderWidth = 4;
        _thumbView.layer.borderColor = [UIColor whiteColor].CGColor;
        [self addSubview:_thumbView];
        _thumbColor = [UIColor grayColor];
        _trackColors = @[[UIColor blackColor], [UIColor whiteColor]];
        [self applyColors];
    }
    return self;
}

- (CGSize)intrinsicContentSize { return CGSizeMake(UIViewNoIntrinsicMetric, kSliderThumb + 4); }

- (void)applyColors {
    NSMutableArray *cg = [NSMutableArray array];
    for (UIColor *c in self.trackColors) [cg addObject:(id)c.CGColor];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.trackLayer.colors = cg;
    [CATransaction commit];
    self.thumbView.backgroundColor = self.thumbColor;
}

- (void)setTrackColors:(NSArray<UIColor *> *)trackColors { _trackColors = [trackColors copy]; [self applyColors]; }
- (void)setThumbColor:(UIColor *)thumbColor { _thumbColor = thumbColor; self.thumbView.backgroundColor = thumbColor; }

- (CGFloat)travelStart { return kSliderThumb / 2.0; }
- (CGFloat)travelLength { return MAX(1, self.bounds.size.width - kSliderThumb); }

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.trackLayer.frame = CGRectMake(0, (self.bounds.size.height - kSliderTrackHeight) / 2.0, self.bounds.size.width, kSliderTrackHeight);
    [CATransaction commit];
    [self placeThumb];
}

- (void)placeThumb {
    CGFloat cx = [self travelStart] + self.value * [self travelLength];
    self.thumbView.frame = CGRectMake(cx - kSliderThumb / 2.0, (self.bounds.size.height - kSliderThumb) / 2.0, kSliderThumb, kSliderThumb);
}

- (void)setValue:(CGFloat)value { [self setValue:value animated:NO]; }

- (void)setValue:(CGFloat)value animated:(BOOL)animated {
    _value = MAX(0, MIN(1, value));
    if (animated) [Material animateSpatial:MaterialMotionFast animations:^{ [self placeThumb]; } completion:nil];
    else [self placeThumb];
}

- (void)updateFromTouch:(UITouch *)touch {
    CGFloat x = [touch locationInView:self].x;
    CGFloat v = (x - [self travelStart]) / [self travelLength];
    v = MAX(0, MIN(1, v));
    if (fabs(v - _value) < 0.0005) return;
    _value = v;
    [self placeThumb];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self updateFromTouch:touch];
    [self growThumb:YES];
    return YES;
}
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event { [self updateFromTouch:touch]; return YES; }
- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event { if (touch) [self updateFromTouch:touch]; [self growThumb:NO]; }
- (void)cancelTrackingWithEvent:(UIEvent *)event { [self growThumb:NO]; }

// The thumb swells under the finger and springs back (Expressive slider feel).
- (void)growThumb:(BOOL)grow {
    CGAffineTransform target = grow ? CGAffineTransformMakeScale(1.18, 1.18) : CGAffineTransformIdentity;
    [Material animateSpatial:MaterialMotionFast animations:^{ self.thumbView.transform = target; } completion:nil];
}

// A generous touch area: the whole row of the slider, a little beyond its edges.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    return CGRectContainsPoint(CGRectInset(self.bounds, -8, -10), point);
}

@end

#pragma mark - MaterialMascotView

// Proxy so the display link does not retain the view (a retained view would never be released).
@interface MascotLinkProxy : NSObject
@property (weak, nonatomic) MaterialMascotView *view;
- (void)tick:(CADisplayLink *)link;
@end

#define MASCOT_SAMPLES 160
#define MASCOT_SHAPES 8

@interface MaterialMascotView ()
@property (strong, nonatomic) CAShapeLayer *shapeLayer;
@property (strong, nonatomic) CADisplayLink *link;
@property (assign, nonatomic) CFTimeInterval lastTime;
@property (assign, nonatomic) CFTimeInterval idleTime;   // time since the last morph, for the automatic cycle
@property (assign, nonatomic) NSInteger shapeIndex;
@property (assign, nonatomic) CGFloat progress;          // 0...1 of the running morph (1 = finished)
@property (assign, nonatomic) CGFloat angle;
@property (assign, nonatomic) CGFloat spin;              // extra angular speed that fades out after a morph
@end

@implementation MascotLinkProxy
- (void)tick:(CADisplayLink *)link { [self.view step:link]; }
@end

static CGFloat gMascotFrom[MASCOT_SAMPLES], gMascotTo[MASCOT_SAMPLES];

// Radius of shape `index` (before normalising) at angle t. The set walks through the Material 3 Expressive
// shapes: circle, cookie, clover, burst, soft square, flower, soft triangle, sunny.
static CGFloat MascotRadius(NSInteger index, CGFloat t) {
    switch (index % MASCOT_SHAPES) {
        case 0: return 1.0;
        case 1: return 1.0 + 0.085 * cos(9 * t);
        case 2: return 1.0 + 0.24 * cos(4 * t);
        case 3: { CGFloat c = fabs(cos(6 * t)); return 0.80 + 0.20 * pow(c, 0.55); }
        case 4: { CGFloat c = fabs(cos(t)), s = fabs(sin(t)); return 1.0 / pow(pow(c, 4.5) + pow(s, 4.5), 1.0 / 4.5); }
        case 5: return 1.0 + 0.18 * cos(5 * t);
        case 6: return 1.0 + 0.30 * cos(3 * t);
        default: return 1.0 + 0.10 * cos(12 * t) + 0.04 * cos(24 * t);
    }
}

static void MascotFill(CGFloat *out, NSInteger index) {
    CGFloat peak = 0;
    for (int i = 0; i < MASCOT_SAMPLES; i++) {
        out[i] = MascotRadius(index, (CGFloat)i / MASCOT_SAMPLES * 2 * M_PI);
        if (out[i] > peak) peak = out[i];
    }
    if (peak > 0) for (int i = 0; i < MASCOT_SAMPLES; i++) out[i] /= peak;
}

@implementation MaterialMascotView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _shapeColor = [UIColor colorWithWhite:1 alpha:0.35];
        _shapeLayer = [CAShapeLayer layer];
        _shapeLayer.fillColor = _shapeColor.CGColor;
        [self.layer addSublayer:_shapeLayer];
        _shapeIndex = 1;
        _progress = 1;
        MascotFill(gMascotTo, 1);
        memcpy(gMascotFrom, gMascotTo, sizeof(gMascotTo));
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [self rebuildPath];
    }
    return self;
}

- (void)dealloc { [self.link invalidate]; [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)appBecameActive { if (self.window) [self startLink]; }

- (void)startLink {
    if (self.link || UIAccessibilityIsReduceMotionEnabled()) return;
    MascotLinkProxy *proxy = [[MascotLinkProxy alloc] init];
    proxy.view = self;
    self.link = [CADisplayLink displayLinkWithTarget:proxy selector:@selector(tick:)];
    self.link.preferredFramesPerSecond = 60;
    self.lastTime = 0;
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)stopLink { [self.link invalidate]; self.link = nil; }

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) [self startLink]; else [self stopLink];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.shapeLayer.frame = self.bounds;
    [CATransaction commit];
    [self rebuildPath];
}

- (void)setShapeColor:(UIColor *)shapeColor {
    _shapeColor = shapeColor;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.shapeLayer.fillColor = shapeColor.CGColor;
    [CATransaction commit];
}

// The hue picks the shape, so dragging the hue slider morphs the figure from one shape to the next.
- (void)setHue:(CGFloat)hue {
    _hue = hue;
    NSInteger target = (NSInteger)floor(MAX(0, MIN(0.999, hue)) * MASCOT_SHAPES);
    if (target != self.shapeIndex) [self morphToShape:target];
}

- (void)morphToShape:(NSInteger)index {
    // start from what is on screen right now, so a morph interrupted half-way continues smoothly
    CGFloat s = [self easedProgress];
    for (int i = 0; i < MASCOT_SAMPLES; i++) gMascotFrom[i] = gMascotFrom[i] + (gMascotTo[i] - gMascotFrom[i]) * s;
    self.shapeIndex = index;
    MascotFill(gMascotTo, index);
    self.progress = 0;
    self.idleTime = 0;
    self.spin = 5.5;   // the figure turns quickly while it changes, then settles to a slow turn
    if (!self.link || UIAccessibilityIsReduceMotionEnabled()) { self.progress = 1; [self rebuildPath]; }
}

- (void)morphToNext { [self morphToShape:(self.shapeIndex + 1) % MASCOT_SHAPES]; }

// Spring-like curve with a small overshoot, like the Expressive "spatial" motion.
- (CGFloat)easedProgress {
    CGFloat t = MAX(0, MIN(1, self.progress));
    if (t >= 1) return 1;
    return 1 - exp(-7.5 * t) * cos(10.5 * t);
}

- (void)step:(CADisplayLink *)link {
    CFTimeInterval now = link.timestamp;
    CFTimeInterval dt = self.lastTime > 0 ? MIN(0.05, now - self.lastTime) : 1.0 / 60.0;
    self.lastTime = now;
    if (self.window == nil || self.bounds.size.width < 1) return;

    self.angle += (0.55 + self.spin) * dt;                       // always turning
    if (self.angle > 2 * M_PI) self.angle -= 2 * M_PI;
    self.spin = MAX(0, self.spin - dt * 5.0);
    if (self.progress < 1) {
        self.progress = MIN(1, self.progress + dt / 0.85);
    } else {
        self.idleTime += dt;
        if (self.idleTime > 2.6) [self morphToNext];             // keeps changing by itself while you look at it
    }
    [self rebuildPath];
}

- (void)rebuildPath {
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    if (w < 1 || h < 1) return;
    CGFloat s = [self easedProgress];
    CGPoint center = CGPointMake(w / 2.0, h / 2.0);
    CGFloat radius = MIN(w, h) / 2.0 * 0.94;
    UIBezierPath *path = [UIBezierPath bezierPath];
    for (int i = 0; i <= MASCOT_SAMPLES; i++) {
        int k = i % MASCOT_SAMPLES;
        CGFloat r = radius * (gMascotFrom[k] + (gMascotTo[k] - gMascotFrom[k]) * s);
        CGFloat a = (CGFloat)k / MASCOT_SAMPLES * 2 * M_PI + self.angle;
        CGPoint pt = CGPointMake(center.x + r * cos(a), center.y + r * sin(a));
        if (i == 0) [path moveToPoint:pt]; else [path addLineToPoint:pt];
    }
    [path closePath];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.shapeLayer.path = path.CGPath;
    [CATransaction commit];
}

@end

#pragma mark - MaterialGradientView

// A soft aurora: a base colour with five large, blurred colour blobs (all derived from the accent) that drift
// along slow elliptical paths and breathe. No stripes and no spinning bands, only light moving in colour.
#define GRADIENT_BLOBS 5

@interface MaterialGradientView ()
@property (strong, nonatomic) NSMutableArray<CAGradientLayer *> *blobs;
@property (assign, nonatomic) CGSize builtSize;
@end

@implementation MaterialGradientView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.clipsToBounds = YES;
        _blobs = [NSMutableArray array];
        for (int i = 0; i < GRADIENT_BLOBS; i++) {
            CAGradientLayer *blob = [CAGradientLayer layer];
            blob.type = kCAGradientLayerRadial;
            blob.startPoint = CGPointMake(0.5, 0.5);
            blob.endPoint = CGPointMake(1.0, 1.0);
            blob.locations = @[@0.0, @0.35, @0.7, @1.0];
            [self.layer addSublayer:blob];
            [_blobs addObject:blob];
        }
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(refreshColors) name:UIApplicationDidBecomeActiveNotification object:nil];
        [center addObserver:self selector:@selector(stopMoving) name:UIApplicationWillResignActiveNotification object:nil];
        [self refreshColors];
    }
    return self;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) { self.builtSize = CGSizeZero; [self refreshColors]; [self setNeedsLayout]; } else [self stopMoving];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!CGSizeEqualToSize(self.builtSize, self.bounds.size)) [self rebuildMotion];
}

- (void)stopMoving {
    for (CAGradientLayer *blob in self.blobs) [blob removeAllAnimations];
    self.builtSize = CGSizeZero;
}

// Colours of one blob: the accent hue moved a little, soft in light mode, deep in dark mode.
- (NSArray *)colorsForBlob:(NSInteger)index {
    static const CGFloat hueShift[GRADIENT_BLOBS] = { 0.0, 0.08, -0.07, 0.16, -0.14 };
    static const CGFloat strength[GRADIENT_BLOBS] = { 0.95, 0.80, 0.85, 0.65, 0.75 };
    CGFloat h = 0, s = 0, v = 0, alpha = 0;
    [[Theme accent] getHue:&h saturation:&s brightness:&v alpha:&alpha];
    CGFloat hue = fmod(h + hueShift[index] + 1.0, 1.0);
    BOOL dark = [Theme darkMode];
    CGFloat sat = MAX(0.35, MIN(1.0, s * (dark ? 0.95 : 0.62)));
    CGFloat bri = dark ? MIN(0.78, MAX(0.5, v * 0.7)) : 1.0;
    CGFloat peak = (dark ? 0.62 : 0.55) * strength[index];
    UIColor *core = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:peak];
    UIColor *mid  = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:peak * 0.55];
    UIColor *soft = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:peak * 0.18];
    UIColor *none = [UIColor colorWithHue:hue saturation:sat brightness:bri alpha:0];
    return @[(id)core.CGColor, (id)mid.CGColor, (id)soft.CGColor, (id)none.CGColor];
}

- (void)refreshColors {
    self.backgroundColor = [Theme background];
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (NSInteger i = 0; i < (NSInteger)self.blobs.count; i++) self.blobs[i].colors = [self colorsForBlob:i];
    [CATransaction commit];
    if (self.window && self.builtSize.width < 1) [self setNeedsLayout];
}

- (void)rebuildMotion {
    CGSize size = self.bounds.size;
    if (size.width < 2 || size.height < 2) return;
    self.builtSize = size;
    // anchor (x, y), diameter (x longest side), radius of the drift (x, y), seconds per lap, direction
    static const CGFloat spec[GRADIENT_BLOBS][7] = {
        { 0.22, 0.18, 1.15, 0.20, 0.10, 23,  1 },
        { 0.80, 0.32, 1.05, 0.16, 0.16, 29, -1 },
        { 0.28, 0.72, 1.25, 0.20, 0.12, 33,  1 },
        { 0.85, 0.86, 1.05, 0.14, 0.14, 27, -1 },
        { 0.55, 0.48, 0.95, 0.24, 0.18, 37,  1 },
    };
    CGFloat longest = MAX(size.width, size.height);
    BOOL still = UIAccessibilityIsReduceMotionEnabled() || self.window == nil;
    for (int i = 0; i < GRADIENT_BLOBS; i++) {
        CAGradientLayer *blob = self.blobs[i];
        [blob removeAllAnimations];
        CGFloat d = longest * spec[i][2];
        CGPoint center = CGPointMake(size.width * spec[i][0], size.height * spec[i][1]);
        CGFloat rx = size.width * spec[i][3], ry = size.height * spec[i][4];
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        blob.bounds = CGRectMake(0, 0, d, d);
        blob.position = CGPointMake(center.x + rx, center.y);   // where the path below starts
        [CATransaction commit];
        if (still) { blob.position = center; continue; }

        UIBezierPath *loop = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(center.x - rx, center.y - ry, rx * 2, ry * 2)];
        if (spec[i][6] < 0) loop = [loop bezierPathByReversingPath];
        CAKeyframeAnimation *drift = [CAKeyframeAnimation animationWithKeyPath:@"position"];
        drift.path = loop.CGPath;
        drift.duration = spec[i][5];
        drift.repeatCount = HUGE_VALF;
        drift.calculationMode = kCAAnimationPaced;
        drift.timeOffset = spec[i][5] * (0.13 * (i + 1));   // the blobs do not start in a row
        [blob addAnimation:drift forKey:@"drift"];

        CABasicAnimation *breathe = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        breathe.fromValue = @0.88; breathe.toValue = @1.14;
        breathe.duration = 8 + 1.7 * i;
        breathe.autoreverses = YES;
        breathe.repeatCount = HUGE_VALF;
        breathe.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [blob addAnimation:breathe forKey:@"breathe"];
    }
}

@end

#pragma mark - Section header

@interface MaterialSectionHeader : UIView
@property (strong, nonatomic) UILabel *label;
@property (strong, nonatomic) UIImageView *chevron;
@property (copy, nonatomic) void (^tap)(void);
@end

@implementation MaterialSectionHeader

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _label = [[UILabel alloc] init];
        _label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightBold];
        _label.textColor = [Theme accent];
        [self addSubview:_label];
        _chevron = [[UIImageView alloc] init];
        _chevron.tintColor = [Theme secondaryText];
        [self addSubview:_chevron];
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)]];
    }
    return self;
}

- (void)tapped { if (self.tap) self.tap(); }

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    self.label.frame = CGRectMake(10, h - 34, w - 60, 24);
    self.chevron.frame = CGRectMake(w - 38, h - 34, 24, 24);
}

@end

#pragma mark - Title

@interface MaterialTitleLabel : UILabel
@end
@implementation MaterialTitleLabel
- (CGSize)intrinsicContentSize { return CGSizeMake(10000, 44); }
@end

#pragma mark - Press handling of table rows

@interface MaterialPressHandler : NSObject <UIGestureRecognizerDelegate>
@property (weak, nonatomic) UITableView *table;
@property (weak, nonatomic) MaterialCardView *pressedCard;
@property (weak, nonatomic) UIView *pressedPlain;   // content of a row that has no card behind it
@property (assign, nonatomic) CGPoint start;
@end

@implementation MaterialPressHandler

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)a shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)b { return YES; }

- (void)release_ {
    [self.pressedCard setPressed:NO animated:YES];
    self.pressedCard = nil;
    UIView *plain = self.pressedPlain;
    self.pressedPlain = nil;
    if (plain) [Material animateSpatial:MaterialMotionFast animations:^{ plain.transform = CGAffineTransformIdentity; } completion:nil];
}

- (void)pressed:(UILongPressGestureRecognizer *)gesture {
    if (![Material active]) { [self release_]; return; }
    CGPoint point = [gesture locationInView:self.table];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.start = point;
        NSIndexPath *path = [self.table indexPathForRowAtPoint:point];
        UITableViewCell *cell = path ? [self.table cellForRowAtIndexPath:path] : nil;
        if ([cell.backgroundView isKindOfClass:[MaterialCardView class]]) {
            MaterialCardView *card = (MaterialCardView *)cell.backgroundView;
            self.pressedCard = card;
            [card setPressed:YES animated:YES];
            [card rippleFrom:[gesture locationInView:card]];
        } else if (cell && cell.selectionStyle != UITableViewCellSelectionStyleNone) {
            // a plain row (chat list, model list): the content dips on the spatial spring
            UIView *content = cell.contentView;
            self.pressedPlain = content;
            [Material animateSpatial:MaterialMotionFast animations:^{ content.transform = CGAffineTransformMakeScale(0.97, 0.97); } completion:nil];
        }
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        if (hypot(point.x - self.start.x, point.y - self.start.y) > 12) [self release_];   // it became a scroll
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {
        [self release_];
    }
}

@end

#pragma mark - Buttons: spring dip while pressed (Material design only)

@interface UIButton (MaterialPress)
@end

@implementation UIButton (MaterialPress)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Method original = class_getInstanceMethod(self, @selector(setHighlighted:));
        Method replacement = class_getInstanceMethod(self, @selector(mat_setHighlighted:));
        if (original && replacement) method_exchangeImplementations(original, replacement);
    });
}

- (void)mat_setHighlighted:(BOOL)highlighted {
    BOOL changed = self.highlighted != highlighted;
    [self mat_setHighlighted:highlighted];   // the original
    if (!changed || ![Theme materialDesign] || UIAccessibilityIsReduceMotionEnabled()) return;
    if (!CATransform3DIsIdentity(self.layer.transform) && ![self.layer animationForKey:@"matpress"]) return;   // a button that is rotated / scaled on purpose keeps its own transform
    if (self.bounds.size.width < 24 || self.bounds.size.height < 24) return;
    if (self.bounds.size.width > 300 && self.bounds.size.height > 120) return;   // a big area (an overlay that catches taps) should not shrink
    CALayer *layer = self.layer;
    CGFloat current = [[layer.presentationLayer valueForKeyPath:@"transform.scale"] doubleValue];
    if (current < 0.5) current = 1;
    CASpringAnimation *spring = [Material spatialSpringForKeyPath:@"transform.scale" from:@(current) to:@(highlighted ? 0.93 : 1.0) speed:MaterialMotionFast];
    spring.fillMode = kCAFillModeForwards;
    spring.removedOnCompletion = !highlighted;
    [layer removeAnimationForKey:@"matpress"];
    [layer addAnimation:spring forKey:@"matpress"];
}

@end

#pragma mark - Material

#pragma mark - Motion tokens

const NSTimeInterval MaterialDurationShort1 = 0.05;
const NSTimeInterval MaterialDurationShort2 = 0.10;
const NSTimeInterval MaterialDurationShort3 = 0.15;
const NSTimeInterval MaterialDurationShort4 = 0.20;
const NSTimeInterval MaterialDurationMedium1 = 0.25;
const NSTimeInterval MaterialDurationMedium2 = 0.30;
const NSTimeInterval MaterialDurationMedium4 = 0.40;
const NSTimeInterval MaterialDurationLong2 = 0.50;

typedef struct { CGFloat damping; CGFloat stiffness; } MaterialSpringSpec;

// Material 3 Expressive scheme (damping ratio, stiffness).
static MaterialSpringSpec SpatialSpec(MaterialMotionSpeed speed) {
    switch (speed) {
        case MaterialMotionFast: return (MaterialSpringSpec){ 0.6, 800 };
        case MaterialMotionSlow: return (MaterialSpringSpec){ 0.8, 200 };
        default:                 return (MaterialSpringSpec){ 0.8, 380 };
    }
}
static MaterialSpringSpec EffectsSpec(MaterialMotionSpeed speed) {
    switch (speed) {
        case MaterialMotionFast: return (MaterialSpringSpec){ 1.0, 3800 };
        case MaterialMotionSlow: return (MaterialSpringSpec){ 1.0, 800 };
        default:                 return (MaterialSpringSpec){ 1.0, 1600 };
    }
}

// Time a spring needs to come to rest (to 0.1 % of the distance): ln(1000) / (damping ratio * natural frequency).
static NSTimeInterval SettleTime(MaterialSpringSpec spec) {
    return 6.9 / (spec.damping * sqrt(spec.stiffness));
}

static CASpringAnimation *MakeSpring(NSString *keyPath, id from, id to, MaterialSpringSpec spec) {
    CASpringAnimation *spring = [CASpringAnimation animationWithKeyPath:keyPath];
    spring.fromValue = from;
    spring.toValue = to;
    spring.mass = 1;
    spring.stiffness = spec.stiffness;
    spring.damping = 2.0 * spec.damping * sqrt(spec.stiffness);   // c = 2 * zeta * sqrt(k * m)
    spring.initialVelocity = 0;
    spring.duration = spring.settlingDuration;
    return spring;
}

static void RunSpring(MaterialSpringSpec spec, NSTimeInterval delay, void (^animations)(void), void (^completion)(BOOL)) {
    if (UIAccessibilityIsReduceMotionEnabled()) {
        animations();
        if (completion) completion(YES);
        return;
    }
    [UIView animateWithDuration:SettleTime(spec) delay:delay usingSpringWithDamping:spec.damping initialSpringVelocity:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:animations completion:completion];
}

static void RunCurve(NSTimeInterval duration, CGPoint c1, CGPoint c2, void (^animations)(void), void (^completion)(BOOL)) {
    if (UIAccessibilityIsReduceMotionEnabled()) {
        animations();
        if (completion) completion(YES);
        return;
    }
    UIViewPropertyAnimator *animator = [[UIViewPropertyAnimator alloc] initWithDuration:duration controlPoint1:c1 controlPoint2:c2 animations:animations];
    animator.interruptible = NO;
    if (completion) [animator addCompletion:^(UIViewAnimatingPosition position) { completion(position == UIViewAnimatingPositionEnd); }];
    [animator startAnimation];
}


@implementation Material

+ (BOOL)active { return [Theme materialDesign]; }

+ (BOOL)reduceMotion { return UIAccessibilityIsReduceMotionEnabled(); }

+ (void)presentDialogCard:(UIView *)card {
    if (![self active] || [self reduceMotion]) return;
    card.alpha = 0;
    card.transform = CGAffineTransformMakeScale(0.9, 0.9);
    [self animateSpatial:MaterialMotionDefault animations:^{ card.transform = CGAffineTransformIdentity; } completion:nil];
    [self animateEffects:MaterialMotionDefault animations:^{ card.alpha = 1; } completion:nil];
}

+ (void)dismissDialogCard:(UIView *)card {
    if (![self active] || [self reduceMotion]) return;
    [self animateEmphasizedAccelerate:MaterialDurationShort3 animations:^{
        card.alpha = 0;
        card.transform = CGAffineTransformMakeScale(0.94, 0.94);
    } completion:nil];
}

+ (void)animateSpatial:(MaterialMotionSpeed)speed animations:(void (^)(void))animations completion:(void (^)(BOOL))completion { RunSpring(SpatialSpec(speed), 0, animations, completion); }
+ (void)animateSpatial:(MaterialMotionSpeed)speed delay:(NSTimeInterval)delay animations:(void (^)(void))animations completion:(void (^)(BOOL))completion { RunSpring(SpatialSpec(speed), delay, animations, completion); }
+ (void)animateEffects:(MaterialMotionSpeed)speed animations:(void (^)(void))animations completion:(void (^)(BOOL))completion { RunSpring(EffectsSpec(speed), 0, animations, completion); }
+ (CASpringAnimation *)spatialSpringForKeyPath:(NSString *)keyPath from:(id)from to:(id)to speed:(MaterialMotionSpeed)speed { return MakeSpring(keyPath, from, to, SpatialSpec(speed)); }
+ (CASpringAnimation *)effectsSpringForKeyPath:(NSString *)keyPath from:(id)from to:(id)to speed:(MaterialMotionSpeed)speed { return MakeSpring(keyPath, from, to, EffectsSpec(speed)); }

// emphasized decelerate = cubic-bezier(0.05, 0.7, 0.1, 1.0); emphasized accelerate = (0.3, 0, 0.8, 0.15); standard = (0.2, 0, 0, 1.0)
+ (void)animateEmphasizedDecelerate:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    RunCurve(duration, CGPointMake(0.05, 0.7), CGPointMake(0.1, 1.0), animations, completion);
}
+ (void)animateEmphasizedAccelerate:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    RunCurve(duration, CGPointMake(0.3, 0.0), CGPointMake(0.8, 0.15), animations, completion);
}
+ (void)animateStandard:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL))completion {
    RunCurve(duration, CGPointMake(0.2, 0.0), CGPointMake(0.0, 1.0), animations, completion);
}

+ (UITableViewCellStyle)cellStyle:(UITableViewCellStyle)classic {
    return [self active] ? UITableViewCellStyleSubtitle : classic;
}

+ (void)decorateTable:(UITableView *)table {
    if (![self active]) return;
    table.separatorStyle = UITableViewCellSeparatorStyleNone;
    table.showsVerticalScrollIndicator = NO;
    if (table.rowHeight < 60) table.rowHeight = 64;
    [self installTableEffects:table];
}

+ (void)layoutTable:(UITableView *)table inBounds:(CGRect)bounds {
    CGRect frame = [self active] ? CGRectInset(bounds, 12, 0) : bounds;
    if (!CGRectEqualToRect(table.frame, frame)) table.frame = frame;
}

+ (UIImage *)chevronImageRight {
    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(14, 20)];
        image = [[renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
            UIBezierPath *p = [UIBezierPath bezierPath];
            [p moveToPoint:CGPointMake(4, 3)];
            [p addLineToPoint:CGPointMake(10.5, 10)];
            [p addLineToPoint:CGPointMake(4, 17)];
            p.lineWidth = 2.2; p.lineCapStyle = kCGLineCapRound; p.lineJoinStyle = kCGLineJoinRound;
            [[UIColor blackColor] setStroke];
            [p stroke];
        }] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

+ (void)decorateCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)table {
    if (![self active]) return;
    NSInteger count = [table numberOfRowsInSection:indexPath.section];
    BOOL first = indexPath.row == 0, last = indexPath.row == count - 1;
    const CGFloat big = 26, small = 6;

    MaterialCardView *card = [[MaterialCardView alloc] init];
    card.fillColor = [Theme surface];
    card.topRadius = first ? big : small;
    card.bottomRadius = last ? big : small;
    cell.backgroundView = card;

    MaterialCardView *selected = [[MaterialCardView alloc] init];
    selected.fillColor = [Theme surface];   // no coloured highlight while touching; the press is shown by the shape and the ripple
    selected.topRadius = card.topRadius;
    selected.bottomRadius = card.bottomRadius;
    cell.selectedBackgroundView = selected;
    cell.backgroundColor = [UIColor clearColor];

    if (cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        UIImageView *chevron = [[UIImageView alloc] initWithImage:[self chevronImageRight]];
        chevron.tintColor = [Theme secondaryText];
        cell.accessoryView = chevron;
    }
    // Balanced sizes: 16 pt title, 13 pt supporting text (the reference app uses small, calm text).
    cell.textLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    if (cell.detailTextLabel.text.length > 0) cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    [self enterCell:cell atIndexPath:indexPath inTable:table];
}

#pragma mark - Expressive motion

static const void *kEntranceKey = &kEntranceKey;
static const void *kPressHandlerKey = &kPressHandlerKey;

+ (CGFloat)classic:(CGFloat)classic material:(CGFloat)material { return [self active] ? material : classic; }

+ (void)springAnimations:(void (^)(void))animations { [self animateSpatial:MaterialMotionDefault animations:animations completion:nil]; }

// The rows that appear in the next moment spring up one after another (first screen opening, or after a reload).
+ (void)markTableForEntrance:(UITableView *)table {
    if (![self active] || UIAccessibilityIsReduceMotionEnabled()) return;
    objc_setAssociatedObject(table, kEntranceKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak UITableView *weakTable = table;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.9 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakTable) objc_setAssociatedObject(weakTable, kEntranceKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

+ (void)enterCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath inTable:(UITableView *)table {
    if (![objc_getAssociatedObject(table, kEntranceKey) boolValue]) return;
    NSInteger order = 0;
    for (NSInteger section = 0; section < indexPath.section; section++) order += [table numberOfRowsInSection:section];
    order += indexPath.row;
    if (order > 14) return;
    cell.alpha = 0;
    cell.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.94, 0.94), CGAffineTransformMakeTranslation(0, 26));
    [self animateSpatial:MaterialMotionDefault delay:0.035 * order animations:^{ cell.alpha = 1; cell.transform = CGAffineTransformIdentity; } completion:nil];
}

+ (void)installTableEffects:(UITableView *)table {
    if (objc_getAssociatedObject(table, kPressHandlerKey)) return;
    MaterialPressHandler *handler = [[MaterialPressHandler alloc] init];
    handler.table = table;
    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:handler action:@selector(pressed:)];
    press.minimumPressDuration = 0;
    press.cancelsTouchesInView = NO;
    press.delaysTouchesBegan = NO;
    press.delaysTouchesEnded = NO;
    press.delegate = handler;
    [table addGestureRecognizer:press];
    objc_setAssociatedObject(table, kPressHandlerKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (CGFloat)headerHeight { return 54; }

+ (UIView *)headerViewWithTitle:(NSString *)title collapsed:(BOOL)collapsed collapsible:(BOOL)collapsible tap:(void (^)(void))tap {
    MaterialSectionHeader *header = [[MaterialSectionHeader alloc] initWithFrame:CGRectMake(0, 0, 320, [self headerHeight])];
    header.label.text = title;
    header.label.textColor = [Theme accent];
    header.chevron.hidden = !collapsible;
    UIImage *base = [self chevronImageRight];
    header.chevron.image = base;
    header.chevron.contentMode = UIViewContentModeCenter;
    header.chevron.transform = CGAffineTransformMakeRotation(collapsed ? 0 : M_PI_2);   // right when closed, down when open
    header.chevron.tintColor = [Theme secondaryText];
    header.tap = collapsible ? tap : nil;
    return header;
}

+ (void)toggleSection:(NSInteger)section collapsed:(NSMutableSet<NSNumber *> *)collapsed inTable:(UITableView *)table header:(UIView *)header {
    NSNumber *key = @(section);
    BOOL willCollapse = ![collapsed containsObject:key];
    // The table view's own numberOfRowsInSection: answers from a cache of the last update (0 while folded),
    // so the count is asked from the data source directly.
    NSInteger count;
    if (willCollapse) {
        count = [table.dataSource tableView:table numberOfRowsInSection:section];   // rows on screen now
        [collapsed addObject:key];
    } else {
        [collapsed removeObject:key];
        count = [table.dataSource tableView:table numberOfRowsInSection:section];   // rows that come back
    }
    NSMutableArray<NSIndexPath *> *paths = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++) [paths addObject:[NSIndexPath indexPathForRow:i inSection:section]];

    if ([header isKindOfClass:[MaterialSectionHeader class]]) {
        UIImageView *chevron = ((MaterialSectionHeader *)header).chevron;
        CGAffineTransform target = CGAffineTransformMakeRotation(willCollapse ? 0 : M_PI_2);
        [Material animateSpatial:MaterialMotionFast animations:^{ chevron.transform = target; } completion:nil];
    }
    if (count == 0 || UIAccessibilityIsReduceMotionEnabled()) { [table reloadData]; return; }

    if (willCollapse) {
        [table beginUpdates];
        [table deleteRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationFade];
        [table endUpdates];
        return;
    }
    // Unfolding: the rows below slide down while the new rows spring in one after another.
    [table beginUpdates];
    [table insertRowsAtIndexPaths:paths withRowAnimation:UITableViewRowAnimationNone];
    [table endUpdates];
    NSInteger order = 0;
    for (NSIndexPath *path in paths) {
        UITableViewCell *cell = [table cellForRowAtIndexPath:path];
        if (!cell) continue;
        cell.alpha = 0;
        cell.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.92, 0.92), CGAffineTransformMakeTranslation(0, -22));
        [Material animateSpatial:MaterialMotionDefault delay:0.05 * order animations:^{ cell.alpha = 1; cell.transform = CGAffineTransformIdentity; } completion:nil];
        order++;
    }
}

+ (void)styleTitleForController:(UIViewController *)controller {
    UINavigationItem *item = controller.navigationItem;
    if (![self active]) {
        if ([item.titleView isKindOfClass:[MaterialTitleLabel class]]) item.titleView = nil;
        return;
    }
    MaterialTitleLabel *label = [item.titleView isKindOfClass:[MaterialTitleLabel class]] ? (MaterialTitleLabel *)item.titleView : [[MaterialTitleLabel alloc] init];
    label.text = controller.title;
    label.font = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];   // calm, smaller title next to the back button
    label.textColor = [Theme text];
    label.textAlignment = NSTextAlignmentLeft;
    [label sizeToFit];
    item.titleView = label;
}

+ (UIImage *)circleIconWithGlyph:(void (^)(CGContextRef ctx))glyph {
    const CGFloat side = 40;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [Mix([Theme surface], [Theme accent], 0.24) setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, side, side)] fill];
        CGContextTranslateCTM(ctx.CGContext, 5, 5);
        if (glyph) glyph(ctx.CGContext);
    }];
}

@end
