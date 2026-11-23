#import <UIKit/UIKit.h>

// Skins. Index 0 is the original Claude look; 1...6 are the colour skins (each has its own accent colour,
// app icon and default chat wallpaper). Every skin has a light and a dark palette.
typedef NS_ENUM(NSInteger, ThemeSkin) {
    ThemeSkinClaude = 0,
    ThemeSkinSideStore,       // purple
    ThemeSkinLiveContainer,   // sea blue
    ThemeSkinDopamine,        // green
    ThemeSkinChimera,         // white
    ThemeSkinSileo,           // cyan / teal
    ThemeSkinGithub,          // red
    ThemeSkinCount
};

@interface Theme : NSObject

#pragma mark - Palette of the current skin (light or dark, as chosen in Settings)

+ (UIColor *)background;      // page background
+ (UIColor *)surface;         // cards / input fields
+ (UIColor *)border;
+ (UIColor *)accent;
+ (UIColor *)accentPressed;
+ (UIColor *)accentDisabled;
+ (UIColor *)text;
+ (UIColor *)secondaryText;
+ (UIColor *)success;
+ (UIColor *)error;
+ (UIColor *)selection;       // highlighted table row

+ (UIColor *)onAccent;        // text colour that reads well on the accent (white, or near-black on a light accent)
+ (UIFont *)serifFontOfSize:(CGFloat)size;           // Georgia, falls back to system font
+ (UIImage *)imageWithColor:(UIColor *)color;        // 1x1 stretchable image for button states

// Template icons drawn in code (no image assets needed). Tint them with tintColor.
+ (UIImage *)iconMenu;
+ (UIImage *)iconPlus;
+ (UIImage *)iconCompose;   // square with a pencil: "new chat"
+ (UIImage *)iconSend;
+ (UIImage *)iconMic;       // microphone (drawn, no emoji)
+ (UIImage *)iconMicOfSize:(CGFloat)side;
+ (UIImage *)iconSearch;    // magnifying glass
+ (UIImage *)iconBolt;
+ (UIImage *)iconTool:(NSString *)name;   // "photo" "file" "library" "camera" "web" "think" "sparkle" "more" (template images)      // lightning bolt
+ (UIImage *)iconClose;     // cross
+ (UIImage *)iconStop;
+ (UIImage *)iconGear;      // cog wheel: Settings
+ (UIImage *)iconRefresh;   // circular arrow: reload the model list
+ (UIImage *)iconBack;      // chevron pointing left

+ (void)styleNavigationBar:(UINavigationBar *)bar;

#pragma mark - Skin, dark mode, chat wallpaper (all stored on the device)

+ (ThemeSkin)skin;
+ (void)setSkin:(ThemeSkin)skin;                     // does not post a notification: call +postChange
+ (UIVisualEffectView *)backdropBlurView;               // the blurred backdrop behind every pop-up (same blur as behind the chat history list)
+ (BOOL)darkMode;                                    // what is shown now (follows the clock when auto mode is on)
+ (void)setDarkMode:(BOOL)dark;                      // the manual choice
+ (BOOL)autoMode;                                    // YES = dark from 18:00 to 05:59 by the device clock
+ (void)setAutoMode:(BOOL)automatic;
+ (BOOL)consumeAutoModeChange;                       // YES once when the clock crossed day <-> night (then call +postChange)
+ (UIImage *)modePreviewImageDark:(BOOL)dark size:(CGSize)size;   // little phone mock-up in the colours of the current skin

// -1 = follow the skin, 0 = no wallpaper (plain colour), 1...6 = the wallpaper of that skin.
+ (NSInteger)wallpaperChoice;
+ (void)setWallpaperChoice:(NSInteger)choice;
+ (NSInteger)effectiveWallpaperIndex;                // what is really shown: 0 (none) or 1...6

+ (void)postChange;                                  // tells every screen to restyle (kNotifThemeChanged)

+ (NSString *)skinName:(ThemeSkin)skin;              // "SideStore Skin", ...
+ (NSString *)skinColorKey:(ThemeSkin)skin;          // localisation key of the colour name ("skin_color_purple", ...)
+ (UIColor *)swatchColorForSkin:(ThemeSkin)skin;     // accent of the skin in the CURRENT light/dark mode
+ (NSString *)wallpaperName:(NSInteger)index;        // name for wallpaper 1...6

+ (UIImage *)wallpaperImage;                         // the wallpaper being shown, or nil
+ (UIImage *)wallpaperThumbnail:(NSInteger)index;    // small preview of wallpaper 1...6 (cached)
+ (CGFloat)wallpaperDimAlpha;                        // black overlay on the wallpaper (dark mode only)

+ (UIKeyboardAppearance)keyboardAppearance;

#pragma mark - Custom accent colour (hue / saturation / brightness picked by the user)

// While active it replaces the accent of the skin and tints the whole palette (backgrounds, cards, borders).
+ (BOOL)customAccentActive;
+ (void)getCustomHue:(CGFloat *)hue saturation:(CGFloat *)saturation brightness:(CGFloat *)brightness;   // the picked values, or the skin accent's when none is picked
+ (void)setCustomHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness;         // does not post a notification
+ (void)resetCustomAccent;                                                                              // back to the accent of the skin
+ (UIColor *)colorWithHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness;
+ (NSString *)hexStringForHue:(CGFloat)hue saturation:(CGFloat)saturation brightness:(CGFloat)brightness;   // "#A34CBE"

#pragma mark - Material 3 design and the moving gradient wallpaper

+ (BOOL)materialDesign;                                // Material 3 look (cards, tonal surfaces, M3 switches and sliders)
+ (void)setMaterialDesign:(BOOL)on;                    // does not post a notification
+ (NSInteger)gradientWallpaperChoice;                  // the wallpaper choice that means "moving gradient" (= ThemeSkinCount)
+ (BOOL)gradientWallpaperActive;                       // the chat shows the moving gradient made from the accent colour
+ (NSArray<UIColor *> *)gradientWallpaperColors;       // four colours, tinted by the accent, for the current light / dark mode

#pragma mark - App icon

+ (NSString *)iconNameForSkin:(ThemeSkin)skin;       // key in CFBundleAlternateIcons; nil for the default icon
+ (UIImage *)iconPreviewForSkin:(ThemeSkin)skin;
+ (NSString *)iconNameForSkin:(ThemeSkin)skin dark:(BOOL)dark;   // key in CFBundleAlternateIcons for the light or dark picture ("SideStore-Dark", "Default-Dark"...)
+ (UIImage *)iconPreviewForSkin:(ThemeSkin)skin dark:(BOOL)dark;
+ (BOOL)iconStyleDark;                                // the style picked in Settings > Appearance > App icon (light or dark pictures)
+ (void)setIconStyleDark:(BOOL)dark;
+ (BOOL)activeIconDark;                               // the Home Screen icon in use is the dark picture
+ (NSString *)iconDisplayNameForSkin:(ThemeSkin)skin;   // "SideStore", "LiveContainer"... (no "Skin"); "Mặc định" for the default icon
+ (UIImage *)activeIconImage;                         // picture of the icon in use (the logo for the default icon)
+ (ThemeSkin)activeIconSkin;                          // the icon that is on the Home Screen now (ThemeSkinClaude = default)
+ (BOOL)respringWithHelper;                           // rootful .deb only: asks the root helper to restart SpringBoard
+ (NSString *)currentIconName;                       // nil = default icon (system alternate-icon API)

// Rootful .deb only: a setuid-root helper swaps the icon files inside the app and runs uicache, because the
// system API does not update the Home Screen for apps installed in /Applications.
+ (BOOL)iconHelperAvailable;
+ (ThemeSkin)helperIconSkin;                         // the skin whose icon the helper last applied
+ (BOOL)applyIconWithHelperForSkin:(ThemeSkin)skin dark:(BOOL)dark message:(NSString **)message;   // blocking: call off the main thread
+ (void)reapplyHelperIconIfNeeded;                   // e.g. after the .deb was upgraded and reset the icon files

#pragma mark - Web page

// CSS rules that give the chat page (WKWebView) the colours of the current skin. Injected into <style id="themevars">.
+ (NSString *)webThemeCSS;

// Changes whenever the skin, light/dark mode or wallpaper changes (use it as a cell reuse identifier suffix).
+ (NSString *)signature;

@end
