#import "ChatViewController.h"
#import <WebKit/WebKit.h>
#import <PhotosUI/PhotosUI.h>
#import <AVFoundation/AVFoundation.h>
#import "Strings.h"
#import "Theme.h"
#import "KeyStore.h"
#import "GeminiClient.h"
#import "GeminiStream.h"
#import "ClaudeClient.h"
#import "ClaudeStream.h"
#import "ChatStreaming.h"
#import "Provider.h"
#import "AppSettings.h"
#import "ImageViewerViewController.h"
#import "DiagnosticLog.h"
#import "ModelStore.h"
#import "ConversationStore.h"
#import "AttachmentStore.h"
#import "HistoryViewController.h"
#import "ModelPickerViewController.h"
#import "ModelPopupViewController.h"
#import "ConfirmPopupViewController.h"
#import "ComposerViews.h"
#import "ChoicePopupViewController.h"
#import "UpdateManager.h"
#import "KeyTier.h"
#import "OfficeExport.h"
#import "VoiceChatManager.h"
#import "FontStyle.h"
#import "Material.h"
#import <math.h>

static const CGFloat kMaxInputHeight = 120;
static const CGFloat kStripHeight = 64;
static const CGFloat kToolsRowHeight = 0;
static const NSUInteger kGreetingCount = 6;
static const NSUInteger kForceMaxContextChars = 4000000;

#pragma mark - Weak script handler

@protocol ScriptMessageTarget <NSObject>
- (void)handleScriptMessage:(WKScriptMessage *)message;
@end

@interface WeakScriptHandler : NSObject <WKScriptMessageHandler>
@property (weak, nonatomic) id<ScriptMessageTarget> target;
- (instancetype)initWithTarget:(id<ScriptMessageTarget>)target;
@end

@implementation WeakScriptHandler
- (instancetype)initWithTarget:(id<ScriptMessageTarget>)target {
    self = [super init];
    if (self) _target = target;
    return self;
}
- (void)userContentController:(WKUserContentController *)userContentController
      didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.target handleScriptMessage:message];
}
@end

static NSString *StreamErrorName(GeminiStreamError error) {
    switch (error) {
        case GeminiStreamErrorNone:             return @"ok";
        case GeminiStreamErrorCancelled:        return @"cancelled";
        case GeminiStreamErrorInvalidKey:       return @"invalid_key";
        case GeminiStreamErrorPermissionDenied: return @"permission_denied";
        case GeminiStreamErrorModelNotFound:    return @"model_not_found";
        case GeminiStreamErrorRateLimited:      return @"rate_limited";
        case GeminiStreamErrorNetwork:          return @"network";
        case GeminiStreamErrorBlocked:          return @"blocked";
        case GeminiStreamErrorServer:           return @"server";
        case GeminiStreamErrorEmptyReply:       return @"empty_reply";
        case GeminiStreamErrorTooLarge:         return @"too_large";
        case GeminiStreamErrorNoCredit:         return @"no_credit";
        default:                                return @"unknown";
    }
}

static NSString *ClippedForLog(NSString *text) {
    if (text.length == 0) return @"-";
    NSString *oneLine = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
    return oneLine.length > 200 ? [[oneLine substringToIndex:200] stringByAppendingString:@"…"] : oneLine;
}

static UIImage *DrawCrossIconImage(CGFloat size, UIColor *color) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    UIBezierPath *p = [UIBezierPath bezierPath];
    CGFloat pad = size * 0.26;
    [p moveToPoint:CGPointMake(pad, pad)];
    [p addLineToPoint:CGPointMake(size - pad, size - pad)];
    [p moveToPoint:CGPointMake(size - pad, pad)];
    [p addLineToPoint:CGPointMake(pad, size - pad)];
    p.lineWidth = 2.2;
    p.lineCapStyle = kCGLineCapRound;
    [color setStroke];
    [p stroke];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

// A solid cog with eight teeth and a round hole, drawn with code (no emoji, no system symbol) so it looks the same on every iOS version.
static UIImage *DrawSettingsGearIconImage(CGFloat size, UIColor *color) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    CGPoint c = CGPointMake(size * 0.5, size * 0.5);
    CGFloat rOuter = size * 0.47, rInner = size * 0.35, rHole = size * 0.15;
    NSInteger teeth = 8;
    CGFloat step = (CGFloat)(2.0 * M_PI) / teeth;
    UIBezierPath *gear = [UIBezierPath bezierPath];
    for (NSInteger i = 0; i < teeth; i++) {
        CGFloat a = i * step - (CGFloat)M_PI_2;
        CGPoint bl = CGPointMake(c.x + cos(a - 0.27 * step) * rInner, c.y + sin(a - 0.27 * step) * rInner);
        CGPoint tl = CGPointMake(c.x + cos(a - 0.15 * step) * rOuter, c.y + sin(a - 0.15 * step) * rOuter);
        CGPoint tr = CGPointMake(c.x + cos(a + 0.15 * step) * rOuter, c.y + sin(a + 0.15 * step) * rOuter);
        CGPoint br = CGPointMake(c.x + cos(a + 0.27 * step) * rInner, c.y + sin(a + 0.27 * step) * rInner);
        if (i == 0) [gear moveToPoint:bl]; else [gear addLineToPoint:bl];
        [gear addLineToPoint:tl];
        [gear addLineToPoint:tr];
        [gear addLineToPoint:br];
        [gear addArcWithCenter:c radius:rInner startAngle:a + 0.27 * step endAngle:a + 0.73 * step clockwise:YES];
    }
    [gear closePath];
    [gear appendPath:[UIBezierPath bezierPathWithArcCenter:c radius:rHole startAngle:0 endAngle:(CGFloat)(M_PI * 2.0) clockwise:YES]];
    gear.usesEvenOddFillRule = YES;
    [color setFill];
    [gear fill];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

static UIImage *DrawChevronRightIconImage(CGFloat size, UIColor *color) {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(size, size), NO, 0);
    UIBezierPath *p = [UIBezierPath bezierPath];
    [p moveToPoint:CGPointMake(size * 0.38, size * 0.24)];
    [p addLineToPoint:CGPointMake(size * 0.64, size * 0.5)];
    [p addLineToPoint:CGPointMake(size * 0.38, size * 0.76)];
    p.lineWidth = 2.0;
    p.lineCapStyle = kCGLineCapRound;
    p.lineJoinStyle = kCGLineJoinRound;
    [color setStroke];
    [p stroke];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

#pragma mark - ChatViewController

@interface ChatViewController () <WKNavigationDelegate, ScriptMessageTarget, UITextViewDelegate,
                                  UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate,
                                  PHPickerViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIView *chatStageView;
@property (strong, nonatomic) WKWebView *webView;
@property (assign, nonatomic) BOOL webReady;
@property (copy, nonatomic) NSString *lastWebError;

// Half-width History Drawer + shifted Chat Stage
@property (assign, nonatomic) BOOL historyDrawerOpen;
@property (assign, nonatomic) BOOL historyPinned;   // iPhone Duo / wide screen: the history list is a fixed pane on the left
@property (strong, nonatomic) UIView *historyDrawerView;
@property (strong, nonatomic) UIView *historySearchWrap;
@property (strong, nonatomic) UIImageView *historySearchIcon;
@property (strong, nonatomic) UITextField *historySearchField;
@property (strong, nonatomic) UILabel *historyEmptyLabel;
@property (strong, nonatomic) UIView *historySettingsBadge;
@property (strong, nonatomic) UIImageView *historySettingsIcon;
@property (strong, nonatomic) UILabel *historySettingsLabel;
@property (strong, nonatomic) UIImageView *historySettingsChevron;
@property (strong, nonatomic) UIView *historyUpdateDot;
@property (assign, nonatomic) BOOL historyDrawerAnimating;
@property (assign, nonatomic) BOOL chatIsEmpty;
@property (copy, nonatomic) NSString *appliedNativeScaleSig;
@property (copy, nonatomic) NSString *appliedWebScaleSig;
@property (strong, nonatomic) UITableView *historyTableView;
@property (strong, nonatomic) UIButton *historyCloseXButton;
@property (strong, nonatomic) UIButton *historySettingsButton;
@property (strong, nonatomic) UIButton *chatRightOverlayButton;
@property (strong, nonatomic) UIVisualEffectView *chatBlurView;   // blurs the chat while the history drawer is open
@property (strong, nonatomic) NSArray<NSDictionary *> *historyAllItems;
@property (strong, nonatomic) NSArray<NSDictionary *> *historyFilteredItems;

@property (strong, nonatomic) UIView *inputBar;
@property (strong, nonatomic) UIScrollView *attachStrip;
@property (strong, nonatomic) UIView *inputBox;
@property (strong, nonatomic) UIButton *attachButton;
@property (strong, nonatomic) UIButton *micButton;
@property (strong, nonatomic) NSLayoutConstraint *modelWidthConstraint;
@property (strong, nonatomic) UIButton *searchChipButton;
@property (strong, nonatomic) UIView *toolMenuOverlay;
@property (strong, nonatomic) UIView *toolMenuCard;
@property (strong, nonatomic) UIView *toolRow;
@property (strong, nonatomic) UIButton *reasoningButton;
@property (strong, nonatomic) UIButton *searchButton;
@property (strong, nonatomic) UIButton *fastButton;
@property (strong, nonatomic) UIButton *mentionButton;
@property (strong, nonatomic) UILabel *reasoningValueLabel;
@property (strong, nonatomic) UIButton *reasoningFastButton;
@property (strong, nonatomic) UILabel *reasoningFastHintLabel;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UILabel *placeholderLabel;
@property (strong, nonatomic) ComposerSendButton *sendButton;
@property (strong, nonatomic) ComposerModelPill *modelPill;     // Material 3 message box: the model name inside the box
@property (strong, nonatomic) ComposerGlowView *glowView;        // the light that runs round the box while a reply is written
@property (strong, nonatomic) VoiceChatManager *voiceManager;
@property (assign, nonatomic) BOOL voiceRecording;
@property (copy, nonatomic) NSString *dictationBase;          // what was typed before the mic was pressed
@property (assign, nonatomic) BOOL dictationUserEdited;       // the user typed while dictating: the spoken text no longer overwrites
@property (assign, nonatomic) BOOL applyingDictation;
@property (strong, nonatomic) UIButton *modelButton;
@property (assign, nonatomic) BOOL pendingModelPopup;
@property (assign, nonatomic) BOOL pendingModelPopupIntro;
@property (strong, nonatomic) UIImageView *wallpaperView;
@property (strong, nonatomic) MaterialGradientView *gradientView;   // the moving accent gradient wallpaper
@property (strong, nonatomic) UIView *dimView;
@property (assign, nonatomic) CGFloat keyboardOverlap;

@property (strong, nonatomic) NSMutableDictionary *conversation;
@property (copy, nonatomic) NSString *model;
@property (strong, nonatomic) id<ChatStreaming> stream;
@property (assign, nonatomic) BOOL streaming;
@property (assign, nonatomic) CFAbsoluteTime requestStartTime;
@property (assign, nonatomic) NSUInteger greetingIndex;
@property (copy, nonatomic) NSString *shownGreeting;
@property (assign, nonatomic) BOOL attemptIsStreaming;
@property (assign, nonatomic) NSInteger streamRetryCount;
@property (assign, nonatomic) BOOL didRecoverModel404;
@property (assign, nonatomic) BOOL didFallbackFromFastMode;
@property (strong, nonatomic) NSMutableString *streamBuffer;
@property (strong, nonatomic) NSMutableString *pendingJSDelta;
@property (strong, nonatomic) dispatch_source_t deltaFlushTimer;
@property (strong, nonatomic) NSMutableString *longReplyAccumulator;
@property (assign, nonatomic) NSUInteger longReplyContinuationCount;
@property (assign, nonatomic) NSUInteger earlyEndContinuations;   // continuations after a stream that closed quietly (capped: a provider that never sends its final event must not loop)
@property (assign, nonatomic) UIBackgroundTaskIdentifier replyBackgroundTask;
@property (assign, nonatomic) BOOL replyBackgroundTaskActive;
@property (strong, nonatomic) NSMutableArray *streamGeneratedAttachments;

@property (strong, nonatomic) NSMutableArray *pendingAttachments;
@property (assign, nonatomic) NSInteger importsInFlight;
@end

@implementation ChatViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [Theme background];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.pendingAttachments = [NSMutableArray array];
    self.chatIsEmpty = YES;
    self.view.clipsToBounds = YES;
    self.greetingIndex = arc4random_uniform((uint32_t)kGreetingCount);

    self.chatStageView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.chatStageView.backgroundColor = [Theme background];
    [self.view addSubview:self.chatStageView];

    UIBarButtonItem *menuItem = [[UIBarButtonItem alloc] initWithImage:[Theme iconMenu] style:UIBarButtonItemStylePlain target:self action:@selector(historyTapped)];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithImage:[Theme iconCompose] style:UIBarButtonItemStylePlain target:self action:@selector(newChatTapped)];

    self.modelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.modelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    self.modelButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    [self.modelButton setTitleColor:[Theme text] forState:UIControlStateNormal];
    [self updateModelTitle];
    [self.modelButton addTarget:self action:@selector(modelTapped) forControlEvents:UIControlEventTouchUpInside];
    self.modelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.modelButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIBarButtonItem *modelItem = [[UIBarButtonItem alloc] initWithCustomView:self.modelButton];
    self.navigationItem.leftBarButtonItems = @[menuItem, modelItem];
    [self updateModelTitle];

    [self setupWebView];
    [self setupInputBar];
    [self setupHistoryDrawer];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uiScaleChanged:) name:@"UIScaleDidChangeNotification" object:nil];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [center addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [center addObserver:self selector:@selector(historyCleared:) name:kNotifHistoryCleared object:nil];
    [center addObserver:self selector:@selector(conversationDeleted:) name:kNotifConversationDeleted object:nil];
    [center addObserver:self selector:@selector(applyTheme) name:kNotifThemeChanged object:nil];
    [center addObserver:self selector:@selector(layoutChanged) name:kNotifLayoutChanged object:nil];
    [center addObserver:self selector:@selector(updateStateChanged) name:kNotifUpdateChanged object:nil];

    NSMutableSet *keep = [NSMutableSet set];
    for (NSDictionary *entry in [ConversationStore allEntries]) {
        if (entry[@"id"]) [keep addObject:entry[@"id"]];
    }
    [AttachmentStore removeOrphansKeepingConversationIds:keep];

    self.model = [ModelStore selectedModelId];
    [self ensureModelMatchesKeys];
    self.conversation = [ConversationStore newConversationWithModel:self.model];
    [self updateModelTitle];
    [self updateSendButton];
    [self updateDailyTokenPrompt];
    [self updateToolButtons];
    [self applyTheme];

    [self loadWebPage];
    [self refreshModels];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ChatViewController *me = weakSelf;
        if (!me || me.webReady) return;
        [DiagnosticLog log:@"chat page did not report ready within 12 s (last web error: %@)", me.lastWebError ?: @"none"];
        [me showAlertMessage:[NSString stringWithFormat:L(@"web_fail_msg"), me.lastWebError ?: @"-"] title:L(@"web_fail_title")];
    });
}

- (void)dealloc {
    [self stopDeltaFlushTimer];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    if (self.replyBackgroundTaskActive) [[UIApplication sharedApplication] endBackgroundTask:self.replyBackgroundTask];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"native"];
}

// While a reply is being written the screen must not auto-lock (a locked phone suspends the app and cuts the connection), and a short
// trip to another app gets a little extra running time. Both are released as soon as the reply ends.
- (void)setStreaming:(BOOL)streaming {
    _streaming = streaming;
    [self.glowView setActive:(streaming && [Material active]) animated:self.view.window != nil];
    UIApplication *app = [UIApplication sharedApplication];
    if (streaming) {
        app.idleTimerDisabled = YES;
        if (!self.replyBackgroundTaskActive) {
            __weak typeof(self) weakSelf = self;
            self.replyBackgroundTask = [app beginBackgroundTaskWithName:@"chat-reply" expirationHandler:^{
                ChatViewController *me = weakSelf;
                if (me && me.replyBackgroundTaskActive) {
                    me.replyBackgroundTaskActive = NO;
                    [[UIApplication sharedApplication] endBackgroundTask:me.replyBackgroundTask];
                }
            }];
            self.replyBackgroundTaskActive = YES;
        }
    } else {
        app.idleTimerDisabled = NO;
        if (self.replyBackgroundTaskActive) {
            self.replyBackgroundTaskActive = NO;
            [app endBackgroundTask:self.replyBackgroundTask];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self ensureModelMatchesKeys];
    [self updateModelTitle];
    [self updateDailyTokenPrompt];
    [self updateToolButtons];
    [self refreshGreetingIfEmpty];
    [self unlockWebViewScrolling];
    [self applyUIScaleToNativeAndWeb];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self unlockWebViewScrolling];
    if ([KeyTier needsGeminiDetection]) [self refreshModels];
    if (self.pendingModelPopup) {
        BOOL intro = self.pendingModelPopupIntro;
        self.pendingModelPopup = NO;
        self.pendingModelPopupIntro = NO;
        [self presentModelPopupIntro:intro];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.voiceRecording) [self.voiceManager cancelDictation];   // leaving the chat (Settings, ...): stop listening
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [Theme darkMode] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark - History Drawer (the whole chat slides to the right; it is never squeezed)

static const CGFloat kDrawerWidthRatio = 0.62;

- (CGFloat)historyDrawerWidth {
    CGFloat w = self.view.bounds.size.width;
    CGFloat safeLeft = 0;
    if (@available(iOS 11.0, *)) safeLeft = self.view.safeAreaInsets.left;   // the notch side of a phone on its side
    if ([self duoActive]) return MIN(floor(w * 0.5), [AppSettings duoSidebarBaseWidth]) + safeLeft;
    return MIN(floor(w * kDrawerWidthRatio), 320.0) + safeLeft;
}

// iPhone Duo / wide screen: two panes (the history list stays on the left of the chat).
- (BOOL)duoActive {
    return [AppSettings duoActiveForSize:self.view.bounds.size];
}

- (BOOL)duoPinned {
    return [self duoActive] && ![AppSettings duoSidebarCollapsed];
}

// Rotation, another layout chosen in Settings, or the left pane folded away: lay everything out again, smoothly.
- (void)layoutChanged {
    [self.view endEditing:YES];
    void (^relayout)(void) = ^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    };
    if ([Material active]) [Material animateEmphasizedDecelerate:MaterialDurationMedium4 animations:relayout completion:nil];
    else [UIView animateWithDuration:0.28 delay:0 options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:relayout completion:nil];
}

// The pinned list shows the open chat highlighted: refresh it when the chats change.
- (void)refreshPinnedSidebar {
    if (self.historyPinned) [self reloadHistoryItems];
}

- (void)setupHistoryDrawer {
    self.historyDrawerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.historyDrawerView.backgroundColor = [Theme surface];
    self.historyDrawerView.layer.borderWidth = 1.0;
    self.historyDrawerView.layer.borderColor = [Theme border].CGColor;
    self.historyDrawerView.clipsToBounds = YES;
    self.historyDrawerView.hidden = YES;
    [self.view addSubview:self.historyDrawerView];

    // Search sits at the top, level with the close button.
    self.historySearchWrap = [[UIView alloc] initWithFrame:CGRectZero];
    self.historySearchWrap.backgroundColor = [Theme background];
    self.historySearchWrap.layer.cornerRadius = 12;
    self.historySearchWrap.layer.borderWidth = 1.0;
    self.historySearchWrap.layer.borderColor = [Theme border].CGColor;
    [self.historyDrawerView addSubview:self.historySearchWrap];

    self.historySearchIcon = [[UIImageView alloc] initWithImage:[Theme iconSearch]];
    self.historySearchIcon.contentMode = UIViewContentModeScaleAspectFit;
    self.historySearchIcon.tintColor = [Theme secondaryText];
    [self.historySearchWrap addSubview:self.historySearchIcon];

    self.historySearchField = [[UITextField alloc] initWithFrame:CGRectZero];
    self.historySearchField.font = [UIFont systemFontOfSize:15];
    self.historySearchField.textColor = [Theme text];
    self.historySearchField.tintColor = [Theme accent];
    self.historySearchField.returnKeyType = UIReturnKeySearch;
    self.historySearchField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.historySearchField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.historySearchField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.historySearchField.keyboardAppearance = [Theme keyboardAppearance];
    self.historySearchField.delegate = self;
    [self.historySearchField addTarget:self action:@selector(historySearchChanged) forControlEvents:UIControlEventEditingChanged];
    [self.historySearchWrap addSubview:self.historySearchField];
    [self refreshHistorySearchPlaceholder];

    self.historyTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [Material installTableEffects:self.historyTableView];   // Material 3 press feedback (does nothing in the Classic design)
    self.historyTableView.backgroundColor = [UIColor clearColor];
    self.historyTableView.separatorColor = [Theme border];
    self.historyTableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.historyTableView.cellLayoutMarginsFollowReadableWidth = NO;
    self.historyTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    self.historyTableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.historyTableView.dataSource = self;
    self.historyTableView.delegate = self;
    [self.historyDrawerView addSubview:self.historyTableView];

    self.historyEmptyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.historyEmptyLabel.text = L(@"history_empty");
    self.historyEmptyLabel.textAlignment = NSTextAlignmentCenter;
    self.historyEmptyLabel.numberOfLines = 0;
    self.historyEmptyLabel.font = [UIFont systemFontOfSize:14];
    self.historyEmptyLabel.textColor = [Theme secondaryText];
    self.historyEmptyLabel.hidden = YES;
    [self.historyDrawerView addSubview:self.historyEmptyLabel];

    self.historyCloseXButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.historyCloseXButton setImage:DrawCrossIconImage(22, [Theme text]) forState:UIControlStateNormal];
    self.historyCloseXButton.tintColor = [Theme text];
    self.historyCloseXButton.backgroundColor = [Theme background];
    self.historyCloseXButton.layer.cornerRadius = 19;
    self.historyCloseXButton.layer.borderWidth = 1.0;
    self.historyCloseXButton.layer.borderColor = [Theme border].CGColor;
    [self.historyCloseXButton addTarget:self action:@selector(closeHistoryDrawer) forControlEvents:UIControlEventTouchUpInside];
    [self.historyDrawerView addSubview:self.historyCloseXButton];

    // Settings: a full-width row with a coloured badge and a word, so a new user can see it at a glance.
    self.historySettingsButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.historySettingsButton.backgroundColor = [Theme background];
    self.historySettingsButton.layer.cornerRadius = 16;
    self.historySettingsButton.layer.borderWidth = 1.0;
    self.historySettingsButton.layer.borderColor = [Theme border].CGColor;
    self.historySettingsButton.accessibilityLabel = L(@"settings");
    [self.historySettingsButton addTarget:self action:@selector(historySettingsTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.historySettingsButton addTarget:self action:@selector(historySettingsHighlight) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
    [self.historySettingsButton addTarget:self action:@selector(historySettingsUnhighlight) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
    [self.historyDrawerView addSubview:self.historySettingsButton];

    self.historySettingsBadge = [[UIView alloc] initWithFrame:CGRectZero];
    self.historySettingsBadge.userInteractionEnabled = NO;
    self.historySettingsBadge.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.16];
    self.historySettingsBadge.layer.cornerRadius = 10;
    [self.historySettingsButton addSubview:self.historySettingsBadge];

    self.historySettingsIcon = [[UIImageView alloc] initWithImage:DrawSettingsGearIconImage(20, [Theme accent])];
    self.historySettingsIcon.tintColor = [Theme accent];
    self.historySettingsIcon.contentMode = UIViewContentModeCenter;
    [self.historySettingsBadge addSubview:self.historySettingsIcon];

    self.historySettingsLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.historySettingsLabel.userInteractionEnabled = NO;
    self.historySettingsLabel.text = L(@"settings");
    self.historySettingsLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.historySettingsLabel.textColor = [Theme text];
    [self.historySettingsButton addSubview:self.historySettingsLabel];

    self.historySettingsChevron = [[UIImageView alloc] initWithImage:DrawChevronRightIconImage(18, [Theme secondaryText])];
    self.historySettingsChevron.userInteractionEnabled = NO;
    self.historySettingsChevron.tintColor = [Theme secondaryText];
    self.historySettingsChevron.contentMode = UIViewContentModeCenter;
    [self.historySettingsButton addSubview:self.historySettingsChevron];

    // A small dot on the cog when a new version is waiting (found by the update check).
    self.historyUpdateDot = [[UIView alloc] initWithFrame:CGRectZero];
    self.historyUpdateDot.userInteractionEnabled = NO;
    self.historyUpdateDot.backgroundColor = [Theme accent];
    self.historyUpdateDot.layer.cornerRadius = 6;
    self.historyUpdateDot.layer.borderWidth = 2;
    self.historyUpdateDot.layer.borderColor = [Theme background].CGColor;
    self.historyUpdateDot.hidden = ![UpdateManager shared].updateAvailable;
    [self.historySettingsBadge addSubview:self.historyUpdateDot];

    self.chatRightOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.chatRightOverlayButton.backgroundColor = [UIColor clearColor];
    self.chatRightOverlayButton.hidden = YES;
    self.chatBlurView = [[UIVisualEffectView alloc] initWithEffect:nil];   // the effect is set while the drawer opens
    self.chatBlurView.userInteractionEnabled = NO;
    self.chatBlurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.chatRightOverlayButton addSubview:self.chatBlurView];
    [self.chatRightOverlayButton addTarget:self action:@selector(closeHistoryDrawer) forControlEvents:UIControlEventTouchUpInside];
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(closeHistoryDrawer)];
    swipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.chatRightOverlayButton addGestureRecognizer:swipe];
    [self.chatStageView addSubview:self.chatRightOverlayButton];
}

- (void)refreshHistorySearchPlaceholder {
    self.historySearchField.attributedPlaceholder =
        [[NSAttributedString alloc] initWithString:L(@"search_chip_title")
                                        attributes:@{ NSForegroundColorAttributeName: [[Theme secondaryText] colorWithAlphaComponent:0.85],
                                                      NSFontAttributeName: [UIFont systemFontOfSize:15] }];
}

- (UIBlurEffect *)chatBlurEffect {
    return [UIBlurEffect effectWithStyle:[Theme darkMode] ? UIBlurEffectStyleDark : UIBlurEffectStyleLight];
}

- (void)updateStateChanged {
    self.historyUpdateDot.hidden = ![UpdateManager shared].updateAvailable;
}

- (void)historySettingsHighlight {
    self.historySettingsButton.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.12];
}

- (void)historySettingsUnhighlight {
    self.historySettingsButton.backgroundColor = [Theme background];
}

- (void)historySettingsTapped {
    [self closeHistoryDrawer];
    if (self.navigationController.topViewController != self || self.navigationController.transitionCoordinator) return;
    Class settingsVCClass = NSClassFromString(@"SettingsViewController");
    if (!settingsVCClass) return;
    UIViewController *settingsVC = [[settingsVCClass alloc] init];
    if (self.navigationController) {
        [self.navigationController pushViewController:settingsVC animated:YES];
    } else {
        [self presentViewController:settingsVC animated:YES completion:nil];
    }
}

- (void)historySearchChanged {
    [self reloadHistoryItems];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (void)reloadHistoryItems {
    NSArray *entries = [ConversationStore allEntries];
    self.historyAllItems = [entries isKindOfClass:[NSArray class]] ? entries : @[];
    NSString *q = [self.historySearchField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] ?: @"";
    if (q.length == 0) {
        self.historyFilteredItems = self.historyAllItems;
    } else {
        NSMutableArray *matches = [NSMutableArray array];
        for (NSDictionary *item in self.historyAllItems) {
            if (![item isKindOfClass:[NSDictionary class]]) continue;
            NSString *title = [item[@"title"] isKindOfClass:[NSString class]] ? item[@"title"] : @"";
            if ([title rangeOfString:q options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch].location != NSNotFound) {
                [matches addObject:item];
            }
        }
        self.historyFilteredItems = matches;
    }
    self.historyEmptyLabel.hidden = self.historyFilteredItems.count > 0;
    [self.historyTableView reloadData];
}

// Where the chat stage sits: pushed to the right by the drawer width when the drawer is open. Only the position changes, never the size.
- (CGPoint)chatStageCenterOpen:(BOOL)open {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    UIEdgeInsets safe = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safe = self.view.safeAreaInsets;
    CGFloat contentW = w - safe.left - safe.right;          // the stage keeps clear of the notch when the phone is on its side
    return CGPointMake(safe.left + contentW / 2.0 + (open ? [self historyDrawerWidth] - safe.left : 0), h / 2.0);
}

- (void)historyTapped {
    [self.view endEditing:YES];
    if ([self duoActive]) {
        // Two panes: the menu button folds the left pane away or brings it back.
        [AppSettings setDuoSidebarCollapsed:![AppSettings duoSidebarCollapsed]];
        [self layoutChanged];
        return;
    }
    if (self.historyDrawerOpen) {
        [self closeHistoryDrawer];
        return;
    }
    [self reloadHistoryItems];
    self.historyDrawerOpen = YES;
    self.historyDrawerAnimating = YES;
    self.historyDrawerView.hidden = NO;
    self.chatRightOverlayButton.hidden = NO;
    self.chatBlurView.frame = self.chatRightOverlayButton.bounds;
    self.chatBlurView.effect = nil;
    [self.view bringSubviewToFront:self.historyDrawerView];
    [self callJS:@"setDrawer" args:@[@YES]];

    CGFloat h = self.view.bounds.size.height;
    CGFloat drawerW = [self historyDrawerWidth];
    if (CGRectGetMaxX(self.historyDrawerView.frame) <= 0 || self.historyDrawerView.frame.size.width != drawerW) {
        self.historyDrawerView.frame = CGRectMake(-drawerW, 0, drawerW, h);
        [self layoutHistoryDrawerSubviews];
    }
    void (^openAnimations)(void) = ^{
        self.historyDrawerView.frame = CGRectMake(0, 0, drawerW, h);
        self.chatStageView.center = [self chatStageCenterOpen:YES];
        self.chatBlurView.effect = [self chatBlurEffect];   // the chat fades into a blur
    };
    void (^openDone)(BOOL) = ^(BOOL finished) { self.historyDrawerAnimating = NO; };
    if ([Material active]) {
        // Material 3: the drawer enters with the emphasized decelerate curve (400 ms)
        [Material animateEmphasizedDecelerate:MaterialDurationMedium4 animations:openAnimations completion:openDone];
    } else {
        [UIView animateWithDuration:0.36 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:0.1
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:openAnimations completion:openDone];
    }
}

- (void)closeHistoryDrawer {
    if (!self.historyDrawerOpen) return;
    [self.view endEditing:YES];
    self.historyDrawerOpen = NO;
    self.historyDrawerAnimating = YES;
    [self callJS:@"setDrawer" args:@[@NO]];

    CGFloat h = self.view.bounds.size.height;
    CGFloat drawerW = [self historyDrawerWidth];
    void (^closeAnimations)(void) = ^{
        self.historyDrawerView.frame = CGRectMake(-drawerW, 0, drawerW, h);
        self.chatStageView.center = [self chatStageCenterOpen:NO];
        self.chatBlurView.effect = nil;
    };
    void (^closeDone)(BOOL) = ^(BOOL finished) {
        if (self.historyDrawerOpen) return;   // opened again while closing
        self.historyDrawerAnimating = NO;
        self.historyDrawerView.hidden = YES;
        self.chatRightOverlayButton.hidden = YES;
    };
    if ([Material active]) {
        // Material 3: leaving is quicker than entering (emphasized accelerate, 250 ms)
        [Material animateEmphasizedAccelerate:MaterialDurationMedium1 animations:closeAnimations completion:closeDone];
    } else {
        [UIView animateWithDuration:0.30 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:closeAnimations completion:closeDone];
    }
}

- (UIViewController *)topPresentedController {
    UIViewController *top = self;
    while (top.presentedViewController) top = top.presentedViewController;
    return top;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.historyFilteredItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"HistoryHalfCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        cell.textLabel.numberOfLines = 1;
        UIView *selected = [[UIView alloc] init];
        selected.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.14];
        cell.selectedBackgroundView = selected;
    }
    NSDictionary *item = indexPath.row < (NSInteger)self.historyFilteredItems.count ? self.historyFilteredItems[(NSUInteger)indexPath.row] : nil;
    NSString *title = [item[@"title"] isKindOfClass:[NSString class]] && [item[@"title"] length] > 0 ? item[@"title"] : L(@"history_title");
    cell.textLabel.text = title;
    cell.textLabel.textColor = [Theme text];
    BOOL isOpen = self.historyPinned && [item[@"id"] isKindOfClass:[NSString class]] && [item[@"id"] isEqualToString:self.conversation[@"id"]];
    cell.backgroundColor = isOpen ? [[Theme accent] colorWithAlphaComponent:0.12] : [UIColor clearColor];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 48;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.row >= (NSInteger)self.historyFilteredItems.count) return;
    NSDictionary *item = self.historyFilteredItems[(NSUInteger)indexPath.row];
    NSString *cid = item[@"id"];
    [self closeHistoryDrawer];
    if ([cid isKindOfClass:[NSString class]] && cid.length > 0) {
        [self openConversationWithId:cid];
    }
}

- (void)layoutHistoryDrawerSubviews {
    CGFloat dw = self.historyDrawerView.bounds.size.width;
    CGFloat dh = self.historyDrawerView.bounds.size.height;
    if (dw < 10) return;
    CGFloat topPad = 12;
    CGFloat bottomPad = 12;
    if (@available(iOS 11.0, *)) {
        topPad += self.view.safeAreaInsets.top;
        bottomPad += self.view.safeAreaInsets.bottom;
    }
    BOOL keyboardUp = self.keyboardOverlap > 0 && self.historySearchField.isFirstResponder;

    CGFloat leftSafe = 0;
    if (@available(iOS 11.0, *)) leftSafe = self.view.safeAreaInsets.left;
    CGFloat rowH = 38;                       // search pill and close button share one row
    CGFloat closeSize = rowH;
    CGFloat sideGap = 12;
    CGFloat sideX = sideGap + leftSafe;      // left edge of the content, clear of the notch
    CGFloat sideW = dw - sideX - sideGap;
    CGFloat closeW = self.historyPinned ? 0 : closeSize + 8;   // no close button in the fixed pane
    self.historyCloseXButton.frame = CGRectMake(dw - sideGap - closeSize, topPad, closeSize, closeSize);
    self.historyCloseXButton.layer.cornerRadius = closeSize / 2.0;
    self.historySearchWrap.frame = CGRectMake(sideX, topPad, MAX(60, sideW - closeW), rowH);
    CGFloat sw = self.historySearchWrap.bounds.size.width;
    self.historySearchIcon.frame = CGRectMake(10, (rowH - 16) / 2.0, 16, 16);
    self.historySearchField.frame = CGRectMake(32, 0, MAX(20, sw - 32 - 8), rowH);

    CGFloat settingsH = 52;
    CGFloat settingsY = dh - bottomPad - settingsH;
    self.historySettingsButton.hidden = keyboardUp;
    self.historySettingsButton.frame = CGRectMake(sideX, settingsY, sideW, settingsH);
    CGFloat bw = self.historySettingsButton.bounds.size.width;
    self.historySettingsBadge.frame = CGRectMake(10, (settingsH - 32) / 2.0, 32, 32);
    self.historySettingsIcon.frame = self.historySettingsBadge.bounds;
    self.historyUpdateDot.frame = CGRectMake(32 - 10, -4, 12, 12);
    self.historySettingsChevron.frame = CGRectMake(bw - 12 - 20, (settingsH - 20) / 2.0, 20, 20);
    self.historySettingsLabel.frame = CGRectMake(10 + 32 + 10, 0, MAX(20, bw - (10 + 32 + 10) - 36), settingsH);

    CGFloat listTop = topPad + rowH + 10;
    CGFloat listBottom = keyboardUp ? (dh - self.keyboardOverlap - 8) : (settingsY - 10);
    self.historyTableView.frame = CGRectMake(0, listTop, dw, MAX(60, listBottom - listTop));
    self.historyEmptyLabel.frame = CGRectMake(16 + leftSafe, listTop + 24, dw - 32 - leftSafe, 44);
}

#pragma mark - Setup

- (void)setupWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    WKUserContentController *controller = [[WKUserContentController alloc] init];
    [controller addScriptMessageHandler:[[WeakScriptHandler alloc] initWithTarget:self] name:@"native"];
    config.userContentController = controller;

    self.wallpaperView = [[UIImageView alloc] init];
    self.wallpaperView.contentMode = UIViewContentModeScaleAspectFill;
    self.wallpaperView.clipsToBounds = YES;
    self.wallpaperView.userInteractionEnabled = NO;
    self.wallpaperView.hidden = YES;
    [self.chatStageView addSubview:self.wallpaperView];
    self.dimView = [[UIView alloc] init];
    self.dimView.userInteractionEnabled = NO;
    [self.wallpaperView addSubview:self.dimView];
    self.gradientView = [[MaterialGradientView alloc] init];
    self.gradientView.hidden = YES;
    [self.chatStageView addSubview:self.gradientView];

    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
    self.webView.navigationDelegate = self;
    self.webView.opaque = NO;
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.webView.scrollView.alwaysBounceVertical = YES;
    self.webView.scrollView.scrollEnabled = YES;
    self.webView.scrollView.bounces = YES;
    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.webView.alpha = 0.0;
    [self.chatStageView addSubview:self.webView];
    // An empty chat cannot be scrolled, so a tap on the page is how the keyboard is put away.
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(webViewTappedToDismissKeyboard)];
    dismissTap.cancelsTouchesInView = NO;
    dismissTap.delegate = self;
    [self.webView addGestureRecognizer:dismissTap];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [weakSelf revealWebView]; });
}

- (void)webViewTappedToDismissKeyboard {
    if (self.textView.isFirstResponder) [self.textView resignFirstResponder];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other {
    return YES;
}

- (void)unlockWebViewScrolling {
    if (!self.webView) return;
    // While the chat is empty the page is pinned (nothing to scroll, no rubber band), so the greeting card stays put.
    BOOL locked = self.chatIsEmpty;
    UIScrollView *sv = self.webView.scrollView;
    self.webView.userInteractionEnabled = YES;
    sv.userInteractionEnabled = YES;
    sv.scrollEnabled = !locked;
    sv.bounces = !locked;
    sv.alwaysBounceVertical = !locked;
    if (locked && sv.contentOffset.y != 0) sv.contentOffset = CGPointZero;
    if (self.webReady && !locked) {
        [self.webView evaluateJavaScript:
         @"document.documentElement.style.overflowY='auto';"
          "document.body.style.overflowY='auto';"
          "document.body.style.touchAction='pan-y';"
          "var c=document.getElementById('chat')||document.querySelector('.chat,.messages,#messages');"
          "if(c){c.style.overflowY='auto';c.style.webkitOverflowScrolling='touch';}"
                       completionHandler:nil];
    }
}

- (void)setupInputBar {
    self.inputBar = [[UIView alloc] init];
    self.inputBar.backgroundColor = [Theme background];
    [self.chatStageView addSubview:self.inputBar];

    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [Theme border];
    line.tag = 1001;
    [self.inputBar addSubview:line];

    self.attachStrip = [[UIScrollView alloc] init];
    self.attachStrip.showsHorizontalScrollIndicator = NO;
    self.attachStrip.alwaysBounceHorizontal = YES;
    self.attachStrip.hidden = YES;
    [self.inputBar addSubview:self.attachStrip];

    self.toolRow = [[UIView alloc] init];
    self.toolRow.backgroundColor = [UIColor clearColor];
    self.toolRow.hidden = YES;
    [self.inputBar addSubview:self.toolRow];

    self.reasoningButton = [self toolButtonWithTitle:@"Suy luận" action:@selector(reasoningTapped)];
    self.searchButton = [self toolButtonWithTitle:L(@"search_chip_title") action:@selector(searchTapped)];
    [self.searchButton setImage:[Theme iconSearch] forState:UIControlStateNormal];
    self.fastButton = [self toolButtonWithTitle:@"" action:@selector(fastTapped)];
    [self.fastButton setImage:[Theme iconBolt] forState:UIControlStateNormal];
    self.mentionButton = [self toolButtonWithTitle:@"@" action:@selector(mentionTapped)];
    [self.toolRow addSubview:self.reasoningButton];
    [self.toolRow addSubview:self.searchButton];
    [self.toolRow addSubview:self.fastButton];
    [self.toolRow addSubview:self.mentionButton];

    self.inputBox = [[UIView alloc] init];
    self.inputBox.backgroundColor = [Theme surface];
    self.inputBox.layer.cornerRadius = 23;   // set again in the layout from the real height
    self.inputBox.layer.borderWidth = 1;
    self.inputBox.layer.borderColor = [Theme border].CGColor;
    [self.inputBar addSubview:self.inputBox];

    self.attachButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.attachButton setImage:[Theme iconPlus] forState:UIControlStateNormal];
    self.attachButton.tintColor = [Theme secondaryText];
    [self.attachButton addTarget:self action:@selector(attachTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBox addSubview:self.attachButton];

    self.searchChipButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.searchChipButton.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    self.searchChipButton.layer.cornerRadius = 11;
    self.searchChipButton.clipsToBounds = YES;
    self.searchChipButton.backgroundColor = [UIColor colorWithRed:0.10 green:0.48 blue:0.34 alpha:0.18];
    [self.searchChipButton setTitleColor:[UIColor colorWithRed:0.22 green:0.82 blue:0.60 alpha:1.0] forState:UIControlStateNormal];
    [self.searchChipButton setTitle:[L(@"search_chip_title") stringByAppendingString:@"  "] forState:UIControlStateNormal];
    [self.searchChipButton setImage:[Theme iconSearch] forState:UIControlStateNormal];
    self.searchChipButton.tintColor = [UIColor colorWithRed:0.22 green:0.82 blue:0.60 alpha:1.0];
    self.searchChipButton.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
    [self.searchChipButton addTarget:self action:@selector(searchChipTapped) forControlEvents:UIControlEventTouchUpInside];
    self.searchChipButton.hidden = YES;
    [self.inputBox addSubview:self.searchChipButton];

    self.textView = [[UITextView alloc] init];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.font = [UIFont systemFontOfSize:17.0 * [AppSettings uiScale]];
    self.textView.textColor = [Theme text];
    self.textView.tintColor = [Theme accent];
    self.textView.textContainerInset = UIEdgeInsetsMake(9, 6, 9, 6);
    self.textView.delegate = self;
    [self.inputBox addSubview:self.textView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = L(@"chat_placeholder");
    self.placeholderLabel.font = [UIFont systemFontOfSize:17.0 * [AppSettings uiScale]];
    self.placeholderLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    [self.inputBox addSubview:self.placeholderLabel];

    self.sendButton = [ComposerSendButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.layer.cornerRadius = 18;
    self.sendButton.tintColor = [UIColor whiteColor];
    [self.sendButton addTarget:self action:@selector(sendTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBox addSubview:self.sendButton];

    self.micButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.micButton setImage:[Theme iconMicOfSize:22] forState:UIControlStateNormal];
    self.micButton.tintColor = [Theme text];
    self.micButton.accessibilityLabel = @"Mic";
    [self.micButton addTarget:self action:@selector(micTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBox addSubview:self.micButton];

    self.modelPill = [[ComposerModelPill alloc] init];
    self.modelPill.textColor = [Theme secondaryText];
    [self.modelPill addTarget:self action:@selector(modelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.inputBox addSubview:self.modelPill];

    self.glowView = [[ComposerGlowView alloc] init];
    [self.inputBox insertSubview:self.glowView atIndex:0];
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    UIEdgeInsets safe = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) safe = self.view.safeAreaInsets;
    CGFloat drawerW = [self historyDrawerWidth];
    BOOL pinned = [self duoPinned];
    BOOL wasPinned = self.historyPinned;
    self.historyPinned = pinned;

    if (pinned) {
        // Two panes: list on the left, chat on the right. The overlay drawer is not used.
        if (self.historyDrawerOpen || self.historyDrawerAnimating) {
            self.historyDrawerOpen = NO;
            self.historyDrawerAnimating = NO;
            [self callJS:@"setDrawer" args:@[@NO]];
        }
        CGFloat stageW = MAX(240, w - drawerW - safe.right);
        self.chatStageView.bounds = CGRectMake(0, 0, stageW, h);
        self.chatStageView.center = CGPointMake(drawerW + stageW / 2.0, h / 2.0);
        self.historyDrawerView.hidden = NO;
        self.historyDrawerView.frame = CGRectMake(0, 0, drawerW, h);
        self.historyCloseXButton.hidden = YES;
        self.chatRightOverlayButton.hidden = YES;
        if (!wasPinned) [self reloadHistoryItems];
        [self layoutHistoryDrawerSubviews];
        [self layoutChatStageSubviews];
        return;
    }
    self.historyCloseXButton.hidden = NO;

    // The stage keeps its full size at all times (so the greeting never re-wraps); the drawer only moves it sideways.
    self.chatStageView.bounds = CGRectMake(0, 0, MAX(200, w - safe.left - safe.right), h);
    if (!self.historyDrawerAnimating) {
        self.chatStageView.center = [self chatStageCenterOpen:self.historyDrawerOpen];
    }
    if (self.historyDrawerOpen) {
        if (!self.historyDrawerAnimating) {
            self.historyDrawerView.hidden = NO;
            self.historyDrawerView.frame = CGRectMake(0, 0, drawerW, h);
            self.chatRightOverlayButton.hidden = NO;
        } else {
            CGRect f = self.historyDrawerView.frame;
            if (fabs(f.size.height - h) > 0.5 || fabs(f.size.width - drawerW) > 0.5) {
                f.size = CGSizeMake(drawerW, h);
                self.historyDrawerView.frame = f;
            }
        }
        [self layoutHistoryDrawerSubviews];
    } else if (!self.historyDrawerAnimating) {
        self.historyDrawerView.hidden = YES;
        self.historyDrawerView.frame = CGRectMake(-drawerW, 0, drawerW, h);
        self.chatRightOverlayButton.hidden = YES;
    }
    [self layoutChatStageSubviews];
}

- (void)layoutChatStageSubviews {
    CGFloat width = self.chatStageView.bounds.size.width;
    CGFloat height = self.chatStageView.bounds.size.height;
    CGFloat safeBottom = 0;
    if (@available(iOS 11.0, *)) safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat bottomInset = self.keyboardOverlap > 0 ? self.keyboardOverlap : safeBottom;

    BOOL showStrip = self.pendingAttachments.count > 0 || self.importsInFlight > 0;
    CGFloat stripHeight = showStrip ? kStripHeight : 0;

    CGFloat scale = [AppSettings uiScale];
    CGFloat boxWidth = MAX(140, width - 24);
    BOOL searchActive = [AppSettings webSearchEnabled];
    BOOL material = [Material active];

    if (material) {
        // Material 3 message box: the text on top (it grows upward line by line), and below it a row with the attach
        // button, the model pill, the mic and the send button.
        CGFloat side = 10, buttonSize = 36, barHeight = 40, topPad = 6, bottomPad = 8;
        CGFloat textWidth = MAX(40, boxWidth - 2 * side);
        CGFloat fit = [self.textView sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
        CGFloat textHeight = MIN(MAX(fit, 38.0), kMaxInputHeight);
        self.textView.scrollEnabled = fit > kMaxInputHeight;
        CGFloat searchRowHeight = searchActive ? 27.0 : 0.0;
        CGFloat textY = topPad + searchRowHeight;
        CGFloat barY = textY + textHeight + 2;
        CGFloat boxHeight = barY + barHeight + bottomPad;
        CGFloat toolsY = 8 + stripHeight;
        CGFloat boxY = toolsY + kToolsRowHeight + 4;
        CGFloat barTotal = boxY + boxHeight + 8;
        self.inputBar.frame = CGRectMake(0, height - bottomInset - barTotal, width, barTotal);
        [self.inputBar viewWithTag:1001].frame = CGRectMake(0, 0, width, 1);
        self.attachStrip.hidden = !showStrip;
        self.attachStrip.frame = CGRectMake(0, 8, width, stripHeight);
        self.toolRow.frame = CGRectMake(12, toolsY, MAX(40, width - 24), kToolsRowHeight);
        self.inputBox.frame = CGRectMake(12, boxY, boxWidth, boxHeight);
        CGFloat radius = MIN(MR(22, 28), boxHeight / 2.0);
        self.inputBox.layer.cornerRadius = radius;
        self.glowView.cornerRadiusValue = radius;
        self.glowView.frame = self.inputBox.bounds;

        CGFloat rowY = barY + (barHeight - buttonSize) / 2;
        self.attachButton.frame = CGRectMake(side, rowY, buttonSize, buttonSize);
        self.attachButton.layer.cornerRadius = buttonSize / 2;
        self.attachButton.layer.borderWidth = 1;
        self.attachButton.layer.borderColor = [Theme border].CGColor;
        self.sendButton.transform = CGAffineTransformIdentity;
        self.sendButton.frame = CGRectMake(boxWidth - side - buttonSize, rowY, buttonSize, buttonSize);
        self.micButton.frame = CGRectMake(boxWidth - side - buttonSize - 6 - buttonSize, rowY, buttonSize, buttonSize);
        CGFloat pillX = side + buttonSize + 6;
        CGFloat pillMax = CGRectGetMinX(self.micButton.frame) - 6 - pillX;
        CGFloat pillWidth = [self.modelPill preferredWidthWithMax:pillMax];
        if (!self.modelPill.rolling) {
            self.modelPill.frame = CGRectMake(pillX, barY + (barHeight - 34) / 2, pillWidth, 34);
        } else {   // the name is rolling over: the pill resizes itself, only its place is kept
            CGRect f = self.modelPill.frame; f.origin = CGPointMake(pillX, barY + (barHeight - 34) / 2); self.modelPill.frame = f;
        }
        self.searchChipButton.hidden = !searchActive;
        if (searchActive) self.searchChipButton.frame = CGRectMake(side + 6, topPad + 3, 94, 22);
        self.textView.frame = CGRectMake(side, textY, textWidth, textHeight);
        CGFloat phHeight = MIN(textHeight, 22.0 * scale);
        self.placeholderLabel.frame = CGRectMake(side + 11, textY + (textHeight - phHeight) * 0.5, textWidth - 12, phHeight);
        self.modelPill.hidden = NO;
        [self updateToolButtons];
    } else {
        self.modelPill.hidden = YES;
        self.glowView.frame = self.inputBox.bounds;
        self.attachButton.layer.borderWidth = 0;
        CGFloat leftPad = 40;
        CGFloat rightPad = 84;
        CGFloat textWidth = MAX(40, boxWidth - leftPad - rightPad);
        CGFloat minInputHeight = 38.0;
        CGFloat fit = [self.textView sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height;
        CGFloat textHeight = MIN(MAX(fit, minInputHeight), kMaxInputHeight);
        self.textView.scrollEnabled = fit > kMaxInputHeight;

        CGFloat searchRowHeight = searchActive ? 27.0 : 0.0;
        CGFloat boxHeight = textHeight + 8 + searchRowHeight;
        CGFloat toolsY = 8 + stripHeight;
        CGFloat boxY = toolsY + kToolsRowHeight + 4;
        CGFloat barHeight = boxY + boxHeight + 8;
        self.inputBar.frame = CGRectMake(0, height - bottomInset - barHeight, width, barHeight);
        [self.inputBar viewWithTag:1001].frame = CGRectMake(0, 0, width, 1);

        self.attachStrip.hidden = !showStrip;
        self.attachStrip.frame = CGRectMake(0, 8, width, stripHeight);
        self.toolRow.frame = CGRectMake(12, toolsY, MAX(40, width - 24), kToolsRowHeight);
        CGFloat toolWidth = floor(MAX(40, width - 24) / 4.0);
        self.reasoningButton.frame = CGRectMake(0, 0, toolWidth, kToolsRowHeight);
        self.searchButton.frame = CGRectMake(toolWidth, 0, toolWidth, kToolsRowHeight);
        self.fastButton.frame = CGRectMake(toolWidth * 2, 0, toolWidth, kToolsRowHeight);
        self.mentionButton.frame = CGRectMake(toolWidth * 3, 0, toolWidth, kToolsRowHeight);
        self.inputBox.frame = CGRectMake(12, boxY, boxWidth, boxHeight);
        // A corner radius larger than half the height bends the ends of the pill into points: never go over it.
        self.inputBox.layer.cornerRadius = MIN(MR(22, 28), boxHeight / 2.0);

        CGFloat centerY = round((boxHeight - 36.0) * 0.5);
        self.attachButton.frame = CGRectMake(5, centerY, 36, 36);
        self.searchChipButton.hidden = !searchActive;
        if (searchActive) self.searchChipButton.frame = CGRectMake(46, 5, 94, 22);
        self.textView.frame = CGRectMake(leftPad, searchRowHeight + 4, textWidth, textHeight);
        CGFloat phHeight = MIN(textHeight, 22.0 * scale);
        self.placeholderLabel.frame = CGRectMake(leftPad + 11, searchRowHeight + 4 + (textHeight - phHeight) * 0.5, textWidth - 12, phHeight);
        self.sendButton.transform = CGAffineTransformIdentity;
        self.sendButton.frame = CGRectMake(boxWidth - 36 - 5, centerY, 36, 36);
        self.micButton.frame = CGRectMake(boxWidth - 36 - 5 - 40, centerY, 36, 36);
        [self updateToolButtons];

    }

    self.webView.frame = CGRectMake(0, 0, width, CGRectGetMinY(self.inputBar.frame));
    // Material 3: the message box floats (no panel and no line under it), so the wallpaper or the moving gradient runs
    // behind it down to the bottom edge; the page itself still stops above the box.
    CGRect backdrop = material ? CGRectMake(0, 0, width, height) : self.webView.frame;
    self.wallpaperView.frame = backdrop;
    self.gradientView.frame = backdrop;
    self.dimView.frame = self.wallpaperView.bounds;
    [self.inputBar viewWithTag:1001].hidden = material;
    self.inputBar.backgroundColor = material ? [UIColor clearColor] : [Theme background];
    CALayer *boxLayer = self.inputBox.layer;
    if (material) {
        boxLayer.shadowColor = [UIColor blackColor].CGColor;
        boxLayer.shadowOpacity = [Theme darkMode] ? 0.38 : 0.14;
        boxLayer.shadowRadius = 14;
        boxLayer.shadowOffset = CGSizeMake(0, 5);
        boxLayer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.inputBox.bounds cornerRadius:boxLayer.cornerRadius].CGPath;
    } else {
        boxLayer.shadowOpacity = 0;
        boxLayer.shadowPath = nil;
    }
    self.chatRightOverlayButton.frame = self.chatStageView.bounds;
    if (self.historyDrawerOpen) {
        [self.chatStageView bringSubviewToFront:self.chatRightOverlayButton];
    }
}

- (UIButton *)toolButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    [button setTitle:title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    button.layer.cornerRadius = 9;
    button.backgroundColor = [Theme surface];
    [button setTitleColor:[Theme secondaryText] forState:UIControlStateNormal];
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (BOOL)currentModelSupportsFastMode {
    AIProvider provider = [Provider forModelId:self.model];
    if (provider == AIProviderGemini) return YES;
    if (provider == AIProviderClaude) return YES;
    return NO;
}

- (void)updateToolButtons {
    UIColor *active = [Theme accent];
    [self.reasoningButton setTitleColor:active forState:UIControlStateNormal];
    [self.searchButton setTitleColor:[AppSettings webSearchEnabled] ? active : [Theme secondaryText] forState:UIControlStateNormal];
    BOOL supportsFast = [self currentModelSupportsFastMode];
    self.fastButton.enabled = supportsFast;
    self.fastButton.alpha = supportsFast ? 1.0 : 0.42;
    [self.fastButton setTitleColor:(supportsFast && [AppSettings fastModeEnabled]) ? active : [Theme secondaryText] forState:UIControlStateNormal];
    NSString *level = @[@"Thấp", @"Trung bình", @"Cao", @"Siêu cao", @"MAX ×8"][(NSUInteger)[AppSettings reasoningLevel]];
    [self.reasoningButton setTitle:level forState:UIControlStateNormal];
    [self.searchButton setTitle:L(@"search_chip_title") forState:UIControlStateNormal];
    self.searchButton.tintColor = [AppSettings webSearchEnabled] ? active : [Theme secondaryText];
    self.fastButton.tintColor = (supportsFast && [AppSettings fastModeEnabled]) ? active : [Theme secondaryText];
    self.searchChipButton.hidden = ![AppSettings webSearchEnabled];
}

- (void)reasoningTapped {
    [self.view endEditing:YES];

    UIViewController *panel = [[UIViewController alloc] init];
    panel.view.frame = self.view.bounds;
    panel.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.28];
    panel.modalPresentationStyle = UIModalPresentationOverFullScreen;
    panel.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

    CGFloat cardWidth = MIN(CGRectGetWidth(self.view.bounds) - 36.0, 420.0);
    CGFloat cardHeight = 370.0;
    UIView *card = [[UIView alloc] initWithFrame:CGRectMake((CGRectGetWidth(self.view.bounds) - cardWidth) / 2.0,
                                                            (CGRectGetHeight(self.view.bounds) - cardHeight) / 2.0,
                                                            cardWidth, cardHeight)];
    card.backgroundColor = [Theme surface];
    card.layer.cornerRadius = MR(25, 28);
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = [Theme border].CGColor;
    card.layer.shadowColor = [UIColor blackColor].CGColor;
    card.layer.shadowOpacity = 0.10;
    card.layer.shadowRadius = 18.0;
    card.layer.shadowOffset = CGSizeMake(0, 7);
    [panel.view addSubview:card];

    CGFloat contentWidth = cardWidth - 44.0;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(22, 22, contentWidth, 36)];
    title.text = @"Mức suy luận";
    title.font = [UIFont systemFontOfSize:25 weight:UIFontWeightBold];
    title.textColor = [Theme text];
    [card addSubview:title];

    self.reasoningValueLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 75, contentWidth, 34)];
    self.reasoningValueLabel.textAlignment = NSTextAlignmentCenter;
    self.reasoningValueLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightSemibold];
    self.reasoningValueLabel.textColor = [Theme text];
    [card addSubview:self.reasoningValueLabel];

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(28, 126, contentWidth - 12, 34)];
    slider.minimumValue = 0;
    slider.maximumValue = 4;
    slider.minimumTrackTintColor = [Theme accent];
    slider.maximumTrackTintColor = [Theme border];
    slider.value = [AppSettings reasoningLevel];
    [slider addTarget:self action:@selector(reasoningSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [card addSubview:slider];

    UILabel *low = [[UILabel alloc] initWithFrame:CGRectMake(22, 169, 100, 25)];
    low.text = @"Thấp";
    low.font = [UIFont systemFontOfSize:15];
    low.textColor = [Theme secondaryText];
    [card addSubview:low];
    UILabel *maximum = [[UILabel alloc] initWithFrame:CGRectMake(cardWidth - 122, 169, 100, 25)];
    maximum.text = @"MAX ×8";
    maximum.textAlignment = NSTextAlignmentRight;
    maximum.font = [UIFont systemFontOfSize:15];
    maximum.textColor = [Theme secondaryText];
    [card addSubview:maximum];

    self.reasoningFastButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.reasoningFastButton.frame = CGRectMake(20, 213, cardWidth - 40, 52);
    self.reasoningFastButton.backgroundColor = [Theme background];
    self.reasoningFastButton.layer.cornerRadius = 16;
    self.reasoningFastButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.reasoningFastButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    [self.reasoningFastButton setTitleColor:[Theme text] forState:UIControlStateNormal];
    [self.reasoningFastButton addTarget:self action:@selector(fastTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:self.reasoningFastButton];
    [self updateReasoningFastButton];

    self.reasoningFastHintLabel = [[UILabel alloc] initWithFrame:CGRectMake(22, 277, contentWidth, 42)];
    self.reasoningFastHintLabel.text = @"Khi kéo suy luận cao và bật Tăng tốc ×10, hệ thống ưu tiên tốc độ phản hồi tối đa (tốn token/chi phí hơn).";
    self.reasoningFastHintLabel.font = [UIFont systemFontOfSize:13];
    self.reasoningFastHintLabel.numberOfLines = 2;
    self.reasoningFastHintLabel.textColor = [Theme secondaryText];
    [card addSubview:self.reasoningFastHintLabel];

    UIButton *done = [UIButton buttonWithType:UIButtonTypeSystem];
    done.frame = CGRectMake(20, 329, cardWidth - 40, 30);
    [done setTitle:L(@"done") forState:UIControlStateNormal];
    done.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightMedium];
    [done addTarget:self action:@selector(dismissReasoningPanel) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:done];

    [self reasoningSliderChanged:slider];
    [self presentViewController:panel animated:YES completion:nil];
}

- (void)reasoningSliderChanged:(UISlider *)slider {
    NSInteger level = (NSInteger)lrintf(slider.value);
    [AppSettings setReasoningLevel:(AIReasoningLevel)level];
    NSArray *names = @[@"Thấp", @"Trung bình", @"Cao", @"Siêu cao", @"MAX ×8"];
    self.reasoningValueLabel.text = names[(NSUInteger)level];
    [self updateToolButtons];
    [self pushStrings];
}

- (void)updateReasoningFastButton {
    if (!self.reasoningFastButton) return;
    BOOL supported = [self currentModelSupportsFastMode];
    NSString *status = supported ? ([AppSettings fastModeEnabled] ? @"Đang bật (×10)" : @"Đang tắt") : @"Không hỗ trợ";
    [self.reasoningFastButton setTitle:[NSString stringWithFormat:@"%@     %@", L(@"fast_boost_title"), status] forState:UIControlStateNormal];
    [self.reasoningFastButton setImage:[Theme iconBolt] forState:UIControlStateNormal];
    self.reasoningFastButton.tintColor = [AppSettings fastModeEnabled] ? [Theme accent] : [Theme text];
    self.reasoningFastButton.imageEdgeInsets = UIEdgeInsetsMake(0, -6, 0, 6);
    self.reasoningFastButton.enabled = supported;
    self.reasoningFastButton.alpha = supported ? 1.0 : 0.55;
}

- (void)dismissReasoningPanel {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchTapped {
    [AppSettings setWebSearchEnabled:![AppSettings webSearchEnabled]];
    [self updateToolButtons];
    [self relayoutAnimated];
}

- (void)searchChipTapped {
    if (![AppSettings webSearchEnabled]) return;
    [AppSettings setWebSearchEnabled:NO];
    [self updateToolButtons];
    [self relayoutAnimated];
}

- (void)fastTapped {
    [AppSettings setFastModeEnabled:![AppSettings fastModeEnabled]];
    [self updateToolButtons];
    [self updateReasoningFastButton];
}

- (void)mentionTapped {
    [self.view endEditing:YES];
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:@"@ Công cụ" message:@"Chọn tác vụ hoặc tích hợp"];
    __weak typeof(self) weakSelf = self;
    NSArray *recent = self.conversation[@"messages"];
    NSString *lastReply = nil;
    for (NSInteger i = (NSInteger)recent.count - 1; i >= 0; i--) {
        NSDictionary *message = recent[(NSUInteger)i];
        if (![message[@"role"] isEqualToString:@"user"] && [message[@"text"] isKindOfClass:[NSString class]] && [message[@"text"] length] > 0) { lastReply = message[@"text"]; break; }
    }
    [sheet addAction:[ChoiceAction actionWithTitle:@"Tạo tệp TXT" style:UIAlertActionStyleDefault handler:^(id a) {
        NSString *source = lastReply.length > 0 ? lastReply : [weakSelf trimmedInput];
        if (source.length > 0) [weakSelf exportText:source asWord:NO];
        else [weakSelf showAlertMessage:@"Hãy nhập nội dung hoặc tạo câu trả lời trước khi xuất tệp TXT."];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:@"Tạo tệp DOCX" style:UIAlertActionStyleDefault handler:^(id a) {
        NSString *source = lastReply.length > 0 ? lastReply : [weakSelf trimmedInput];
        if (source.length > 0) [weakSelf exportText:source asWord:YES];
        else [weakSelf showAlertMessage:@"Hãy nhập nội dung hoặc tạo câu trả lời trước khi xuất tệp DOCX."];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:@"Chọn tệp để đính kèm…" style:UIAlertActionStyleDefault handler:^(id a) {
        [weakSelf attachTapped];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:@"/tạo ảnh" style:UIAlertActionStyleDefault handler:^(id a) {
        weakSelf.textView.text = @"/tạo ảnh ";
        [weakSelf textViewDidChange:weakSelf.textView];
        [weakSelf.textView becomeFirstResponder];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:[AppSettings webSearchEnabled] ? @"Tắt tìm kiếm web" : @"Bật tìm kiếm web" style:UIAlertActionStyleDefault handler:^(id a) { [weakSelf searchTapped]; }]];
    NSArray *external = @[@"Gmail", @"Google Calendar", @"Google Docs", @"Google Drive", @"Google Home", @"Google Keep", @"Google Photos", @"Google Sheets", @"Google Tasks"];
    for (NSString *name in external) {
        [sheet addAction:[ChoiceAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(id a) {
            [weakSelf showAlertMessage:[NSString stringWithFormat:@"%@ cần kết nối OAuth/API riêng. Phiên bản này chưa có thông tin xác thực để truy cập tài khoản.", name]];
        }]];
    }
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

- (void)updateDailyTokenPrompt {
    self.navigationItem.prompt = nil;
}

- (void)relayoutAnimated {
    [self.view setNeedsLayout];
    if ([Material active] && ![Material reduceMotion]) {   // the box grows upward line by line with the standard easing
        [Material animateStandard:0.25 animations:^{ [self.view layoutIfNeeded]; } completion:nil];
        return;
    }
    [UIView animateWithDuration:0.15 animations:^{ [self.view layoutIfNeeded]; }];
}

// Material 3: the text that was sent lifts off the box and fades while the box shrinks back.
- (void)flyTextUp:(NSString *)text {
    if (![Material active] || [Material reduceMotion] || text.length == 0 || self.view.window == nil) return;
    CGRect source = [self.chatStageView convertRect:self.textView.frame fromView:self.inputBox];
    UILabel *ghost = [[UILabel alloc] initWithFrame:CGRectInset(source, 6, 9)];
    ghost.text = text;
    ghost.font = self.textView.font;
    ghost.textColor = [Theme text];
    ghost.numberOfLines = 0;
    ghost.lineBreakMode = NSLineBreakByTruncatingTail;
    ghost.userInteractionEnabled = NO;
    [self.chatStageView addSubview:ghost];
    [UIView animateWithDuration:0.42 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        ghost.alpha = 0;
        ghost.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.97, 0.97), CGAffineTransformMakeTranslation(0, -22));
    } completion:^(BOOL finished) { [ghost removeFromSuperview]; }];
}

#pragma mark - Keyboard

- (void)keyboardWillChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect local = [self.view convertRect:endFrame fromView:nil];
    self.keyboardOverlap = MAX(0, CGRectGetMaxY(self.view.bounds) - local.origin.y);
    [self animateLayoutForKeyboardNote:note];
}

- (void)keyboardWillHide:(NSNotification *)note {
    self.keyboardOverlap = 0;
    [self animateLayoutForKeyboardNote:note];
}

- (void)animateLayoutForKeyboardNote:(NSNotification *)note {
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    NSUInteger curve = [note.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
    UIScrollView *sv = self.webView.scrollView;
    CGFloat oldHeight = self.webView.bounds.size.height;
    CGFloat oldOffset = sv.contentOffset.y;
    BOOL wasEmpty = self.chatIsEmpty;
    [self.view setNeedsLayout];
    [UIView animateWithDuration:duration
                          delay:0
                        options:(curve << 16) | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        [self.view layoutIfNeeded];
        // The page got shorter (keyboard up) or taller (keyboard down). Move the scroll position by the same amount so the
        // messages stay where they are relative to the input bar, instead of jumping to the end of the chat.
        if (!wasEmpty && !self.chatIsEmpty) {
            CGFloat newHeight = self.webView.bounds.size.height;
            CGFloat maxOffset = MAX(0, sv.contentSize.height - newHeight);
            CGFloat target = MIN(MAX(0, oldOffset + (oldHeight - newHeight)), maxOffset);
            if (fabs(target - sv.contentOffset.y) > 0.5) sv.contentOffset = CGPointMake(0, target);
        }
    } completion:nil];
}

#pragma mark - Alerts

- (void)showAlertMessage:(NSString *)message {
    [self showAlertMessage:message title:nil];
}

- (void)showAlertMessage:(NSString *)message title:(NSString *)title {
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:title message:message];
    [alert addAction:[ChoiceAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *top = self;
    while (top.presentedViewController) top = top.presentedViewController;
    [alert presentFromViewController:top];
}

#pragma mark - Web page

- (NSString *)resourceText:(NSString *)name ext:(NSString *)ext {
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext inDirectory:@"web"];
    if (!path) return @"";
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    return text ?: @"";
}

- (NSString *)scaleCSSRuleForScale:(CGFloat)scale {
    CGFloat clamped = MIN(1.4, MAX(0.7, scale));
    CGFloat bubbleMaxW = MIN(96.0, MAX(60.0, 80.0 * clamped));
    NSInteger step = [AppSettings fontWeightStep];
    NSString *weightRule = step == 0 ? @"" : [NSString stringWithFormat:
            @"body,.bubble,.btext,.markdown,p,li,td{font-weight:%ld;}strong,b,h1,h2,h3,h4,h5,h6,th{font-weight:%ld;}",
            (long)CMWebFontWeight(), (long)MIN(900, CMWebFontWeight() + 300)];
    return [weightRule stringByAppendingFormat:
            @":root{--uiscale:%.3f;}"
             "html{font-size:calc(16px * var(--uiscale)) !important;}"
             "body,#chat,.chat,.messages,#messages,.msg,.msg-row,.msg-wrap,.msg-text,.msg-content,.markdown,.markdown-body,pre,code,table,blockquote,p,li{font-size:calc(16px * var(--uiscale)) !important;line-height:1.45 !important;}"
             ".msg,.bubble,.message,.msg-bubble{max-width:%.1f%% !important;padding:calc(10px * var(--uiscale)) calc(14px * var(--uiscale)) !important;border-radius:calc(14px * var(--uiscale)) !important;}",
            clamped, bubbleMaxW];
}

- (NSString *)scaleCSSRuleForScaleMaterialAware:(CGFloat)scale {
    NSString *rule = [self scaleCSSRuleForScale:scale];
    if ([Theme materialDesign]) rule = [rule stringByReplacingOccurrencesOfString:@"border-radius:calc(14px" withString:@"border-radius:calc(22px"];
    return rule;
}

- (void)loadWebPage {
    self.webReady = NO;
    self.appliedWebScaleSig = nil;
    NSString *html = [self resourceText:@"index" ext:@"html"];
    html = [html stringByReplacingOccurrencesOfString:@"{{THEME}}" withString:[Theme webThemeCSS]];
    NSString *css = [[self resourceText:@"vendor" ext:@"css"] stringByAppendingFormat:@"\n%@", [self resourceText:@"chat" ext:@"css"]];
    NSString *js = [NSString stringWithFormat:@"%@\n%@\n%@", [self resourceText:@"vendor" ext:@"js"],
                                              [self resourceText:@"render" ext:@"js"], [self resourceText:@"chat" ext:@"js"]];

    NSString *logoPath = [[NSBundle mainBundle] pathForResource:@"logo_small" ofType:@"png"];
    NSData *logoData = logoPath ? [NSData dataWithContentsOfFile:logoPath] : nil;
    NSString *logoURI = logoData ? [@"data:image/png;base64," stringByAppendingString:[logoData base64EncodedStringWithOptions:0]] : @"";
    css = [css stringByReplacingOccurrencesOfString:@"{{LOGO}}" withString:logoURI];

    CGFloat scale = [AppSettings uiScale];
    css = [css stringByAppendingFormat:@"\n:root{--serif:%@;--ui-font:%@;}", [self serifCSSValue], CMWebFontStack()];
    css = [css stringByAppendingFormat:@"\n%@", CMRoundedFontFaceCSS()];
    css = [css stringByAppendingFormat:@"\n%@", [self scaleCSSRuleForScaleMaterialAware:scale]];
    html = [html stringByReplacingOccurrencesOfString:@"{{CSS}}" withString:css];
    html = [html stringByReplacingOccurrencesOfString:@"{{JS}}" withString:js];
    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)callJS:(NSString *)function args:(NSArray *)args {
    if (!self.webReady) return;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:args options:0 error:nil];
    } @catch (NSException *exception) {   // dataWithJSONObject: throws (not returns an error) on invalid values
        [DiagnosticLog log:@"callJS %@ skipped: %@", function, exception.reason];
        return;
    }
    if (!data) return;
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    json = [json stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
    json = [json stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
    NSString *script = [NSString stringWithFormat:@"ChatUI.%@.apply(null,%@);", function, json];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

#pragma mark - Stream Delta Batching

- (void)startDeltaFlushTimer {
    if (self.deltaFlushTimer) return;
    self.pendingJSDelta = [NSMutableString string];
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 32 * NSEC_PER_MSEC), 32 * NSEC_PER_MSEC, 8 * NSEC_PER_MSEC);
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(timer, ^{
        [weakSelf flushPendingJSDelta];
    });
    self.deltaFlushTimer = timer;
    dispatch_resume(timer);
}

- (void)flushPendingJSDelta {
    if (self.pendingJSDelta.length == 0) return;
    NSString *chunk = [self.pendingJSDelta copy];
    [self.pendingJSDelta setString:@""];
    [self callJS:@"delta" args:@[chunk]];
}

- (void)stopDeltaFlushTimer {
    [self flushPendingJSDelta];
    if (self.deltaFlushTimer) {
        dispatch_source_cancel(self.deltaFlushTimer);
        self.deltaFlushTimer = nil;
    }
    self.pendingJSDelta = nil;
}

#pragma mark - Skin

- (void)applyTheme {
    self.view.backgroundColor = [Theme background];
    self.chatStageView.backgroundColor = [Theme background];
    if (self.historyDrawerView) {
        self.historyDrawerView.backgroundColor = [Theme surface];
        self.historyDrawerView.layer.borderColor = [Theme border].CGColor;
        self.historySearchWrap.backgroundColor = [Theme background];
        self.historySearchWrap.layer.borderColor = [Theme border].CGColor;
        self.historySearchIcon.tintColor = [Theme secondaryText];
        self.historySearchField.textColor = [Theme text];
        self.historySearchField.tintColor = [Theme accent];
        self.historySearchField.keyboardAppearance = [Theme keyboardAppearance];
        [self refreshHistorySearchPlaceholder];
        self.historyTableView.separatorColor = [Theme border];
        self.historyEmptyLabel.textColor = [Theme secondaryText];
        self.historyCloseXButton.tintColor = [Theme text];
        self.historyCloseXButton.backgroundColor = [Theme background];
        self.historyCloseXButton.layer.borderColor = [Theme border].CGColor;
        self.historySettingsButton.backgroundColor = [Theme background];
        self.historySettingsButton.layer.borderColor = [Theme border].CGColor;
        self.historySettingsBadge.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.16];
        self.historySettingsIcon.tintColor = [Theme accent];
        self.historySettingsLabel.textColor = [Theme text];
        self.historySettingsChevron.tintColor = [Theme secondaryText];
        self.historyUpdateDot.backgroundColor = [Theme accent];
        self.historyUpdateDot.layer.borderColor = [Theme background].CGColor;
        if (self.historyDrawerOpen) self.chatBlurView.effect = [self chatBlurEffect];
        [self.historyTableView reloadData];
    }

    UIImage *wallpaper = [Theme wallpaperImage];
    self.wallpaperView.image = wallpaper;
    self.wallpaperView.hidden = (wallpaper == nil);
    self.dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:[Theme wallpaperDimAlpha]];
    BOOL movingGradient = [Theme gradientWallpaperActive];
    self.gradientView.hidden = !movingGradient;
    if (movingGradient) [self.gradientView refreshColors];
    self.webView.scrollView.indicatorStyle = [Theme darkMode] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;

    [self.modelButton setTitleColor:[Theme text] forState:UIControlStateNormal];
    [self updateModelTitle];
    self.inputBar.backgroundColor = [Material active] ? [UIColor clearColor] : [Theme background];
    [self.inputBar viewWithTag:1001].backgroundColor = [Theme border];
    self.inputBox.backgroundColor = [Theme surface];
    self.inputBox.layer.borderColor = [Theme border].CGColor;
    self.inputBox.layer.cornerRadius = MIN(MR(22, 28), MAX(1, self.inputBox.bounds.size.height / 2.0));   // Material 3 shape; changes at once with the design switch
    self.attachButton.tintColor = [Theme secondaryText];
    self.modelPill.textColor = [Theme secondaryText];
    [self.glowView refreshColors];
    if (![Material active]) [self.glowView setActive:NO animated:NO];
    else if (self.streaming) [self.glowView setActive:YES animated:NO];
    self.textView.textColor = [Theme text];
    self.textView.tintColor = [Theme accent];
    UIKeyboardAppearance appearance = [Theme keyboardAppearance];
    if (self.textView.keyboardAppearance != appearance) {
        self.textView.keyboardAppearance = appearance;
        if (self.textView.isFirstResponder) [self.textView reloadInputViews];
    }
    self.placeholderLabel.textColor = [[Theme secondaryText] colorWithAlphaComponent:0.75];
    for (UIButton *button in @[self.reasoningButton, self.searchButton, self.fastButton, self.mentionButton]) {
        button.backgroundColor = [Theme surface];
    }
    [self updateToolButtons];
    [self updateSendButton];
    if (self.pendingAttachments.count > 0 || self.importsInFlight > 0) [self refreshAttachStrip];

    [self setNeedsStatusBarAppearanceUpdate];
     [self pushThemeToWeb];
     [self applyUIScaleToNativeAndWeb];   // design (Material radii) and font follow the theme at once
    [self.view setNeedsLayout];
}

- (void)pushThemeToWeb {
    if (!self.webReady) return;
    NSData *data = [NSJSONSerialization dataWithJSONObject:@[[Theme webThemeCSS]] options:0 error:nil];
    if (!data) return;
    NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *script = [NSString stringWithFormat:@"(function(){var s=document.getElementById('themevars');if(s){s.textContent=(%@)[0];}})();", json];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

#pragma mark - Greeting

- (NSString *)greetingTitle {
    NSInteger hour = [[NSCalendar currentCalendar] component:NSCalendarUnitHour fromDate:[NSDate date]];
    if (hour >= 23 || hour < 3) return L(@"greeting_night");
    if (hour < 11) return L(@"greeting_morning");
    if (hour < 14) return L(@"greeting_noon");
    if (hour < 18) return L(@"greeting_afternoon");
    return L(@"greeting_evening");
}

- (NSString *)greetingSubtitle {
    switch (self.greetingIndex) {
        case 0:  return L(@"empty_sub_1");
        case 1:  return L(@"empty_sub_2");
        case 2:  return L(@"empty_sub_3");
        case 3:  return L(@"empty_sub_4");
        case 4:  return L(@"empty_sub_5");
        default: return L(@"empty_sub_6");
    }
}

- (void)rerollGreeting {
    NSUInteger previous = self.greetingIndex;
    NSUInteger next = previous;
    while (next == previous) next = arc4random_uniform((uint32_t)kGreetingCount);
    self.greetingIndex = next;
}

- (void)refreshGreetingIfEmpty {
    if (!self.webReady || [self.conversation[@"messages"] count] > 0) return;
    NSString *current = [NSString stringWithFormat:@"%@|%@", [self greetingTitle], [self greetingSubtitle]];
    if ([current isEqualToString:self.shownGreeting]) return;
    [self pushStrings];
    [self callJS:@"clear" args:@[]];
}

- (void)appWillEnterForeground:(NSNotification *)note {
    [self refreshGreetingIfEmpty];
}

- (void)pushStrings {
    self.shownGreeting = [NSString stringWithFormat:@"%@|%@", [self greetingTitle], [self greetingSubtitle]];
    [self callJS:@"setStrings" args:@[@{ @"emptyTitle": [self greetingTitle],
                                          @"emptySub": [self greetingSubtitle],
                                          @"copy": L(@"copy"),
                                          @"copyCode": L(@"copy"),
                                          @"copied": L(@"copied"),
                                          @"regenerate": L(@"regenerate"),
                                          @"retry": L(@"retry"),
                                          @"edit": L(@"edit"),
                                          @"save": L(@"save_reply"),
                                          @"share": L(@"share_image"),
                                          @"thinking": ([AppSettings reasoningLevel] >= AIReasoningLevelHigh) ? @"Đang suy luận sâu…" : @"Đang xử lý…",
                                          @"thoughtFor": L(@"thought_for"),
                                          @"thoughtShort": L(@"thought_short") }]];
}

- (NSArray *)webAttachmentsFrom:(NSArray *)attachments conversation:(NSString *)cid {
    NSMutableArray *out = [NSMutableArray array];
    if (![attachments isKindOfClass:[NSArray class]]) return out;
    for (NSDictionary *att in attachments) {
        if (![att isKindOfClass:[NSDictionary class]]) continue;
        NSString *kind = [att[@"kind"] isKindOfClass:[NSString class]] ? att[@"kind"] : @"text";
        NSString *name = [att[@"name"] isKindOfClass:[NSString class]] ? att[@"name"] : @"";
        NSString *thumb = [kind isEqualToString:@"image"] ? [AttachmentStore thumbnailDataURIForAttachment:att conversation:cid] : @"";
        NSString *attachmentId = [att[@"id"] isKindOfClass:[NSString class]] ? att[@"id"] : @"";
        [out addObject:@{ @"id": attachmentId, @"kind": kind, @"name": name, @"thumb": thumb }];
    }
    return out;
}

- (void)renderConversation {
    NSString *cid = self.conversation[@"id"];
    NSArray *messages = self.conversation[@"messages"];
    NSMutableArray *list = [NSMutableArray array];
    for (NSUInteger messageIndex = 0; messageIndex < messages.count; messageIndex++) {
        NSDictionary *message = messages[messageIndex];
        NSString *role = message[@"role"];
        NSString *text = message[@"text"];
        if (![role isKindOfClass:[NSString class]] || ![text isKindOfClass:[NSString class]]) continue;
        NSMutableDictionary *item = [@{ @"role": role, @"text": text, @"index": @(messageIndex) } mutableCopy];
        NSArray *attachments = message[@"attachments"];
        if ([attachments isKindOfClass:[NSArray class]] && attachments.count > 0) {
            item[@"attachments"] = [self webAttachmentsFrom:attachments conversation:cid];
        }
        [list addObject:item];
    }
    [self callJS:@"load" args:@[list]];
    [self unlockWebViewScrolling];
}

// The page stays invisible until it has drawn once, so the greeting fades in instead of popping in half-built.
- (void)revealWebView {
    if (self.webView.alpha >= 1.0) return;
    if ([Material active]) { [Material animateEffects:MaterialMotionSlow animations:^{ self.webView.alpha = 1.0; } completion:nil]; return; }
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.webView.alpha = 1.0;
    } completion:nil];
}

- (void)handleScriptMessage:(WKScriptMessage *)message {
    if (![message.body isKindOfClass:[NSDictionary class]]) return;
    NSDictionary *body = message.body;
    NSString *type = body[@"type"];
    if ([type isEqualToString:@"ready"]) {
        [DiagnosticLog log:@"chat page ready"];
        self.webReady = YES;
        [self revealWebView];
        [self pushThemeToWeb];
        [self applyUIScaleToNativeAndWeb];
        [self pushStrings];
        [self renderConversation];
        if (self.streaming) {
            // iOS restarted the page while a reply was being written: draw the text received so far and carry on.
            [self callJS:@"begin" args:@[]];
            NSString *soFar = self.longReplyAccumulator.length > 0
                ? [self.longReplyAccumulator stringByAppendingString:(self.streamBuffer ?: @"")]
                : (self.streamBuffer ?: @"");
            [self.pendingJSDelta setString:@""];   // already part of soFar
            if (soFar.length > 0) [self callJS:@"delta" args:@[soFar]];
        }
        [self updateSendButton];
        [self unlockWebViewScrolling];
    } else if ([type isEqualToString:@"empty"]) {
        self.chatIsEmpty = [body[@"value"] boolValue];
        if (self.chatIsEmpty) [self resetWebScrollToTop];
        [self unlockWebViewScrolling];
        if (self.chatIsEmpty) [self reassertEmptyLockSoon];
    } else if ([type isEqualToString:@"copy"]) {
        NSString *text = body[@"text"];
        if ([text isKindOfClass:[NSString class]]) [UIPasteboard generalPasteboard].string = text;
    } else if ([type isEqualToString:@"regenerate"]) {
        [self regenerate];
    } else if ([type isEqualToString:@"edit"]) {
        [self editMessageAtIndex:[body[@"index"] integerValue]];
    } else if ([type isEqualToString:@"save"]) {
        NSString *text = body[@"text"];
        if ([text isKindOfClass:[NSString class]] && text.length > 0) [self offerExportForText:text];
    } else if ([type isEqualToString:@"image"]) {
        [self showImageForAttachmentId:body[@"id"]];
    } else if ([type isEqualToString:@"shareImage"]) {
        [self shareImageForAttachmentId:body[@"id"]];
    } else if ([type isEqualToString:@"jserror"]) {
        [DiagnosticLog log:@"page script error: %@ (line %@)", ClippedForLog(body[@"message"]), body[@"line"] ?: @"?"];
    }
}

- (void)shareImageForAttachmentId:(NSString *)attachmentId {
    if (![attachmentId isKindOfClass:[NSString class]] || attachmentId.length == 0) return;
    NSString *cid = self.conversation[@"id"];
    for (NSDictionary *message in self.conversation[@"messages"]) {
        NSArray *attachments = [message[@"attachments"] isKindOfClass:[NSArray class]] ? message[@"attachments"] : @[];
        for (NSDictionary *attachment in attachments) {
            if (![attachment[@"id"] isEqualToString:attachmentId] || ![attachment[@"kind"] isEqualToString:@"image"]) continue;
            NSString *path = [AttachmentStore pathForFile:attachment[@"file"] conversation:cid];
            if (!path) return;
            UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[[NSURL fileURLWithPath:path]] applicationActivities:nil];
            activity.popoverPresentationController.sourceView = self.view;
            activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
            [self presentViewController:activity animated:YES completion:nil];
            return;
        }
    }
}

- (void)offerExportForText:(NSString *)text {
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"export_file") message:nil];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"export_txt") style:UIAlertActionStyleDefault handler:^(id action) {
        [weakSelf exportText:text asWord:NO];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"export_docx") style:UIAlertActionStyleDefault handler:^(id action) {
        [weakSelf exportText:text asWord:YES];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

- (void)exportText:(NSString *)text asWord:(BOOL)asWord {
    NSError *error = nil;
    NSURL *url = asWord ? [OfficeExport writeWordFile:text error:&error] : [OfficeExport writeTextFile:text error:&error];
    if (!url) {
        [self showAlertMessage:L(@"export_failed")];
        [DiagnosticLog log:@"reply export failed: %@", error.localizedDescription ?: @"unknown"];
        return;
    }
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    activity.popoverPresentationController.sourceView = self.view;
    activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    [self presentViewController:activity animated:YES completion:nil];
}

- (void)showImageForAttachmentId:(NSString *)attachmentId {
    if (![attachmentId isKindOfClass:[NSString class]] || attachmentId.length == 0) return;
    NSString *cid = self.conversation[@"id"];
    for (NSDictionary *message in self.conversation[@"messages"]) {
        NSArray *atts = message[@"attachments"];
        if (![atts isKindOfClass:[NSArray class]]) continue;
        for (NSDictionary *att in atts) {
            if (![att[@"id"] isEqualToString:attachmentId] || ![att[@"kind"] isEqualToString:@"image"]) continue;
            NSString *path = [AttachmentStore pathForFile:att[@"file"] conversation:cid];
            if (!path) return;
            [self.view endEditing:YES];
            [self presentViewController:[[ImageViewerViewController alloc] initWithImagePath:path] animated:YES completion:nil];
            return;
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSURL *url = navigationAction.request.URL;
        if (url) [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self unlockWebViewScrolling];
    [self applyUIScaleToNativeAndWeb];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.lastWebError = error.localizedDescription;
    [DiagnosticLog log:@"web view failed: %@ [%@ %ld]", error.localizedDescription, error.domain, (long)error.code];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    self.lastWebError = error.localizedDescription;
    [DiagnosticLog log:@"web view failed to start: %@ [%@ %ld]", error.localizedDescription, error.domain, (long)error.code];
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    [DiagnosticLog log:@"web content process was terminated by iOS (probably memory): reloading the page"];
    self.shownGreeting = nil;
    [self loadWebPage];
}

#pragma mark - Models

- (void)updateModelTitle {
    NSArray<NSString *> *parts = self.model.length > 0 ? [ModelStore titlePartsForModelId:self.model] : @[ L(@"choose_model"), @"" ];
    NSString *main = parts.count > 0 ? parts[0] : self.model;
    NSString *detail = parts.count > 1 ? parts[1] : @"";
    NSMutableAttributedString *title = [[NSMutableAttributedString alloc] init];
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:main attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold], NSForegroundColorAttributeName: [Theme text] }]];
    if (detail.length > 0) {
        [title appendAttributedString:[[NSAttributedString alloc] initWithString:[@" " stringByAppendingString:detail] attributes:@{
            NSFontAttributeName: [UIFont systemFontOfSize:15 weight:UIFontWeightRegular], NSForegroundColorAttributeName: [Theme secondaryText] }]];
    }
    [title appendAttributedString:[[NSAttributedString alloc] initWithString:@" \u25BE" attributes:@{
        NSFontAttributeName: [UIFont systemFontOfSize:11 weight:UIFontWeightRegular], NSForegroundColorAttributeName: [Theme secondaryText] }]];
    [self.modelButton setAttributedTitle:title forState:UIControlStateNormal];
    // Material 3: the model lives in the message box (its name rolls over when it changes), not in the bar above
    BOOL material = [Material active];
    self.modelButton.hidden = material;
    [self.modelPill setTitle:main animated:material && self.view.window != nil];
    self.modelPill.accessibilityLabel = [NSString stringWithFormat:@"%@ %@", L(@"choose_model"), main];
    if (material) [self.view setNeedsLayout];

    CGFloat available = self.view.bounds.size.width > 0 ? self.view.bounds.size.width : [UIScreen mainScreen].bounds.size.width;
    CGFloat maxWidth = MAX(120, available - 44 - 44 - 40);
    CGSize size = [self.modelButton sizeThatFits:CGSizeMake(maxWidth, 44)];
    CGFloat width = MIN(ceil(size.width) + 8, maxWidth);
    if (!self.modelWidthConstraint) {
        self.modelWidthConstraint = [self.modelButton.widthAnchor constraintEqualToConstant:width];
        self.modelWidthConstraint.active = YES;
        [self.modelButton.heightAnchor constraintEqualToConstant:44].active = YES;
    } else {
        self.modelWidthConstraint.constant = width;
    }
}

- (void)ensureModelMatchesKeys {
    BOOL usable = self.model.length > 0 && [KeyStore hasKeyForProvider:[Provider forModelId:self.model]];
    if (usable) return;
    NSString *fallback = [ModelStore defaultModelIdAcrossProviders];
    self.model = fallback;
    if (fallback.length > 0) [ModelStore setSelectedModelId:fallback];
    self.conversation[@"model"] = fallback ?: @"";
    [self updateModelTitle];
}

- (void)refreshModels {
    for (NSNumber *value in [Provider all]) {
        AIProvider provider = (AIProvider)value.integerValue;
        NSString *key = [KeyStore loadKeyForProvider:provider];
        if (key.length == 0) continue;
        __weak typeof(self) weakSelf = self;
        GeminiModelsCompletion completion = ^(NSArray *models, GeminiCheckResult result) {
            ChatViewController *me = weakSelf;
            if (!me) return;
            if (result != GeminiCheckOK || models.count == 0) {
                [DiagnosticLog log:@"model list: %@ failed (check result %ld, %lu models)", [Provider nameFor:provider], (long)result, (unsigned long)models.count];
                return;
            }
            [ModelStore saveModels:models forProvider:provider];
            if (provider == AIProviderGemini) {
                [KeyTier detectGeminiTierIfNeededWithModels:models completion:^(KeyTierLevel tier) {
                    [weakSelf geminiTierDetected:tier];
                }];
            }
            [me ensureModelMatchesKeys];
        };
        if (provider == AIProviderClaude) [ClaudeClient fetchModelsWithKey:key completion:completion];
        else [GeminiClient fetchModelsWithKey:key completion:completion];
    }
}

- (void)modelTapped {
    [self presentModelPopupIntro:NO];
}

- (void)presentModelPopupIntro:(BOOL)intro {
    [self.view endEditing:YES];
    BOOL visible = self.view.window != nil && self.navigationController.topViewController == self && self.presentedViewController == nil;
    if (!visible) {
        self.pendingModelPopup = YES;
        self.pendingModelPopupIntro = intro || self.pendingModelPopupIntro;
        return;
    }
    ModelPopupViewController *popup = [[ModelPopupViewController alloc] initWithSelectedModel:self.model intro:intro];
    __weak typeof(self) weakSelf = self;
    popup.onSelect = ^(NSString *modelId) { [weakSelf selectModelId:modelId]; };
    popup.onMore = ^{ [weakSelf openFullModelPicker]; };
    [self presentViewController:popup animated:YES completion:nil];
}

- (void)selectModelId:(NSString *)modelId {
    self.model = modelId;
    [ModelStore setSelectedModelId:modelId];
    self.conversation[@"model"] = modelId;
    if ([self.conversation[@"messages"] count] > 0) [ConversationStore saveConversation:self.conversation];
    [self refreshPinnedSidebar];
    [self updateModelTitle];
    [self updateToolButtons];
}

- (void)openFullModelPicker {
    ModelPickerViewController *picker = [[ModelPickerViewController alloc] initWithSelectedModel:self.model];
    __weak typeof(self) weakSelf = self;
    picker.onSelect = ^(NSString *modelId) { [weakSelf selectModelId:modelId]; };
    picker.chatPrompt = [self.conversation[@"system"] isKindOfClass:[NSString class]] ? self.conversation[@"system"] : @"";
    picker.onChatPromptChange = ^(NSString *text) {
        ChatViewController *me = weakSelf;
        if (!me) return;
        me.conversation[@"system"] = text ?: @"";
        if ([me.conversation[@"messages"] count] > 0) [ConversationStore saveConversation:me.conversation];
    };
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)geminiTierDetected:(KeyTierLevel)tier {
    if (tier == KeyTierUnknown) return;
    if ([ModelStore selectionIsAutomatic] || ![ModelStore isModelAvailableNow:self.model]) {
        NSString *pick = [ModelStore defaultModelIdAcrossProviders];
        if (pick.length > 0) {
            self.model = pick;
            [ModelStore setAutomaticSelectedModelId:pick];
            self.conversation[@"model"] = pick;
            [self updateModelTitle];
        }
    }
    if ([KeyTier consumePopupPending]) [self presentModelPopupIntro:YES];
}

#pragma mark - Navigation buttons

- (void)newChatTapped {
    [self.view endEditing:YES];
    [self closeHistoryDrawer];
    if ([self topPresentedController] != self) return;   // a pop-up is already on screen
    BOOL hasContent = [self.conversation[@"messages"] count] > 0 || self.pendingAttachments.count > 0;
    if (!hasContent) {   // already a fresh chat: nothing to confirm
        [self startNewChat];
        return;
    }
    ConfirmPopupViewController *popup = [[ConfirmPopupViewController alloc] initWithTitle:L(@"new_chat_title")
                                                                                   message:L(@"new_chat_msg")
                                                                              confirmTitle:L(@"new_chat_confirm")];
    __weak typeof(self) weakSelf = self;
    popup.onConfirm = ^{ [weakSelf startNewChat]; };
    [self presentViewController:popup animated:YES completion:nil];
}

- (void)historyCleared:(NSNotification *)note {
    [self reloadHistoryItems];
    [self startNewChat];
}

- (void)conversationDeleted:(NSNotification *)note {
    [self reloadHistoryItems];
    NSString *cid = note.userInfo[@"id"];
    if ([cid isEqualToString:self.conversation[@"id"]]) [self startNewChat];
}

- (void)discardPendingAttachments {
    NSString *cid = self.conversation[@"id"];
    for (NSDictionary *att in self.pendingAttachments) [AttachmentStore deleteAttachment:att conversation:cid];
    [self.pendingAttachments removeAllObjects];
    [self refreshAttachStrip];
}

- (void)startNewChat {
    [self abandonStream];
    [self discardPendingAttachments];
    self.conversation = [ConversationStore newConversationWithModel:self.model];
    [self rerollGreeting];
    [self pushStrings];
    [self resetWebScrollToTop];   // while the old (tall) chat is still there, so no stale offset survives the page shrinking
    self.chatIsEmpty = YES;
    [self callJS:@"clear" args:@[]];
    [self updateSendButton];
    [self unlockWebViewScrolling];
    [self reassertEmptyLockSoon];
    [self refreshPinnedSidebar];
}

// The page scroll position is native state too (UIScrollView). If it is left at, say, 3000 pt when the page becomes one
// screen tall, the greeting is drawn half cut off until the user pulls the page. Always bring it back to 0 explicitly.
- (void)resetWebScrollToTop {
    UIScrollView *sv = self.webView.scrollView;
    if (sv.contentOffset.y != 0 || sv.contentOffset.x != 0) [sv setContentOffset:CGPointZero animated:NO];
    [self callJS:@"scrollTop" args:@[]];
}

- (void)reassertEmptyLockSoon {
    __weak typeof(self) weakSelf = self;
    for (NSNumber *delay in @[@0.05, @0.2, @0.5]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            ChatViewController *me = weakSelf;
            if (!me || !me.chatIsEmpty) return;
            [me unlockWebViewScrolling];
        });
    }
}

- (void)openConversationWithId:(NSString *)cid {
    NSMutableDictionary *loaded = [ConversationStore loadConversationWithId:cid];
    if (!loaded) return;
    [self abandonStream];
    [self discardPendingAttachments];
    self.conversation = loaded;
    NSString *savedModel = loaded[@"model"];
    if ([savedModel isKindOfClass:[NSString class]] && savedModel.length > 0) {
        self.model = savedModel;
        [ModelStore setSelectedModelId:savedModel];
    }
    [self ensureModelMatchesKeys];
    [self updateModelTitle];
    [self renderConversation];
    [self updateSendButton];
    [self unlockWebViewScrolling];
    [self refreshPinnedSidebar];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(80 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self unlockWebViewScrolling];
    });
}

#pragma mark - Input

- (void)textViewDidChange:(UITextView *)textView {
    if (self.voiceRecording && !self.applyingDictation) {
        // The user started typing while dictating: stop listening and keep their own text.
        self.dictationUserEdited = YES;
        [self.voiceManager cancelDictation];
    }
    self.placeholderLabel.hidden = textView.text.length > 0;
    [self updateSendButton];
    [self relayoutAnimated];
}

- (NSString *)trimmedInput {
    return [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)micTapped {
    if (self.voiceRecording) {
        [self.voiceManager finishDictation];   // keep the last words; the final text arrives in a moment
        return;
    }
    if (self.streaming) return;
    [self startDictation];
}

- (void)updateSendButton {
    BOOL hasContent = [self trimmedInput].length > 0 || self.pendingAttachments.count > 0;
    BOOL canSend = hasContent && self.webReady && self.importsInFlight == 0;
    BOOL material = [Material active];
    self.sendButton.materialStyle = material;
    if (material) {
        // Material 3: a drawn arrow that wakes up when there is something to send and turns into a stop square while
        // the reply is being written
        [self.sendButton setImage:nil forState:UIControlStateNormal];
        [self.sendButton applyReady:canSend generating:self.streaming animated:self.view.window != nil];
    } else if (self.streaming) {
        [self.sendButton setImage:[Theme iconStop] forState:UIControlStateNormal];
        self.sendButton.backgroundColor = [Theme accent];
    } else {
        [self.sendButton setImage:[Theme iconSend] forState:UIControlStateNormal];
        self.sendButton.backgroundColor = canSend ? [Theme accent] : [Theme accentDisabled];
    }
    self.sendButton.enabled = self.streaming || canSend;
    BOOL micAvailable = !self.streaming || self.voiceRecording;
    self.micButton.enabled = micAvailable;
    if (!self.voiceRecording) self.micButton.alpha = micAvailable ? 1.0 : 0.4;
    self.micButton.tintColor = self.voiceRecording ? [UIColor colorWithRed:0.90 green:0.22 blue:0.22 alpha:1.0] : [Theme text];
    self.attachButton.enabled = !self.streaming;
    self.attachButton.alpha = self.streaming ? 0.4 : 1.0;
}

- (NSString *)serifCSSValue {
    return [AppSettings fontStyle] == 0 ? @"Georgia, \"Times New Roman\", serif" : CMWebFontStack();
}

- (void)applyUIScaleToNativeAndWeb {
    // Called on every appearance of the chat: do the work only when the size or the font really changed,
    // otherwise returning from Settings would restyle the page (and flash the greeting) for nothing.
    CGFloat sc = [AppSettings uiScale];
    NSString *sig = [NSString stringWithFormat:@"%.3f|%ld|%ld|%d", sc, (long)[AppSettings fontStyle], (long)[AppSettings fontWeightStep], [Theme materialDesign] ? 1 : 0];
    if (![sig isEqualToString:self.appliedNativeScaleSig]) {
        self.appliedNativeScaleSig = sig;
        self.textView.font = [UIFont systemFontOfSize:17.0 * sc];
        self.placeholderLabel.font = [UIFont systemFontOfSize:17.0 * sc];
        [self.view setNeedsLayout];
    }

    if (!self.webReady || !self.webView) return;
    if ([sig isEqualToString:self.appliedWebScaleSig]) return;
    self.appliedWebScaleSig = sig;
    NSData *fontData = [NSJSONSerialization dataWithJSONObject:@[[self serifCSSValue], CMWebFontStack()] options:0 error:nil];
    NSString *fontJSON = fontData ? [[NSString alloc] initWithData:fontData encoding:NSUTF8StringEncoding] : @"[\"Georgia, serif\"]";
    NSData *cssData = [NSJSONSerialization dataWithJSONObject:@[[self scaleCSSRuleForScaleMaterialAware:sc]] options:0 error:nil];
    NSString *cssJSON = cssData ? [[NSString alloc] initWithData:cssData encoding:NSUTF8StringEncoding] : @"[\"\"]";
    NSString *script = [NSString stringWithFormat:
                        @"(function(){"
                         "document.documentElement.style.setProperty('--serif',(%@)[0]);"
                         "document.documentElement.style.setProperty('--ui-font',(%@)[1]);"
                         "var el=document.getElementById('uiscale_live_css');"
                         "if(!el){el=document.createElement('style');el.id='uiscale_live_css';document.head.appendChild(el);}"
                         "el.textContent=(%@)[0];"
                         "})();", fontJSON, fontJSON, cssJSON];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

- (void)uiScaleChanged:(NSNotification *)note {
    [self updateModelTitle];
    [self applyUIScaleToNativeAndWeb];
}

#pragma mark - Dictation (mic: speech to text, the user presses send)

- (void)setDictationActive:(BOOL)active {
    self.voiceRecording = active;
    self.micButton.tintColor = active ? [UIColor colorWithRed:0.90 green:0.22 blue:0.22 alpha:1.0] : [Theme text];
    self.micButton.accessibilityLabel = active ? @"Stop" : @"Mic";
    [self.micButton.layer removeAnimationForKey:@"dictationPulse"];
    if (active) {
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
        pulse.fromValue = @1.0;
        pulse.toValue = @0.35;
        pulse.duration = 0.7;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        [self.micButton.layer addAnimation:pulse forKey:@"dictationPulse"];
    }
}

// Writes the spoken text after what was already typed.
- (void)applyDictatedText:(NSString *)spoken {
    NSString *base = self.dictationBase ?: @"";
    NSString *joined = base;
    if (spoken.length > 0) {
        BOOL needsSpace = base.length > 0 && ![[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[base characterAtIndex:base.length - 1]];
        joined = [NSString stringWithFormat:@"%@%@%@", base, needsSpace ? @" " : @"", spoken];
    }
    self.applyingDictation = YES;
    self.textView.text = joined;
    [self textViewDidChange:self.textView];
    self.applyingDictation = NO;
    UITextRange *end = [self.textView textRangeFromPosition:self.textView.endOfDocument toPosition:self.textView.endOfDocument];
    if (end) self.textView.selectedTextRange = end;
}

- (void)startDictation {
    if (!self.voiceManager) self.voiceManager = [VoiceChatManager shared];
    __weak typeof(self) weakSelf = self;
    [self.voiceManager requestAuthorization:^(BOOL granted) {
        ChatViewController *me = weakSelf;
        if (!me || me.voiceRecording || me.streaming) return;
        if (!granted) { [me showAlertMessage:L(@"voice_denied")]; return; }
        me.dictationBase = me.textView.text ?: @"";
        me.dictationUserEdited = NO;
        [me setDictationActive:YES];
        [me.voiceManager startDictationWithPartial:^(NSString *text) {
            ChatViewController *self2 = weakSelf;
            if (!self2 || !self2.voiceRecording || self2.dictationUserEdited) return;
            [self2 applyDictatedText:text];
        } final:^(NSString *text) {
            ChatViewController *self2 = weakSelf;
            if (!self2) return;
            if (!self2.dictationUserEdited && text.length > 0) [self2 applyDictatedText:text];
            self2.dictationBase = nil;
            [self2 setDictationActive:NO];
            [self2 updateSendButton];
        } issue:^(VoiceDictationIssue issue) {
            ChatViewController *self2 = weakSelf;
            if (!self2) return;
            switch (issue) {
                case VoiceDictationIssueDenied:      [self2 showAlertMessage:L(@"voice_denied")]; break;
                case VoiceDictationIssueUnavailable: [self2 showAlertMessage:L(@"voice_unavailable")]; break;
                case VoiceDictationIssueNoSpeech:    [self2 showAlertMessage:L(@"voice_no_speech")]; break;
                default:                             [self2 showAlertMessage:L(@"voice_failed")]; break;
            }
        }];
    }];
}

#pragma mark - Attachments

- (NSUInteger)inlineBytesOf:(NSArray *)attachments {
    NSUInteger total = 0;
    for (NSDictionary *att in attachments) {
        NSString *kind = att[@"kind"];
        if ([kind isEqualToString:@"image"] || [kind isEqualToString:@"pdf"]) total += [att[@"bytes"] unsignedIntegerValue];
    }
    return total;
}

- (NSString *)extLabelForAttachment:(NSDictionary *)att {
    if ([att[@"kind"] isEqualToString:@"pdf"]) return @"PDF";
    if ([att[@"kind"] isEqualToString:@"image"]) return @"IMG";
    NSString *ext = [[att[@"name"] pathExtension] uppercaseString];
    return (ext.length > 0 && ext.length <= 5) ? ext : @"TXT";
}

- (UIView *)chipForAttachment:(NSDictionary *)att conversation:(NSString *)cid index:(NSUInteger)index {
    BOOL isImage = [att[@"kind"] isEqualToString:@"image"];
    CGFloat width = isImage ? 56 : 168;
    UIView *chip = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 56)];
    chip.layer.cornerRadius = 10;
    chip.clipsToBounds = YES;

    if (isImage) {
        NSString *thumbPath = [AttachmentStore pathForFile:att[@"thumb"] conversation:cid];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:chip.bounds];
        imageView.image = thumbPath ? [UIImage imageWithContentsOfFile:thumbPath] : nil;
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.clipsToBounds = YES;
        imageView.backgroundColor = [Theme selection];
        [chip addSubview:imageView];
    } else {
        chip.backgroundColor = [Theme selection];

        UILabel *badge = [[UILabel alloc] init];
        badge.text = [self extLabelForAttachment:att];
        badge.font = [UIFont systemFontOfSize:10 weight:UIFontWeightBold];
        badge.textColor = [UIColor whiteColor];
        badge.backgroundColor = [Theme accent];
        badge.textAlignment = NSTextAlignmentCenter;
        badge.layer.cornerRadius = 4;
        badge.clipsToBounds = YES;
        CGSize badgeSize = [badge sizeThatFits:CGSizeMake(80, 16)];
        badge.frame = CGRectMake(8, 8, ceil(badgeSize.width) + 10, 16);
        [chip addSubview:badge];

        UILabel *name = [[UILabel alloc] initWithFrame:CGRectMake(8, 28, width - 16, 20)];
        name.text = att[@"name"];
        name.font = [UIFont systemFontOfSize:12];
        name.textColor = [Theme text];
        name.lineBreakMode = NSLineBreakByTruncatingMiddle;
        [chip addSubview:name];
    }

    UIButton *remove = [UIButton buttonWithType:UIButtonTypeCustom];
    remove.frame = CGRectMake(width - 24, 4, 20, 20);
    remove.backgroundColor = [UIColor colorWithWhite:0 alpha:0.55];
    remove.layer.cornerRadius = 10;
    remove.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    [remove setTitle:@"\u00D7" forState:UIControlStateNormal];
    [remove setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    remove.tag = (NSInteger)index;
    [remove addTarget:self action:@selector(removeAttachmentTapped:) forControlEvents:UIControlEventTouchUpInside];
    [chip addSubview:remove];
    return chip;
}

- (void)refreshAttachStrip {
    for (UIView *view in [self.attachStrip.subviews copy]) [view removeFromSuperview];
    NSString *cid = self.conversation[@"id"];
    CGFloat x = 12;
    for (NSUInteger i = 0; i < self.pendingAttachments.count; i++) {
        UIView *chip = [self chipForAttachment:self.pendingAttachments[i] conversation:cid index:i];
        chip.frame = CGRectMake(x, 4, chip.frame.size.width, 56);
        [self.attachStrip addSubview:chip];
        x += chip.frame.size.width + 8;
    }
    if (self.importsInFlight > 0) {
        UIView *busy = [[UIView alloc] initWithFrame:CGRectMake(x, 4, 56, 56)];
        busy.backgroundColor = [Theme selection];
        busy.layer.cornerRadius = 10;
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.center = CGPointMake(28, 28);
        [spinner startAnimating];
        [busy addSubview:spinner];
        [self.attachStrip addSubview:busy];
        x += 64;
    }
    self.attachStrip.contentSize = CGSizeMake(x + 4, kStripHeight);
    [self relayoutAnimated];
}

- (void)removeAttachmentTapped:(UIButton *)sender {
    NSInteger index = sender.tag;
    if (index < 0 || index >= (NSInteger)self.pendingAttachments.count) return;
    [AttachmentStore deleteAttachment:self.pendingAttachments[index] conversation:self.conversation[@"id"]];
    [self.pendingAttachments removeObjectAtIndex:index];
    [self refreshAttachStrip];
    [self updateSendButton];
}

- (void)attachTapped {
    if (self.streaming || self.toolMenuOverlay) return;
    [self.view endEditing:YES];
    if (self.keyboardOverlap <= 0) {
        [self showToolMenu];
    } else {
        __weak typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(260 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            ChatViewController *me = weakSelf;
            if (me && !me.streaming) [me showToolMenu];
        });
    }
}

- (void)dismissToolMenu {
    if (!self.toolMenuOverlay) return;
    UIView *overlay = self.toolMenuOverlay;
    UIView *card = self.toolMenuCard;
    self.toolMenuOverlay = nil;   // a second tap while it leaves must not start a second dismissal
    self.toolMenuCard = nil;
    void (^leave)(void) = ^{
        card.alpha = 0.0;
        card.transform = [Material active] ? CGAffineTransformConcat(CGAffineTransformMakeScale(0.92, 0.92), CGAffineTransformMakeTranslation(0, 8)) : CGAffineTransformMakeTranslation(0, 12);
        overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    };
    void (^gone)(BOOL) = ^(BOOL finished) { [overlay removeFromSuperview]; };
    if ([Material active]) [Material animateEmphasizedAccelerate:MaterialDurationShort3 animations:leave completion:gone];
    else [UIView animateWithDuration:0.16 animations:leave completion:gone];
}

- (void)toolMenuItemTapped:(UIControl *)sender {
    NSInteger item = sender.tag;
    [self dismissToolMenu];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(190 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        ChatViewController *me = weakSelf;
        if (!me) return;
        if (item <= 3 && (NSInteger)me.pendingAttachments.count + me.importsInFlight >= kMaxAttachmentsPerMessage) {
            [me showAlertMessage:[NSString stringWithFormat:L(@"att_err_limit"), (long)kMaxAttachmentsPerMessage]];
            return;
        }
        switch (item) {
            case 0:
                [DiagnosticLog log:@"attach menu: photos"];
                [me presentPhotoLibraryPicker];
                break;
            case 1:
            case 2:
                [DiagnosticLog log:@"attach menu: document picker"];
                [me presentDocumentPicker];
                break;
            case 3:
                if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
                    [DiagnosticLog log:@"attach menu: camera"];
                    [me presentImagePickerWithSource:UIImagePickerControllerSourceTypeCamera];
                } else {
                    [me showAlertMessage:@"Camera không khả dụng trên thiết bị này."];
                }
                break;
            case 4:
                [AppSettings setWebSearchEnabled:![AppSettings webSearchEnabled]];
                [me updateToolButtons];
                [me relayoutAnimated];
                break;
            case 5:
                [me reasoningTapped];
                break;
            case 6:
                [me mentionTapped];
                break;
            case 7:
                me.textView.text = @"/tạo ảnh ";
                [me textViewDidChange:me.textView];
                [me.textView becomeFirstResponder];
                break;
            default:
                break;
        }
    });
}

- (void)addToolMenuRowToCard:(UIView *)card y:(CGFloat)y icon:(NSString *)icon title:(NSString *)title subtitle:(NSString *)subtitle tag:(NSInteger)tag width:(CGFloat)width {
    UIControl *row = [[UIControl alloc] initWithFrame:CGRectMake(10, y, width - 20, 46)];
    row.tag = tag;
    row.layer.cornerRadius = MR(13, 16);
    row.backgroundColor = [UIColor clearColor];
    [row addTarget:self action:@selector(toolMenuItemTapped:) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *iconView = [[UIImageView alloc] initWithImage:[Theme iconTool:icon]];
    iconView.tintColor = [Theme text];
    iconView.contentMode = UIViewContentModeCenter;
    iconView.frame = CGRectMake(13, 0, 30, 46);
    iconView.userInteractionEnabled = NO;
    [row addSubview:iconView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(52, 0, width - 92, 46)];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    titleLabel.textColor = [Theme text];
    [row addSubview:titleLabel];

    if (subtitle.length > 0) {
        titleLabel.frame = CGRectMake(52, 3, width - 92, 21);
        UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(52, 23, width - 92, 18)];
        detail.text = subtitle;
        detail.font = [UIFont systemFontOfSize:11];
        detail.textColor = [Theme secondaryText];
        [row addSubview:detail];
    }
    [card addSubview:row];
}

- (void)showToolMenu {
    if (self.toolMenuOverlay) return;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat cardWidth = MIN(width - 28.0, 430.0);
    CGFloat rowHeight = 46.0;
    BOOL canUseCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    NSArray *items = @[
        @{@"icon":@"photo", @"title":@"Ảnh", @"subtitle":@"Chọn ảnh từ thư viện", @"tag":@0},
        @{@"icon":@"file", @"title":@"Tệp", @"subtitle":@"PDF, Word, video và tài liệu", @"tag":@1},
        @{@"icon":@"library", @"title":@"Thêm từ thư viện", @"subtitle":@"Duyệt các tệp đã lưu", @"tag":@2},
        @{@"icon":@"camera", @"title":@"Camera", @"subtitle":@"Chụp ảnh mới", @"tag":@3},
        @{@"icon":@"web", @"title":@"Tìm kiếm trên mạng", @"subtitle":@"Tìm thông tin mới trên web", @"tag":@4},
        @{@"icon":@"think", @"title":@"Suy nghĩ đi", @"subtitle":@"Điều chỉnh mức suy luận", @"tag":@5},
        @{@"icon":@"sparkle", @"title":@"Tạo ảnh", @"subtitle":@"Nhập mô tả để tạo ảnh", @"tag":@7},
        @{@"icon":@"more", @"title":@"Công cụ khác", @"subtitle":@"Tạo tệp và lệnh bổ sung", @"tag":@6}
    ];
    CGFloat headerHeight = 42.0;
    CGFloat cancelHeight = 42.0;
    NSUInteger visibleItemCount = items.count - (canUseCamera ? 0 : 1);
    CGFloat cardHeight = headerHeight + rowHeight * visibleItemCount + cancelHeight + 12.0;
    CGFloat safeTop = 12.0;
    if (@available(iOS 11.0, *)) safeTop += self.view.safeAreaInsets.top;
    CGFloat bottomY = CGRectGetMinY(self.inputBar.frame) - 8.0;
    CGFloat cardY = MAX(safeTop, bottomY - cardHeight);
    if (cardY + cardHeight > bottomY) cardHeight = MAX(250.0, bottomY - safeTop);

    self.toolMenuOverlay = [[UIView alloc] initWithFrame:self.view.bounds];
    self.toolMenuOverlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.toolMenuOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    UIButton *outside = [UIButton buttonWithType:UIButtonTypeCustom];
    outside.frame = self.toolMenuOverlay.bounds;
    outside.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [outside addTarget:self action:@selector(dismissToolMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.toolMenuOverlay addSubview:outside];

    self.toolMenuCard = [[UIView alloc] initWithFrame:CGRectMake((width - cardWidth) / 2.0, cardY, cardWidth, cardHeight)];
    self.toolMenuCard.backgroundColor = [Theme surface];
    self.toolMenuCard.layer.cornerRadius = MR(22, 28);
    self.toolMenuCard.layer.borderWidth = 1.0;
    self.toolMenuCard.layer.borderColor = [Theme border].CGColor;
    self.toolMenuCard.layer.shadowColor = [UIColor blackColor].CGColor;
    self.toolMenuCard.layer.shadowOpacity = 0.22;
    self.toolMenuCard.layer.shadowRadius = 18.0;
    self.toolMenuCard.layer.shadowOffset = CGSizeMake(0, 6);
    [self.toolMenuOverlay addSubview:self.toolMenuCard];

    UILabel *heading = [[UILabel alloc] initWithFrame:CGRectMake(18, 8, cardWidth - 36, 30)];
    heading.text = @"Công cụ";
    heading.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    heading.textColor = [Theme secondaryText];
    [self.toolMenuCard addSubview:heading];

    CGFloat y = headerHeight;
    for (NSDictionary *item in items) {
        NSInteger tag = [item[@"tag"] integerValue];
        if (tag == 3 && !canUseCamera) continue;
        NSString *title = item[@"title"];
        NSString *subtitle = item[@"subtitle"];
        if (tag == 4 && [AppSettings webSearchEnabled]) {
            title = @"Tắt tìm kiếm trên mạng";
            subtitle = @"Tìm kiếm đang được bật";
        }
        [self addToolMenuRowToCard:self.toolMenuCard y:y icon:item[@"icon"] title:title subtitle:subtitle tag:tag width:cardWidth];
        y += rowHeight;
    }

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    cancel.frame = CGRectMake(12, cardHeight - cancelHeight - 2, cardWidth - 24, cancelHeight);
    [cancel setTitle:L(@"cancel") forState:UIControlStateNormal];
    cancel.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    [cancel setTitleColor:[Theme accent] forState:UIControlStateNormal];
    [cancel addTarget:self action:@selector(dismissToolMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.toolMenuCard addSubview:cancel];

    [self.view addSubview:self.toolMenuOverlay];
    UIView *menuCard = self.toolMenuCard;
    UIView *menuOverlay = self.toolMenuOverlay;
    if ([Material active] && ![Material reduceMotion]) {
        // Material 3 menu: grows from 0.85 on the spatial spring while it fades in on the effects spring
        menuCard.alpha = 0.0;
        menuCard.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(0.85, 0.85), CGAffineTransformMakeTranslation(0, 12));
        [Material animateSpatial:MaterialMotionDefault animations:^{ menuCard.transform = CGAffineTransformIdentity; } completion:nil];
        [Material animateEffects:MaterialMotionDefault animations:^{
            menuCard.alpha = 1.0;
            menuOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.20];
        } completion:nil];
        return;
    }
    self.toolMenuCard.transform = CGAffineTransformMakeTranslation(0, 12);
    self.toolMenuCard.alpha = 0.0;
    [UIView animateWithDuration:0.20 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.toolMenuOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.20];
        self.toolMenuCard.transform = CGAffineTransformIdentity;
        self.toolMenuCard.alpha = 1.0;
    } completion:nil];
}

- (void)presentImagePickerWithSource:(UIImagePickerControllerSourceType)source {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = source;
    picker.mediaTypes = @[@"public.image"];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)presentPhotoLibraryPicker {
    if (@available(iOS 14.0, *)) {
        NSInteger available = MAX(0, kMaxAttachmentsPerMessage - (NSInteger)self.pendingAttachments.count - self.importsInFlight);
        if (available == 0) {
            [self showAlertMessage:[NSString stringWithFormat:L(@"att_err_limit"), (long)kMaxAttachmentsPerMessage]];
            return;
        }
        PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] init];
        configuration.filter = PHPickerFilter.imagesFilter;
        configuration.selectionLimit = available;
        PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
        picker.delegate = self;
        [self presentViewController:picker animated:YES completion:nil];
    } else {
        [self presentImagePickerWithSource:UIImagePickerControllerSourceTypePhotoLibrary];
    }
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results API_AVAILABLE(ios(14.0)) {
    [picker dismissViewControllerAnimated:YES completion:nil];
    if (results.count == 0) return;

    NSString *cid = self.conversation[@"id"];
    NSInteger available = MAX(0, kMaxAttachmentsPerMessage - (NSInteger)self.pendingAttachments.count - self.importsInFlight);
    NSUInteger count = MIN(results.count, (NSUInteger)available);
    if (count == 0) {
        [self showAlertMessage:[NSString stringWithFormat:L(@"att_err_limit"), (long)kMaxAttachmentsPerMessage]];
        return;
    }

    self.importsInFlight += (NSInteger)count;
    [self refreshAttachStrip];
    [self updateSendButton];
    __weak typeof(self) weakSelf = self;
    for (NSUInteger index = 0; index < count; index++) {
        NSItemProvider *provider = results[index].itemProvider;
        NSString *displayName = provider.suggestedName.length ? provider.suggestedName : [NSString stringWithFormat:@"photo-%lu.jpg", (unsigned long)(index + 1)];
        [provider loadDataRepresentationForTypeIdentifier:@"public.image" completionHandler:^(NSData *data, NSError *loadError) {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                NSString *errorKey = nil;
                NSDictionary *attachment = data.length > 0
                    ? [AttachmentStore importImageData:data name:displayName conversation:cid errorKey:&errorKey]
                    : nil;
                if (!attachment && !errorKey) errorKey = loadError ? @"att_err_unreadable" : @"att_err_empty";
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf finishImport:attachment conversation:cid errorKey:errorKey];
                });
            });
        }];
    }
    if (results.count > count) [self showAlertMessage:[NSString stringWithFormat:@"Chỉ nhận tối đa %ld ảnh/tệp trong một tin nhắn.", (long)kMaxAttachmentsPerMessage]];
}

- (void)presentDocumentPicker {
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data", @"public.content", @"public.movie", @"public.video", @"com.apple.quicktime-movie", @"public.mpeg-4"]
                                                               inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    picker.allowsMultipleSelection = YES;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    NSURL *imageURL = info[UIImagePickerControllerImageURL];
    UIImage *original = info[UIImagePickerControllerOriginalImage];
    [picker dismissViewControllerAnimated:YES completion:nil];

    [self runImportWithWork:^NSDictionary *(NSString *cid, NSString **errorKey) {
        NSData *data = imageURL ? [NSData dataWithContentsOfURL:imageURL] : nil;
        if (data.length == 0 && original) data = UIImageJPEGRepresentation(original, 0.9);
        return [AttachmentStore importImageData:data name:imageURL.lastPathComponent conversation:cid errorKey:errorKey];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSInteger available = MAX(0, kMaxAttachmentsPerMessage - (NSInteger)self.pendingAttachments.count - self.importsInFlight);
    NSUInteger count = MIN(urls.count, (NSUInteger)available);
    for (NSUInteger index = 0; index < count; index++) {
        NSURL *url = urls[index];
        [self runImportWithWork:^NSDictionary *(NSString *cid, NSString **errorKey) {
            return [AttachmentStore importDocumentAtURL:url conversation:cid errorKey:errorKey];
        }];
    }
    if (urls.count > count) {
        [self showAlertMessage:[NSString stringWithFormat:@"Chỉ nhận tối đa %ld ảnh/tệp trong một tin nhắn.", (long)kMaxAttachmentsPerMessage]];
    }
}

#pragma mark Import pipeline

- (void)runImportWithWork:(NSDictionary *(^)(NSString *cid, NSString **errorKey))work {
    NSString *cid = self.conversation[@"id"];
    self.importsInFlight++;
    [self refreshAttachStrip];
    [self updateSendButton];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *errorKey = nil;
        NSDictionary *attachment = work(cid, &errorKey);
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf finishImport:attachment conversation:cid errorKey:errorKey];
        });
    });
}

- (void)finishImport:(NSDictionary *)attachment conversation:(NSString *)cid errorKey:(NSString *)errorKey {
    self.importsInFlight = MAX(0, self.importsInFlight - 1);
    NSString *problem = nil;

    if (attachment) {
        if (![cid isEqualToString:self.conversation[@"id"]]) {
            [AttachmentStore deleteAttachment:attachment conversation:cid];
        } else if ((NSInteger)self.pendingAttachments.count >= kMaxAttachmentsPerMessage) {
            [AttachmentStore deleteAttachment:attachment conversation:cid];
            problem = [NSString stringWithFormat:L(@"att_err_limit"), (long)kMaxAttachmentsPerMessage];
        } else if ([self inlineBytesOf:self.pendingAttachments] + [self inlineBytesOf:@[attachment]] > kMaxInlineBytesPerMessage) {
            [AttachmentStore deleteAttachment:attachment conversation:cid];
            problem = L(@"att_err_budget");
        } else {
            [self.pendingAttachments addObject:attachment];
        }
    } else {
        problem = L(errorKey ?: @"att_err_unreadable");
    }

    [DiagnosticLog log:@"attachment: %@", attachment ? [NSString stringWithFormat:@"ok kind=%@ bytes=%@", attachment[@"kind"], attachment[@"bytes"]]
                                                       : [NSString stringWithFormat:@"failed (%@)", errorKey ?: @"unknown"]];
    if (attachment && problem) [DiagnosticLog log:@"attachment rejected after import: %@", ClippedForLog(problem)];
    [self refreshAttachStrip];
    [self updateSendButton];
    if (problem) [self showAlertMessage:problem];
}

#pragma mark - Sending

- (void)sendTapped {
    if (self.streaming) {
        [self.stream cancel];
        return;
    }
    if (self.voiceRecording) {
        // Sending while the mic is open: stop listening now and send what has been written so far.
        [self.voiceManager cancelDictation];
    }
    NSString *text = [self trimmedInput];
    BOOL hasAttachments = self.pendingAttachments.count > 0;
    if (text.length == 0 && !hasAttachments) return;
    if (!self.webReady || self.importsInFlight > 0) return;

    NSString *lowerText = text.lowercaseString;
    if ([lowerText hasPrefix:@"/tạo ảnh"] && text.length >= [@"/tạo ảnh" length]) {
        NSString *imagePrompt = [[text substringFromIndex:([@"/tạo ảnh" length])] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (imagePrompt.length == 0) { [self showAlertMessage:@"Hãy nhập mô tả ảnh sau lệnh /tạo ảnh."]; return; }
        if (![KeyStore hasKeyForProvider:AIProviderGemini]) {
            [self showAlertMessage:@"Tạo ảnh cần Gemini API key. Hãy thêm key Gemini trong Cài đặt."];
            return;
        }
        NSString *currentModel = self.model.lowercaseString;
        NSString *imageModel = ([currentModel containsString:@"image"] || [currentModel containsString:@"nano-banana"])
            && [Provider forModelId:self.model] == AIProviderGemini ? self.model : nil;
        if (!imageModel) {
            for (NSDictionary *model in [ModelStore cachedModelsForProvider:AIProviderGemini]) {
                NSString *mid = [model[@"id"] isKindOfClass:[NSString class]] ? model[@"id"] : @"";
                NSString *name = [model[@"name"] isKindOfClass:[NSString class]] ? model[@"name"] : @"";
                NSString *lowerID = mid.lowercaseString;
                NSString *lowerName = name.lowercaseString;
                if ([lowerID containsString:@"image"] || [lowerID containsString:@"nano-banana"] ||
                    [lowerName containsString:@"image generation"] || [lowerName containsString:@"nano banana"]) { imageModel = mid; break; }
            }
        }
        if (imageModel.length == 0) {
            [self showAlertMessage:@"Danh sách model Gemini hiện tại chưa có model tạo ảnh. Hãy làm mới danh sách model hoặc chọn model Gemini hỗ trợ tạo ảnh."];
            [self refreshModels];
            return;
        }
        self.model = imageModel;
        [ModelStore setSelectedModelId:imageModel];
        self.conversation[@"model"] = imageModel;
        [self updateModelTitle];
        text = [NSString stringWithFormat:@"Create an image based on this prompt: %@", imagePrompt];
    }

    if (![KeyStore hasAnyKey]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
        return;
    }
    if (self.model.length == 0) {
        [self modelTapped];
        return;
    }
    if (![self checkKeyForCurrentModel]) return;

    NSString *cid = self.conversation[@"id"];
    NSArray *attachments = [self.pendingAttachments copy];
    NSMutableDictionary *message = [@{ @"role": @"user", @"text": text, @"ts": @([[NSDate date] timeIntervalSince1970]) } mutableCopy];
    if (hasAttachments) message[@"attachments"] = attachments;

    NSMutableArray *messages = self.conversation[@"messages"];
    [messages addObject:message];
    if ([self.conversation[@"title"] length] == 0) {
        NSString *source = text.length > 0 ? text : (attachments.firstObject[@"name"] ?: @"");
        self.conversation[@"title"] = [self titleFromText:source];
    }
    self.conversation[@"model"] = self.model;
    self.conversation[@"updated"] = @([[NSDate date] timeIntervalSince1970]);
    [ConversationStore saveConversation:self.conversation];
    [self refreshPinnedSidebar];

    [self callJS:@"addUser" args:@[text, [self webAttachmentsFrom:attachments conversation:cid], @([messages count] - 1)]];
    [self.pendingAttachments removeAllObjects];
    [self refreshAttachStrip];
    [self flyTextUp:text];
    self.textView.text = @"";
    [self textViewDidChange:self.textView];
    [self startStreamingReply];
}

- (NSString *)titleFromText:(NSString *)text {
    NSString *firstLine = [[text componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
    firstLine = [firstLine stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (firstLine.length <= 40) return firstLine;
    NSRange range = [firstLine rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, 40)];
    return [[firstLine substringWithRange:range] stringByAppendingString:@"…"];
}

#pragma mark - Request contents

- (void)addPartsForAttachment:(NSDictionary *)att
                 conversation:(NSString *)cid
                    inlineIds:(NSSet *)inlineIds
                           to:(NSMutableArray *)parts {
    if (![att isKindOfClass:[NSDictionary class]]) return;
    NSString *kind = att[@"kind"];
    NSString *name = [att[@"name"] isKindOfClass:[NSString class]] ? att[@"name"] : @"file";
    NSString *path = [AttachmentStore pathForFile:att[@"file"] conversation:cid];

    if ([kind isEqualToString:@"text"]) {
        NSString *content = nil;
        if (path) {
            NSData *mapped = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
            if (mapped.length > 0) {
                content = [[NSString alloc] initWithData:mapped encoding:NSUTF8StringEncoding];
                if (!content) content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            }
        }
        NSString *text = content.length > 0
            ? [NSString stringWithFormat:@"[Attached file: %@]\n%@", name, content]
            : [NSString stringWithFormat:@"[Attached file unavailable: %@]", name];
        [parts addObject:@{ @"type": @"text", @"text": text }];
    } else if ([kind isEqualToString:@"video"]) {
        NSArray *frames = [att[@"frames"] isKindOfClass:[NSArray class]] ? att[@"frames"] : @[];
        if ([inlineIds containsObject:att[@"id"]] && frames.count > 0) {
            NSUInteger addedFrames = 0;
            for (NSString *frameFile in frames) {
                NSString *framePath = [AttachmentStore pathForFile:frameFile conversation:cid];
                NSData *frameData = framePath ? [NSData dataWithContentsOfFile:framePath] : nil;
                if (frameData.length == 0) continue;
                [parts addObject:@{ @"type": @"image", @"mime": @"image/jpeg",
                                    @"data": [frameData base64EncodedStringWithOptions:0] }];
                addedFrames++;
            }
            if (addedFrames == 0) [parts addObject:@{ @"type": @"text", @"text": [NSString stringWithFormat:@"[Video frames unavailable: %@]", name] }];
        } else {
            [parts addObject:@{ @"type": @"text", @"text": [NSString stringWithFormat:@"[Earlier video not included: %@]", name] }];
        }
    } else if ([kind isEqualToString:@"image"] || [kind isEqualToString:@"pdf"]) {
        NSData *data = ([inlineIds containsObject:att[@"id"]] && path) ? [NSData dataWithContentsOfFile:path] : nil;
        if (data.length > 0) {
            NSString *encoded = [data base64EncodedStringWithOptions:0];
            if ([kind isEqualToString:@"pdf"]) {
                [parts addObject:@{ @"type": @"pdf", @"data": encoded }];
            } else {
                NSString *mime = [att[@"mime"] isKindOfClass:[NSString class]] ? att[@"mime"] : @"image/jpeg";
                [parts addObject:@{ @"type": @"image", @"mime": mime, @"data": encoded }];
                [DiagnosticLog log:@"image attachment inlined for API: %@ bytes=%lu mime=%@", name, (unsigned long)data.length, mime];
            }
        } else {
            [parts addObject:@{ @"type": @"text", @"text": [NSString stringWithFormat:@"[Earlier attachment not included: %@]", name] }];
            [DiagnosticLog log:@"image/pdf attachment not inlined: %@ id=%@ pathReadable=%@", name, att[@"id"] ?: @"-", path && [[NSFileManager defaultManager] isReadableFileAtPath:path] ? @"yes" : @"no"];
        }
    }
}

- (NSArray *)buildTurns {
    NSString *cid = self.conversation[@"id"];
    NSArray *messages = self.conversation[@"messages"];

    NSInteger memory = [AppSettings attachmentMemory];
    NSInteger mediaMessages = 0;
    NSMutableSet *inlineIds = [NSMutableSet set];
    NSUInteger remaining = kMaxInlineBytesPerMessage;
    for (NSInteger i = (NSInteger)messages.count - 1; i >= 0; i--) {
        NSArray *atts = messages[i][@"attachments"];
        if (![atts isKindOfClass:[NSArray class]]) continue;
        BOOL hasMedia = NO;
        for (NSDictionary *att in atts) {
            NSString *kind = att[@"kind"];
            if ([kind isEqualToString:@"image"] || [kind isEqualToString:@"pdf"] || [kind isEqualToString:@"video"]) { hasMedia = YES; break; }
        }
        if (!hasMedia) continue;
        mediaMessages++;
        if (memory > 0 && mediaMessages > memory) continue;
        for (NSDictionary *att in atts) {
            NSString *kind = att[@"kind"];
            if (![kind isEqualToString:@"image"] && ![kind isEqualToString:@"pdf"] && ![kind isEqualToString:@"video"]) continue;
            NSUInteger bytes = [att[@"bytes"] unsignedIntegerValue];
            if (bytes <= remaining && att[@"id"]) {
                remaining -= bytes;
                [inlineIds addObject:att[@"id"]];
            }
        }
    }

    NSMutableArray *turns = [NSMutableArray array];
    for (NSDictionary *message in messages) {
        NSString *role = message[@"role"];
        if (![role isKindOfClass:[NSString class]]) continue;
        NSString *text = [message[@"text"] isKindOfClass:[NSString class]] ? message[@"text"] : @"";
        NSString *turnRole = [role isEqualToString:@"user"] ? @"user" : @"assistant";

        NSMutableArray *parts = [NSMutableArray array];
        NSArray *atts = [message[@"attachments"] isKindOfClass:[NSArray class]] ? message[@"attachments"] : @[];
        for (NSDictionary *att in atts) [self addPartsForAttachment:att conversation:cid inlineIds:inlineIds to:parts];
        if (text.length > 0) [parts addObject:@{ @"type": @"text", @"text": text }];
        if (parts.count == 0) continue;

        NSMutableDictionary *last = turns.lastObject;
        if (last && [last[@"role"] isEqualToString:turnRole]) {
            [last[@"parts"] addObjectsFromArray:parts];
        } else {
            [turns addObject:[@{ @"role": turnRole, @"parts": parts } mutableCopy]];
        }
    }

    NSUInteger contextLimit = MAX([AppSettings contextLimitChars], kForceMaxContextChars);
    AIProvider provider = [Provider forModelId:self.model];
    NSInteger inputTokenCap = [ModelStore maxInputTokensForModelId:self.model provider:provider];
    if (inputTokenCap > 0) {
        NSUInteger modelCharCap = (NSUInteger)inputTokenCap * 4;
        NSUInteger reservedChars = [self effectiveSystemPrompt].length + 4096;
        modelCharCap = modelCharCap > reservedChars ? modelCharCap - reservedChars : 16384;
        contextLimit = MIN(contextLimit, MAX(modelCharCap, (NSUInteger)1000000));
    }

    while (turns.count > 1 && [self totalTextChars:turns] > contextLimit) [turns removeObjectAtIndex:0];
    while (turns.count > 1 && [turns.firstObject[@"role"] isEqualToString:@"assistant"]) [turns removeObjectAtIndex:0];

    if (turns.count == 1 && [self totalTextChars:turns] > contextLimit) {
        NSMutableArray *parts = turns.firstObject[@"parts"];
        NSString *marker = @"[Earlier text omitted to fit the model context]\n";
        for (NSInteger i = 0; i < (NSInteger)parts.count && [self totalTextChars:turns] > contextLimit; i++) {
            NSMutableDictionary *part = parts[(NSUInteger)i];
            NSString *content = [part[@"text"] isKindOfClass:[NSString class]] ? part[@"text"] : nil;
            if (content.length == 0) continue;

            NSUInteger total = [self totalTextChars:turns];
            NSUInteger excess = total - contextLimit;
            if (content.length <= excess) {
                [parts removeObjectAtIndex:(NSUInteger)i];
                i--;
                continue;
            }

            NSUInteger otherChars = total - content.length;
            NSUInteger available = contextLimit > otherChars + marker.length
                ? contextLimit - otherChars - marker.length : 0;
            NSUInteger keep = MIN(available, content.length - excess);
            if (keep > 0) {
                NSUInteger start = content.length - keep;
                NSRange safe = [content rangeOfComposedCharacterSequencesForRange:NSMakeRange(start, keep)];
                part[@"text"] = [marker stringByAppendingString:[content substringWithRange:safe]];
                break;
            }

            [parts removeObjectAtIndex:(NSUInteger)i];
            i--;
        }
    }
    return turns;
}

- (NSUInteger)totalTextChars:(NSArray *)turns {
    NSUInteger total = 0;
    for (NSDictionary *turn in turns) {
        for (NSDictionary *part in turn[@"parts"]) {
            NSString *text = part[@"text"];
            if ([text isKindOfClass:[NSString class]]) total += text.length;
        }
    }
    return total;
}

#pragma mark - Streaming

- (BOOL)checkKeyForCurrentModel {
    AIProvider provider = [Provider forModelId:self.model];
    if ([KeyStore hasKeyForProvider:provider]) return YES;
    [self showAlertMessage:[NSString stringWithFormat:L(@"err_no_key_for_provider"), [Provider nameFor:provider]]];
    return NO;
}

- (void)startStreamingReply {
    if (![self checkKeyForCurrentModel]) return;
    self.streamBuffer = [NSMutableString string];
    self.longReplyAccumulator = [NSMutableString string];
    self.longReplyContinuationCount = 0;
    self.earlyEndContinuations = 0;
    self.streamRetryCount = 0;
    self.didRecoverModel404 = NO;
    self.didFallbackFromFastMode = NO;
    self.streaming = YES;
    [self updateSendButton];
    [self startDeltaFlushTimer];
    [self callJS:@"begin" args:@[]];
    [self launchRequestStreaming:YES];
}

- (NSString *)effectiveSystemPrompt {
    NSString *own = self.conversation[@"system"];
    NSString *prompt = ([own isKindOfClass:[NSString class]] && own.length > 0) ? own : [AppSettings systemPrompt];
    NSUInteger promptBudget = 1500000;
    NSString *query = @"";
    NSArray *messages = self.conversation[@"messages"];
    for (NSInteger i = (NSInteger)messages.count - 1; i >= 0; i--) {
        NSDictionary *message = messages[(NSUInteger)i];
        if ([message[@"role"] isEqualToString:@"user"] && [message[@"text"] isKindOfClass:[NSString class]]) {
            query = message[@"text"];
            break;
        }
    }
    NSString *selectedPrompt = [AppSettings promptText:prompt forQuery:query characterBudget:promptBudget];
    NSString *lowerQuery = query.lowercaseString ?: @"";
    NSArray *codingSignals = @[@"code", @"mã nguồn", @"sửa code", @"viết code", @"lập trình", @"objective-c", @"swift", @"theos", @"xcode", @"compile", @"build", @".m", @".h", @".swift", @"c++", @"debug", @"hàm", @"class", @"zip source"];
    BOOL codingTask = NO;
    for (NSString *signal in codingSignals) {
        if ([lowerQuery containsString:signal]) { codingTask = YES; break; }
    }
    NSString *responseDirective = @"\n\n[RESPONSE COMPLETENESS] Unless the user explicitly asks for a short answer, answer every part with enough useful detail to act on it. Do not substitute a long outline for the requested explanation, implementation, or deliverable. Include relevant steps, examples, assumptions, and limitations without filler. For technical topics, identify the actual cause before proposing a change; distinguish verified facts from hypotheses. Never claim a search, API action, file edit, or build succeeded unless it actually did.";
    selectedPrompt = [selectedPrompt stringByAppendingString:responseDirective];
    if (codingTask) {
        NSString *codingDirective = @"\n\n[CODING RESPONSE REQUIREMENTS] For a coding, debugging, or source-editing request, deliver implementation rather than an outline alone. Include the complete requested function or changed file sections with all required declarations/imports; do not replace code with ellipses, placeholders, TODOs, or pseudo-code. Do not describe a large architecture while returning only a tiny code fragment. When the user asks for a complete file or a large implementation, provide the full requested code, not a shortened sample. Do not arbitrarily stop after the design or first few functions; continue until every requested component is implemented. Preserve unrelated behavior and make only requested changes. Check method names, property declarations, types, API payload fields, and error paths for consistency. Explain the exact files and behavior changed, then clearly state anything not build-tested. Prefer complete, compilable code over an inflated architecture proposal. The app automatically requests continuation when the provider reports its output-token limit; continue from the exact next line without repeating earlier code. If continuation cannot proceed because the model context or provider limit is reached, state the precise remaining section instead of claiming the work is complete.";
        selectedPrompt = [selectedPrompt stringByAppendingString:codingDirective];
    }
    if ([AppSettings webSearchEnabled]) {
        selectedPrompt = [selectedPrompt stringByAppendingString:@"\n\n[WEB SEARCH ENABLED] A real provider-managed web search tool is attached to this request. When the user explicitly asks to search, or the answer depends on current, recent, external, or verifiable information, you MUST invoke the search tool before answering and base factual claims on the returned results. Do not claim to have searched unless the API actually returned results. If the selected model/provider rejects or does not support the tool, state that limitation plainly instead of pretending the search happened." ];
    }
    return selectedPrompt;
}

- (NSString *)summaryOfTurns:(NSArray *)turns {
    NSUInteger images = 0, pdfs = 0, mediaChars = 0, textChars = 0;
    for (NSDictionary *turn in turns) {
        for (NSDictionary *part in turn[@"parts"]) {
            NSString *type = part[@"type"];
            if ([type isEqualToString:@"image"]) { images++; mediaChars += [part[@"data"] length]; }
            else if ([type isEqualToString:@"pdf"]) { pdfs++; mediaChars += [part[@"data"] length]; }
            else textChars += [part[@"text"] length];
        }
    }
    return [NSString stringWithFormat:@"turns=%lu images=%lu pdfs=%lu media=%.1fMB textChars=%lu",
            (unsigned long)turns.count, (unsigned long)images, (unsigned long)pdfs, mediaChars / 1048576.0, (unsigned long)textChars];
}

- (void)launchRequestStreaming:(BOOL)useStreaming {
    self.attemptIsStreaming = useStreaming;
    AIProvider provider = [Provider forModelId:self.model];
    NSString *key = [KeyStore loadKeyForProvider:provider] ?: @"";
    NSMutableArray *turns = [[self buildTurns] mutableCopy];
    NSString *system = [self effectiveSystemPrompt];
    if (self.longReplyAccumulator.length > 0) {
        [turns addObject:[@{ @"role": @"assistant", @"parts": @[@{ @"type": @"text", @"text": [self.longReplyAccumulator copy] }] } mutableCopy]];
        NSString *continueInstruction = @"Continue the response exactly where the previous assistant message ended. Do not repeat, summarize, shorten, or rewrite any text already provided. If writing code, continue the same file/code block with identical indentation and complete syntax; include every remaining line, declaration, implementation, and closing delimiter. Do not replace code with placeholders or ellipses. Finish the original request fully.";
        [turns addObject:[@{ @"role": @"user", @"parts": @[@{ @"type": @"text", @"text": continueInstruction }] } mutableCopy]];

        NSInteger inputCap = [ModelStore maxInputTokensForModelId:self.model provider:[Provider forModelId:self.model]];
        NSUInteger safeCharCap = inputCap > 0 ? MAX((NSUInteger)inputCap * 4, (NSUInteger)1000000) : 1000000;
        NSUInteger reserve = system.length + 4096;
        safeCharCap = safeCharCap > reserve ? safeCharCap - reserve : 16000;
        while (turns.count > 3 && [self totalTextChars:turns] > safeCharCap) [turns removeObjectAtIndex:0];
        while (turns.count > 1 && [turns.firstObject[@"role"] isEqualToString:@"assistant"]) [turns removeObjectAtIndex:0];
    }
    id<ChatStreaming> stream = (provider == AIProviderClaude)
        ? (id<ChatStreaming>)[[ClaudeStream alloc] initWithKey:key model:self.model turns:turns system:system]
        : (id<ChatStreaming>)[[GeminiStream alloc] initWithKey:key model:self.model turns:turns system:system];
    BOOL fastEnabled = [AppSettings fastModeEnabled] && !self.didFallbackFromFastMode;
    if (provider == AIProviderClaude) {
        ((ClaudeStream *)stream).useFastSpeed = fastEnabled;
    } else if ([stream respondsToSelector:NSSelectorFromString(@"setUseFastSpeed:")]) {
        [(id)stream setValue:@(fastEnabled) forKey:@"useFastSpeed"];
    }
    stream.useStreaming = useStreaming;
    self.stream = stream;
    if (!self.streamGeneratedAttachments) self.streamGeneratedAttachments = [NSMutableArray array];
    self.requestStartTime = CFAbsoluteTimeGetCurrent();
    [DiagnosticLog log:@"request: %@ model=%@ mode=%@ fast=%d %@ systemChars=%lu", [Provider nameFor:provider], self.model,
                       useStreaming ? @"stream" : @"single", fastEnabled, [self summaryOfTurns:turns], (unsigned long)system.length];
    __weak typeof(self) weakSelf = self;
    __weak id<ChatStreaming> weakStream = stream;
    stream.onDelta = ^(NSString *text) {
        ChatViewController *me = weakSelf;
        if (!me || me.stream != weakStream || text.length == 0) return;
        [me.streamBuffer appendString:text];
        if (me.pendingJSDelta) {
            [me.pendingJSDelta appendString:text];
        } else {
            [me callJS:@"delta" args:@[text]];
        }
    };
    stream.onThought = ^(NSString *text) {
        ChatViewController *me = weakSelf;
        if (!me || me.stream != weakStream || text.length == 0) return;
        [me callJS:@"thought" args:@[text]];
    };
    stream.onImage = ^(NSData *data, NSString *mimeType) {
        ChatViewController *me = weakSelf;
        if (!me || me.stream != weakStream || data.length == 0) return;
        NSString *errorKey = nil;
        NSString *imageName = @"generated-image.jpg";
        NSDictionary *attachment = [AttachmentStore importImageData:data name:imageName
                                                         conversation:me.conversation[@"id"] errorKey:&errorKey];
        if (attachment) {
            [me.streamGeneratedAttachments addObject:attachment];
            [DiagnosticLog log:@"generated image saved: bytes=%@ mime=%@", attachment[@"bytes"], mimeType ?: @"image/*"];
        } else {
            [DiagnosticLog log:@"generated image could not be stored: %@", errorKey ?: @"unknown"];
        }
    };
    stream.onUsage = ^(long long inputTokens, long long outputTokens) {
        ChatViewController *me = weakSelf;
        if (!me || me.stream != weakStream) return;
        [AppSettings addDailyTokenUsage:(inputTokens + outputTokens)];
        [me updateDailyTokenPrompt];
        [DiagnosticLog log:@"usage: input=%lld output=%lld dayTotal=%lld", inputTokens, outputTokens, [AppSettings dailyTokenUsage]];
    };
    stream.onFinish = ^(GeminiStreamError error, NSInteger status, NSString *detail) {
        ChatViewController *me = weakSelf;
        if (!me || me.stream != weakStream) return;
        [me flushPendingJSDelta];
        [me streamFinishedWithError:error status:status detail:detail];
    };
    [stream start];
}

- (void)streamFinishedWithError:(GeminiStreamError)error status:(NSInteger)status detail:(NSString *)detail {
    NSString *partial = [self.streamBuffer copy] ?: @"";
    [DiagnosticLog log:@"reply: model=%@ mode=%@ result=%@ http=%ld textChars=%lu elapsed=%.0fms detail=%@", self.model,
                       self.attemptIsStreaming ? @"stream" : @"single", StreamErrorName(error), (long)status,
                       (unsigned long)partial.length, (CFAbsoluteTimeGetCurrent() - self.requestStartTime) * 1000, ClippedForLog(detail)];

    // A stream that closed quietly (no error, but also no final event) is continued; a provider that never sends the final
    // event must not make every reply loop, so after two such continuations the reply counts as finished.
    if (error == GeminiStreamErrorNetwork && [detail isEqualToString:kStreamEndedEarlyMarker]) {
        if (partial.length == 0 || self.earlyEndContinuations >= 2) {
            error = GeminiStreamErrorNone;
            status = 200;
            detail = nil;
        } else {
            self.earlyEndContinuations++;
        }
    }

    AIProvider currentProvider = [Provider forModelId:self.model];
    BOOL interruptedMidStream = (error == GeminiStreamErrorNetwork || error == GeminiStreamErrorServer) && partial.length > 0 && self.longReplyContinuationCount < 6;
    if (((error == GeminiStreamErrorNone && status == 200 && [detail isEqualToString:@"__OUTPUT_LIMIT_REACHED__"]) || interruptedMidStream) && partial.length > 0) {
        const NSUInteger kMaxAutomaticContinuations = 10;
        NSInteger continuationInputCap = [ModelStore maxInputTokensForModelId:self.model provider:currentProvider];
        NSUInteger continuationCharCap = continuationInputCap > 0 ? MAX((NSUInteger)continuationInputCap * 4, (NSUInteger)1500000) : 1500000;
        NSUInteger continuationPromptChars = [self effectiveSystemPrompt].length + 8192;
        continuationCharCap = continuationCharCap > continuationPromptChars ? continuationCharCap - continuationPromptChars : 0;
        BOOL continuationFitsContext = continuationCharCap > 0 &&
            self.longReplyAccumulator.length + partial.length < (continuationCharCap * 3) / 4;
        if (self.longReplyContinuationCount < kMaxAutomaticContinuations &&
            self.longReplyAccumulator.length + partial.length < 3000000 && continuationFitsContext) {
            if (!self.longReplyAccumulator) self.longReplyAccumulator = [NSMutableString string];
            [self.longReplyAccumulator appendString:partial];
            self.longReplyContinuationCount++;
            self.stream = nil;
            self.streamBuffer = [NSMutableString string];
            [DiagnosticLog log:@"continuing response segment %lu/%lu accumulatedChars=%lu",
                              (unsigned long)self.longReplyContinuationCount, (unsigned long)kMaxAutomaticContinuations,
                              (unsigned long)self.longReplyAccumulator.length];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.streaming && self.stream == nil) [self launchRequestStreaming:YES];
            });
            return;
        }
        detail = @"Đã đạt giới hạn an toàn của chuỗi tự nối tiếp. Phần đã tạo được giữ lại; gửi 'tiếp tục' để lấy phần còn lại.";
    }
    NSInteger claudeModelOutputCap = [ModelStore maxOutputTokensForModelId:self.model provider:AIProviderClaude];
    NSInteger configuredOutputCap = [AppSettings maxOutputTokens];
    BOOL largeClaudeReply = currentProvider == AIProviderClaude &&
        (configuredOutputCap > 21333 || (configuredOutputCap == 0 && claudeModelOutputCap > 21333));

    NSString *lowerDetail = detail.lowercaseString ?: @"";
    BOOL permanentQuota = status == 429 &&
        ([lowerDetail containsString:@"per day"] || [lowerDetail containsString:@"per_day"] ||
         [lowerDetail containsString:@"perday"] || [lowerDetail containsString:@"daily quota"] ||
         [lowerDetail containsString:@"per month"] || [lowerDetail containsString:@"per_month"] ||
         [lowerDetail containsString:@"monthly quota"] || [lowerDetail containsString:@"insufficient_quota"] ||
         [lowerDetail containsString:@"billing"] || [lowerDetail containsString:@"spend limit"] ||
         [lowerDetail containsString:@"spend cap"] || [lowerDetail containsString:@"usage limit"] ||
         [lowerDetail containsString:@"payment"] || [lowerDetail containsString:@"quota_exceeded"]);

    BOOL wasFastRequest = self.stream && [AppSettings fastModeEnabled] && !self.didFallbackFromFastMode;
    NSString *fastErrorText = lowerDetail;
    BOOL fastRateLimited = wasFastRequest && !permanentQuota && (status == 429 || status == 529);
    BOOL fastRejected = wasFastRequest && (status == 400 || status == 403) &&
                        ([fastErrorText containsString:@"fast"] || [fastErrorText containsString:@"speed"]);
    if ((fastRateLimited || fastRejected) && partial.length == 0 &&
        self.streamGeneratedAttachments.count == 0 && !self.didFallbackFromFastMode) {
        self.didFallbackFromFastMode = YES;
        NSTimeInterval fastRetryAfter = self.stream.retryAfterSeconds;
        self.stream = nil;
        [DiagnosticLog log:@"Fast mode rejected/limited; retrying once at standard speed"];
        NSTimeInterval fallbackDelay = fastRateLimited ? MAX(1.0, MIN(900.0, fastRetryAfter)) : 0.4;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fallbackDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.streaming && self.stream == nil) [self launchRequestStreaming:self.attemptIsStreaming];
        });
        return;
    }

    BOOL retryableStatus = (status == 429 || status == 500 || status == 502 || status == 503 || status == 504 || status == 529);
    BOOL transientServer = (error == GeminiStreamErrorServer || error == GeminiStreamErrorRateLimited) && retryableStatus;
    NSInteger retryLimit = status == 429 ? 1 : 3;
    if (transientServer && !permanentQuota && partial.length == 0 && self.streamGeneratedAttachments.count == 0 && self.streamRetryCount < retryLimit) {
        NSTimeInterval providerDelay = self.stream.retryAfterSeconds;
        self.stream = nil;
        self.streamRetryCount++;
        NSTimeInterval backoff = status == 429 ? 8.0 : (self.streamRetryCount == 1 ? 1.5 : (self.streamRetryCount == 2 ? 4.0 : 8.0));
        NSTimeInterval delay = MAX(backoff, MIN(900.0, providerDelay));
        [DiagnosticLog log:@"server overload HTTP %ld: retry %ld after %.0fs", (long)status, (long)self.streamRetryCount, delay];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.streaming && self.stream == nil) [self launchRequestStreaming:self.attemptIsStreaming];
        });
        return;
    }

    if (error == GeminiStreamErrorModelNotFound && status == 404 && partial.length == 0 && !self.didRecoverModel404) {
        self.stream = nil;
        self.didRecoverModel404 = YES;
        NSString *key = [KeyStore loadKeyForProvider:currentProvider] ?: @"";
        __weak typeof(self) weakSelf = self;
        GeminiModelsCompletion completion = ^(NSArray *models, GeminiCheckResult result) {
            ChatViewController *me = weakSelf;
            if (!me || !me.streaming) return;
            if (result != GeminiCheckOK || models.count == 0) {
                [me stopDeltaFlushTimer];
                me.streaming = NO;
                me.stream = nil;
                me.streamBuffer = nil;
                me.streamGeneratedAttachments = nil;
                [me callJS:@"end" args:@[@""]];
                NSString *reason = result == GeminiCheckRateLimited
                    ? @"API đang giới hạn yêu cầu khi làm mới danh sách model. Hãy đợi rồi thử lại."
                    : @"Không làm mới được danh sách model để khôi phục lỗi 404. Kiểm tra API key, quyền truy cập và kết nối.";
                [me callJS:@"error" args:@[reason, @YES]];
                [me updateSendButton];
                [DiagnosticLog log:@"404 recovery model refresh failed: result=%ld models=%lu", (long)result, (unsigned long)models.count];
                return;
            }
            [ModelStore saveModels:models forProvider:currentProvider];
            BOOL selectedStillExists = NO;
            for (NSDictionary *item in models) if ([item[@"id"] isEqualToString:me.model]) { selectedStillExists = YES; break; }
            if (!selectedStillExists) {
                NSString *fallback = [ModelStore defaultModelIdForProvider:currentProvider models:models];
                if (fallback.length > 0) {
                    me.model = fallback;
                    [ModelStore setSelectedModelId:fallback];
                    me.conversation[@"model"] = fallback;
                    [me updateModelTitle];
                    [DiagnosticLog log:@"stale model recovered from HTTP 404: switched to %@", fallback];
                    [me launchRequestStreaming:me.attemptIsStreaming];
                    return;
                }
            }
            [me stopDeltaFlushTimer];
            me.streaming = NO;
            me.streamBuffer = nil;
            [me callJS:@"end" args:@[@""]];
            [me callJS:@"error" args:@[[me messageForError:GeminiStreamErrorModelNotFound status:404 detail:detail], @YES]];
            [me updateSendButton];
        };
        if (currentProvider == AIProviderClaude) [ClaudeClient fetchModelsWithKey:key completion:completion];
        else [GeminiClient fetchModelsWithKey:key completion:completion];
        return;
    }

    if (error == GeminiStreamErrorNetwork && partial.length == 0 && self.streamGeneratedAttachments.count == 0 && self.attemptIsStreaming) {
        self.stream = nil;
        if (largeClaudeReply && self.streamRetryCount < 1) {
            self.streamRetryCount++;
            [DiagnosticLog log:@"large Claude stream failed before first event: retrying stream once"];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.streaming && self.stream == nil) [self launchRequestStreaming:self.attemptIsStreaming];
            });
            return;
        }
        if (!largeClaudeReply) {
            [DiagnosticLog log:@"live stream failed before any text: retrying once as a single request"];
            [self launchRequestStreaming:NO];
            return;
        }
    }

    [self stopDeltaFlushTimer];
    self.stream = nil;
    self.streamBuffer = nil;
    self.streaming = NO;

    NSString *completeReply = self.longReplyAccumulator.length > 0
        ? [self.longReplyAccumulator stringByAppendingString:(partial ?: @"")]
        : partial;
    NSArray *generatedAttachments = [self.streamGeneratedAttachments copy] ?: @[];
    if (completeReply.length > 0 || generatedAttachments.count > 0) {
        [self appendAssistantMessage:completeReply attachments:generatedAttachments];
    }
    self.longReplyAccumulator = nil;
    self.longReplyContinuationCount = 0;
    self.earlyEndContinuations = 0;
    self.streamGeneratedAttachments = nil;
    [self callJS:@"end" args:@[(completeReply ?: @"")]];
    if (generatedAttachments.count > 0) [self renderConversation];
    if ([detail isEqualToString:kStreamEndedEarlyMarker]) detail = @"Kết nối bị ngắt khi AI đang trả lời. Phần đã nhận được giữ lại; gửi 'tiếp tục' để lấy phần còn lại.";
    if ([detail hasPrefix:@"Đã đạt giới hạn an toàn của chuỗi tự nối tiếp."]) {
        [self callJS:@"error" args:@[detail, @YES]];
    } else if (error != GeminiStreamErrorNone && error != GeminiStreamErrorCancelled) {
        [self callJS:@"error" args:@[[self messageForError:error status:status detail:detail], @YES]];
    }
    [self updateSendButton];
    [self unlockWebViewScrolling];
}

- (void)appendAssistantMessage:(NSString *)text {
    [self appendAssistantMessage:text attachments:@[]];
}

- (void)appendAssistantMessage:(NSString *)text attachments:(NSArray *)attachments {
    NSMutableDictionary *message = [@{ @"role": @"model", @"text": text ?: @"",
                                        @"ts": @([[NSDate date] timeIntervalSince1970]) } mutableCopy];
    if (attachments.count > 0) message[@"attachments"] = attachments;
    NSMutableArray *messages = self.conversation[@"messages"];
    [messages addObject:message];
    self.conversation[@"updated"] = @([[NSDate date] timeIntervalSince1970]);
    [ConversationStore saveConversation:self.conversation];
    [self refreshPinnedSidebar];
}

- (void)abandonStream {
    if (!self.stream) return;
    [self stopDeltaFlushTimer];
    NSString *partial = [self.streamBuffer copy] ?: @"";
    NSString *completeReply = self.longReplyAccumulator.length > 0
        ? [self.longReplyAccumulator stringByAppendingString:partial]
        : partial;
    id<ChatStreaming> old = self.stream;
    old.onDelta = nil;
    old.onFinish = nil;
    self.stream = nil;
    self.streamBuffer = nil;
    self.streaming = NO;
    [old cancel];
    NSArray *generatedAttachments = [self.streamGeneratedAttachments copy] ?: @[];
    if (completeReply.length > 0 || generatedAttachments.count > 0) [self appendAssistantMessage:completeReply attachments:generatedAttachments];
    self.longReplyAccumulator = nil;
    self.longReplyContinuationCount = 0;
    self.earlyEndContinuations = 0;
    self.streamGeneratedAttachments = nil;
    [self updateSendButton];
}

- (void)editMessageAtIndex:(NSInteger)index {
    if (self.streaming || !self.webReady) return;
    NSMutableArray *messages = self.conversation[@"messages"];
    if (index < 0 || index >= (NSInteger)messages.count) return;
    NSDictionary *target = messages[(NSUInteger)index];
    if (![target[@"role"] isEqualToString:@"user"]) return;

    NSString *cid = self.conversation[@"id"];
    for (NSDictionary *att in self.pendingAttachments) [AttachmentStore deleteAttachment:att conversation:cid];
    [self.pendingAttachments removeAllObjects];

    NSString *text = [target[@"text"] isKindOfClass:[NSString class]] ? target[@"text"] : @"";
    NSArray *attachments = [target[@"attachments"] isKindOfClass:[NSArray class]] ? [target[@"attachments"] copy] : @[];

    for (NSInteger i = (NSInteger)messages.count - 1; i >= index; i--) {
        if (i != index) {
            NSArray *laterAttachments = [messages[(NSUInteger)i][@"attachments"] isKindOfClass:[NSArray class]]
                ? messages[(NSUInteger)i][@"attachments"] : @[];
            for (NSDictionary *att in laterAttachments) [AttachmentStore deleteAttachment:att conversation:cid];
        }
    }
    [messages removeObjectsInRange:NSMakeRange((NSUInteger)index, messages.count - (NSUInteger)index)];
    [self.pendingAttachments addObjectsFromArray:attachments];

    self.conversation[@"updated"] = @([[NSDate date] timeIntervalSince1970]);
    [ConversationStore saveConversation:self.conversation];
    [self refreshPinnedSidebar];
    [self renderConversation];
    [self refreshAttachStrip];
    self.textView.text = text;
    [self textViewDidChange:self.textView];
    [self updateSendButton];
    [self.textView becomeFirstResponder];
}

- (void)regenerate {
    if (self.streaming || !self.webReady) return;
    NSMutableArray *messages = self.conversation[@"messages"];
    if ([messages.lastObject[@"role"] isEqualToString:@"model"]) [messages removeLastObject];
    if (![messages.lastObject[@"role"] isEqualToString:@"user"]) return;
    self.conversation[@"updated"] = @([[NSDate date] timeIntervalSince1970]);
    [ConversationStore saveConversation:self.conversation];
    [self refreshPinnedSidebar];
    [self renderConversation];
    [self startStreamingReply];
}

#pragma mark - Error text

- (NSString *)messageForError:(GeminiStreamError)error status:(NSInteger)status detail:(NSString *)detail {
    NSString *base = nil;
    BOOL showDetail = NO;
    BOOL viaGoogle = self.model.length > 0 && [Provider forModelId:self.model] == AIProviderGemini && [KeyStore geminiUsesGoogleAccount];
    switch (error) {
        case GeminiStreamErrorInvalidKey:       base = viaGoogle ? L(@"err_google_auth") : L(@"err_invalid_key"); break;
        case GeminiStreamErrorPermissionDenied: base = viaGoogle ? L(@"err_google_permission") : L(@"err_permission"); showDetail = YES; break;
        case GeminiStreamErrorModelNotFound:    base = L(@"err_model_not_found"); break;
        case GeminiStreamErrorRateLimited:      base = L(@"err_rate"); showDetail = YES; break;
        case GeminiStreamErrorNetwork:          base = L(@"err_network"); showDetail = YES; break;
        case GeminiStreamErrorBlocked:          base = L(@"err_blocked"); break;
        case GeminiStreamErrorEmptyReply:       base = L(@"err_empty_reply"); break;
        case GeminiStreamErrorTooLarge:         base = L(@"err_too_large"); break;
        case GeminiStreamErrorNoCredit:         base = L(@"err_no_credit"); break;
        case GeminiStreamErrorServer:
            base = [NSString stringWithFormat:L(@"err_server"), (long)status];
            showDetail = YES;
            break;
        default:
            base = [NSString stringWithFormat:L(@"err_unknown"), (long)status];
            showDetail = YES;
            break;
    }
    if (showDetail && detail.length > 0) {
        NSString *clipped = detail.length > 240 ? [[detail substringToIndex:240] stringByAppendingString:@"…"] : detail;
        base = [base stringByAppendingFormat:@"\n\n%@", [NSString stringWithFormat:L(@"err_detail"), clipped]];
    }
    return base;
}

@end
