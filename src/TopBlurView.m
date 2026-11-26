#import "TopBlurView.h"
#import "Theme.h"
#import "Strings.h"

// Xóa lớp tint (màu xám/trắng mặc định của Apple) để chỉ giữ lại độ mờ của kính
void TopBlurStripTint(UIVisualEffectView *view) {
    for (UIView *sub in view.subviews) {
        if (sub == view.contentView) continue;
        NSString *name = NSStringFromClass([sub class]);
        if ([name rangeOfString:@"Backdrop"].location != NSNotFound) continue;
        sub.hidden = YES;
        sub.alpha = 0;
    }
}

// iOS 26 style: Sử dụng System Materials để có độ sâu và "chất" kính giống Apple
static UIBlurEffect *CurrentBlur(void) {
    return [UIBlurEffect effectWithStyle:[Theme darkMode] ? UIBlurEffectStyleSystemThinMaterialDark : UIBlurEffectStyleSystemThinMaterialLight];
}

#pragma mark - Progressive Blur

@interface TopBlurView ()
@property (strong, nonatomic) UIVisualEffectView *blurView;
@property (strong, nonatomic) CAGradientLayer *fadeMaskLayer;
@property (assign, nonatomic) BOOL darkBuilt;
@end

@implementation TopBlurView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = NO;
        self.backgroundColor = [UIColor clearColor];
        self.clipsToBounds = YES;
        
        // 1. Tạo 1 lớp Blur duy nhất thay vì 6 dải
        _blurView = [[UIVisualEffectView alloc] initWithEffect:CurrentBlur()];
        _blurView.userInteractionEnabled = NO;
        _blurView.contentScaleFactor = [UIScreen mainScreen].scale; // Fix lỗi pixel/răng cưa
        [self addSubview:_blurView];
        
        // 2. Tạo Gradient Mask để làm mờ dần (Progressive Fade)
        _fadeMaskLayer = [CAGradientLayer layer];
        // Màu đen = hiện blur, Màu trong suốt = mất blur
        _fadeMaskLayer.colors = @[
            (id)[UIColor blackColor].CGColor,
            (id)[UIColor blackColor].CGColor,
            (id)[UIColor clearColor].CGColor
        ];
        // Chỉnh lại locations để blur không bị "dài quá" (Fade bắt đầu từ 60% đến 100%)
        _fadeMaskLayer.locations = @[@0.0, @0.6, @1.0]; 
        _blurView.layer.mask = _fadeMaskLayer;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rebuild) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)rebuild {
    self.darkBuilt = [Theme darkMode];
    self.blurView.effect = CurrentBlur();
    TopBlurStripTint(self.blurView);
    [self setNeedsLayout];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window) [self rebuild];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.darkBuilt != [Theme darkMode]) { [self rebuild]; }
    
    // Fix lỗi "không ngang mũi tên": Ép chiều cao của blur khớp với view
    self.blurView.frame = self.bounds;
    
    // Tắt animation của mask để tránh bị giật khi scroll
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.fadeMaskLayer.frame = self.bounds;
    [CATransaction commit];
    
    TopBlurStripTint(self.blurView);
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
        _glass.contentScaleFactor = [UIScreen mainScreen].scale;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
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
    self.tint.backgroundColor = [UIColor clearColor];
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
