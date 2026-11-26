#import "GooFanView.h"
#import "Theme.h"
#import "Material.h"

static const CGFloat kFabR = 20;      // the blob that replaces the + (the button of the box is 36-40 pt)
static const CGFloat kBlobR = 22;
static const CGFloat kRadius = 116;   // distance from the + to the fan buttons

@implementation GooFanItem
+ (instancetype)itemWithTitle:(NSString *)title icon:(UIImage *)icon handler:(void (^)(void))handler {
    GooFanItem *item = [[GooFanItem alloc] init];
    item.title = title; item.icon = icon; item.handler = handler;
    return item;
}
@end

// The neck between two circles (the classic metaball construction); nil when they are too far apart or one swallows the other.
static UIBezierPath *Bridge(CGPoint c1, CGFloat r1, CGPoint c2, CGFloat r2, CGFloat reach) {
    CGFloat dx = c2.x - c1.x, dy = c2.y - c1.y, d = sqrt(dx * dx + dy * dy);
    if (r1 < 1 || r2 < 1 || d < 0.5 || d > r1 + r2 + reach || d <= fabs(r1 - r2)) return nil;
    CGFloat u1 = 0, u2 = 0;
    if (d < r1 + r2) {
        u1 = acos(MAX(-1, MIN(1, (r1 * r1 + d * d - r2 * r2) / (2 * r1 * d))));
        u2 = acos(MAX(-1, MIN(1, (r2 * r2 + d * d - r1 * r1) / (2 * r2 * d))));
    }
    CGFloat between = atan2(dy, dx);
    CGFloat spreadMax = acos(MAX(-1, MIN(1, (r1 - r2) / d)));
    CGFloat v = 0.5;
    CGFloat a1 = between + u1 + (spreadMax - u1) * v;
    CGFloat a2 = between - u1 - (spreadMax - u1) * v;
    CGFloat a3 = between + M_PI - u2 - (M_PI - u2 - spreadMax) * v;
    CGFloat a4 = between - M_PI + u2 + (M_PI - u2 - spreadMax) * v;
#define PT(c, a, r) CGPointMake((c).x + cos(a) * (r), (c).y + sin(a) * (r))
    CGPoint p1a = PT(c1, a1, r1), p1b = PT(c1, a2, r1), p2a = PT(c2, a3, r2), p2b = PT(c2, a4, r2);
    CGFloat total = r1 + r2;
    CGFloat pd = hypot(p1a.x - p2a.x, p1a.y - p2a.y);
    CGFloat rate = MIN(v * 2.4, pd / total);
    rate *= MIN(1, d * 2 / total);
    CGFloat h1 = r1 * rate, h2 = r2 * rate;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:p1a];
    [path addCurveToPoint:p2a controlPoint1:PT(p1a, a1 - M_PI_2, h1) controlPoint2:PT(p2a, a3 + M_PI_2, h2)];
    [path addLineToPoint:p2b];
    [path addCurveToPoint:p1b controlPoint1:PT(p2b, a4 - M_PI_2, h2) controlPoint2:PT(p1b, a2 + M_PI_2, h1)];
    [path closePath];
#undef PT
    return path;
}

@interface GooFanView ()
@property (assign, nonatomic) CGPoint anchor;
@property (strong, nonatomic) NSArray<GooFanItem *> *items;
@property (strong, nonatomic) NSMutableArray<UIButton *> *blobs;
@property (strong, nonatomic) NSMutableArray<CAShapeLayer *> *necks;
@property (strong, nonatomic) UIView *fab;
@property (strong, nonatomic) UIImageView *fabIcon;
@property (strong, nonatomic) NSMutableArray<NSValue *> *targets;
@property (strong, nonatomic) CADisplayLink *link;
@property (assign, nonatomic) CFTimeInterval linkEnd;
@property (assign, nonatomic) BOOL opened;
@property (assign, nonatomic) BOOL closing;
@property (assign, nonatomic) NSInteger generation;
@end

@implementation GooFanView

+ (UIImage *)glyph:(NSString *)name {
    CGSize size = CGSizeMake(24, 24);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        UIBezierPath *p = [UIBezierPath bezierPath];
        p.lineWidth = 2; p.lineCapStyle = kCGLineCapRound; p.lineJoinStyle = kCGLineJoinRound;
        [[UIColor blackColor] setStroke];
        [[UIColor blackColor] setFill];
        if ([name isEqualToString:@"photo"]) {
            [p appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.5, 4.5, 17, 15) cornerRadius:3.5]];
            [p appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(7.3, 8.3, 3.4, 3.4)]];
            [p moveToPoint:CGPointMake(4.5, 17.5)]; [p addLineToPoint:CGPointMake(9.1, 12.9)]; [p addLineToPoint:CGPointMake(11.2, 12.9)]; [p addLineToPoint:CGPointMake(13, 14.7)];
            [p moveToPoint:CGPointMake(13, 14.7)]; [p addLineToPoint:CGPointMake(15.1, 12.6)]; [p addLineToPoint:CGPointMake(17.2, 12.6)]; [p addLineToPoint:CGPointMake(20, 15.4)];
            [p stroke];
        } else if ([name isEqualToString:@"camera"]) {
            [p moveToPoint:CGPointMake(4, 8.5)];
            [p addQuadCurveToPoint:CGPointMake(6.5, 6) controlPoint:CGPointMake(4, 6)];
            [p addLineToPoint:CGPointMake(7.8, 6)]; [p addLineToPoint:CGPointMake(9.2, 4)]; [p addLineToPoint:CGPointMake(14.8, 4)]; [p addLineToPoint:CGPointMake(16.2, 6)];
            [p addLineToPoint:CGPointMake(17.5, 6)];
            [p addQuadCurveToPoint:CGPointMake(20, 8.5) controlPoint:CGPointMake(20, 6)];
            [p addLineToPoint:CGPointMake(20, 16.5)];
            [p addQuadCurveToPoint:CGPointMake(17.5, 19) controlPoint:CGPointMake(20, 19)];
            [p addLineToPoint:CGPointMake(6.5, 19)];
            [p addQuadCurveToPoint:CGPointMake(4, 16.5) controlPoint:CGPointMake(4, 19)];
            [p closePath];
            [p appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(8.6, 9, 6.8, 6.8)]];
            [p stroke];
        } else if ([name isEqualToString:@"file"]) {
            [p moveToPoint:CGPointMake(14, 3)]; [p addLineToPoint:CGPointMake(7.5, 3)];
            [p addQuadCurveToPoint:CGPointMake(5, 5.5) controlPoint:CGPointMake(5, 3)];
            [p addLineToPoint:CGPointMake(5, 18.5)];
            [p addQuadCurveToPoint:CGPointMake(7.5, 21) controlPoint:CGPointMake(5, 21)];
            [p addLineToPoint:CGPointMake(16.5, 21)];
            [p addQuadCurveToPoint:CGPointMake(19, 18.5) controlPoint:CGPointMake(19, 21)];
            [p addLineToPoint:CGPointMake(19, 8)]; [p closePath];
            [p moveToPoint:CGPointMake(14, 3)]; [p addLineToPoint:CGPointMake(14, 8)]; [p addLineToPoint:CGPointMake(19, 8)];
            [p moveToPoint:CGPointMake(9, 13)]; [p addLineToPoint:CGPointMake(15, 13)];
            [p moveToPoint:CGPointMake(9, 17)]; [p addLineToPoint:CGPointMake(13, 17)];
            [p stroke];
        } else if ([name isEqualToString:@"search"]) {
            [p appendPath:[UIBezierPath bezierPathWithOvalInRect:CGRectMake(4, 4, 12.5, 12.5)]];
            [p moveToPoint:CGPointMake(14.8, 14.8)]; [p addLineToPoint:CGPointMake(20, 20)];
            [p stroke];
        } else if ([name isEqualToString:@"dots"]) {
            for (NSInteger i = 0; i < 3; i++) [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(3.2 + i * 7.4, 10.2, 3.6, 3.6)] fill];
        } else {   // plus
            p.lineWidth = 2.4;
            [p moveToPoint:CGPointMake(12, 5)]; [p addLineToPoint:CGPointMake(12, 19)];
            [p moveToPoint:CGPointMake(5, 12)]; [p addLineToPoint:CGPointMake(19, 12)];
            [p stroke];
        }
    }];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

- (instancetype)initWithFrame:(CGRect)frame anchor:(CGPoint)anchor items:(NSArray<GooFanItem *> *)items {
    return [self initWithFrame:frame anchor:anchor rowY:0 items:items];
}

- (instancetype)initWithFrame:(CGRect)frame anchor:(CGPoint)anchor rowY:(CGFloat)rowY items:(NSArray<GooFanItem *> *)items {
    self = [super initWithFrame:frame];
    if (self) {
        _anchor = anchor;
        _items = items;
        self.backgroundColor = [UIColor clearColor];
        self.accessibilityViewIsModal = YES;
        // The same look as the + of the message box when it is closed: the colour of the box, a thin border and the grey icon
        // (the accent only marks a switched-on action), so that the + simply turns into the row of buttons.
        UIColor *fill = [[Theme surface] colorWithAlphaComponent:1], *ink = [Theme secondaryText];
        UIColor *edge = [Theme border];
        // The blobs are one soft body: they share a drop shadow (the necks too) so they read as a single droplet lifting off the box.
        UIColor *shadow = [UIColor blackColor];

        // angles: a fan opening upward from the + (the + sits at the left of the box, so it does not go off the screen)
        NSInteger n = (NSInteger)items.count;
        CGFloat step = 22.0 * M_PI / 180.0;
        CGFloat start = -90.0 * M_PI / 180.0;
        if (anchor.x > frame.size.width - 120) { start = -90.0 * M_PI / 180.0 - step * (n - 1); }   // + at the right: fan to the left
        _targets = [NSMutableArray array];
        _blobs = [NSMutableArray array];
        _necks = [NSMutableArray array];
        for (NSInteger i = 0; i < n; i++) {
            CGFloat a = start + step * i;
            CGPoint t = CGPointMake(anchor.x + cos(a) * kRadius, anchor.y + sin(a) * kRadius);
            if (rowY > 0) {   // a straight row along the message box, the first button right above the +
                CGFloat gap = kBlobR * 2 + 10;
                CGFloat dir = (anchor.x + gap * (n - 1) + kBlobR + 8 > frame.size.width) ? -1 : 1;   // no room on the right: run to the left
                t = CGPointMake(anchor.x + dir * gap * i, rowY);
            }
            [_targets addObject:[NSValue valueWithCGPoint:t]];
            CAShapeLayer *neck = [CAShapeLayer layer];
            neck.fillColor = fill.CGColor;
            
            [self.layer addSublayer:neck];
            [_necks addObject:neck];
        }
        for (NSInteger i = 0; i < n; i++) {
            GooFanItem *item = items[i];
            UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
            b.frame = CGRectMake(0, 0, kBlobR * 2, kBlobR * 2);
            b.center = anchor;
            b.layer.cornerRadius = kBlobR;
            b.backgroundColor = fill;
            b.layer.shadowColor = shadow.CGColor; b.layer.shadowOpacity = 0.22; b.layer.shadowRadius = 8; b.layer.shadowOffset = CGSizeMake(0, 4);
            b.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:b.bounds].CGPath;
            b.tag = i;
            [b setImage:item.icon forState:UIControlStateNormal];
            b.tintColor = ink;
            b.accessibilityLabel = item.title;
            b.layer.borderWidth = 1; b.layer.borderColor = edge.CGColor;
            if (item.highlighted) { b.tintColor = [Theme accent]; b.layer.borderColor = [Theme accent].CGColor; b.layer.borderWidth = 1.5; }
            [b addTarget:self action:@selector(blobTapped:) forControlEvents:UIControlEventTouchUpInside];
            b.transform = CGAffineTransformMakeScale(0.5, 0.5);
            [self addSubview:b];
            [_blobs addObject:b];
        }
        _fab = [[UIView alloc] initWithFrame:CGRectMake(anchor.x - kFabR, anchor.y - kFabR, kFabR * 2, kFabR * 2)];
        _fab.backgroundColor = fill;
        _fab.layer.cornerRadius = kFabR;
        _fab.layer.borderWidth = 1; _fab.layer.borderColor = edge.CGColor;
        _fab.layer.shadowColor = shadow.CGColor; _fab.layer.shadowOpacity = 0.22; _fab.layer.shadowRadius = 8; _fab.layer.shadowOffset = CGSizeMake(0, 4);
        _fab.layer.shadowPath = [UIBezierPath bezierPathWithOvalInRect:_fab.bounds].CGPath;   // a path: no offscreen pass per frame
        [self addSubview:_fab];
        _fabIcon = [[UIImageView alloc] initWithImage:[GooFanView glyph:@"plus"]];
        _fabIcon.tintColor = ink;
        _fabIcon.contentMode = UIViewContentModeCenter;
        _fabIcon.frame = _fab.bounds;
        [_fab addSubview:_fabIcon];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fabTapped)];
        [_fab addGestureRecognizer:tap];
        _fab.isAccessibilityElement = YES;
        _fab.accessibilityTraits = UIAccessibilityTraitButton;
        _fab.accessibilityLabel = @"×";
    }
    return self;
}

- (void)dealloc { [self.link invalidate]; }

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit ?: self;   // a touch anywhere else closes the menu
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self closeWithCompletion:nil];
}

- (void)fabTapped { [self closeWithCompletion:nil]; }

#pragma mark Metaball bridges follow the blobs

- (void)startLinkFor:(CFTimeInterval)seconds {
    self.linkEnd = CACurrentMediaTime() + seconds;
    if (self.link) return;
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}

- (void)tick {
    [self updateNecks];
    if (CACurrentMediaTime() > self.linkEnd) { [self.link invalidate]; self.link = nil; [self updateNecks]; }
}

- (void)updateNecks {
    CALayer *fabLayer = self.fab.layer.presentationLayer ?: self.fab.layer;
    CGFloat fabScale = fabLayer.transform.m11 > 0 ? fabLayer.transform.m11 : 1;
    CGPoint fc = fabLayer.position;
    CGFloat fr = kFabR * fabScale;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    for (NSInteger i = 0; i < (NSInteger)self.blobs.count; i++) {
        CALayer *layer = self.blobs[i].layer.presentationLayer ?: self.blobs[i].layer;
        CGFloat scale = layer.transform.m11;
        CGFloat r = kBlobR * scale;
        UIBezierPath *neck = Bridge(fc, fr, layer.position, r, 52);
        self.necks[i].path = neck.CGPath;
    }
    [CATransaction commit];
}

#pragma mark Open and close

- (void)animateBlob:(UIButton *)b to:(CGPoint)to scale:(CGFloat)scale duration:(CFTimeInterval)duration delay:(CFTimeInterval)delay timing:(CAMediaTimingFunction *)timing {
    CGPoint fromPos = b.layer.presentationLayer ? b.layer.presentationLayer.position : b.layer.position;
    CGFloat fromScale = b.layer.presentationLayer ? b.layer.presentationLayer.transform.m11 : 1;
    [b.layer removeAllAnimations];
    b.layer.position = to;
    b.layer.transform = CATransform3DMakeScale(scale, scale, 1);
    CABasicAnimation *pos = [CABasicAnimation animationWithKeyPath:@"position"];
    pos.fromValue = [NSValue valueWithCGPoint:fromPos]; pos.toValue = [NSValue valueWithCGPoint:to];
    CABasicAnimation *sc = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    sc.fromValue = @(fromScale); sc.toValue = @(scale);
    for (CABasicAnimation *a in @[pos, sc]) {
        a.duration = duration;
        a.timingFunction = timing;
        a.beginTime = CACurrentMediaTime() + delay;
        a.fillMode = kCAFillModeBackwards;
        [b.layer addAnimation:a forKey:a.keyPath];
    }
}

- (void)open {
    if (self.opened) return;
    self.opened = YES;
    self.generation++;
    BOOL still = [Material reduceMotion];
    NSInteger n = (NSInteger)self.blobs.count;
    if (still) {
        for (NSInteger i = 0; i < n; i++) {
            self.blobs[i].transform = CGAffineTransformIdentity;
            self.blobs[i].center = [self.targets[i] CGPointValue];
        }
        self.fabIcon.transform = CGAffineTransformMakeRotation(M_PI_4 * 3);
        return;
    }
    CAMediaTimingFunction *out = [CAMediaTimingFunction functionWithControlPoints:0.3 :1.45 :0.45 :1];   // overshoot: the droplet splits off
    for (NSInteger i = 0; i < n; i++) {
        [self animateBlob:self.blobs[i] to:[self.targets[i] CGPointValue] scale:1 duration:0.7 delay:i * 0.045 timing:out];
    }
    // the + squashes like the droplet and turns into ×
    CAKeyframeAnimation *squash = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    squash.values = @[@1, @0.86, @1.06, @1]; squash.keyTimes = @[@0, @0.3, @0.65, @1]; squash.duration = 0.56;
    [self.fab.layer addAnimation:squash forKey:@"squash"];
    [UIView animateWithDuration:0.55 delay:0 usingSpringWithDamping:0.62 initialSpringVelocity:0 options:0 animations:^{
        self.fabIcon.transform = CGAffineTransformMakeRotation(M_PI_4 * 3);
    } completion:nil];
    [self startLinkFor:0.7 + n * 0.045 + 0.1];
}

- (void)closeWithCompletion:(void (^)(void))completion {
    if (self.closing) return;
    self.closing = YES;
    NSInteger gen = ++self.generation;
    void (^finish)(void) = ^{
        [self.link invalidate]; self.link = nil;
        [self removeFromSuperview];
        if (self.onClosed) self.onClosed();
        if (completion) completion();
    };
    if ([Material reduceMotion]) { finish(); return; }
    NSInteger n = (NSInteger)self.blobs.count;
    CAMediaTimingFunction *in = [CAMediaTimingFunction functionWithControlPoints:0.55 :-0.35 :0.4 :1];   // pulled back stickily
    for (NSInteger i = 0; i < n; i++) {
        [self animateBlob:self.blobs[i] to:self.anchor scale:0.5 duration:0.5 delay:(n - 1 - i) * 0.035 timing:in];
    }
    CAKeyframeAnimation *squash = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    squash.values = @[@1, @0.9, @1.06, @1]; squash.keyTimes = @[@0, @0.3, @0.65, @1]; squash.duration = 0.56;
    squash.beginTime = CACurrentMediaTime() + 0.2;
    squash.fillMode = kCAFillModeBackwards;
    [self.fab.layer addAnimation:squash forKey:@"squash"];
    [UIView animateWithDuration:0.45 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0 options:0 animations:^{
        self.fabIcon.transform = CGAffineTransformIdentity;
    } completion:nil];
    CFTimeInterval total = 0.5 + n * 0.035 + 0.05;
    [self startLinkFor:total];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(total * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.generation == gen) finish();
    });
}

- (void)blobTapped:(UIButton *)sender {
    if (self.closing) return;
    GooFanItem *item = self.items[sender.tag];
    void (^handler)(void) = item.handler;
    if (![Material reduceMotion]) {
        CAKeyframeAnimation *pulse = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        pulse.values = @[@1.1, @1.28, @1]; pulse.duration = 0.26;
        [sender.layer addAnimation:pulse forKey:@"pulse"];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(([Material reduceMotion] ? 0 : 0.2) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self closeWithCompletion:handler];
    });
}

@end
