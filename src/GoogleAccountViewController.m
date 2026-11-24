#import "GoogleAccountViewController.h"
#import "Theme.h"
#import "Material.h"
#import "GoogleAuth.h"
#import "GeminiClient.h"
#import "KeyStore.h"
#import "RootViewController.h"
#import "ChoicePopupViewController.h"
#import "Strings.h"

// The rings follow the accent colour: the outer one is the accent made a little lighter and softer (so the dots stay
// readable on a light card and glow on a dark one), the inner one is its neighbour on the colour wheel.
static void RingColors(UIColor **outer, UIColor **inner) {
    CGFloat h = 0, s = 0, b = 0, a = 0;
    [[Theme accent] getHue:&h saturation:&s brightness:&b alpha:&a];
    BOOL dark = [Theme darkMode];
    CGFloat sat = MIN(0.85, MAX(0.38, s * (dark ? 0.78 : 0.88)));
    CGFloat bri = dark ? MAX(0.86, b) : MIN(0.95, MAX(0.72, b));
    *outer = [UIColor colorWithHue:h saturation:sat brightness:bri alpha:1];
    *inner = [UIColor colorWithHue:fmod(h + 0.07, 1.0) saturation:MAX(0.3, sat * 0.85) brightness:MIN(1.0, bri + (dark ? 0 : 0.03)) alpha:1];
}

#pragma mark - Ring

@interface GoogleRingView ()
@property (strong, nonatomic) CAShapeLayer *outer;
@property (strong, nonatomic) CAShapeLayer *inner;
@property (strong, nonatomic) UIImageView *logo;
@end

@implementation GoogleRingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        _outer = [CAShapeLayer layer];
        _inner = [CAShapeLayer layer];
        for (CAShapeLayer *ring in @[_outer, _inner]) {
            ring.fillColor = nil;
            ring.lineCap = kCALineCapRound;
            [self.layer addSublayer:ring];
        }
        _inner.opacity = 0.7;
        _logo = [[UIImageView alloc] initWithImage:[Theme claudeMarkImage]];
        _logo.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_logo];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startSpinning) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshLogo) name:kNotifThemeChanged object:nil];
        [self applyRingColors];
    }
    return self;
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)applyRingColors {
    UIColor *outer = nil, *inner = nil;
    RingColors(&outer, &inner);
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.outer.strokeColor = outer.CGColor;
    self.inner.strokeColor = inner.CGColor;
    [CATransaction commit];
}

// The mark takes the colour of the app icon, so it changes with the icon; the rings take the accent.
- (void)refreshLogo {
    [self applyRingColors];
    UIImage *image = [Theme claudeMarkImage];
    if (image && image != self.logo.image) {
        [UIView transitionWithView:self.logo duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ self.logo.image = image; } completion:nil];
    }
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) [self refreshLogo];
    if (self.window) [self startSpinning]; else { [self.outer removeAllAnimations]; [self.inner removeAllAnimations]; }
}

// A circle of `count` dots of the given size: a dashed stroke with round caps and almost zero-length dashes.
- (void)configureRing:(CAShapeLayer *)ring radius:(CGFloat)radius count:(NSInteger)count dot:(CGFloat)dot {
    CGRect bounds = self.bounds;
    ring.bounds = bounds;
    ring.position = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    ring.path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:M_PI * 1.5 clockwise:YES].CGPath;
    CGFloat step = 2 * M_PI * radius / count;
    ring.lineWidth = dot;
    ring.lineDashPattern = @[@0.01, @(step - 0.01)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = MIN(self.bounds.size.width, self.bounds.size.height);
    if (w < 2) return;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self configureRing:self.outer radius:w * 0.465 count:36 dot:MAX(1.5, w * 0.05)];
    [self configureRing:self.inner radius:w * 0.365 count:26 dot:MAX(1.2, w * 0.034)];
    [CATransaction commit];
    CGFloat mark = w * 0.40;
    self.logo.frame = CGRectMake((self.bounds.size.width - mark) / 2, (self.bounds.size.height - mark) / 2, mark, mark);
}

- (void)startSpinning {
    [self.outer removeAnimationForKey:@"spin"];
    [self.inner removeAnimationForKey:@"spin"];
    if (UIAccessibilityIsReduceMotionEnabled() || self.window == nil) return;
    NSArray *rings = @[self.outer, self.inner];
    NSArray *seconds = @[@48, @34];
    for (NSInteger i = 0; i < 2; i++) {
        CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        spin.fromValue = @0;
        spin.toValue = @(i == 0 ? 2 * M_PI : -2 * M_PI);
        spin.duration = [seconds[i] doubleValue];
        spin.repeatCount = HUGE_VALF;
        spin.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        [rings[i] addAnimation:spin forKey:@"spin"];
    }
}

@end

#pragma mark - Card

@interface GoogleAccountCardView ()
@property (strong, nonatomic) GoogleRingView *ring;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *detailLabel;
@property (strong, nonatomic) UIImageView *chevron;
@end

@implementation GoogleAccountCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.masksToBounds = YES;
        _ring = [[GoogleRingView alloc] init];
        [self addSubview:_ring];
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];
        _detailLabel = [[UILabel alloc] init];
        _detailLabel.font = [UIFont systemFontOfSize:14];
        _detailLabel.numberOfLines = 3;
        _detailLabel.userInteractionEnabled = NO;
        [self addSubview:_detailLabel];
        _chevron = [[UIImageView alloc] initWithImage:[Material chevronImageRight]];
        _chevron.userInteractionEnabled = NO;
        [self addSubview:_chevron];
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
        self.accessibilityTraits = UIAccessibilityTraitButton;
        [self refresh];
    }
    return self;
}

- (void)touchDown {
    if (![Material active] || [Material reduceMotion]) return;
    [Material animateSpatial:MaterialMotionFast animations:^{ self.transform = CGAffineTransformMakeScale(0.98, 0.98); } completion:nil];
}

- (void)touchUp {
    if (CGAffineTransformIsIdentity(self.transform)) return;
    [Material animateSpatial:MaterialMotionFast animations:^{ self.transform = CGAffineTransformIdentity; } completion:nil];
}

- (void)refresh {
    self.backgroundColor = [Theme surface];
    self.titleLabel.textColor = [Theme text];
    self.detailLabel.textColor = [Theme secondaryText];
    self.chevron.tintColor = [Theme secondaryText];
    if ([GoogleAuth isSignedIn]) {
        self.titleLabel.text = L(@"google_account_title");
        NSString *email = [GoogleAuth accountEmail];
        self.detailLabel.text = email.length > 0 ? email : L(@"google_account_signed_in");
    } else {
        self.titleLabel.text = L(@"google_account_title");
        self.detailLabel.text = L(@"google_account_desc");
    }
    self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", self.titleLabel.text, self.detailLabel.text];
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat w = self.bounds.size.width, h = self.bounds.size.height;
    self.layer.cornerRadius = MIN(MR(12, 28), h / 2);
    CGFloat ringSize = 66;
    self.ring.frame = CGRectMake(14, (h - ringSize) / 2, ringSize, ringSize);
    CGFloat x = 14 + ringSize + 12;
    CGFloat right = w - 14 - 14 - 10;
    self.chevron.frame = CGRectMake(w - 14 - 14, (h - 20) / 2, 14, 20);
    CGFloat textWidth = MAX(40, right - x);
    CGSize detail = [self.detailLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)];
    CGFloat titleHeight = ceil(self.titleLabel.font.lineHeight);
    CGFloat detailHeight = MIN(ceil(detail.height), 3 * ceil(self.detailLabel.font.lineHeight));
    CGFloat total = titleHeight + 2 + detailHeight;
    CGFloat y = (h - total) / 2;
    self.titleLabel.frame = CGRectMake(x, y, textWidth, titleHeight);
    self.detailLabel.frame = CGRectMake(x, y + titleHeight + 2, textWidth, detailHeight);
}

@end

#pragma mark - Screen

@interface GoogleAccountViewController () <UITextFieldDelegate>
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) GoogleRingView *ring;
@property (strong, nonatomic) UILabel *nameLabel;
@property (strong, nonatomic) UILabel *emailLabel;
@property (strong, nonatomic) UILabel *infoLabel;
@property (strong, nonatomic) UIButton *signInButton;
@property (strong, nonatomic) UIButton *checkButton;
@property (strong, nonatomic) UIButton *signOutButton;
@property (strong, nonatomic) UIButton *keyButton;
@property (strong, nonatomic) UILabel *statusLabel;
@property (assign, nonatomic) BOOL busy;
@end

@implementation GoogleAccountViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"google_account_title");
    self.view.backgroundColor = [Theme background];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.alwaysBounceVertical = YES;
    [Material installStretchOnScrollView:self.scrollView];   // Material 3 stretch at the ends
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.scrollView];

    self.ring = [[GoogleRingView alloc] init];
    [self.scrollView addSubview:self.ring];

    self.nameLabel = [[UILabel alloc] init];
    self.nameLabel.font = [UIFont systemFontOfSize:28 weight:UIFontWeightBold];
    self.nameLabel.textAlignment = NSTextAlignmentCenter;
    self.nameLabel.adjustsFontSizeToFitWidth = YES;
    self.nameLabel.minimumScaleFactor = 0.7;
    [self.scrollView addSubview:self.nameLabel];

    self.emailLabel = [[UILabel alloc] init];
    self.emailLabel.font = [UIFont systemFontOfSize:17];
    self.emailLabel.textAlignment = NSTextAlignmentCenter;
    self.emailLabel.numberOfLines = 2;
    [self.scrollView addSubview:self.emailLabel];

    self.infoLabel = [[UILabel alloc] init];
    self.infoLabel.font = [UIFont systemFontOfSize:14];
    self.infoLabel.textAlignment = NSTextAlignmentCenter;
    self.infoLabel.numberOfLines = 0;
    [self.scrollView addSubview:self.infoLabel];

    self.signInButton = [self makeButton:@selector(signInTapped)];
    self.checkButton = [self makeButton:@selector(checkTapped)];
    self.signOutButton = [self makeButton:@selector(signOutTapped)];
    self.keyButton = [self makeButton:@selector(keyTapped)];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:15];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.scrollView addSubview:self.statusLabel];

    [Material styleTitleForController:self];
    [self applyTheme];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme) name:kNotifThemeChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refresh) name:kNotifKeyChanged object:nil];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (UIButton *)makeButton:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleLabel.minimumScaleFactor = 0.8;
    button.clipsToBounds = YES;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:button];
    return button;
}

- (void)applyTheme {
    self.view.backgroundColor = [Theme background];
    [Material styleTitleForController:self];
    self.nameLabel.textColor = [Theme text];
    self.emailLabel.textColor = [Theme secondaryText];
    self.infoLabel.textColor = [Theme secondaryText];
    self.signInButton.backgroundColor = [Theme accent];
    [self.signInButton setTitleColor:[Theme onAccent] forState:UIControlStateNormal];
    [self.signInButton setTitleColor:[[Theme onAccent] colorWithAlphaComponent:0.5] forState:UIControlStateDisabled];
    // tonal buttons (Material 3): a soft fill, text in the accent; sign out is tonal in the error colour
    UIColor *tonal = [[Theme accent] colorWithAlphaComponent:0.14];
    for (UIButton *button in @[self.checkButton, self.keyButton]) {
        button.backgroundColor = tonal;
        [button setTitleColor:[Theme accent] forState:UIControlStateNormal];
        [button setTitleColor:[[Theme accent] colorWithAlphaComponent:0.4] forState:UIControlStateDisabled];
    }
    self.signOutButton.backgroundColor = [[Theme error] colorWithAlphaComponent:0.14];
    [self.signOutButton setTitleColor:[Theme error] forState:UIControlStateNormal];
    [self.signOutButton setTitleColor:[[Theme error] colorWithAlphaComponent:0.4] forState:UIControlStateDisabled];
    [self refresh];
}

- (void)refresh {
    BOOL signedIn = [GoogleAuth isSignedIn];
    self.nameLabel.text = L(@"google_account_title");
    NSString *email = [GoogleAuth accountEmail];
    if (signedIn) {
        self.emailLabel.text = email.length > 0 ? email : L(@"google_account_signed_in");
        self.infoLabel.text = L(@"google_account_active");
    } else {
        self.emailLabel.text = L(@"google_account_not_signed_in");
        self.infoLabel.text = L(@"google_account_desc");
    }
    [self.signInButton setTitle:signedIn ? L(@"google_sign_in_again") : L(@"google_sign_in") forState:UIControlStateNormal];
    [self.checkButton setTitle:L(@"google_check") forState:UIControlStateNormal];
    [self.signOutButton setTitle:L(@"google_sign_out") forState:UIControlStateNormal];
    [self.keyButton setTitle:L(@"google_use_key") forState:UIControlStateNormal];
    self.checkButton.hidden = !signedIn;
    self.signOutButton.hidden = !signedIn;
    for (UIButton *button in @[self.signInButton, self.checkButton, self.signOutButton, self.keyButton]) {
        button.enabled = !self.busy;
        button.alpha = self.busy ? 0.7 : 1;
    }
    [self.view setNeedsLayout];
}

- (void)setBusy:(BOOL)busy {
    _busy = busy;
    [self refresh];
}

- (void)setStatus:(NSString *)text success:(BOOL)success {
    self.statusLabel.text = text;
    self.statusLabel.textColor = text.length == 0 ? [Theme secondaryText] : (success ? [Theme success] : [Theme error]);
    [self.view setNeedsLayout];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refresh];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat total = self.view.bounds.size.width;
    CGFloat width = MIN(total - 40, 520);
    CGFloat x = (total - width) / 2;
    CGFloat y = 24;
    CGFloat ringSize = 132;
    self.ring.frame = CGRectMake((total - ringSize) / 2, y, ringSize, ringSize);
    y += ringSize + 18;
    self.nameLabel.frame = CGRectMake(x, y, width, 34);
    y += 34 + 4;
    CGSize email = [self.emailLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    self.emailLabel.frame = CGRectMake(x, y, width, ceil(email.height));
    y += ceil(email.height) + 10;
    CGSize info = [self.infoLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
    self.infoLabel.frame = CGRectMake(x, y, width, ceil(info.height));
    y += ceil(info.height) + 28;

    CGFloat buttonHeight = 52;
    NSArray *buttons = @[self.signInButton, self.checkButton, self.signOutButton, self.keyButton];
    for (UIButton *button in buttons) {
        if (button.hidden) continue;
        button.frame = CGRectMake(x, y, width, buttonHeight);
        button.layer.cornerRadius = MIN(MR(12, 26), buttonHeight / 2);
        y += buttonHeight + 10;
    }
    if (self.statusLabel.text.length > 0) {
        CGSize status = [self.statusLabel sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)];
        self.statusLabel.frame = CGRectMake(x, y + 4, width, ceil(status.height));
        y += 4 + ceil(status.height) + 10;
    } else {
        self.statusLabel.frame = CGRectZero;
    }
    y += 24;
    self.scrollView.contentSize = CGSizeMake(total, y);
}

#pragma mark - Actions

- (void)signInTapped {
    if (self.busy) return;
    if ([GoogleAuth builtInClientID].length > 0) {
        [self startSignInWithClientID:[GoogleAuth builtInClientID] projectID:[GoogleAuth savedProjectID]];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"google_setup_title")
                                                                   message:L(@"google_setup_msg")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = L(@"google_client_id_placeholder");
        field.text = [GoogleAuth savedClientID];
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.keyboardType = UIKeyboardTypeURL;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = L(@"google_project_placeholder");
        field.text = [GoogleAuth savedProjectID];
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:L(@"google_continue") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        GoogleAccountViewController *me = weakSelf;
        if (!me) return;
        [me startSignInWithClientID:alert.textFields[0].text projectID:alert.textFields[1].text];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)startSignInWithClientID:(NSString *)clientID projectID:(NSString *)projectID {
    [self setStatus:@"" success:NO];
    self.busy = YES;
    __weak typeof(self) weakSelf = self;
    [GoogleAuth signInWithClientID:clientID projectID:projectID presenter:self completion:^(BOOL ok, NSString *message) {
        GoogleAccountViewController *me = weakSelf;
        if (!me) return;
        if (!ok) {
            me.busy = NO;
            if (message.length > 0) [me setStatus:message success:NO];
            return;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
        [me verifyConnection];
    }];
}

- (void)checkTapped {
    if (self.busy) return;
    [self setStatus:L(@"google_checking") success:YES];
    self.statusLabel.textColor = [Theme secondaryText];
    self.busy = YES;
    [self verifyConnection];
}

// Asks Gemini for the model list with the Google session: proves that the account and the project really work.
- (void)verifyConnection {
    __weak typeof(self) weakSelf = self;
    [GeminiClient verifyKey:kGoogleOAuthKeyMarker completion:^(GeminiCheckResult result, NSInteger count, NSInteger httpStatus) {
        GoogleAccountViewController *me = weakSelf;
        if (!me) return;
        me.busy = NO;
        if (result == GeminiCheckOK) {
            [me setStatus:[NSString stringWithFormat:L(@"status_ok"), (long)count] success:YES];
        } else if (result == GeminiCheckRateLimited) {
            [me setStatus:L(@"status_rate") success:NO];
        } else if (result == GeminiCheckNetworkError) {
            [me setStatus:L(@"status_network") success:NO];
        } else {
            NSString *msg = httpStatus == 0 ? L(@"google_err_expired") : [NSString stringWithFormat:L(@"google_status_denied"), (long)httpStatus];
            [me setStatus:msg success:NO];
        }
    }];
}

- (void)signOutTapped {
    if (self.busy) return;
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:L(@"google_sign_out") message:L(@"google_sign_out_confirm")];
    [alert addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[ChoiceAction actionWithTitle:L(@"google_sign_out") style:UIAlertActionStyleDestructive handler:^(id action) {
        GoogleAccountViewController *me = weakSelf;
        if (!me) return;
        [GoogleAuth signOut];
        [me setStatus:L(@"google_signed_out") success:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
        [me refresh];
    }]];
    [alert presentFromViewController:self];
}

- (void)keyTapped {
    RootViewController *keyScreen = [[RootViewController alloc] init];
    keyScreen.embedded = YES;
    keyScreen.provider = AIProviderGemini;
    [self.navigationController pushViewController:keyScreen animated:YES];
}

@end
