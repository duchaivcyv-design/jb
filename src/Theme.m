#import "Theme.h"
#import "Strings.h"
#import "AppSettings.h"
#import <ImageIO/ImageIO.h>
#import <math.h>
#import <spawn.h>
#import <errno.h>
#import <sys/stat.h>
#import <sys/wait.h>

extern char **environ;

// ---------------------------------------------------------------------------------------------
// Palettes. Order of fields: background, surface, border, accent, text, secondary text, selection.
// [skin][0] = light, [skin][1] = dark.
// ---------------------------------------------------------------------------------------------
typedef struct {
    uint32_t bg, surface, border, accent, text, secondary, selection;
} ThemePalette;

static const ThemePalette kPalettes[ThemeSkinCount][2] = {
    // Claude (original look)
    { { 0xFAF9F5, 0xFFFFFF, 0xE3E0D5, 0xC96442, 0x29261B, 0x6F6B5E, 0xF0EEE6 },
      { 0x1F1E1B, 0x2B2A26, 0x3F3D38, 0xD9774F, 0xEEECE5, 0xA9A598, 0x34322E } },
    // SideStore Skin (purple)
    { { 0xF5F1FE, 0xFFFFFF, 0xE1D7F6, 0x8A3FFC, 0x20172F, 0x66597F, 0xEBE3FA },
      { 0x130F1E, 0x1D1730, 0x33294D, 0xA878FF, 0xEFEAFB, 0xA99DC8, 0x2A2142 } },
    // LiveContainer Skin (sea blue)
    { { 0xEFF5FF, 0xFFFFFF, 0xD3E1F7, 0x0A6CFF, 0x10213B, 0x52668A, 0xE1ECFD },
      { 0x0B1220, 0x131C2E, 0x22324D, 0x4A98FF, 0xE7EFFC, 0x94A7C8, 0x1B2840 } },
    // Dopamine Skin (green)
    { { 0xEFF8F4, 0xFFFFFF, 0xCFE6DC, 0x14A36F, 0x0F2B26, 0x4D6F65, 0xDFF1E9 },
      { 0x0A1B1B, 0x112626, 0x1E3F3C, 0x2ED08E, 0xE2F4EE, 0x8DB4A9, 0x193431 } },
    // Chimera Skin (white)
    { { 0xF8F9FB, 0xFFFFFF, 0xE3E6EB, 0x2D9A92, 0x1B232B, 0x5F6B77, 0xEEF1F5 },
      { 0x141619, 0x1D2024, 0x2F333A, 0x45BDB3, 0xEDF0F3, 0x9EA6B0, 0x282C32 } },
    // Sileo Skin (cyan / teal)
    { { 0xEDF9FA, 0xFFFFFF, 0xCBE7EA, 0x0A9FAA, 0x0E2A2E, 0x4A6E73, 0xDDF1F3 },
      { 0x08191C, 0x0F2A2E, 0x1C4248, 0x1FCAD4, 0xE0F5F7, 0x8AB8BD, 0x163539 } },
    // Github Skin (red)
    { { 0xFBF3F5, 0xFFFFFF, 0xEBD3D9, 0xBE2748, 0x2A1418, 0x7A5A61, 0xF4E3E7 },
      { 0x1A0E12, 0x281820, 0x44272F, 0xE8506F, 0xF6E7EB, 0xBF9BA4, 0x372029 } },
};

static NSString *const kSkinKey = @"theme.skin";
static NSString *const kDarkKey = @"theme.dark";
static NSString *const kAutoKey = @"theme.auto";
static NSString *const kWallpaperKey = @"theme.wallpaper";
static NSString *const kAccOnKey = @"theme.acc.on";
static NSString *const kAccHKey = @"theme.acc.h";
static NSString *const kAccSKey = @"theme.acc.s";
static NSString *const kAccBKey = @"theme.acc.b";
static NSString *const kMaterialKey = @"theme.material";
static NSString *const kHelperIconKey = @"theme.helperIconSkin";
static NSString *const kHelperIconDarkKey = @"theme.helperIconDark";
static NSString *const kIconStyleDarkKey = @"theme.iconStyleDark";

static ThemeSkin gSkin = ThemeSkinClaude;
static BOOL gDark = NO;        // the manual choice (used when auto mode is off)
static BOOL gAuto = NO;        // follow the device clock: dark from 18:00 to 05:59
static BOOL gLastDark = NO;    // what the screens were last styled with (to notice the clock crossing 18:00 / 06:00)
static NSInteger gWallpaper = -1;
static BOOL gAccOn = NO;
static CGFloat gAccH = 0.78, gAccS = 0.6, gAccB = 0.75;
static BOOL gMaterial = NO;
static dispatch_once_t gPrefsOnce;

static BOOL IsNightNow(void);

static void LoadPrefs(void) {
    dispatch_once(&gPrefsOnce, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger skin = [defaults integerForKey:kSkinKey];
        gSkin = (skin >= 0 && skin < ThemeSkinCount) ? (ThemeSkin)skin : ThemeSkinClaude;
        gDark = [defaults boolForKey:kDarkKey];
        gAuto = [defaults boolForKey:kAutoKey];
        NSNumber *wallpaper = [defaults objectForKey:kWallpaperKey];
        NSInteger choice = [wallpaper isKindOfClass:[NSNumber class]] ? wallpaper.integerValue : -1;
        gWallpaper = (choice >= -1 && choice <= ThemeSkinCount) ? choice : -1;   // ThemeSkinCount = the moving gradient
        gAccOn = [defaults boolForKey:kAccOnKey];
        if ([defaults objectForKey:kAccHKey]) {
            gAccH = MAX(0, MIN(1, [defaults doubleForKey:kAccHKey]));
            gAccS = MAX(0, MIN(1, [defaults doubleForKey:kAccSKey]));
            gAccB = MAX(0, MIN(1, [defaults doubleForKey:kAccBKey]));
        }
        // Material 3 is the default look: a fresh install has it, and so does the first launch of each newly installed version
        // (the choice is made again on every update; it can still be switched back to Classic afterwards).
        NSString *build = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"?";
        if ([defaults objectForKey:kMaterialKey] == nil || ![[defaults stringForKey:@"theme.materialSetFor"] isEqualToString:build]) {
            [defaults setBool:YES forKey:kMaterialKey];
            [defaults setObject:build forKey:@"theme.materialSetFor"];
        }
        gMaterial = [defaults boolForKey:kMaterialKey];
        gLastDark = gAuto ? IsNightNow() : gDark;
    });
}

// Device clock: night is 18:00-05:59 (same hour boundaries as the "Chào buổi tối" greeting).
static BOOL IsNightNow(void) {
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    return hour >= 18 || hour < 6;
}

static BOOL EffectiveDark(void) {
    LoadPrefs();
    return gAuto ? IsNightNow() : gDark;
}

static uint32_t HexFromHSB(CGFloat h, CGFloat s, CGFloat b) {
    UIColor *color = [UIColor colorWithHue:h saturation:s brightness:b alpha:1];
    CGFloat r = 0, g = 0, bl = 0, a = 0;
    [color getRed:&r green:&g blue:&bl alpha:&a];
    return ((uint32_t)lround(r * 255) << 16) | ((uint32_t)lround(g * 255) << 8) | (uint32_t)lround(bl * 255);
}

// Material-style tonal palette from one colour: surfaces carry a little of the hue, text stays neutral.
static ThemePalette DerivedPalette(CGFloat h, CGFloat s, CGFloat b, BOOL dark) {
    CGFloat t = MIN(1.0, 0.35 + s);   // a grey accent gives neutral surfaces
    ThemePalette p;
    if (dark) {
        p.bg = HexFromHSB(h, 0.30 * t, 0.095);
        p.surface = HexFromHSB(h, 0.28 * t, 0.165);
        p.border = HexFromHSB(h, 0.24 * t, 0.27);
        p.selection = HexFromHSB(h, 0.26 * t, 0.22);
        p.text = HexFromHSB(h, 0.05 * t, 0.94);
        p.secondary = HexFromHSB(h, 0.12 * t, 0.70);
        p.accent = HexFromHSB(h, s, MAX(b, 0.62));
    } else {
        p.bg = HexFromHSB(h, 0.06 * t, 0.985);
        p.surface = 0xFFFFFF;
        p.border = HexFromHSB(h, 0.14 * t, 0.89);
        p.selection = HexFromHSB(h, 0.10 * t, 0.95);
        p.text = HexFromHSB(h, 0.35 * t, 0.13);
        p.secondary = HexFromHSB(h, 0.14 * t, 0.42);
        p.accent = HexFromHSB(h, s, MIN(b, 0.80));
    }
    return p;
}

static ThemePalette CurrentPalette(void) {
    LoadPrefs();
    BOOL dark = EffectiveDark();
    if (gAccOn) return DerivedPalette(gAccH, gAccS, gAccB, dark);
    return kPalettes[gSkin][dark ? 1 : 0];
}

static ThemePalette PaletteForMode(BOOL dark) {
    LoadPrefs();
    if (gAccOn) return DerivedPalette(gAccH, gAccS, gAccB, dark);
    return kPalettes[gSkin][dark ? 1 : 0];
}

static UIColor *HexColor(uint32_t hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0
                           green:((hex >> 8) & 0xFF) / 255.0
                            blue:(hex & 0xFF) / 255.0
                           alpha:1.0];
}

// t = 0 gives a, t = 1 gives b.
static uint32_t MixHex(uint32_t a, uint32_t b, double t) {
    double r = ((a >> 16) & 0xFF) * (1 - t) + ((b >> 16) & 0xFF) * t;
    double g = ((a >> 8) & 0xFF) * (1 - t) + ((b >> 8) & 0xFF) * t;
    double bl = (a & 0xFF) * (1 - t) + (b & 0xFF) * t;
    return ((uint32_t)lround(r) << 16) | ((uint32_t)lround(g) << 8) | (uint32_t)lround(bl);
}

static uint32_t ScaleHex(uint32_t a, double factor) {
    double r = MIN(255.0, ((a >> 16) & 0xFF) * factor);
    double g = MIN(255.0, ((a >> 8) & 0xFF) * factor);
    double b = MIN(255.0, (a & 0xFF) * factor);
    return ((uint32_t)lround(r) << 16) | ((uint32_t)lround(g) << 8) | (uint32_t)lround(b);
}

static BOOL AccentIsLight(uint32_t hex) {
    double r = ((hex >> 16) & 0xFF) / 255.0, g = ((hex >> 8) & 0xFF) / 255.0, b = (hex & 0xFF) / 255.0;
    return 0.2126 * r + 0.7152 * g + 0.0722 * b > 0.62;
}

static NSString *CSSHex(uint32_t hex) {
    return [NSString stringWithFormat:@"#%06X", (unsigned)(hex & 0xFFFFFF)];
}

static NSString *CSSRGBA(uint32_t hex, double alpha) {
    return [NSString stringWithFormat:@"rgba(%u,%u,%u,%.2f)", (unsigned)((hex >> 16) & 0xFF),
            (unsigned)((hex >> 8) & 0xFF), (unsigned)(hex & 0xFF), alpha];
}

static NSString *WallpaperFileKey(NSInteger index) {
    static NSString *const keys[] = { @"", @"sidestore", @"livecontainer", @"dopamine", @"chimera", @"sileo", @"github" };
    if (index < 1 || index >= ThemeSkinCount) return nil;
    return keys[index];
}

@implementation Theme

#pragma mark - Palette

+ (UIColor *)background     { return HexColor(CurrentPalette().bg); }
+ (UIColor *)surface        { return HexColor(CurrentPalette().surface); }
+ (UIColor *)border         { return HexColor(CurrentPalette().border); }
+ (UIColor *)accent         { return HexColor(CurrentPalette().accent); }
+ (UIColor *)accentPressed  { return HexColor(ScaleHex(CurrentPalette().accent, 0.84)); }
+ (UIColor *)accentDisabled { ThemePalette p = CurrentPalette(); return HexColor(MixHex(p.accent, p.bg, 0.55)); }
+ (UIColor *)text           { return HexColor(CurrentPalette().text); }
+ (UIColor *)secondaryText  { return HexColor(CurrentPalette().secondary); }
+ (UIColor *)success        { LoadPrefs(); return HexColor(EffectiveDark() ? 0x5CB985 : 0x3F7D58); }
+ (UIColor *)error          { LoadPrefs(); return HexColor(EffectiveDark() ? 0xE8705A : 0xB3402A); }
+ (UIColor *)selection      { return HexColor(CurrentPalette().selection); }

+ (UIFont *)serifFontOfSize:(CGFloat)size {
    if ([AppSettings fontStyle] != 0) return [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];   // "System font" / "SF Rounded" choice
    UIFont *font = [UIFont fontWithName:@"Georgia" size:size];
    return font ? font : [UIFont systemFontOfSize:size weight:UIFontWeightSemibold];
}

+ (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image resizableImageWithCapInsets:UIEdgeInsetsZero];
}

+ (UIKeyboardAppearance)keyboardAppearance {
    LoadPrefs();
    return EffectiveDark() ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
}

+ (UIColor *)onAccent {
    return AccentIsLight(CurrentPalette().accent) ? HexColor(0x1B1B1B) : [UIColor whiteColor];
}

#pragma mark - Custom accent

+ (BOOL)customAccentActive { LoadPrefs(); return gAccOn; }

+ (void)getCustomHue:(CGFloat *)hue saturation:(CGFloat *)saturation brightness:(CGFloat *)brightness {
    LoadPrefs();
    CGFloat h = gAccH, s = gAccS, b = gAccB;
    if (!gAccOn) {
        CGFloat a = 0;
        [HexColor(kPalettes[gSkin][EffectiveDark() ? 1 : 0].accent) getHue:&h saturation:&s brightness:&b alpha:&a];
    }
    if (hue) *hue = h;
    if (saturation) *saturation = s;
    if (brightness) *brightness = b;
}

+ (void)setCustomHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness {
    LoadPrefs();
    gAccOn = YES;
    gAccH = MAX(0, MIN(1, hue));
    gAccS = MAX(0, MIN(1, saturation));
    gAccB = MAX(0, MIN(1, brightness));
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:YES forKey:kAccOnKey];
    [defaults setDouble:gAccH forKey:kAccHKey];
    [defaults setDouble:gAccS forKey:kAccSKey];
    [defaults setDouble:gAccB forKey:kAccBKey];
}

+ (void)resetCustomAccent {
    LoadPrefs();
    gAccOn = NO;
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kAccOnKey];
}

+ (UIColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness {
    return [UIColor colorWithHue:MAX(0, MIN(1, hue)) saturation:MAX(0, MIN(1, saturation)) brightness:MAX(0, MIN(1, brightness)) alpha:1];
}

+ (NSString *)hexStringForHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness {
    return CSSHex(HexFromHSB(MAX(0, MIN(1, hue)), MAX(0, MIN(1, saturation)), MAX(0, MIN(1, brightness))));
}

#pragma mark - Material 3 design and the moving gradient

+ (BOOL)materialDesign { LoadPrefs(); return gMaterial; }

+ (void)setMaterialDesign:(BOOL)on {
    LoadPrefs();
    gMaterial = on;
    [[NSUserDefaults standardUserDefaults] setBool:on forKey:kMaterialKey];
}

+ (NSInteger)gradientWallpaperChoice { return ThemeSkinCount; }

+ (BOOL)gradientWallpaperActive { LoadPrefs(); return gWallpaper == ThemeSkinCount; }

+ (NSArray<UIColor *> *)gradientWallpaperColors {
    ThemePalette p = CurrentPalette();
    BOOL dark = EffectiveDark();
    CGFloat h = 0, s = 0, b = 0, a = 0;
    [HexColor(p.accent) getHue:&h saturation:&s brightness:&b alpha:&a];
    uint32_t shifted = HexFromHSB(fmod(h + 0.07, 1.0), s, b);
    uint32_t cooler = HexFromHSB(fmod(h + 0.93, 1.0), s, b);
    if (dark) {
        return @[HexColor(MixHex(p.bg, p.accent, 0.20)), HexColor(MixHex(p.bg, shifted, 0.42)),
                 HexColor(MixHex(p.bg, p.accent, 0.12)), HexColor(MixHex(p.bg, cooler, 0.34))];
    }
    return @[HexColor(MixHex(p.bg, p.accent, 0.16)), HexColor(MixHex(p.bg, shifted, 0.34)),
             HexColor(MixHex(p.bg, p.accent, 0.08)), HexColor(MixHex(p.bg, cooler, 0.28))];
}

#pragma mark - Icons

+ (UIImage *)iconWithSize:(CGSize)size draw:(void (^)(CGContextRef ctx))draw {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        draw(rendererContext.CGContext);
    }];
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *)iconMenu {
    return [self iconWithSize:CGSizeMake(24, 24) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 2);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGFloat ys[3] = {6.5, 12, 17.5};
        for (int i = 0; i < 3; i++) {
            CGContextMoveToPoint(c, 4, ys[i]);
            CGContextAddLineToPoint(c, 20, ys[i]);
        }
        CGContextStrokePath(c);
    }];
}

+ (UIImage *)iconPlus {
    return [self iconWithSize:CGSizeMake(24, 24) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 2);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextMoveToPoint(c, 12, 5);
        CGContextAddLineToPoint(c, 12, 19);
        CGContextMoveToPoint(c, 5, 12);
        CGContextAddLineToPoint(c, 19, 12);
        CGContextStrokePath(c);
    }];
}

+ (UIImage *)iconCompose {
    return [self iconWithSize:CGSizeMake(24, 24) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 2);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        UIBezierPath *path = [UIBezierPath bezierPath];
        // rounded square, open at the top-right where the pencil goes
        [path moveToPoint:CGPointMake(11, 5)];
        [path addLineToPoint:CGPointMake(7, 5)];
        [path addQuadCurveToPoint:CGPointMake(4, 8) controlPoint:CGPointMake(4, 5)];
        [path addLineToPoint:CGPointMake(4, 17)];
        [path addQuadCurveToPoint:CGPointMake(7, 20) controlPoint:CGPointMake(4, 20)];
        [path addLineToPoint:CGPointMake(16, 20)];
        [path addQuadCurveToPoint:CGPointMake(19, 17) controlPoint:CGPointMake(19, 20)];
        [path addLineToPoint:CGPointMake(19, 13)];
        // pencil
        [path moveToPoint:CGPointMake(10.5, 13.5)];
        [path addLineToPoint:CGPointMake(19.5, 4.5)];
        CGContextAddPath(c, path.CGPath);
        CGContextStrokePath(c);
    }];
}

+ (UIImage *)iconGear {
    return [self iconWithSize:CGSizeMake(24, 24) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 1.9);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        // one closed outline: 8 teeth around a body, then the hub circle
        const int teeth = 8;
        const CGFloat cx = 12, cy = 12, rOuter = 9.6, rInner = 7.1;
        UIBezierPath *path = [UIBezierPath bezierPath];
        for (int i = 0; i < teeth; i++) {
            CGFloat base = (CGFloat)i * (2 * M_PI / teeth) - M_PI / 2;
            CGFloat half = (CGFloat)(M_PI / teeth);          // half of one tooth+gap period
            CGFloat a0 = base - half * 0.95, a1 = base - half * 0.45, a2 = base + half * 0.45, a3 = base + half * 0.95;
            CGPoint p0 = CGPointMake(cx + rInner * cos(a0), cy + rInner * sin(a0));
            if (i == 0) [path moveToPoint:p0]; else [path addLineToPoint:p0];
            [path addLineToPoint:CGPointMake(cx + rOuter * cos(a1), cy + rOuter * sin(a1))];
            [path addLineToPoint:CGPointMake(cx + rOuter * cos(a2), cy + rOuter * sin(a2))];
            [path addLineToPoint:CGPointMake(cx + rInner * cos(a3), cy + rInner * sin(a3))];
        }
        [path closePath];
        CGContextAddPath(c, path.CGPath);
        CGContextAddEllipseInRect(c, CGRectMake(cx - 3, cy - 3, 6, 6));
        CGContextStrokePath(c);
    }];
}

+ (UIImage *)iconRefresh {
    // Same look as the system "arrow.clockwise": a ~290 degree ring that opens at the upper right, with a solid arrow head.
    return [self iconWithSize:CGSizeMake(24, 24) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetFillColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 2.2);
        CGContextSetLineCap(c, kCGLineCapRound);
        const CGFloat cx = 12, cy = 12.5, radius = 7.2;
        const CGFloat startAngle = (CGFloat)(M_PI * 0.10);                    // just below the right-hand side
        const CGFloat endAngle = startAngle + (CGFloat)(M_PI * 1.62);        // ends at the upper right (clockwise)
        UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:CGPointMake(cx, cy) radius:radius
                                                       startAngle:startAngle endAngle:endAngle clockwise:YES];
        CGContextAddPath(c, arc.CGPath);
        CGContextStrokePath(c);

        // Arrow head: a filled triangle pointing along the direction of travel.
        CGPoint tip = CGPointMake(cx + radius * cos(endAngle), cy + radius * sin(endAngle));
        CGPoint dir = CGPointMake(-sin(endAngle), cos(endAngle));
        CGPoint normal = CGPointMake(cos(endAngle), sin(endAngle));
        CGFloat len = 5.2, half = 3.6;
        CGPoint front = CGPointMake(tip.x + 2.0 * dir.x, tip.y + 2.0 * dir.y);
        CGPoint baseA = CGPointMake(tip.x - (len - 2.0) * dir.x + half * normal.x, tip.y - (len - 2.0) * dir.y + half * normal.y);
        CGPoint baseB = CGPointMake(tip.x - (len - 2.0) * dir.x - half * normal.x, tip.y - (len - 2.0) * dir.y - half * normal.y);
        UIBezierPath *head = [UIBezierPath bezierPath];
        [head moveToPoint:front];
        [head addLineToPoint:baseA];
        [head addLineToPoint:baseB];
        [head closePath];
        head.lineJoinStyle = kCGLineJoinRound;
        head.lineWidth = 1.2;
        CGContextAddPath(c, head.CGPath);
        CGContextDrawPath(c, kCGPathFillStroke);
    }];
}

+ (UIImage *)iconBack {
    return [self iconWithSize:CGSizeMake(24, 24) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 2.4);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextMoveToPoint(c, 14.5, 5.5);
        CGContextAddLineToPoint(c, 8, 12);
        CGContextAddLineToPoint(c, 14.5, 18.5);
        CGContextStrokePath(c);
    }];
}

+ (UIImage *)iconSend {
    return [self iconWithSize:CGSizeMake(20, 20) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 2.2);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        CGContextMoveToPoint(c, 10, 16.5);
        CGContextAddLineToPoint(c, 10, 4);
        CGContextMoveToPoint(c, 4.5, 9.5);
        CGContextAddLineToPoint(c, 10, 4);
        CGContextAddLineToPoint(c, 15.5, 9.5);
        CGContextStrokePath(c);
    }];
}

// Microphone: a filled capsule, a cradle arc under it and a stem with a base.
+ (UIImage *)iconMicOfSize:(CGFloat)side {
    CGFloat k = side / 20.0;
    return [self iconWithSize:CGSizeMake(side, side) draw:^(CGContextRef c) {
        CGContextScaleCTM(c, k, k);
        CGContextSetFillColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 1.8);
        CGContextSetLineCap(c, kCGLineCapRound);
        UIBezierPath *capsule = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(7, 1.8, 6, 10.4) cornerRadius:3];
        CGContextAddPath(c, capsule.CGPath);
        CGContextFillPath(c);
        UIBezierPath *cradle = [UIBezierPath bezierPathWithArcCenter:CGPointMake(10, 9.2) radius:5.8 startAngle:0 endAngle:(CGFloat)M_PI clockwise:YES];
        CGContextAddPath(c, cradle.CGPath);
        CGContextStrokePath(c);
        CGContextMoveToPoint(c, 10, 15);
        CGContextAddLineToPoint(c, 10, 18);
        CGContextMoveToPoint(c, 6.8, 18);
        CGContextAddLineToPoint(c, 13.2, 18);
        CGContextStrokePath(c);
    }];
}

+ (UIImage *)iconMic {
    return [self iconMicOfSize:20];
}

+ (UIImage *)iconSearch {
    return [self iconWithSize:CGSizeMake(16, 16) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 1.7);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextStrokeEllipseInRect(c, CGRectMake(2, 2, 8.6, 8.6));
        CGContextMoveToPoint(c, 9.2, 9.2);
        CGContextAddLineToPoint(c, 13.6, 13.6);
        CGContextStrokePath(c);
    }];
}

+ (UIImage *)iconBolt {
    return [self iconWithSize:CGSizeMake(16, 16) draw:^(CGContextRef c) {
        CGContextSetFillColorWithColor(c, [UIColor blackColor].CGColor);
        UIBezierPath *b = [UIBezierPath bezierPath];
        [b moveToPoint:CGPointMake(9.4, 1)];
        [b addLineToPoint:CGPointMake(3.2, 9)];
        [b addLineToPoint:CGPointMake(7.2, 9)];
        [b addLineToPoint:CGPointMake(6.4, 15)];
        [b addLineToPoint:CGPointMake(12.8, 6.6)];
        [b addLineToPoint:CGPointMake(8.6, 6.6)];
        [b closePath];
        b.lineJoinStyle = kCGLineJoinRound;
        CGContextAddPath(c, b.CGPath);
        CGContextFillPath(c);
    }];
}

+ (UIImage *)iconClose {
    return [self iconWithSize:CGSizeMake(20, 20) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 2.2);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextMoveToPoint(c, 4.5, 4.5);
        CGContextAddLineToPoint(c, 15.5, 15.5);
        CGContextMoveToPoint(c, 15.5, 4.5);
        CGContextAddLineToPoint(c, 4.5, 15.5);
        CGContextStrokePath(c);
    }];
}

// Icons of the "+" tool menu. Template images: the caller tints them with the theme colour, so they follow light / dark.
+ (UIImage *)iconTool:(NSString *)name {
    return [self iconWithSize:CGSizeMake(24, 24) draw:^(CGContextRef c) {
        CGContextSetStrokeColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetFillColorWithColor(c, [UIColor blackColor].CGColor);
        CGContextSetLineWidth(c, 1.8);
        CGContextSetLineCap(c, kCGLineCapRound);
        CGContextSetLineJoin(c, kCGLineJoinRound);
        if ([name isEqualToString:@"photo"]) {
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.5, 4.5, 17, 15) cornerRadius:3.5] stroke];
            CGContextFillEllipseInRect(c, CGRectMake(7.4, 8.2, 3.2, 3.2));
            UIBezierPath *hill = [UIBezierPath bezierPath];
            [hill moveToPoint:CGPointMake(4.5, 17.5)];
            [hill addLineToPoint:CGPointMake(10, 12.8)];
            [hill addLineToPoint:CGPointMake(14, 16.2)];
            [hill addLineToPoint:CGPointMake(16.5, 14)];
            [hill addLineToPoint:CGPointMake(19.5, 17.5)];
            hill.lineWidth = 1.8; [hill stroke];
        } else if ([name isEqualToString:@"file"]) {
            UIBezierPath *page = [UIBezierPath bezierPath];
            [page moveToPoint:CGPointMake(6, 3.5)];
            [page addLineToPoint:CGPointMake(13.5, 3.5)];
            [page addLineToPoint:CGPointMake(18.5, 8.5)];
            [page addLineToPoint:CGPointMake(18.5, 20.5)];
            [page addLineToPoint:CGPointMake(6, 20.5)];
            [page closePath];
            page.lineWidth = 1.8; [page stroke];
            UIBezierPath *fold = [UIBezierPath bezierPath];
            [fold moveToPoint:CGPointMake(13.5, 3.5)];
            [fold addLineToPoint:CGPointMake(13.5, 8.5)];
            [fold addLineToPoint:CGPointMake(18.5, 8.5)];
            fold.lineWidth = 1.8; [fold stroke];
            CGContextMoveToPoint(c, 9, 13); CGContextAddLineToPoint(c, 15.5, 13);
            CGContextMoveToPoint(c, 9, 16.5); CGContextAddLineToPoint(c, 14, 16.5);
            CGContextStrokePath(c);
        } else if ([name isEqualToString:@"library"]) {
            UIBezierPath *folder = [UIBezierPath bezierPath];
            [folder moveToPoint:CGPointMake(3.5, 7)];
            [folder addQuadCurveToPoint:CGPointMake(5.5, 5)  controlPoint:CGPointMake(3.5, 5)];
            [folder addLineToPoint:CGPointMake(9.5, 5)];
            [folder addLineToPoint:CGPointMake(11.5, 7.5)];
            [folder addLineToPoint:CGPointMake(18.5, 7.5)];
            [folder addQuadCurveToPoint:CGPointMake(20.5, 9.5) controlPoint:CGPointMake(20.5, 7.5)];
            [folder addLineToPoint:CGPointMake(20.5, 17.5)];
            [folder addQuadCurveToPoint:CGPointMake(18.5, 19.5) controlPoint:CGPointMake(20.5, 19.5)];
            [folder addLineToPoint:CGPointMake(5.5, 19.5)];
            [folder addQuadCurveToPoint:CGPointMake(3.5, 17.5) controlPoint:CGPointMake(3.5, 19.5)];
            [folder closePath];
            folder.lineWidth = 1.8; [folder stroke];
        } else if ([name isEqualToString:@"camera"]) {
            UIBezierPath *body = [UIBezierPath bezierPath];
            [body moveToPoint:CGPointMake(3.5, 9)];
            [body addQuadCurveToPoint:CGPointMake(5.5, 7) controlPoint:CGPointMake(3.5, 7)];
            [body addLineToPoint:CGPointMake(8, 7)];
            [body addLineToPoint:CGPointMake(9.5, 4.8)];
            [body addLineToPoint:CGPointMake(14.5, 4.8)];
            [body addLineToPoint:CGPointMake(16, 7)];
            [body addLineToPoint:CGPointMake(18.5, 7)];
            [body addQuadCurveToPoint:CGPointMake(20.5, 9) controlPoint:CGPointMake(20.5, 7)];
            [body addLineToPoint:CGPointMake(20.5, 17.5)];
            [body addQuadCurveToPoint:CGPointMake(18.5, 19.5) controlPoint:CGPointMake(20.5, 19.5)];
            [body addLineToPoint:CGPointMake(5.5, 19.5)];
            [body addQuadCurveToPoint:CGPointMake(3.5, 17.5) controlPoint:CGPointMake(3.5, 19.5)];
            [body closePath];
            body.lineWidth = 1.8; [body stroke];
            CGContextStrokeEllipseInRect(c, CGRectMake(8.5, 9.5, 7, 7));
        } else if ([name isEqualToString:@"web"]) {
            CGContextStrokeEllipseInRect(c, CGRectMake(3.5, 3.5, 17, 17));
            CGContextStrokeEllipseInRect(c, CGRectMake(8, 3.5, 8, 17));
            CGContextMoveToPoint(c, 3.5, 12); CGContextAddLineToPoint(c, 20.5, 12);
            CGContextStrokePath(c);
        } else if ([name isEqualToString:@"think"]) {   // light bulb
            UIBezierPath *bulb = [UIBezierPath bezierPathWithArcCenter:CGPointMake(12, 9.5) radius:5.8 startAngle:(CGFloat)(M_PI * 0.78) endAngle:(CGFloat)(M_PI * 0.22) clockwise:YES];
            [bulb addLineToPoint:CGPointMake(14.6, 16)];
            [bulb addLineToPoint:CGPointMake(9.4, 16)];
            [bulb closePath];
            bulb.lineWidth = 1.8; [bulb stroke];
            CGContextMoveToPoint(c, 9.6, 19); CGContextAddLineToPoint(c, 14.4, 19);
            CGContextMoveToPoint(c, 10.6, 21.4); CGContextAddLineToPoint(c, 13.4, 21.4);
            CGContextStrokePath(c);
        } else if ([name isEqualToString:@"sparkle"]) {
            UIBezierPath *star = [UIBezierPath bezierPath];
            [star moveToPoint:CGPointMake(12, 3)];
            [star addQuadCurveToPoint:CGPointMake(21, 12) controlPoint:CGPointMake(13, 11)];
            [star addQuadCurveToPoint:CGPointMake(12, 21) controlPoint:CGPointMake(13, 13)];
            [star addQuadCurveToPoint:CGPointMake(3, 12) controlPoint:CGPointMake(11, 13)];
            [star addQuadCurveToPoint:CGPointMake(12, 3) controlPoint:CGPointMake(11, 11)];
            [star closePath];
            star.lineWidth = 1.8; [star stroke];
        } else {   // "more": three dots
            for (int i = 0; i < 3; i++) CGContextFillEllipseInRect(c, CGRectMake(4.2 + i * 6.6, 10.2, 3.6, 3.6));
        }
    }];
}

+ (UIImage *)iconStop {
    return [self iconWithSize:CGSizeMake(16, 16) draw:^(CGContextRef c) {
        CGContextSetFillColorWithColor(c, [UIColor blackColor].CGColor);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2, 2, 12, 12) cornerRadius:3];
        CGContextAddPath(c, path.CGPath);
        CGContextFillPath(c);
    }];
}

#pragma mark - Navigation bar

+ (void)styleNavigationBar:(UINavigationBar *)bar {
    LoadPrefs();
    bar.barStyle = EffectiveDark() ? UIBarStyleBlack : UIBarStyleDefault;   // also decides the status bar text colour
    bar.barTintColor = [self background];
    bar.tintColor = [self accent];
    // See-through bar: the page runs under it and a progressive blur (TopBlurView, owned by MiniNavigationController) sits behind the buttons.
    bar.translucent = YES;
    // A custom shadow image is only honored together with a custom background image.
    [bar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
    bar.shadowImage = [[UIImage alloc] init];
    bar.titleTextAttributes = @{ NSForegroundColorAttributeName: [self text],
                                 NSFontAttributeName: [self serifFontOfSize:[self materialDesign] ? 16 : 18] };   // smaller bar title in Material 3
}

#pragma mark - Skin, dark mode, wallpaper

+ (ThemeSkin)skin { LoadPrefs(); return gSkin; }

+ (void)setSkin:(ThemeSkin)skin {
    LoadPrefs();
    if (skin < 0 || skin >= ThemeSkinCount) skin = ThemeSkinClaude;
    gSkin = skin;
    [[NSUserDefaults standardUserDefaults] setInteger:skin forKey:kSkinKey];
}

+ (UIVisualEffectView *)backdropBlurView {
    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:[self darkMode] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight]];
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blur.userInteractionEnabled = NO;
    return blur;
}

+ (BOOL)darkMode { return EffectiveDark(); }

+ (BOOL)autoMode { LoadPrefs(); return gAuto; }

+ (void)setAutoMode:(BOOL)automatic {
    LoadPrefs();
    gAuto = automatic;
    [[NSUserDefaults standardUserDefaults] setBool:automatic forKey:kAutoKey];
    gLastDark = EffectiveDark();
}

// YES once when auto mode crosses day <-> night while the app is open (then the screens must be restyled).
+ (BOOL)consumeAutoModeChange {
    LoadPrefs();
    BOOL now = EffectiveDark();
    if (now == gLastDark) return NO;
    gLastDark = now;
    return YES;
}

+ (void)setDarkMode:(BOOL)dark {
    LoadPrefs();
    gDark = dark;
    [[NSUserDefaults standardUserDefaults] setBool:dark forKey:kDarkKey];
    gLastDark = EffectiveDark();
}

+ (NSInteger)wallpaperChoice { LoadPrefs(); return gWallpaper; }

+ (void)setWallpaperChoice:(NSInteger)choice {
    LoadPrefs();
    if (choice < -1 || choice > ThemeSkinCount) choice = -1;   // ThemeSkinCount = the moving gradient
    gWallpaper = choice;
    [[NSUserDefaults standardUserDefaults] setInteger:choice forKey:kWallpaperKey];
}

+ (NSInteger)effectiveWallpaperIndex {
    LoadPrefs();
    NSInteger index = gWallpaper < 0 ? (NSInteger)gSkin : gWallpaper;   // the Claude skin has no wallpaper (0)
    return (index >= 1 && index < ThemeSkinCount) ? index : 0;   // the moving gradient is not a picture: 0
}

+ (void)postChange {
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotifThemeChanged object:nil];
}

+ (NSString *)skinName:(ThemeSkin)skin {
    switch (skin) {
        case ThemeSkinSideStore:     return @"SideStore Skin";
        case ThemeSkinLiveContainer: return @"LiveContainer Skin";
        case ThemeSkinDopamine:      return @"Dopamine Skin";
        case ThemeSkinChimera:       return @"Chimera Skin";
        case ThemeSkinSileo:         return @"Sileo Skin";
        case ThemeSkinGithub:        return @"Github Skin";
        default:                     return L(@"skin_claude");
    }
}

+ (NSString *)skinColorKey:(ThemeSkin)skin {
    switch (skin) {
        case ThemeSkinSideStore:     return @"skin_color_purple";
        case ThemeSkinLiveContainer: return @"skin_color_blue";
        case ThemeSkinDopamine:      return @"skin_color_green";
        case ThemeSkinChimera:       return @"skin_color_white";
        case ThemeSkinSileo:         return @"skin_color_cyan";
        case ThemeSkinGithub:        return @"skin_color_red";
        default:                     return @"skin_color_default";
    }
}

+ (UIColor *)swatchColorForSkin:(ThemeSkin)skin {
    LoadPrefs();
    if (skin < 0 || skin >= ThemeSkinCount) skin = ThemeSkinClaude;
    return HexColor(kPalettes[skin][EffectiveDark() ? 1 : 0].accent);
}

+ (NSString *)wallpaperName:(NSInteger)index {
    static NSString *const names[] = { @"", @"SideStore", @"LiveContainer", @"Dopamine", @"Chimera", @"Sileo", @"Github" };
    if (index < 1 || index >= ThemeSkinCount) return @"";
    return names[index];
}

+ (NSString *)wallpaperPathForIndex:(NSInteger)index {
    NSString *key = WallpaperFileKey(index);
    if (key.length == 0) return nil;
    return [[NSBundle mainBundle] pathForResource:[@"wp_" stringByAppendingString:key] ofType:@"jpg" inDirectory:@"Wallpapers"];
}

+ (UIImage *)wallpaperImage {
    static NSInteger cachedIndex = 0;
    static UIImage *cachedImage = nil;
    NSInteger index = [self effectiveWallpaperIndex];
    if (index == 0) {
        cachedIndex = 0;
        cachedImage = nil;   // free the decoded bitmap when no wallpaper is shown
        return nil;
    }
    if (cachedImage && cachedIndex == index) return cachedImage;
    NSString *path = [self wallpaperPathForIndex:index];
    UIImage *image = nil;
    if (path) {
        // Decode once, already scaled to the screen: a full-size bitmap behind the web view makes every screen change heavier.
        CGSize screen = [UIScreen mainScreen].bounds.size;
        CGFloat maxPixels = MAX(screen.width, screen.height) * [UIScreen mainScreen].scale;
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
        if (source) {
            NSDictionary *options = @{ (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                                       (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
                                       (id)kCGImageSourceShouldCacheImmediately: @YES,
                                       (id)kCGImageSourceThumbnailMaxPixelSize: @(maxPixels) };
            CGImageRef cg = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
            CFRelease(source);
            if (cg) {
                image = [UIImage imageWithCGImage:cg scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
                CGImageRelease(cg);
            }
        }
        if (!image) image = [UIImage imageWithContentsOfFile:path];
    }
    cachedImage = image;
    cachedIndex = image ? index : 0;
    return image;
}

+ (UIImage *)wallpaperThumbnail:(NSInteger)index {
    if (index < 1 || index >= ThemeSkinCount) return nil;
    static NSCache *cache = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [[NSCache alloc] init]; });
    UIImage *cached = [cache objectForKey:@(index)];
    if (cached) return cached;
    NSString *path = [self wallpaperPathForIndex:index];
    if (!path) return nil;
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
    if (!source) return nil;
    NSDictionary *options = @{ (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                               (id)kCGImageSourceCreateThumbnailWithTransform: @YES,
                               (id)kCGImageSourceShouldCacheImmediately: @YES,
                               (id)kCGImageSourceThumbnailMaxPixelSize: @240 };
    CGImageRef cg = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    if (!cg) return nil;
    UIImage *image = [UIImage imageWithCGImage:cg scale:1 orientation:UIImageOrientationUp];
    CGImageRelease(cg);
    if (image) [cache setObject:image forKey:@(index)];
    return image;
}

+ (CGFloat)wallpaperDimAlpha {
    LoadPrefs();
    return EffectiveDark() ? 0.55 : 0.0;
}

#pragma mark - Light / dark preview (small phone mock-up in Settings > Appearance)

+ (UIImage *)modePreviewImageDark:(BOOL)dark size:(CGSize)size {
    LoadPrefs();
    ThemePalette p = PaletteForMode(dark);
    NSInteger wallpaperIndex = [self effectiveWallpaperIndex];
    UIImage *wallpaper = wallpaperIndex > 0 ? [self wallpaperThumbnail:wallpaperIndex] : nil;
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        UIBezierPath *outline = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(rect, 0.5, 0.5) cornerRadius:13];
        [outline addClip];

        [HexColor(p.bg) setFill];
        UIRectFill(rect);
        if (wallpaper) {
            CGFloat scale = MAX(size.width / wallpaper.size.width, size.height / wallpaper.size.height);
            CGSize drawn = CGSizeMake(wallpaper.size.width * scale, wallpaper.size.height * scale);
            [wallpaper drawInRect:CGRectMake((size.width - drawn.width) / 2, (size.height - drawn.height) / 2, drawn.width, drawn.height)];
            if (dark) {
                [[UIColor colorWithWhite:0 alpha:0.55] setFill];
                UIRectFill(rect);
            }
        }

        // title bar with the clock
        [HexColor(p.bg) setFill];
        UIRectFill(CGRectMake(0, 0, size.width, 24));
        NSDictionary *attrs = @{ NSFontAttributeName: [UIFont systemFontOfSize:9 weight:UIFontWeightSemibold],
                                 NSForegroundColorAttributeName: HexColor(p.text) };
        NSString *clock = @"09:41";
        CGSize clockSize = [clock sizeWithAttributes:attrs];
        [clock drawAtPoint:CGPointMake((size.width - clockSize.width) / 2, 7) withAttributes:attrs];

        // AI reply card with two text lines
        CGFloat margin = 8;
        [HexColor(p.surface) setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(margin, 34, size.width - margin * 2, 40) cornerRadius:8] fill];
        [HexColor(p.secondary) setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(margin + 6, 43, size.width - margin * 2 - 22, 4) cornerRadius:2] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(margin + 6, 53, size.width - margin * 2 - 36, 4) cornerRadius:2] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(margin + 6, 63, size.width - margin * 2 - 30, 4) cornerRadius:2] fill];

        // your message bubble
        [HexColor(p.accent) setFill];
        CGFloat bubbleWidth = size.width * 0.5;
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(size.width - margin - bubbleWidth, 84, bubbleWidth, 20) cornerRadius:9] fill];

        // input bar
        [HexColor(p.bg) setFill];
        UIRectFill(CGRectMake(0, size.height - 30, size.width, 30));
        UIBezierPath *field = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(margin, size.height - 25, size.width - margin * 2, 17) cornerRadius:8.5];
        [HexColor(p.surface) setFill];
        [field fill];
        [HexColor(p.border) setStroke];
        field.lineWidth = 1;
        [field stroke];

        // thin frame
        [HexColor(p.border) setStroke];
        outline.lineWidth = 1;
        [outline stroke];
    }];
}

#pragma mark - App icon

+ (NSString *)iconNameForSkin:(ThemeSkin)skin {
    switch (skin) {
        case ThemeSkinSideStore:     return @"SideStore";
        case ThemeSkinLiveContainer: return @"LiveContainer";
        case ThemeSkinDopamine:      return @"Dopamine";
        case ThemeSkinChimera:       return @"Chimera";
        case ThemeSkinSileo:         return @"Sileo";
        case ThemeSkinGithub:        return @"Github";
        default:                     return nil;
    }
}

+ (NSString *)iconNameForSkin:(ThemeSkin)skin dark:(BOOL)dark {
    NSString *name = [self iconNameForSkin:skin];
    if (!dark) return name;                                       // nil = the default (light) icon
    return [(name ?: @"Default") stringByAppendingString:@"-Dark"];
}

+ (UIImage *)iconPreviewForSkin:(ThemeSkin)skin {
    return [self iconPreviewForSkin:skin dark:NO];
}

+ (UIImage *)iconPreviewForSkin:(ThemeSkin)skin dark:(BOOL)dark {
    NSString *name = [self iconNameForSkin:skin];
    NSString *file = [NSString stringWithFormat:@"Icon-%@%@@3x", name ?: @"Default", dark ? @"-Dark" : @""];
    static NSCache *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [[NSCache alloc] init]; });
    UIImage *cached = [cache objectForKey:file];
    if (cached) return cached;
    NSString *path = [[NSBundle mainBundle] pathForResource:file ofType:@"png"];
    UIImage *image = path ? [UIImage imageWithContentsOfFile:path] : nil;
    if (image) [cache setObject:image forKey:file];
    return image;
}

+ (BOOL)iconStyleDark {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIconStyleDarkKey];
}

+ (void)setIconStyleDark:(BOOL)dark {
    [[NSUserDefaults standardUserDefaults] setBool:dark forKey:kIconStyleDarkKey];
}

// The picture of the icon that is in use now: the key screen and the greeting show the same icon as the Home Screen.
+ (UIImage *)activeIconImage {
    NSString *name = [self iconNameForSkin:[self activeIconSkin]];
    BOOL dark = [self activeIconDark];
    if (name.length > 0 || dark) {
        UIImage *image = [self iconPreviewForSkin:[self activeIconSkin] dark:dark];
        if (image) return image;
    }
    return [UIImage imageNamed:@"logo.png"];
}

// The Claude mark follows the app icon: change the icon to the red one and the starburst becomes red everywhere.
+ (UIColor *)claudeMarkColor {
    ThemeSkin skin = [self activeIconSkin];
    if (skin == ThemeSkinClaude) return nil;
    return [self swatchColorForSkin:skin];
}

+ (UIImage *)claudeMarkImage {
    static UIImage *base;
    static NSMutableDictionary<NSString *, UIImage *> *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        base = [UIImage imageNamed:@"logo_claude_mark.png"];
        cache = [NSMutableDictionary dictionary];
    });
    UIColor *color = [self claudeMarkColor];
    if (!color || !base) return base;
    CGFloat r = 0, g = 0, b = 0, a = 0;
    [color getRed:&r green:&g blue:&b alpha:&a];
    NSString *key = [NSString stringWithFormat:@"%.3f-%.3f-%.3f", r, g, b];
    UIImage *cached = cache[key];
    if (cached) return cached;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = base.scale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:base.size format:format];
    UIImage *tinted = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rc) {
        CGRect rect = CGRectMake(0, 0, base.size.width, base.size.height);
        [base drawInRect:rect];
        CGContextSetBlendMode(rc.CGContext, kCGBlendModeSourceIn);   // keeps the shape (alpha), replaces the colour
        [color setFill];
        CGContextFillRect(rc.CGContext, rect);
    }];
    if (tinted) cache[key] = tinted;
    return tinted ?: base;
}

+ (NSString *)iconDisplayNameForSkin:(ThemeSkin)skin {
    NSString *name = [self iconNameForSkin:skin];
    return name.length > 0 ? name : L(@"icon_default");
}

// The icon that is really on the Home Screen: the helper's last choice (.deb) or the system's alternate icon (.ipa).
+ (ThemeSkin)activeIconSkin {
    if ([self iconHelperAvailable]) return [self helperIconSkin];
    NSString *name = [self currentIconName];
    if ([name hasSuffix:@"-Dark"]) name = [name substringToIndex:name.length - 5];
    if (name.length == 0 || [name isEqualToString:@"Default"]) return ThemeSkinClaude;
    for (NSInteger i = ThemeSkinSideStore; i < ThemeSkinCount; i++) {
        if ([[self iconNameForSkin:(ThemeSkin)i] isEqualToString:name]) return (ThemeSkin)i;
    }
    return ThemeSkinClaude;
}

+ (BOOL)activeIconDark {
    if ([self iconHelperAvailable]) return [[NSUserDefaults standardUserDefaults] boolForKey:kHelperIconDarkKey];
    return [[self currentIconName] hasSuffix:@"-Dark"];
}

+ (NSString *)currentIconName {
    if (@available(iOS 10.3, *)) return [UIApplication sharedApplication].alternateIconName;
    return nil;
}

static NSString *HelperPath(void) {
    return [[NSBundle mainBundle].bundlePath stringByAppendingPathComponent:@"claudemini-icon"];
}

+ (BOOL)iconHelperAvailable {
    struct stat st;
    if (stat(HelperPath().fileSystemRepresentation, &st) != 0) return NO;
    return (st.st_mode & S_ISUID) != 0 && st.st_uid == 0;   // only the .deb install has it (owner root, setuid)
}

+ (ThemeSkin)helperIconSkin {
    NSInteger value = [[NSUserDefaults standardUserDefaults] integerForKey:kHelperIconKey];
    return (value >= 0 && value < ThemeSkinCount) ? (ThemeSkin)value : ThemeSkinClaude;
}

+ (BOOL)applyIconWithHelperForSkin:(ThemeSkin)skin dark:(BOOL)dark message:(NSString **)message {
    if (![self iconHelperAvailable]) {
        if (message) *message = @"icon helper missing or not setuid";
        return NO;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger previous = [defaults integerForKey:kHelperIconKey];
    BOOL previousDark = [defaults boolForKey:kHelperIconDarkKey];
    [defaults setInteger:skin forKey:kHelperIconKey];   // saved first: uicache may restart the app
    [defaults setBool:dark forKey:kHelperIconDarkKey];
    [defaults synchronize];

    NSString *name = [self iconNameForSkin:skin dark:dark] ?: @"Default";
    const char *path = HelperPath().fileSystemRepresentation;
    char *argv[] = { (char *)path, (char *)name.UTF8String, NULL };
    pid_t pid = 0;
    int spawnResult = posix_spawn(&pid, path, NULL, NULL, argv, environ);
    BOOL ok = NO;
    int code = -1;
    if (spawnResult == 0) {
        int status = 0;
        while (waitpid(pid, &status, 0) < 0) {
            if (errno != EINTR) break;
        }
        code = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
        ok = (code == 0);
    } else {
        code = spawnResult;
    }
    if (!ok) {
        [defaults setInteger:previous forKey:kHelperIconKey];
        [defaults setBool:previousDark forKey:kHelperIconDarkKey];
        [defaults synchronize];
        if (message) *message = [NSString stringWithFormat:@"icon helper failed (code %d)", code];
    }
    return ok;
}

+ (void)reapplyHelperIconIfNeeded {
    if (![self iconHelperAvailable]) return;
    ThemeSkin skin = [self helperIconSkin];
    BOOL dark = [self activeIconDark];
    NSString *name = [self iconNameForSkin:skin dark:dark] ?: @"Default";
    NSString *dir = [NSBundle mainBundle].bundlePath;
    NSData *current = [NSData dataWithContentsOfFile:[dir stringByAppendingPathComponent:@"AppIcon60x60@3x.png"]];
    NSData *wanted = [NSData dataWithContentsOfFile:[dir stringByAppendingPathComponent:[NSString stringWithFormat:@"Icon-%@@3x.png", name]]];
    if (current && wanted && ![current isEqualToData:wanted]) [self applyIconWithHelperForSkin:skin dark:dark message:NULL];
}

+ (BOOL)respringWithHelper {
    if (![self iconHelperAvailable]) return NO;
    const char *path = HelperPath().fileSystemRepresentation;
    char *argv[] = { (char *)path, (char *)"--respring", NULL };
    pid_t pid = 0;
    return posix_spawn(&pid, path, NULL, NULL, argv, environ) == 0;   // not awaited: SpringBoard restarts right away
}

#pragma mark - Web page

+ (NSString *)signature {
    LoadPrefs();
    return [NSString stringWithFormat:@"%ld-%d-%ld-%d-%.3f-%.3f-%.3f-%d-%ld", (long)gSkin, EffectiveDark() ? 1 : 0, (long)[self effectiveWallpaperIndex],
            gAccOn ? 1 : 0, gAccH, gAccS, gAccB, gMaterial ? 1 : 0, (long)gWallpaper];
}

// data: URI of the chosen alternate icon (nil for the default icon). Cached per icon: the files never change at run time.
+ (NSString *)activeIconDataURI {
    ThemeSkin skin = [self activeIconSkin];
    BOOL dark = [self activeIconDark];
    NSString *name = [self iconNameForSkin:skin dark:dark];
    if (name.length == 0) return nil;
    static NSMutableDictionary *cache = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSMutableDictionary dictionary]; });
    NSString *cached = cache[name];
    if (cached) return cached;
    NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Icon-%@@3x", name] ofType:@"png"];
    NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
    if (!data) return nil;
    NSString *uri = [@"data:image/png;base64," stringByAppendingString:[data base64EncodedStringWithOptions:0]];
    cache[name] = uri;
    return uri;
}

+ (NSString *)webThemeCSS {
    LoadPrefs();
    ThemePalette p = CurrentPalette();
    BOOL dark = EffectiveDark();
    BOOL hasWallpaper = [self effectiveWallpaperIndex] > 0 || gWallpaper == ThemeSkinCount;   // a picture or the moving gradient

    uint32_t bubble = (gSkin == ThemeSkinClaude && !gAccOn) ? p.selection : MixHex(p.surface, p.accent, dark ? 0.30 : 0.16);
    uint32_t link = dark ? p.accent : ScaleHex(p.accent, 0.82);   // darker in light mode so links stay readable
    uint32_t codeBg = MixHex(p.bg, p.selection, 0.5);

    NSMutableString *css = [NSMutableString string];
    [css appendString:@":root{"];
    [css appendFormat:@"--bg:%@;--text:%@;--sec:%@;--border:%@;--sel:%@;--bubble:%@;",
        CSSHex(p.bg), CSSHex(p.text), CSSHex(p.secondary), CSSHex(p.border), CSSHex(p.selection), CSSHex(bubble)];
    [css appendFormat:@"--accent:%@;--onaccent:%@;--link:%@;--card:%@;--code-bg:%@;",
        CSSHex(p.accent), AccentIsLight(p.accent) ? @"#1B1B1B" : @"#FFFFFF", CSSHex(link), CSSRGBA(p.surface, dark ? 0.88 : 0.90), CSSHex(codeBg)];
    if (dark) {
        [css appendString:@"--err-bg:#3A1D18;--err-border:#6B3328;--err-text:#F0A494;"];
        [css appendFormat:@"--toast-bg:%@;--toast-fg:%@;", CSSHex(p.text), CSSHex(p.bg)];
        [css appendString:@"--hl-kw:#E2896A;--hl-str:#7CC79A;--hl-com:#8F8B80;--hl-num:#6DB3DB;--hl-title:#B48AE0;--hl-attr:#E0A850;"];
    } else {
        [css appendString:@"--err-bg:#FCEDEA;--err-border:#EBC4BB;--err-text:#8F2F1D;"];
        [css appendFormat:@"--toast-bg:%@;--toast-fg:%@;", CSSHex(p.text), CSSHex(p.bg)];
        [css appendString:@"--hl-kw:#A5472B;--hl-str:#3F7D58;--hl-com:#8A8677;--hl-num:#2F6B8C;--hl-title:#7B4FA2;--hl-attr:#B0731A;"];
    }
    [css appendString:@"}"];

    // The picture on the empty chat follows the app icon that is chosen (the default icon keeps the original logo).
    NSString *iconURI = [self activeIconDataURI];
    if (iconURI.length > 0) [css appendFormat:@".empty .logo{background-image:url(\"%@\") !important;}", iconURI];

    if (gMaterial) {
        // Material 3: rounder message shapes, tonal user bubble, softer cards.
        [css appendString:@".bubble{border-radius:calc(22px * var(--uiscale)) calc(22px * var(--uiscale)) calc(6px * var(--uiscale)) calc(22px * var(--uiscale)) !important;}"];
        [css appendString:@".act,.code-block,pre{border-radius:calc(18px * var(--uiscale)) !important;}"];
    }
    if (hasWallpaper) {
        // Text sits on translucent cards so it stays readable on any wallpaper.
        [css appendString:@".row.assistant .body{background:var(--card);padding:12px 14px;border-radius:16px;}"];
        [css appendString:@".act{background:var(--card);}"];
        [css appendString:@".thinking-label{display:inline-block;background:var(--card);padding:3px 9px;border-radius:9px;}"];
        // Pinned with fixed pixels (not vh): when the keyboard opens the page gets shorter and a vh margin made the card jump.
        [css appendString:@".empty{background:var(--card);border-radius:22px;top:24px;width:calc(100% - 44px);max-width:716px;padding:26px 16px 24px 16px;box-sizing:border-box;}"];
    }
    return css;
}

@end
