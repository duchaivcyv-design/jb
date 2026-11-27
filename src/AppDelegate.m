#import "TimeSync.h"
#import "AppDelegate.h"
#import "RootViewController.h"
#import "ChatViewController.h"
#import "KeyStore.h"
#import "Strings.h"
#import "Theme.h"
#import "DiagnosticLog.h"
#import "MiniNavigationController.h"
#import "UpdateManager.h"
#import "InstructionFile.h"
#import "AppSettings.h"

@interface AppDelegate ()
@property (assign, nonatomic) BOOL showingMain;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [DiagnosticLog logLaunch];
    [TimeSync refreshForce:YES];
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    [self applyThemeToWindow];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{ [Theme reapplyHelperIconIfNeeded]; });

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(themeChanged)
                                                 name:kNotifThemeChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applyKeyState)
                                                 name:kNotifKeyChanged
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(languageChanged)
                                                 name:kNotifLanguageChanged
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(layoutModeChanged)
                                                 name:kNotifLayoutChanged
                                               object:nil];

    [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(autoThemeTick) userInfo:nil repeats:YES];

    [self applyKeyState];
    [self.window makeKeyAndVisible];
    // Look for a new version a few seconds after launch (the result only shows as a dot on the cog and in Settings).
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [[UpdateManager shared] checkForUpdateForce:NO];
    });
    return YES;
}

// Which orientations the app may use follows the layout chosen in Settings (phone = portrait only).
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    return [AppSettings allowedOrientations];
}

// Phone layout chosen while the device is on its side: bring it back upright. Otherwise let iOS pick up the new allowance.
- (void)layoutModeChanged {
    if ([AppSettings layoutMode] == 1 && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        [[UIDevice currentDevice] setValue:@(UIInterfaceOrientationPortrait) forKey:@"orientation"];
    }
    [UIViewController attemptRotationToDeviceOrientation];
}

// A .clmn instruction file opened with ClaudeMini (Files, share sheet, AirDrop): its text goes into the AI instructions.
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if (!url.isFileURL) return NO;
    // The screens may still be building when the app is launched by the file: give them a moment.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [InstructionFile handleOpenedURL:url];
    });
    return YES;
}

// Window colours follow the chosen skin. On iOS 13+ the window also switches system controls (alerts, pickers) to dark.
- (void)applyThemeToWindow {
    self.window.backgroundColor = [Theme background];
    if (![self.window.tintColor isEqual:[Theme accent]]) self.window.tintColor = [Theme accent];   // a change re-lays out every bar: only when needed
    if (@available(iOS 13.0, *)) {
        UIUserInterfaceStyle style = [Theme darkMode] ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
        if (self.window.overrideUserInterfaceStyle != style) self.window.overrideUserInterfaceStyle = style;
    }
}

// Auto dark mode follows the device clock: check when the app comes back and once a minute while it is open.
- (void)applicationDidBecomeActive:(UIApplication *)application {
    [TimeSync refresh];
    [self autoThemeTick];
}

- (void)autoThemeTick {
    if ([Theme consumeAutoModeChange]) [Theme postChange];
}

// The skin, dark mode or wallpaper changed in Settings: restyle in place (the open chat is kept).
- (void)themeChanged {
    [self applyThemeToWindow];
    UIViewController *root = self.window.rootViewController;
    if ([root isKindOfClass:[MiniNavigationController class]]) {
        // Restyling the bar in the middle of a push/pop (or for a wallpaper-only change) can leave "back" dead.
        [(MiniNavigationController *)root restyleBarWhenIdle];
    }
}

// Key present -> chat. No key -> key screen.
- (void)applyKeyState {
    BOOL hasKey = [KeyStore hasAnyKey];   // a Gemini key or a Claude key is enough
    if (self.window.rootViewController == nil) {
        if (hasKey) [self showMainAnimated:NO]; else [self showOnboardingAnimated:NO];
    } else if (hasKey && !self.showingMain) {
        [self showMainAnimated:YES];
    } else if (!hasKey && self.showingMain) {
        [self showOnboardingAnimated:YES];
    }
}

// The language was changed in Settings: rebuild the screens so every label uses it.
- (void)languageChanged {
    if (self.showingMain) [self showMainAnimated:YES]; else [self showOnboardingAnimated:YES];
}

- (void)setRoot:(UIViewController *)controller animated:(BOOL)animated {
    if (!animated || self.window.rootViewController == nil) {
        self.window.rootViewController = controller;
        return;
    }
    [UIView transitionWithView:self.window
                      duration:0.25
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ self.window.rootViewController = controller; }
                    completion:nil];
}

- (void)showMainAnimated:(BOOL)animated {
    self.showingMain = YES;
    MiniNavigationController *nav = [[MiniNavigationController alloc] initWithRootViewController:[[ChatViewController alloc] init]];
    [Theme styleNavigationBar:nav.navigationBar];
    [nav restyleBarWhenIdle];
    [self setRoot:nav animated:animated];
}

- (void)showOnboardingAnimated:(BOOL)animated {
    self.showingMain = NO;
    [self setRoot:[[RootViewController alloc] init] animated:animated];
}

@end
