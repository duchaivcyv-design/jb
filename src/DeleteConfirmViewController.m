#import "DeleteConfirmViewController.h"
#import "ChoicePopupViewController.h"
#import "Theme.h"
#import "Material.h"
#import "Strings.h"

static const CGFloat kCan = 38;                  // size of the drawing
static const CGFloat kUnit = 38.0 / 32.0;        // the film is drawn on a 32 x 32 grid
static const NSTimeInterval kFilm = 1.25;        // length of the film
static inline CGPoint G(CGFloat x, CGFloat y) { return CGPointMake(x * kUnit, y * kUnit); }

#pragma mark - Trash can

@interface TrashCanView ()
@property (strong, nonatomic) CALayer *lidLayer;
@property (strong, nonatomic) CALayer *bodyLayer;
@property (strong, nonatomic) CALayer *docLayer;
@property (strong, nonatomic) CAShapeLayer *lidShape;
@property (strong, nonatomic) CAShapeLayer *bodyShape;
@property (strong, nonatomic) CAShapeLayer *docFill;
@property (strong, nonatomic) CAShapeLayer *docLines;
@end

@implementation TrashCanView

- (CAShapeLayer *)strokeLayerWithPath:(UIBezierPath *)path width:(CGFloat)width {
    CAShapeLayer *layer = [CAShapeLayer layer];
    layer.frame = CGRectMake(0, 0, kCan, kCan);
    layer.path = path.CGPath;
    layer.fillColor = nil;
    layer.lineWidth = width * kUnit;
    layer.lineCap = kCALineCapRound;
    layer.lineJoin = kCALineJoinRound;
    return layer;
}

// A group that turns / scales about (px, py) of the 32 grid.
- (CALayer *)groupAbout:(CGPoint)pivot {
    CALayer *group = [CALayer layer];
    group.bounds = CGRectMake(0, 0, kCan, kCan);
    group.anchorPoint = CGPointMake(pivot.x / 32.0, pivot.y / 32.0);
    group.position = G(pivot.x, pivot.y);
    [self.layer addSublayer:group];
    return group;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:CGRectMake(0, 0, kCan, kCan)];
    if (self) {
        self.userInteractionEnabled = NO;
        _strokeColor = [Theme error];
        _sheetColor = [Theme surface];

        // the sheet: only visible above the mouth of the can, so it disappears into it as it falls
        UIBezierPath *fillPath = [UIBezierPath bezierPath];
        [fillPath moveToPoint:G(12.5, -1.5)]; [fillPath addLineToPoint:G(17.5, -1.5)]; [fillPath addLineToPoint:G(20.5, 1.5)];
        [fillPath addLineToPoint:G(20.5, 9.5)]; [fillPath addLineToPoint:G(12.5, 9.5)]; [fillPath closePath];
        UIBezierPath *linePath = [UIBezierPath bezierPath];
        [linePath moveToPoint:G(14.5, 3.5)]; [linePath addLineToPoint:G(18, 3.5)];
        [linePath moveToPoint:G(14.5, 6)];   [linePath addLineToPoint:G(18, 6)];
        CALayer *clip = [CALayer layer];
        clip.frame = CGRectMake(-10 * kUnit, -30 * kUnit, 52 * kUnit, 40.5 * kUnit);
        clip.masksToBounds = YES;
        [self.layer addSublayer:clip];
        _docLayer = [CALayer layer];
        _docLayer.bounds = CGRectMake(0, 0, kCan, kCan);
        _docLayer.anchorPoint = CGPointMake(16.5 / 32.0, 4.0 / 32.0);
        _docLayer.position = CGPointMake(G(16.5, 4).x - clip.frame.origin.x, G(16.5, 4).y - clip.frame.origin.y);
        _docLayer.opacity = 0;
        [clip addSublayer:_docLayer];
        _docFill = [self strokeLayerWithPath:fillPath width:1.5];
        _docLines = [self strokeLayerWithPath:linePath width:1.2];
        [_docLayer addSublayer:_docFill];
        [_docLayer addSublayer:_docLines];

        // the lid: line + handle, turns about its left end
        UIBezierPath *lidPath = [UIBezierPath bezierPath];
        [lidPath moveToPoint:G(5.5, 9.5)]; [lidPath addLineToPoint:G(26.5, 9.5)];
        [lidPath moveToPoint:G(12.5, 9)]; [lidPath addLineToPoint:G(12.5, 7)];
        [lidPath addQuadCurveToPoint:G(14, 5.5) controlPoint:G(12.5, 5.5)];
        [lidPath addLineToPoint:G(18, 5.5)];
        [lidPath addQuadCurveToPoint:G(19.5, 7) controlPoint:G(19.5, 5.5)];
        [lidPath addLineToPoint:G(19.5, 9)];
        _lidLayer = [self groupAbout:CGPointMake(6, 9.5)];
        _lidShape = [self strokeLayerWithPath:lidPath width:1.9];
        // the group's bounds start at its own origin: shift the drawing so it keeps its place
        _lidShape.frame = CGRectMake(0, 0, kCan, kCan);
        [_lidLayer addSublayer:_lidShape];

        // the body: bucket + two ribs, squashes when the lid lands
        UIBezierPath *bodyPath = [UIBezierPath bezierPath];
        [bodyPath moveToPoint:G(8, 10.5)]; [bodyPath addLineToPoint:G(9.3, 25.1)];
        [bodyPath addQuadCurveToPoint:G(11.7, 27.3) controlPoint:G(9.3, 27.3)];
        [bodyPath addLineToPoint:G(20.3, 27.3)];
        [bodyPath addQuadCurveToPoint:G(22.7, 25.1) controlPoint:G(22.7, 27.3)];
        [bodyPath addLineToPoint:G(24, 10.5)];
        [bodyPath moveToPoint:G(13.5, 15)]; [bodyPath addLineToPoint:G(13.5, 22.5)];
        [bodyPath moveToPoint:G(18.5, 15)]; [bodyPath addLineToPoint:G(18.5, 22.5)];
        _bodyLayer = [self groupAbout:CGPointMake(16, 27)];
        _bodyShape = [self strokeLayerWithPath:bodyPath width:1.9];
        [_bodyLayer addSublayer:_bodyShape];
        [self applyColors];
    }
    return self;
}

- (CGSize)intrinsicContentSize { return CGSizeMake(kCan, kCan); }

- (void)applyColors {
    self.lidShape.strokeColor = self.strokeColor.CGColor;
    self.bodyShape.strokeColor = self.strokeColor.CGColor;
    self.docFill.strokeColor = self.strokeColor.CGColor;
    self.docFill.fillColor = self.sheetColor.CGColor;
    self.docLines.strokeColor = self.strokeColor.CGColor;
}

- (void)setStrokeColor:(UIColor *)strokeColor { _strokeColor = strokeColor; [self applyColors]; }
- (void)setSheetColor:(UIColor *)sheetColor { _sheetColor = sheetColor; [self applyColors]; }

- (CAKeyframeAnimation *)film:(NSString *)keyPath values:(NSArray *)values times:(NSArray *)times curve:(NSString *)curve {
    CAKeyframeAnimation *a = [CAKeyframeAnimation animationWithKeyPath:keyPath];
    a.values = values;
    a.keyTimes = times;
    a.duration = kFilm;
    NSMutableArray *functions = [NSMutableArray array];
    for (NSUInteger i = 0; i + 1 < values.count; i++) [functions addObject:[CAMediaTimingFunction functionWithName:curve]];
    a.timingFunctions = functions;
    return a;
}

- (void)playDeleteFilm {
    if ([Material reduceMotion]) { self.docLayer.opacity = 0; return; }
    for (CALayer *layer in @[self.lidLayer, self.bodyLayer, self.docLayer, self.layer]) [layer removeAnimationForKey:@"film"];
    CGFloat deg = M_PI / 180.0;

    // lid: opens to -38 deg, waits, snaps shut with a small overshoot (+7 deg)
    CAKeyframeAnimation *lid = [self film:@"transform.rotation.z"
                                   values:@[@0, @(-38 * deg), @(-38 * deg), @(7 * deg), @0, @0]
                                    times:@[@0, @0.22, @0.58, @0.74, @0.86, @1]
                                    curve:kCAMediaTimingFunctionEaseInEaseOut];
    [self.lidLayer addAnimation:lid forKey:@"film"];

    // sheet: appears, falls into the can, ends below the mouth (hidden by the clip)
    CAAnimationGroup *doc = [CAAnimationGroup animation];
    doc.duration = kFilm;
    CAKeyframeAnimation *fade = [self film:@"opacity" values:@[@0, @0, @1, @1, @1, @1] times:@[@0, @0.14, @0.26, @0.52, @0.60, @1] curve:kCAMediaTimingFunctionLinear];
    CAKeyframeAnimation *drop = [self film:@"transform.translation.y"
                                    values:@[@(-14 * kUnit), @(-14 * kUnit), @(-12 * kUnit), @(9 * kUnit), @(14 * kUnit), @(14 * kUnit)]
                                     times:@[@0, @0.14, @0.26, @0.52, @0.60, @1]
                                     curve:kCAMediaTimingFunctionEaseIn];
    CAKeyframeAnimation *tilt = [self film:@"transform.rotation.z"
                                    values:@[@(-8 * deg), @(-8 * deg), @(-4 * deg), @0, @0, @0]
                                     times:@[@0, @0.14, @0.26, @0.52, @0.60, @1]
                                     curve:kCAMediaTimingFunctionEaseInEaseOut];
    doc.animations = @[fade, drop, tilt];
    [self.docLayer addAnimation:doc forKey:@"film"];

    // body: squashes when the lid lands, then springs back
    CAKeyframeAnimation *squash = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    squash.values = @[[NSValue valueWithCATransform3D:CATransform3DIdentity],
                      [NSValue valueWithCATransform3D:CATransform3DIdentity],
                      [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.07, 0.9, 1)],
                      [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.97, 1.04, 1)],
                      [NSValue valueWithCATransform3D:CATransform3DIdentity]];
    squash.keyTimes = @[@0, @0.72, @0.80, @0.90, @1];
    squash.duration = kFilm;
    squash.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [self.bodyLayer addAnimation:squash forKey:@"film"];

    // the whole can gives a little (the tile dips 2 pt as the lid lands)
    CAKeyframeAnimation *dip = [self film:@"transform.translation.y" values:@[@0, @0, @2, @(-1), @0] times:@[@0, @0.74, @0.80, @0.90, @1] curve:kCAMediaTimingFunctionEaseOut];
    [self.layer addAnimation:dip forKey:@"film"];
}

@end

#pragma mark - Dialog

@interface DeleteConfirmViewController ()
@property (copy, nonatomic) NSString *titleText;
@property (copy, nonatomic) NSString *messageText;
@property (copy, nonatomic) NSString *confirmText;
@property (copy, nonatomic) void (^onConfirm)(void);
@property (strong, nonatomic) UIView *card;
@property (strong, nonatomic) UIView *tile;
@property (strong, nonatomic) TrashCanView *can;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *deleteButton;
@property (assign, nonatomic) BOOL busy;
@end

@implementation DeleteConfirmViewController

+ (void)presentFrom:(UIViewController *)host title:(NSString *)title message:(NSString *)message
       confirmTitle:(NSString *)confirmTitle onConfirm:(void (^)(void))onConfirm {
    if (![Material active]) {   // Classic design: the usual pop-up
        ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:title message:message];
        [alert addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[ChoiceAction actionWithTitle:confirmTitle style:UIAlertActionStyleDestructive handler:^(id action) {
            if (onConfirm) onConfirm();
        }]];
        [alert presentFromViewController:host];
        return;
    }
    DeleteConfirmViewController *dialog = [[DeleteConfirmViewController alloc] init];
    dialog.titleText = title;
    dialog.messageText = message;
    dialog.confirmText = confirmTitle;
    dialog.onConfirm = onConfirm;
    UIViewController *top = host;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:dialog animated:YES completion:nil];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.8;
    button.clipsToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.card addSubview:button];
    return button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    UIVisualEffectView *backdrop = [Theme backdropBlurView];
    backdrop.frame = self.view.bounds;
    backdrop.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:backdrop];

    self.card = [[UIView alloc] init];
    self.card.backgroundColor = [Theme surface];
    self.card.layer.borderWidth = 1;
    self.card.layer.borderColor = [Theme border].CGColor;
    self.card.layer.shadowColor = [UIColor blackColor].CGColor;
    self.card.layer.shadowOpacity = 0.3;
    self.card.layer.shadowRadius = 26;
    self.card.layer.shadowOffset = CGSizeMake(0, 14);
    [self.view addSubview:self.card];

    self.tile = [[UIView alloc] init];
    self.tile.backgroundColor = [[Theme error] colorWithAlphaComponent:0.14];
    self.tile.layer.cornerRadius = 18;
    [self.card addSubview:self.tile];
    self.can = [[TrashCanView alloc] init];
    self.can.strokeColor = [Theme error];
    self.can.sheetColor = [Theme surface];
    [self.tile addSubview:self.can];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightBold];
    self.titleLabel.textColor = [Theme text];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = self.titleText;
    [self.card addSubview:self.titleLabel];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont systemFontOfSize:14];
    self.messageLabel.textColor = [Theme secondaryText];
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.text = self.messageText;
    [self.card addSubview:self.messageLabel];

    self.cancelButton = [self buttonWithTitle:L(@"cancel") action:@selector(cancelTapped)];
    self.cancelButton.backgroundColor = [UIColor clearColor];
    [self.cancelButton setTitleColor:[Theme text] forState:UIControlStateNormal];
    self.cancelButton.layer.borderWidth = 1;
    self.cancelButton.layer.borderColor = [Theme border].CGColor;

    self.deleteButton = [self buttonWithTitle:self.confirmText action:@selector(deleteTapped)];
    self.deleteButton.backgroundColor = [Theme error];
    [self.deleteButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelTapped)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];

    self.cancelButton.accessibilityLabel = L(@"cancel");
    self.titleLabel.accessibilityTraits |= UIAccessibilityTraitHeader;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat cardWidth = MIN(bounds.size.width - 48, 320);
    CGFloat inner = cardWidth - 44;
    CGFloat y = 22;
    self.tile.frame = CGRectMake(22, y, 60, 60);
    self.can.frame = CGRectMake((60 - kCan) / 2, (60 - kCan) / 2, kCan, kCan);
    y += 60 + 16;
    CGSize t = [self.titleLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)];
    self.titleLabel.frame = CGRectMake(22, y, inner, ceil(t.height));
    y += ceil(t.height) + 6;
    CGSize m = [self.messageLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)];
    self.messageLabel.frame = CGRectMake(22, y, inner, ceil(m.height));
    y += ceil(m.height) + 20;
    CGFloat gap = 8, w = (inner - gap) / 2, h = 42;
    self.cancelButton.frame = CGRectMake(22, y, w, h);
    self.deleteButton.frame = CGRectMake(22 + w + gap, y, w, h);
    CGFloat radius = MR(12, h / 2);
    self.cancelButton.layer.cornerRadius = radius;
    self.deleteButton.layer.cornerRadius = radius;
    y += h + 22;
    self.card.layer.cornerRadius = MR(20, 28);
    CGFloat centerY = safe.top + (bounds.size.height - safe.top - safe.bottom) / 2;
    CGRect frame = CGRectMake((bounds.size.width - cardWidth) / 2, centerY - y / 2, cardWidth, y);
    if (!CGAffineTransformIsIdentity(self.card.transform)) {   // laid out while the card is animating: keep the centre, set the size
        self.card.bounds = CGRectMake(0, 0, cardWidth, y);
        self.card.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    } else {
        self.card.frame = frame;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [Material presentDialogCard:self.card];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [Material dismissDialogCard:self.card];
}

- (void)setButtonsEnabled:(BOOL)enabled {
    for (UIButton *button in @[self.cancelButton, self.deleteButton]) {
        button.enabled = enabled;
        button.alpha = enabled ? 1 : (button == self.cancelButton ? 0.45 : 1);
    }
}

- (void)cancelTapped {
    if (self.busy) return;
    self.busy = YES;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)deleteTapped {
    if (self.busy) return;
    self.busy = YES;
    [self setButtonsEnabled:NO];
    [self.can playDeleteFilm];
    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [haptic prepare];
    BOOL still = [Material reduceMotion];
    __weak typeof(self) weak = self;
    if (!still) {   // the lid lands at 80 % of the film
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kFilm * 0.78 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [haptic impactOccurred]; });
    }
    NSTimeInterval wait = still ? 0.2 : kFilm + 0.1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(wait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        DeleteConfirmViewController *me = weak;
        if (!me) return;
        void (^action)(void) = me.onConfirm;
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, L(@"deleted_announce"));
        [me dismissViewControllerAnimated:YES completion:^{ if (action) action(); }];
    });
}

// A tap outside the card cancels; taps on the card do not.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return touch.view == self.view;
}

@end
