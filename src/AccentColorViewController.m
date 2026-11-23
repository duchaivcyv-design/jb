#import "AccentColorViewController.h"
#import "Material.h"
#import "Theme.h"
#import "Strings.h"

static const uint32_t kSwatchHex[10] = {
    0xA34CBE, 0xD63A6B, 0xD0412F, 0xCC6A1E, 0xCC9A12, 0x4CAF6A, 0x2DB1B1, 0x2F6FD1, 0x6A50BE, 0xBEBEBE
};

static UIColor *MixColors(UIColor *a, UIColor *b, CGFloat t) {
    CGFloat ar = 0, ag = 0, ab = 0, aa = 0, br = 0, bg = 0, bb = 0, ba = 0;
    [a getRed:&ar green:&ag blue:&ab alpha:&aa];
    [b getRed:&br green:&bg blue:&bb alpha:&ba];
    return [UIColor colorWithRed:ar + (br - ar) * t green:ag + (bg - ag) * t blue:ab + (bb - ab) * t alpha:1];
}

static UIColor *ColorFromHex(uint32_t hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0 green:((hex >> 8) & 0xFF) / 255.0 blue:(hex & 0xFF) / 255.0 alpha:1];
}

static BOOL ColorIsLight(UIColor *c) {
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [c getRed:&r green:&g blue:&b alpha:&a];
    return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.62;
}

@interface AccentColorViewController ()
@property (assign, nonatomic) CGFloat hue, sat, bri;
@property (strong, nonatomic) CAGradientLayer *backdrop;
@property (strong, nonatomic) UIView *card;
@property (strong, nonatomic) CAGradientLayer *cardGradient;
@property (strong, nonatomic) UILabel *hexLabel;
@property (strong, nonatomic) UILabel *captionLabel;
@property (strong, nonatomic) MaterialMascotView *mascot;
@property (strong, nonatomic) NSArray<UILabel *> *sliderLabels;
@property (strong, nonatomic) NSArray<MaterialSlider *> *sliders;   // hue, saturation, brightness
@property (strong, nonatomic) NSArray<UIButton *> *swatches;
@property (strong, nonatomic) UIButton *defaultButton;
@end

@implementation AccentColorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"appearance_menu_accent");
    self.view.backgroundColor = [Theme background];
    self.extendedLayoutIncludesOpaqueBars = YES;
    self.edgesForExtendedLayout = UIRectEdgeAll;

    CGFloat h = 0, s = 0, b = 0;
    [Theme getCustomHue:&h saturation:&s brightness:&b];
    self.hue = h; self.sat = s; self.bri = b;

    self.backdrop = [CAGradientLayer layer];
    self.backdrop.startPoint = CGPointMake(0, 0);
    self.backdrop.endPoint = CGPointMake(0.85, 1);
    self.backdrop.locations = @[@0, @0.5, @1];
    [self.view.layer addSublayer:self.backdrop];

    self.card = [[UIView alloc] init];
    self.card.layer.cornerRadius = 28;
    self.card.layer.masksToBounds = YES;
    self.card.layer.borderWidth = 1;
    [self.view addSubview:self.card];
    self.cardGradient = [CAGradientLayer layer];
    self.cardGradient.startPoint = CGPointMake(0, 0);
    self.cardGradient.endPoint = CGPointMake(1, 1);
    [self.card.layer addSublayer:self.cardGradient];

    self.hexLabel = [[UILabel alloc] init];
    self.hexLabel.font = [UIFont systemFontOfSize:30 weight:UIFontWeightHeavy];
    self.hexLabel.adjustsFontSizeToFitWidth = YES;
    self.hexLabel.minimumScaleFactor = 0.7;
    [self.card addSubview:self.hexLabel];
    self.captionLabel = [[UILabel alloc] init];
    self.captionLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    self.captionLabel.text = L(@"appearance_menu_accent");
    [self.card addSubview:self.captionLabel];
    self.mascot = [[MaterialMascotView alloc] init];
    [self.card addSubview:self.mascot];

    NSArray *names = @[L(@"accent_hue"), L(@"accent_saturation"), L(@"accent_brightness")];
    NSMutableArray *labels = [NSMutableArray array], *sliders = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.text = names[i];
        label.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
        [self.view addSubview:label];
        [labels addObject:label];
        MaterialSlider *slider = [[MaterialSlider alloc] init];
        slider.tag = i;
        [slider addTarget:self action:@selector(sliderMoved:) forControlEvents:UIControlEventValueChanged];
        [slider addTarget:self action:@selector(sliderReleased:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        [self.view addSubview:slider];
        [sliders addObject:slider];
    }
    self.sliderLabels = labels;
    self.sliders = sliders;

    NSMutableArray *swatches = [NSMutableArray array];
    for (NSInteger i = 0; i < 10; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        button.backgroundColor = ColorFromHex(kSwatchHex[i]);
        button.tintColor = [UIColor whiteColor];
        [button setImage:[self checkImageForColor:ColorFromHex(kSwatchHex[i])] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(swatchTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:button];
        [swatches addObject:button];
    }
    self.swatches = swatches;

    self.defaultButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.defaultButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [self.defaultButton setTitle:L(@"accent_default") forState:UIControlStateNormal];
    [self.defaultButton addTarget:self action:@selector(defaultTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.defaultButton];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(themeChanged) name:kNotifThemeChanged object:nil];
    [self applyColorsAnimated:NO];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

#pragma mark - Navigation bar (see-through, the page tint runs under it)

- (void)makeBarTransparent {
    UINavigationBar *bar = self.navigationController.navigationBar;
    bar.translucent = YES;
    [bar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    bar.shadowImage = [UIImage new];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self makeBarTransparent];
    [Material styleTitleForController:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.navigationController) [Theme styleNavigationBar:self.navigationController.navigationBar];
}

- (void)themeChanged {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.view.window) [self makeBarTransparent];
        [self applyColorsAnimated:NO];
    });
}

#pragma mark - Colours

- (UIColor *)currentColor { return [Theme colorWithHue:self.hue saturation:self.sat brightness:self.bri]; }

- (UIImage *)checkImageForColor:(UIColor *)color {
    UIColor *ink = ColorIsLight(color) ? [UIColor colorWithWhite:0.1 alpha:1] : [UIColor whiteColor];
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(22, 22)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        UIBezierPath *tick = [UIBezierPath bezierPath];
        [tick moveToPoint:CGPointMake(4.5, 11.5)];
        [tick addLineToPoint:CGPointMake(9.5, 16.5)];
        [tick addLineToPoint:CGPointMake(17.5, 6.5)];
        tick.lineWidth = 2.6; tick.lineCapStyle = kCGLineCapRound; tick.lineJoinStyle = kCGLineJoinRound;
        [ink setStroke];
        [tick stroke];
    }];
}

- (void)applyColorsAnimated:(BOOL)animated {
    BOOL dark = [Theme darkMode];
    UIColor *color = [self currentColor];
    UIColor *base = dark ? [UIColor colorWithRed:0.07 green:0.06 blue:0.08 alpha:1] : [UIColor colorWithRed:0.98 green:0.97 blue:0.98 alpha:1];
    UIColor *text = dark ? [UIColor colorWithWhite:0.96 alpha:1] : [UIColor colorWithWhite:0.10 alpha:1];

    [CATransaction begin];
    [CATransaction setDisableActions:!animated];
    self.backdrop.colors = @[(id)MixColors(base, color, dark ? 0.52 : 0.42).CGColor,
                             (id)MixColors(base, color, dark ? 0.20 : 0.16).CGColor,
                             (id)MixColors(base, color, dark ? 0.06 : 0.05).CGColor];
    self.cardGradient.colors = @[(id)MixColors(color, [UIColor whiteColor], 0.16).CGColor, (id)MixColors(color, [UIColor blackColor], 0.28).CGColor];
    [CATransaction commit];

    BOOL light = ColorIsLight(color);
    UIColor *onColor = light ? [UIColor colorWithWhite:0.1 alpha:1] : [UIColor whiteColor];
    self.card.layer.borderColor = [onColor colorWithAlphaComponent:0.14].CGColor;
    self.hexLabel.textColor = onColor;
    self.hexLabel.text = [Theme hexStringForHue:self.hue saturation:self.sat brightness:self.bri];
    self.captionLabel.textColor = [onColor colorWithAlphaComponent:0.72];
    self.mascot.shapeColor = [onColor colorWithAlphaComponent:0.30];
    self.mascot.hue = self.hue;

    for (UILabel *label in self.sliderLabels) label.textColor = [text colorWithAlphaComponent:0.72];

    MaterialSlider *hueSlider = self.sliders[0], *satSlider = self.sliders[1], *briSlider = self.sliders[2];
    NSMutableArray *rainbow = [NSMutableArray array];
    for (NSInteger i = 0; i <= 12; i++) [rainbow addObject:[Theme colorWithHue:i / 12.0 saturation:0.78 brightness:0.88]];
    hueSlider.trackColors = rainbow;
    satSlider.trackColors = @[[Theme colorWithHue:self.hue saturation:0 brightness:self.bri], [Theme colorWithHue:self.hue saturation:1 brightness:self.bri]];
    briSlider.trackColors = @[[Theme colorWithHue:self.hue saturation:self.sat brightness:0], [Theme colorWithHue:self.hue saturation:self.sat brightness:1]];
    hueSlider.value = self.hue; satSlider.value = self.sat; briSlider.value = self.bri;
    for (MaterialSlider *slider in self.sliders) slider.thumbColor = color;

    self.defaultButton.backgroundColor = [(dark ? [UIColor whiteColor] : [UIColor blackColor]) colorWithAlphaComponent:0.10];
    [self.defaultButton setTitleColor:MixColors(color, dark ? [UIColor whiteColor] : [UIColor blackColor], 0.12) forState:UIControlStateNormal];

    uint32_t current = 0;
    {
        CGFloat r = 0, g = 0, b = 0, a = 0;
        [color getRed:&r green:&g blue:&b alpha:&a];
        current = ((uint32_t)lround(r * 255) << 16) | ((uint32_t)lround(g * 255) << 8) | (uint32_t)lround(b * 255);
    }
    for (UIButton *button in self.swatches) {
        uint32_t hex = kSwatchHex[button.tag];
        NSInteger dr = labs((NSInteger)((hex >> 16) & 0xFF) - (NSInteger)((current >> 16) & 0xFF));
        NSInteger dg = labs((NSInteger)((hex >> 8) & 0xFF) - (NSInteger)((current >> 8) & 0xFF));
        NSInteger db = labs((NSInteger)(hex & 0xFF) - (NSInteger)(current & 0xFF));
        BOOL selected = [Theme customAccentActive] && dr <= 4 && dg <= 4 && db <= 4;
        button.selected = selected;
        CGFloat side = button.bounds.size.width;
        button.layer.cornerRadius = selected ? 14 : (side > 0 ? side / 2.0 : 20);
    }
}

#pragma mark - Actions

- (void)sliderMoved:(MaterialSlider *)slider {
    if (slider.tag == 0) self.hue = slider.value;
    else if (slider.tag == 1) self.sat = slider.value;
    else self.bri = slider.value;
    [self applyColorsAnimated:NO];
}

- (void)commit {
    [Theme setCustomHue:self.hue saturation:self.sat brightness:self.bri];
    [Theme postChange];
}

- (void)sliderReleased:(MaterialSlider *)slider { [self commit]; }

- (void)swatchTapped:(UIButton *)button {
    CGFloat h = 0, s = 0, b = 0, a = 0;
    [ColorFromHex(kSwatchHex[button.tag]) getHue:&h saturation:&s brightness:&b alpha:&a];
    self.hue = h; self.sat = s; self.bri = b;
    [self commit];
    [UIView animateWithDuration:0.25 animations:^{ [self applyColorsAnimated:YES]; }];
}

- (void)defaultTapped {
    [Theme resetCustomAccent];
    CGFloat h = 0, s = 0, b = 0;
    [Theme getCustomHue:&h saturation:&s brightness:&b];
    self.hue = h; self.sat = s; self.bri = b;
    [Theme postChange];
    [self applyColorsAnimated:YES];
}

#pragma mark - Layout (fixed, spread evenly over the screen)

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.backdrop.frame = bounds;
    [CATransaction commit];

    CGFloat top = safe.top + 8;                       // safe.top already includes the navigation bar
    CGFloat bottom = bounds.size.height - MAX(safe.bottom, 12) - 12;
    BOOL wide = bounds.size.width > bounds.size.height * 1.1;
    CGFloat margin = MAX(16, MAX(safe.left, safe.right));
    CGFloat usable = bounds.size.width - 2 * margin;

    CGFloat cardH = 112, sliderBlock = 22 + 46, swatchSide = 44, defaultH = 56;

    if (wide) {
        CGFloat gap = 24;
        CGFloat colW = (usable - gap) / 2.0;
        // left column: card, swatches, default; right column: three sliders
        CGFloat leftTotal = cardH + 2 * swatchSide + 12 + defaultH;
        CGFloat leftGap = MAX(10, (bottom - top - leftTotal) / 3.0);
        CGFloat y = top + leftGap;
        self.card.frame = CGRectMake(margin, y, colW, cardH);
        y += cardH + leftGap;
        [self layoutSwatchesInRect:CGRectMake(margin, y, colW, 2 * swatchSide + 12) side:swatchSide];
        y += 2 * swatchSide + 12 + leftGap;
        self.defaultButton.frame = CGRectMake(margin, y, colW, defaultH);
        CGFloat rightTotal = 3 * sliderBlock;
        CGFloat rightGap = MAX(8, (bottom - top - rightTotal) / 4.0);
        CGFloat ry = top + rightGap;
        for (NSInteger i = 0; i < 3; i++) {
            self.sliderLabels[i].frame = CGRectMake(margin + colW + gap + 6, ry, colW - 12, 20);
            self.sliders[i].frame = CGRectMake(margin + colW + gap, ry + 22, colW, 44);
            ry += sliderBlock + rightGap;
        }
    } else {
        CGFloat total = cardH + 3 * sliderBlock + 2 * swatchSide + 12 + defaultH;
        CGFloat gap = MAX(10, MIN(34, (bottom - top - total) / 5.0));
        CGFloat y = top + MAX(0, (bottom - top - total - 5 * gap) / 2.0) + gap;
        self.card.frame = CGRectMake(margin, y, usable, cardH);
        y += cardH + gap;
        for (NSInteger i = 0; i < 3; i++) {
            self.sliderLabels[i].frame = CGRectMake(margin + 6, y, usable - 12, 20);
            self.sliders[i].frame = CGRectMake(margin, y + 22, usable, 44);
            y += sliderBlock + (i < 2 ? gap * 0.45 : gap);
        }
        [self layoutSwatchesInRect:CGRectMake(margin, y, usable, 2 * swatchSide + 12) side:swatchSide];
        y += 2 * swatchSide + 12 + gap;
        self.defaultButton.frame = CGRectMake(margin, y, usable, defaultH);
    }
    self.defaultButton.layer.cornerRadius = defaultH / 2.0;

    CGRect cb = self.card.bounds;
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.cardGradient.frame = cb;
    [CATransaction commit];
    CGFloat mascotSide = cb.size.height - 28;
    self.mascot.frame = CGRectMake(cb.size.width - mascotSide - 18, 14, mascotSide, mascotSide);
    self.hexLabel.frame = CGRectMake(22, cb.size.height / 2.0 - 30, cb.size.width - mascotSide - 52, 36);
    self.captionLabel.frame = CGRectMake(22, cb.size.height / 2.0 + 8, cb.size.width - mascotSide - 52, 20);
    for (UIButton *button in self.swatches) {
        button.layer.cornerRadius = button.selected ? 14 : button.bounds.size.width / 2.0;
    }
}

- (void)layoutSwatchesInRect:(CGRect)rect side:(CGFloat)side {
    NSInteger perRow = 5;
    CGFloat step = perRow > 1 ? (rect.size.width - side) / (perRow - 1) : 0;
    for (NSInteger i = 0; i < 10; i++) {
        NSInteger row = i / perRow, col = i % perRow;
        self.swatches[i].frame = CGRectMake(rect.origin.x + col * step, rect.origin.y + row * (side + 12), side, side);
    }
}

@end
