#import "FontStyle.h"
#import "AppSettings.h"
#import <objc/runtime.h>
#import <CoreText/CoreText.h>
#import <dlfcn.h>

// The nine SF Pro Rounded weights shipped in the app (Resources/Fonts), lightest first.
static NSString *const kRoundedNames[9] = {
    @"SFProRounded-Ultralight", @"SFProRounded-Thin", @"SFProRounded-Light", @"SFProRounded-Regular", @"SFProRounded-Medium",
    @"SFProRounded-Semibold", @"SFProRounded-Bold", @"SFProRounded-Heavy", @"SFProRounded-Black"
};
static const CGFloat kRoundedWeights[9] = { -0.8, -0.6, -0.4, 0.0, 0.23, 0.3, 0.4, 0.56, 0.62 };   // UIFontWeight of each file

static BOOL gFontsRegistered = NO;

static void RegisterRoundedFonts(void) {
    NSArray<NSURL *> *urls = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"otf" subdirectory:@"Fonts"];
    for (NSURL *url in urls) {
        CFErrorRef error = NULL;
        if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)url, kCTFontManagerScopeProcess, &error) && error) CFRelease(error);   // "already registered" is fine
    }
    gFontsRegistered = YES;
}

NSString *CMWebFontStack(void) {
    if ([AppSettings fontStyle] == 2) return @"ui-rounded, \"SF Pro Rounded\", \"SFProRounded-Regular\", -apple-system, \"Helvetica Neue\", sans-serif";
    return @"-apple-system, \"Helvetica Neue\", Helvetica, sans-serif";
}

NSInteger CMWebFontWeight(void) {
    return 400 + 100 * [AppSettings fontWeightStep];   // 100...700
}

NSString *CMRoundedFontFaceCSS(void) {
    // iOS 13+ has ui-rounded (the real SF Rounded). On iOS 12 the page gets the shipped files as data URIs.
    if (@available(iOS 13.0, *)) return @"";
    NSMutableString *css = [NSMutableString string];
    NSArray *names = @[@"Light", @"Regular", @"Medium", @"Semibold", @"Bold"];
    NSArray *weights = @[@300, @400, @500, @600, @700];
    for (NSUInteger i = 0; i < names.count; i++) {
        NSString *path = [[NSBundle mainBundle] pathForResource:[@"SF-Pro-Rounded-" stringByAppendingString:names[i]] ofType:@"otf" inDirectory:@"Fonts"];
        NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
        if (!data) continue;
        [css appendFormat:@"@font-face{font-family:\"SFProRounded-Regular\";font-weight:%@;src:url(data:font/otf;base64,%@) format(\"opentype\");}",
         weights[i], [data base64EncodedStringWithOptions:0]];
    }
    return css;
}

static CGFloat AdjustedWeight(CGFloat weight) {
    CGFloat w = weight + 0.14 * (CGFloat)[AppSettings fontWeightStep];
    return MAX(UIFontWeightUltraLight, MIN(UIFontWeightBlack, w));
}

static UIFont *RoundedFont(CGFloat size, CGFloat weight) {
    if (!gFontsRegistered) RegisterRoundedFonts();
    NSInteger best = 3;
    CGFloat distance = CGFLOAT_MAX;
    for (NSInteger i = 0; i < 9; i++) {
        CGFloat d = fabs(kRoundedWeights[i] - weight);
        if (d < distance) { distance = d; best = i; }
    }
    return [UIFont fontWithName:kRoundedNames[best] size:size];
}

@implementation UIFont (ClaudeMiniStyle)

+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        RegisterRoundedFonts();
        Method original = class_getClassMethod(self, @selector(systemFontOfSize:weight:));
        Method replacement = class_getClassMethod(self, @selector(cm_systemFontOfSize:weight:));
        if (original && replacement) method_exchangeImplementations(original, replacement);
        Method plain = class_getClassMethod(self, @selector(systemFontOfSize:));
        Method plainNew = class_getClassMethod(self, @selector(cm_systemFontOfSize:));
        if (plain && plainNew) method_exchangeImplementations(plain, plainNew);
        Method bold = class_getClassMethod(self, @selector(boldSystemFontOfSize:));
        Method boldNew = class_getClassMethod(self, @selector(cm_boldSystemFontOfSize:));
        if (bold && boldNew) method_exchangeImplementations(bold, boldNew);
    });
}

// ---- Only the app's own text is restyled ----
// The three methods are exchanged for the whole process, so UIKit's own code (alerts, keyboard, share sheet,
// context menus ...) would also get the chosen font. Each replacement therefore looks at who is calling:
// only code inside this app's executable gets the SF Rounded / weight treatment, everything else gets the
// untouched system font.
static const void *OwnImageBase(void) {
    static const void *base = NULL;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        Dl_info info;
        if (dladdr((const void *)&OwnImageBase, &info)) base = info.dli_fbase;
    });
    return base;
}

static BOOL CalledFromApp(const void *returnAddress) {
    Dl_info info;
    if (!dladdr(returnAddress, &info)) return NO;
    return info.dli_fbase != NULL && info.dli_fbase == OwnImageBase();
}

// The styled font for the app; `original` is the system's own implementation (reached through the exchanged selector).
+ (UIFont *)cm_styledFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    CGFloat adjusted = AdjustedWeight(weight);
    if ([AppSettings fontStyle] == 2) {
        UIFont *rounded = RoundedFont(size, adjusted);   // the shipped SF Pro Rounded files: also on iOS 12
        if (rounded) return rounded;
    }
    return [self cm_systemFontOfSize:size weight:adjusted];   // after the exchange: the original implementation
}

// After the exchange, this body runs for [UIFont systemFontOfSize:weight:] and calling cm_... runs the original.
+ (UIFont *)cm_systemFontOfSize:(CGFloat)size weight:(UIFontWeight)weight {
    if (!CalledFromApp(__builtin_return_address(0))) return [self cm_systemFontOfSize:size weight:weight];
    return [self cm_styledFontOfSize:size weight:weight];
}

+ (UIFont *)cm_systemFontOfSize:(CGFloat)size {
    if (!CalledFromApp(__builtin_return_address(0))) return [self cm_systemFontOfSize:size];   // the original plain method
    return [self cm_styledFontOfSize:size weight:UIFontWeightRegular];
}

+ (UIFont *)cm_boldSystemFontOfSize:(CGFloat)size {
    if (!CalledFromApp(__builtin_return_address(0))) return [self cm_boldSystemFontOfSize:size];   // the original bold method
    return [self cm_styledFontOfSize:size weight:UIFontWeightBold];
}

@end
