#import "ChatViewController.h"
#import <WebKit/WebKit.h>
#import <PhotosUI/PhotosUI.h>
#import <AVFoundation/AVFoundation.h>
#import "Strings.h"
#import "Theme.h"
#import "KeyStore.h"
#import "GoogleAuth.h"
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
#import "UpdateManager.h"
#import "KeyTier.h"
#import "OfficeExport.h"
#import "VoiceChatManager.h"
#import <math.h>

static const CGFloat kMaxInputHeight = 120;
static const CGFloat kStripHeight = 64;
static const CGFloat kToolsRowHeight = 0;
static const NSUInteger kGreetingCount = 6;
static const NSUInteger kForceMaxContextChars = 4000000;
static const NSUInteger kFastChunkReadBytes = 4 * 1024 * 1024;

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

#pragma mark - Forward Declarations & Interfaces

@class ChatViewController;

@interface ChatViewController (VoiceIntegration)
@property (strong, nonatomic) VoiceChatManager *voiceManager;
@property (strong, nonatomic) UITextView *textView;
@property (assign, nonatomic) BOOL activeFullScreenVoice;
@property (assign, nonatomic) NSInteger activeVoiceStyleIndex;
- (void)textViewDidChange:(UITextView *)textView;
- (void)sendTapped;
- (void)speakLastAssistantMessage;
@end

#pragma mark - VoiceChatFullScreenViewController

@interface VoiceChatFullScreenViewController : UIViewController
@property (assign, nonatomic) NSInteger selectedVoiceIndex;
@property (strong, nonatomic) ChatViewController *chatController;
- (void)onAssistantStartedSpeaking:(NSString *)text;
- (void)onAssistantFinishedSpeaking;
@end

@implementation VoiceChatFullScreenViewController {
    UIView *_blueLightView1;
    UIView *_blueLightView2;
    UILabel *_statusLabel;
    UIButton *_micButton;
    BOOL _isListening;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:0.05 green:0.08 blue:0.15 alpha:1.0];
    [self setupMovingBlueLights];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(20, 50, 40, 40);
    [closeBtn setImage:[Theme iconClose] forState:UIControlStateNormal];
    closeBtn.tintColor = [UIColor whiteColor];
    [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeBtn];

    CGFloat screenW = CGRectGetWidth(self.view.bounds);
    CGFloat screenH = CGRectGetHeight(self.view.bounds);

    UIView *centerOrb = [[UIView alloc] initWithFrame:CGRectMake((screenW - 140)/2, (screenH - 140)/2 - 40, 140, 140)];
    centerOrb.layer.cornerRadius = 70;
    centerOrb.backgroundColor = [[UIColor colorWithRed:0.2 green:0.6 blue:1.0 alpha:0.3] colorWithAlphaComponent:0.4];
    centerOrb.layer.shadowColor = [UIColor colorWithRed:0.1 green:0.5 blue:1.0 alpha:1.0].CGColor;
    centerOrb.layer.shadowOpacity = 0.8;
    centerOrb.layer.shadowRadius = 30;
    centerOrb.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:centerOrb];

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.fromValue = @1.0;
    pulse.toValue = @1.15;
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    pulse.duration = 2.0;
    [centerOrb.layer addAnimation:pulse forKey:@"pulse"];

    _statusLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, CGRectGetMaxY(centerOrb.frame) + 30, screenW - 40, 60)];
    _statusLabel.text = @"Đang sẵn sàng trò chuyện...";
    _statusLabel.textColor = [UIColor whiteColor];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.numberOfLines = 2;
    _statusLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    [self.view addSubview:_statusLabel];

    _micButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _micButton.frame = CGRectMake((screenW - 80)/2, screenH - 120, 80, 80);
    _micButton.layer.cornerRadius = 40;
    _micButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0];
    [_micButton setImage:[Theme iconMicOfSize:36] forState:UIControlStateNormal];
    _micButton.tintColor = [UIColor whiteColor];
    [_micButton addTarget:self action:@selector(micButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_micButton];

    self.chatController.activeFullScreenVoice = YES;
    self.chatController.activeVoiceStyleIndex = self.selectedVoiceIndex;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self startVoiceSession];
    });
}

- (void)configureAudioSessionForPlayback:(BOOL)forPlayback {
    NSError *error = nil;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    AVAudioSessionCategoryOptions opts = AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:opts error:&error];
    [session setMode:(forPlayback ? AVAudioSessionModeDefault : AVAudioSessionModeMeasurement) error:&error];
    [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
}

- (void)setupMovingBlueLights {
    CGFloat screenW = CGRectGetWidth(self.view.bounds);
    CGFloat screenH = CGRectGetHeight(self.view.bounds);

    _blueLightView1 = [[UIView alloc] initWithFrame:CGRectMake(-50, -50, 300, 300)];
    _blueLightView1.layer.cornerRadius = 150;
    _blueLightView1.backgroundColor = [UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:0.35];
    _blueLightView1.clipsToBounds = YES;
    [self.view addSubview:_blueLightView1];

    _blueLightView2 = [[UIView alloc] initWithFrame:CGRectMake(screenW - 250, screenH - 250, 350, 350)];
    _blueLightView2.layer.cornerRadius = 175;
    _blueLightView2.backgroundColor = [UIColor colorWithRed:0.1 green:0.7 blue:0.9 alpha:0.3];
    [self.view addSubview:_blueLightView2];

    [UIView animateKeyframesWithDuration:8.0 delay:0 options:UIViewKeyframeAnimationOptionAutoreverse | UIViewKeyframeAnimationOptionRepeat animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
            self->_blueLightView1.frame = CGRectMake(screenW - 200, screenH / 3, 350, 350);
            self->_blueLightView2.frame = CGRectMake(50, 100, 300, 300);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            self->_blueLightView1.frame = CGRectMake(50, screenH - 300, 320, 320);
            self->_blueLightView2.frame = CGRectMake(screenW - 250, 80, 360, 360);
        }];
    } completion:nil];
}

- (void)closeTapped {
    self.chatController.activeFullScreenVoice = NO;
    if (self.chatController.voiceManager) {
        [self.chatController.voiceManager stopRecording];
        [self.chatController.voiceManager stopSpeaking];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onAssistantStartedSpeaking:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureAudioSessionForPlayback:YES];
        self->_isListening = NO;
        [self resetMicButtonState];
        self->_statusLabel.text = @"AI đang trả lời bằng giọng nói...";
    });
}

- (void)onAssistantFinishedSpeaking {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.view.window || !self.chatController.activeFullScreenVoice) return;
        [self startVoiceSession];
    });
}

- (void)startVoiceSession {
    if (!self.chatController.voiceManager) {
        self.chatController.voiceManager = [VoiceChatManager shared];
    }
    [self.chatController.voiceManager stopSpeaking];
    [self configureAudioSessionForPlayback:NO];

    _statusLabel.text = @"Đang lắng nghe...";
    _isListening = YES;
    _micButton.backgroundColor = [UIColor colorWithRed:0.9 green:0.2 blue:0.2 alpha:1.0];

    __weak typeof(self) weakSelf = self;
    [self.chatController.voiceManager requestAuthorization:^(BOOL granted) {
        if (!granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_statusLabel.text = @"Cần quyền microphone.";
                [self resetMicButtonState];
            });
            return;
        }
        [weakSelf.chatController.voiceManager startRecordingWithPartial:^(NSString *text) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (text.length > 0) {
                    self->_statusLabel.text = text;
                }
            });
        } final:^(NSString *text) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *clean = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if (clean.length > 0) {
                    self->_isListening = NO;
                    [weakSelf resetMicButtonState];
                    self->_statusLabel.text = [NSString stringWithFormat:@"Đã gửi: %@", clean];
                    [weakSelf sendVoiceTextToAI:clean];
                } else {
                    self->_statusLabel.text = @"Không nghe rõ, thử lại nhé.";
                    [weakSelf resetMicButtonState];
                }
            });
        } error:^(NSString *msg) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_statusLabel.text = msg ?: @"Lỗi ghi âm.";
                [weakSelf resetMicButtonState];
            });
        }];
    }];
}

- (void)micButtonTapped {
    if (_isListening) {
        [self.chatController.voiceManager stopRecording];
        _isListening = NO;
        [self resetMicButtonState];
        _statusLabel.text = @"Đã tạm dừng mic. Nhấn để nói tiếp.";
    } else {
        [self startVoiceSession];
    }
}

- (void)resetMicButtonState {
    _isListening = NO;
    _micButton.backgroundColor = [UIColor colorWithRed:0.1 green:0.5 blue:0.9 alpha:1.0];
}

- (void)sendVoiceTextToAI:(NSString *)text {
    [self.chatController.voiceManager stopRecording];
    [self configureAudioSessionForPlayback:YES];
    self.chatController.activeFullScreenVoice = YES;
    self.chatController.activeVoiceStyleIndex = self.selectedVoiceIndex;
    _statusLabel.text = @"AI đang suy nghĩ...";
    self.chatController.textView.text = text;
    [self.chatController textViewDidChange:self.chatController.textView];
    [self.chatController sendTapped];
}

@end

#pragma mark - ChatViewController

@interface ChatViewController () <WKNavigationDelegate, ScriptMessageTarget, UITextViewDelegate,
                                  UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIDocumentPickerDelegate,
                                  PHPickerViewControllerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>
@property (strong, nonatomic) UIView *chatStageView;
@property (strong, nonatomic) WKWebView *webView;
@property (assign, nonatomic) BOOL webReady;
@property (copy, nonatomic) NSString *lastWebError;
@property (nonatomic, strong) dispatch_queue_t jsSerializationQueue;
@property (assign, nonatomic) BOOL historyDrawerOpen;
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
@property (strong, nonatomic) UIButton *sendButton;
@property (strong, nonatomic) VoiceChatManager *voiceManager;
@property (assign, nonatomic) BOOL voiceRecording;
@property (assign, nonatomic) BOOL activeFullScreenVoice;
@property (assign, nonatomic) NSInteger activeVoiceStyleIndex;
@property (assign, nonatomic) BOOL lastWasStreaming;
@property (strong, nonatomic) UIButton *modelButton;
@property (assign, nonatomic) BOOL pendingModelPopup;
@property (assign, nonatomic) BOOL pendingModelPopupIntro;
@property (strong, nonatomic) UIImageView *wallpaperView;
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
    self.jsSerializationQueue = dispatch_queue_create("com.app.chat.jsserialization", DISPATCH_QUEUE_SERIAL);

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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"native"];
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

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [Theme darkMode] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

#pragma mark - History Drawer

static const CGFloat kDrawerWidthRatio = 0.62;

- (CGFloat)historyDrawerWidth {
    CGFloat w = self.view.bounds.size.width;
    return MIN(floor(w * kDrawerWidthRatio), 320.0);
}

- (void)setupHistoryDrawer {
    self.historyDrawerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.historyDrawerView.backgroundColor = [Theme surface];
    self.historyDrawerView.layer.borderWidth = 1.0;
    self.historyDrawerView.layer.borderColor = [Theme border].CGColor;
    self.historyDrawerView.clipsToBounds = YES;
    self.historyDrawerView.hidden = YES;
    [self.view addSubview:self.historyDrawerView];

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
    self.historyTableView.backgroundColor = [UIColor clearColor];
    self.historyTableView.separatorColor = [Theme border];
    self.historyTableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
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

    self.historyUpdateDot = [[UIView alloc] initWithFrame:CGRectZero];
    self.historyUpdateDot.userInteractionEnabled = NO;
    self.historyUpdateDot.backgroundColor = [Theme accent];
    self.historyUpdateDot.layer.cornerRadius = 6;
    self.historyUpdateDot.layer.borderWidth = 2;
    self.historyUpdateDot.layer.borderColor = [Theme background].CGColor;
    self.historyUpdateDot.hidden = ![UpdateManager shared].updateAvailable;
    [self.historySettingsBadge addSubview:self.historyUpdateDot];

    self.chatRightOverlayButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.chatRightOverlayButton.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.14];
    self.chatRightOverlayButton.hidden = YES;
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

- (CGPoint)chatStageCenterOpen:(BOOL)open {
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    return CGPointMake(w / 2.0 + (open ? [self historyDrawerWidth] : 0), h / 2.0);
}

- (void)historyTapped {
    [self.view endEditing:YES];
    if (self.historyDrawerOpen) {
        [self closeHistoryDrawer];
        return;
    }
    [self reloadHistoryItems];
    self.historyDrawerOpen = YES;
    self.historyDrawerAnimating = YES;
    self.historyDrawerView.hidden = NO;
    self.chatRightOverlayButton.hidden = NO;
    self.chatRightOverlayButton.alpha = 0;
    [self.view bringSubviewToFront:self.historyDrawerView];
    [self callJS:@"setDrawer" args:@[@YES]];

    CGFloat h = self.view.bounds.size.height;
    CGFloat drawerW = [self historyDrawerWidth];
    if (CGRectGetMaxX(self.historyDrawerView.frame) <= 0 || self.historyDrawerView.frame.size.width != drawerW) {
        self.historyDrawerView.frame = CGRectMake(-drawerW, 0, drawerW, h);
        [self layoutHistoryDrawerSubviews];
    }
    [UIView animateWithDuration:0.36 delay:0 usingSpringWithDamping:0.95 initialSpringVelocity:0.1
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        self.historyDrawerView.frame = CGRectMake(0, 0, drawerW, h);
        self.chatStageView.center = [self chatStageCenterOpen:YES];
        self.chatRightOverlayButton.alpha = 1;
    } completion:^(BOOL finished) {
        self.historyDrawerAnimating = NO;
    }];
}

- (void)closeHistoryDrawer {
    if (!self.historyDrawerOpen) return;
    [self.view endEditing:YES];
    self.historyDrawerOpen = NO;
    self.historyDrawerAnimating = YES;
    [self callJS:@"setDrawer" args:@[@NO]];

    CGFloat h = self.view.bounds.size.height;
    CGFloat drawerW = [self historyDrawerWidth];
    [UIView animateWithDuration:0.30 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction animations:^{
        self.historyDrawerView.frame = CGRectMake(-drawerW, 0, drawerW, h);
        self.chatStageView.center = [self chatStageCenterOpen:NO];
        self.chatRightOverlayButton.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.historyDrawerOpen) return;
        self.historyDrawerAnimating = NO;
        self.historyDrawerView.hidden = YES;
        self.chatRightOverlayButton.hidden = YES;
        self.chatRightOverlayButton.alpha = 1;
    }];
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

    CGFloat rowH = 38;
    CGFloat closeSize = rowH;
    CGFloat sideGap = 12;
    self.historyCloseXButton.frame = CGRectMake(dw - sideGap - closeSize, topPad, closeSize, closeSize);
    self.historyCloseXButton.layer.cornerRadius = closeSize / 2.0;
    self.historySearchWrap.frame = CGRectMake(sideGap, topPad, MAX(60, dw - sideGap * 2 - closeSize - 8), rowH);
    CGFloat sw = self.historySearchWrap.bounds.size.width;
    self.historySearchIcon.frame = CGRectMake(10, (rowH - 16) / 2.0, 16, 16);
    self.historySearchField.frame = CGRectMake(32, 0, MAX(20, sw - 32 - 8), rowH);

    CGFloat settingsH = 52;
    CGFloat settingsY = dh - bottomPad - settingsH;
    self.historySettingsButton.hidden = keyboardUp;
    self.historySettingsButton.frame = CGRectMake(sideGap, settingsY, dw - sideGap * 2, settingsH);
    CGFloat bw = self.historySettingsButton.bounds.size.width;
    self.historySettingsBadge.frame = CGRectMake(10, (settingsH - 32) / 2.0, 32, 32);
    self.historySettingsIcon.frame = self.historySettingsBadge.bounds;
    self.historyUpdateDot.frame = CGRectMake(32 - 10, -4, 12, 12);
    self.historySettingsChevron.frame = CGRectMake(bw - 12 - 20, (settingsH - 20) / 2.0, 20, 20);
    self.historySettingsLabel.frame = CGRectMake(10 + 32 + 10, 0, MAX(20, bw - (10 + 32 + 10) - 36), settingsH);

    CGFloat listTop = topPad + rowH + 10;
    CGFloat listBottom = keyboardUp ? (dh - self.keyboardOverlap - 8) : (settingsY - 10);
    self.historyTableView.frame = CGRectMake(0, listTop, dw, MAX(60, listBottom - listTop));
    self.historyEmptyLabel.frame = CGRectMake(16, listTop + 24, dw - 32, 44);
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
    self.inputBox.layer.cornerRadius = 22;
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

    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
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
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    CGFloat drawerW = [self historyDrawerWidth];

    self.chatStageView.bounds = CGRectMake(0, 0, w, h);
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

    self.webView.frame = CGRectMake(0, 0, width, CGRectGetMinY(self.inputBar.frame));
    self.wallpaperView.frame = self.webView.frame;
    self.dimView.frame = self.wallpaperView.bounds;
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
    card.layer.cornerRadius = 25.0;
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
    self.reasoningFastHintLabel.text = @"Mức thấp ưu tiên tốc độ phản hồi cực nhanh; mức cao/MAX ×8 ép suy nghĩ sâu và chi tiết tối đa.";
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
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"@ Công cụ" message:@"Chọn tác vụ hoặc tích hợp" preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    NSArray *recent = self.conversation[@"messages"];
    NSString *lastReply = nil;
    for (NSInteger i = (NSInteger)recent.count - 1; i >= 0; i--) {
        NSDictionary *message = recent[(NSUInteger)i];
        if (![message[@"role"] isEqualToString:@"user"] && [message[@"text"] isKindOfClass:[NSString class]] && [message[@"text"] length] > 0) { lastReply = message[@"text"]; break; }
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Tạo tệp TXT" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *source = lastReply.length > 0 ? lastReply : [weakSelf trimmedInput];
        if (source.length > 0) [weakSelf exportText:source asWord:NO];
        else [weakSelf showAlertMessage:@"Hãy nhập nội dung hoặc tạo câu trả lời trước khi xuất tệp TXT."];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Tạo tệp DOCX" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *source = lastReply.length > 0 ? lastReply : [weakSelf trimmedInput];
        if (source.length > 0) [weakSelf exportText:source asWord:YES];
        else [weakSelf showAlertMessage:@"Hãy nhập nội dung hoặc tạo câu trả lời trước khi xuất tệp DOCX."];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Chọn tệp để đính kèm…" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [weakSelf attachTapped];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"/tạo ảnh" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        weakSelf.textView.text = @"/tạo ảnh ";
        [weakSelf textViewDidChange:weakSelf.textView];
        [weakSelf.textView becomeFirstResponder];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:[AppSettings webSearchEnabled] ? @"Tắt tìm kiếm web" : @"Bật tìm kiếm web" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) { [weakSelf searchTapped]; }]];
    NSArray *external = @[@"Gmail", @"Google Calendar", @"Google Docs", @"Google Drive", @"Google Home", @"Google Keep", @"Google Photos", @"Google Sheets", @"Google Tasks"];
    for (NSString *name in external) {
        [sheet addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [weakSelf showAlertMessage:[NSString stringWithFormat:@"%@ cần kết nối OAuth/API riêng. Phiên bản này chưa có thông tin xác thực để truy cập tài khoản.", name]];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.mentionButton;
    sheet.popoverPresentationController.sourceRect = self.mentionButton.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)updateDailyTokenPrompt {
    self.navigationItem.prompt = nil;
}

- (void)relayoutAnimated {
    [self.view setNeedsLayout];
    [UIView animateWithDuration:0.15 animations:^{ [self.view layoutIfNeeded]; }];
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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    UIViewController *top = self;
    while (top.presentedViewController) top = top.presentedViewController;
    [top presentViewController:alert animated:YES completion:nil];
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
    return [NSString stringWithFormat:
            @":root{--uiscale:%.3f;}"
             "html{font-size:calc(16px * var(--uiscale)) !important;}"
             "body,#chat,.chat,.messages,#messages,.msg,.msg-row,.msg-wrap,.msg-text,.msg-content,.markdown,.markdown-body,pre,code,table,blockquote,p,li{font-size:calc(16px * var(--uiscale)) !important;line-height:1.45 !important;}"
             ".msg,.bubble,.message,.msg-bubble{max-width:%.1f%% !important;padding:calc(10px * var(--uiscale)) calc(14px * var(--uiscale)) !important;border-radius:calc(14px * var(--uiscale)) !important;}",
            clamped, bubbleMaxW];
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
    css = [css stringByAppendingFormat:@"\n:root{--serif:%@;}", [self serifCSSValue]];
    css = [css stringByAppendingFormat:@"\n%@", [self scaleCSSRuleForScale:scale]];
    html = [html stringByReplacingOccurrencesOfString:@"{{CSS}}" withString:css];
    html = [html stringByReplacingOccurrencesOfString:@"{{JS}}" withString:js];
    [self.webView loadHTMLString:html baseURL:nil];
}

- (void)callJS:(NSString *)function args:(NSArray *)args {
    if (!self.webReady) return;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:args options:0 error:nil];
    } @catch (NSException *exception) {
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
    // Tăng lên 50ms để giảm tải cho Main Thread, vẫn đủ mượt
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC), 50 * NSEC_PER_MSEC, 10 * NSEC_PER_MSEC);
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

    // Đẩy việc xử lý chuỗi sang Background Queue để không làm nghẽn Main Thread
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.jsSerializationQueue, ^{
        NSData *data = nil;
        @try {
            data = [NSJSONSerialization dataWithJSONObject:@[chunk] options:0 error:nil];
        } @catch (NSException *exception) {
            [DiagnosticLog log:@"flushPendingJSDelta skipped: %@", exception.reason];
            return;
        }
        if (!data) return;
        
        NSString *json = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        json = [json stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
        json = [json stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
        NSString *script = [NSString stringWithFormat:@"ChatUI.delta.apply(null,%@);", json];

        // Quay lại Main Thread để thực thi JS trên WebView
        dispatch_async(dispatch_get_main_queue(), ^{
            ChatViewController *strongSelf = weakSelf;
            if (strongSelf && strongSelf.webReady) {
                [strongSelf.webView evaluateJavaScript:script completionHandler:nil];
            }
        });
    });
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
        [self.historyTableView reloadData];
    }

    UIImage *wallpaper = [Theme wallpaperImage];
    self.wallpaperView.image = wallpaper;
    self.wallpaperView.hidden = (wallpaper == nil);
    self.dimView.backgroundColor = [UIColor colorWithWhite:0 alpha:[Theme wallpaperDimAlpha]];
    self.webView.scrollView.indicatorStyle = [Theme darkMode] ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;

    [self.modelButton setTitleColor:[Theme text] forState:UIControlStateNormal];
    [self updateModelTitle];
    self.inputBar.backgroundColor = [Theme background];
    [self.inputBar viewWithTag:1001].backgroundColor = [Theme border];
    self.inputBox.backgroundColor = [Theme surface];
    self.inputBox.layer.borderColor = [Theme border].CGColor;
    self.attachButton.tintColor = [Theme secondaryText];
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
                                          @"thinking": ([AppSettings reasoningLevel] >= AIReasoningLevelHigh) ? @"Đang suy luận sâu…" : @"Đang xử lý siêu tốc…" }]];
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

// iOS can kill the web view's process while a long reply streams in (memory). The page is then rebuilt, and without this
// the reply that is still being generated would no longer be shown (the chat looks frozen). Show it again from what has
// been received so far; the rest keeps streaming in as usual.
- (void)restoreStreamingUIIfNeeded {
    if (!self.streaming) return;
    NSMutableString *soFar = [NSMutableString string];
    if (self.longReplyAccumulator.length > 0) [soFar appendString:self.longReplyAccumulator];
    if (self.streamBuffer.length > 0) [soFar appendString:self.streamBuffer];
    [self.pendingJSDelta setString:@""];   // anything still pending is already inside soFar
    [self callJS:@"begin" args:@[]];
    if (soFar.length > 0) [self callJS:@"delta" args:@[soFar]];
    [DiagnosticLog log:@"chat page rebuilt during a reply: restored %lu chars", (unsigned long)soFar.length];
}

- (void)revealWebView {
    if (self.webView.alpha >= 1.0) return;
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
        [self restoreStreamingUIIfNeeded];
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
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:L(@"export_file")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"export_txt") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf exportText:text asWord:NO];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"export_docx") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [weakSelf exportText:text asWord:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    sheet.popoverPresentationController.sourceView = self.view;
    sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - 80, 1, 1);
    [self presentViewController:sheet animated:YES completion:nil];
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
    [DiagnosticLog log:@"web content process was terminated by iOS: reloading the page"];
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
    if ([self topPresentedController] != self) return;
    BOOL hasContent = [self.conversation[@"messages"] count] > 0 || self.pendingAttachments.count > 0;
    if (!hasContent) {
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
    [self resetWebScrollToTop];
    self.chatIsEmpty = YES;
    [self callJS:@"clear" args:@[]];
    [self updateSendButton];
    [self unlockWebViewScrolling];
    [self reassertEmptyLockSoon];
}

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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(80 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [self unlockWebViewScrolling];
    });
}

#pragma mark - Input

- (void)textViewDidChange:(UITextView *)textView {
    self.placeholderLabel.hidden = textView.text.length > 0;
    [self updateSendButton];
    [self relayoutAnimated];
}

- (NSString *)trimmedInput {
    return [self.textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)micTapped {
    if (self.streaming || self.voiceRecording) return;
    [self showVoiceSelectionPopup];
}

- (void)updateSendButton {
    BOOL hasContent = [self trimmedInput].length > 0 || self.pendingAttachments.count > 0;
    BOOL canSend = hasContent && self.webReady && self.importsInFlight == 0;
    if (self.streaming) {
        [self.sendButton setImage:[Theme iconStop] forState:UIControlStateNormal];
        self.sendButton.backgroundColor = [Theme accent];
    } else if (self.voiceRecording) {
        [self.sendButton setImage:[Theme iconStop] forState:UIControlStateNormal];
        self.sendButton.backgroundColor = [UIColor colorWithRed:0.85 green:0.20 blue:0.20 alpha:1.0];
    } else {
        [self.sendButton setImage:[Theme iconSend] forState:UIControlStateNormal];
        self.sendButton.backgroundColor = canSend ? [Theme accent] : [Theme accentDisabled];
    }
    self.sendButton.enabled = self.streaming || self.voiceRecording || canSend;
    BOOL micAvailable = !self.streaming && !self.voiceRecording;
    self.micButton.enabled = micAvailable;
    self.micButton.alpha = micAvailable ? 1.0 : 0.4;
    self.micButton.tintColor = [Theme text];
    self.attachButton.enabled = !self.streaming;
    self.attachButton.alpha = self.streaming ? 0.4 : 1.0;
    if (self.lastWasStreaming && !self.streaming) {
        if (self.activeFullScreenVoice) {
            [self speakLastAssistantMessage];
        }
    }
    self.lastWasStreaming = self.streaming;
}

- (NSString *)serifCSSValue {
    return [AppSettings fontStyle] == 1 ? @"-apple-system, \"Helvetica Neue\", Helvetica, sans-serif" : @"Georgia, \"Times New Roman\", serif";
}

- (void)applyUIScaleToNativeAndWeb {
    CGFloat sc = [AppSettings uiScale];
    NSString *sig = [NSString stringWithFormat:@"%.3f|%ld", sc, (long)[AppSettings fontStyle]];
    if (![sig isEqualToString:self.appliedNativeScaleSig]) {
        self.appliedNativeScaleSig = sig;
        self.textView.font = [UIFont systemFontOfSize:17.0 * sc];
        self.placeholderLabel.font = [UIFont systemFontOfSize:17.0 * sc];
        [self.view setNeedsLayout];
    }

    if (!self.webReady || !self.webView) return;
    if ([sig isEqualToString:self.appliedWebScaleSig]) return;
    self.appliedWebScaleSig = sig;
    NSData *fontData = [NSJSONSerialization dataWithJSONObject:@[[self serifCSSValue]] options:0 error:nil];
    NSString *fontJSON = fontData ? [[NSString alloc] initWithData:fontData encoding:NSUTF8StringEncoding] : @"[\"Georgia, serif\"]";
    NSData *cssData = [NSJSONSerialization dataWithJSONObject:@[[self scaleCSSRuleForScale:sc]] options:0 error:nil];
    NSString *cssJSON = cssData ? [[NSString alloc] initWithData:cssData encoding:NSUTF8StringEncoding] : @"[\"\"]";
    NSString *script = [NSString stringWithFormat:
                        @"(function(){"
                         "document.documentElement.style.setProperty('--serif',(%@)[0]);"
                         "var el=document.getElementById('uiscale_live_css');"
                         "if(!el){el=document.createElement('style');el.id='uiscale_live_css';document.head.appendChild(el);}"
                         "el.textContent=(%@)[0];"
                         "})();", fontJSON, cssJSON];
    [self.webView evaluateJavaScript:script completionHandler:nil];
}

- (void)uiScaleChanged:(NSNotification *)note {
    [self updateModelTitle];
    [self applyUIScaleToNativeAndWeb];
}

#pragma mark - Voice chat & Voice Selection Popup

- (void)showVoiceSelectionPopup {
    if ([self.view viewWithTag:9988]) return;

    CGFloat screenW = CGRectGetWidth(self.view.bounds);

    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.tag = 9988;
    overlay.backgroundColor = [UIColor clearColor];

    UIButton *dismissBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    dismissBtn.frame = overlay.bounds;
    [dismissBtn addTarget:self action:@selector(dismissVoicePopup) forControlEvents:UIControlEventTouchUpInside];
    [overlay addSubview:dismissBtn];

    CGFloat menuW = 230;
    CGFloat menuH = 170;
    CGFloat bottomBarY = CGRectGetMinY(self.inputBar.frame);
    CGFloat startX = screenW - 12 - 36 - menuW;
    CGFloat startY = bottomBarY - menuH - 8;

    UIView *menuCard = [[UIView alloc] initWithFrame:CGRectMake(screenW - 12 - 36, startY + menuH/2, 0, 0)];
    menuCard.tag = 9989;
    menuCard.backgroundColor = [Theme surface];
    menuCard.layer.cornerRadius = 16;
    menuCard.layer.borderWidth = 1;
    menuCard.layer.borderColor = [Theme border].CGColor;
    menuCard.clipsToBounds = YES;
    menuCard.layer.shadowColor = [UIColor blackColor].CGColor;
    menuCard.layer.shadowOpacity = 0.25;
    menuCard.layer.shadowRadius = 12;
    menuCard.layer.shadowOffset = CGSizeMake(-4, 4);
    [overlay addSubview:menuCard];

    UILabel *titleLbl = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, menuW - 32, 24)];
    titleLbl.text = @"Chọn giọng nói AI";
    titleLbl.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    titleLbl.textColor = [Theme text];
    [menuCard addSubview:titleLbl];

    NSArray *voices = @[@"1. Giọng nữ tự nhiên", @"2. Giọng nam trầm ấm", @"3. Giọng biểu cảm"];
    CGFloat rowY = 42;
    for (NSInteger i = 0; i < voices.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.frame = CGRectMake(12, rowY, menuW - 24, 36);
        btn.backgroundColor = [Theme background];
        btn.layer.cornerRadius = 8;
        [btn setTitle:voices[i] forState:UIControlStateNormal];
        [btn setTitleColor:[Theme text] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
        btn.tag = 100 + i;
        [btn addTarget:self action:@selector(voiceOptionSelected:) forControlEvents:UIControlEventTouchUpInside];
        [menuCard addSubview:btn];
        rowY += 40;
    }

    [self.view addSubview:overlay];

    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.75 initialSpringVelocity:0.6 options:UIViewAnimationOptionCurveEaseOut animations:^{
        menuCard.frame = CGRectMake(startX, startY, menuW, menuH);
    } completion:nil];
}

- (void)dismissVoicePopup {
    UIView *overlay = [self.view viewWithTag:9988];
    if (!overlay) return;
    UIView *menuCard = [overlay viewWithTag:9989];
    [UIView animateWithDuration:0.20 animations:^{
        menuCard.alpha = 0;
        menuCard.transform = CGAffineTransformMakeScale(0.7, 0.7);
        overlay.alpha = 0;
    } completion:^(BOOL finished) {
        [overlay removeFromSuperview];
    }];
}

- (void)voiceOptionSelected:(UIButton *)sender {
    NSInteger voiceIndex = sender.tag - 100;
    [self dismissVoicePopup];
    [self presentFullScreenVoiceChatWithVoiceIndex:voiceIndex];
}

- (void)presentFullScreenVoiceChatWithVoiceIndex:(NSInteger)voiceIndex {
    VoiceChatFullScreenViewController *vc = [[VoiceChatFullScreenViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    vc.selectedVoiceIndex = voiceIndex;
    vc.chatController = self;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)speakLastAssistantMessage {
    NSArray *msgs = self.conversation[@"messages"];
    if (![msgs isKindOfClass:[NSArray class]]) return;
    for (NSInteger i = (NSInteger)msgs.count - 1; i >= 0; i--) {
        id m = msgs[(NSUInteger)i];
        if (![m isKindOfClass:[NSDictionary class]]) continue;
        NSDictionary *msgDict = (NSDictionary *)m;
        NSString *role = msgDict[@"role"];
        if ([role isEqualToString:@"model"] || [role isEqualToString:@"assistant"]) {
            NSString *text = [msgDict[@"text"] isKindOfClass:[NSString class]] ? msgDict[@"text"] : nil;
            if (text.length == 0) {
                id content = msgDict[@"content"];
                if ([content isKindOfClass:[NSString class]]) text = content;
                else if ([content isKindOfClass:[NSArray class]]) text = [(NSArray *)content componentsJoinedByString:@" "];
            }
            if (text.length > 0) {
                if (!self.voiceManager) self.voiceManager = [VoiceChatManager shared];
                [self.voiceManager stopRecording];

                NSError *err = nil;
                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setCategory:AVAudioSessionCategoryPlayAndRecord
                          withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                                error:&err];
                [session setMode:AVAudioSessionModeDefault error:&err];
                [session setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&err];

                VoiceChatFullScreenViewController *voiceVC = [self.presentedViewController isKindOfClass:[VoiceChatFullScreenViewController class]]
                    ? (VoiceChatFullScreenViewController *)self.presentedViewController : nil;
                [voiceVC onAssistantStartedSpeaking:text];

                NSString *spoken = text.length > 2500 ? [text substringToIndex:2500] : text;
                SEL speakWithStyleSel = NSSelectorFromString(@"speak:voiceIndex:completion:");
                SEL speakWithCompletionSel = NSSelectorFromString(@"speak:completion:");
                if ([self.voiceManager respondsToSelector:speakWithStyleSel]) {
                    NSMethodSignature *sig = [self.voiceManager methodSignatureForSelector:speakWithStyleSel];
                    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                    [inv setTarget:self.voiceManager];
                    [inv setSelector:speakWithStyleSel];
                    NSInteger style = self.activeVoiceStyleIndex;
                    void (^done)(void) = ^{
                        [voiceVC onAssistantFinishedSpeaking];
                    };
                    [inv setArgument:&spoken atIndex:2];
                    [inv setArgument:&style atIndex:3];
                    [inv setArgument:&done atIndex:4];
                    [inv invoke];
                } else if ([self.voiceManager respondsToSelector:speakWithCompletionSel]) {
                    NSMethodSignature *sig = [self.voiceManager methodSignatureForSelector:speakWithCompletionSel];
                    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
                    [inv setTarget:self.voiceManager];
                    [inv setSelector:speakWithCompletionSel];
                    void (^done)(void) = ^{
                        [voiceVC onAssistantFinishedSpeaking];
                    };
                    [inv setArgument:&spoken atIndex:2];
                    [inv setArgument:&done atIndex:3];
                    [inv invoke];
                } else {
                    [self.voiceManager speak:spoken];
                    if (voiceVC) {
                        NSTimeInterval approxDuration = MAX(2.0, MIN(30.0, (double)spoken.length * 0.065));
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(approxDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            [voiceVC onAssistantFinishedSpeaking];
                        });
                    }
                }
            }
            return;
        }
    }
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
    [UIView animateWithDuration:0.16 animations:^{
        self.toolMenuCard.alpha = 0.0;
        self.toolMenuCard.transform = CGAffineTransformMakeTranslation(0, 12);
        self.toolMenuOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
    } completion:^(BOOL finished) {
        [self.toolMenuOverlay removeFromSuperview];
        self.toolMenuOverlay = nil;
        self.toolMenuCard = nil;
    }];
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
    row.layer.cornerRadius = 13;
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
    self.toolMenuCard.layer.cornerRadius = 22.0;
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

    [self callJS:@"addUser" args:@[text, [self webAttachmentsFrom:attachments conversation:cid], @([messages count] - 1)]];
    [self.pendingAttachments removeAllObjects];
    [self refreshAttachStrip];
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

#pragma mark - Request contents (High-speed chunked reader for huge files)

- (NSString *)decodeChunkToString:(NSData *)data {
    if (data.length == 0) return @"";
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!str) {
        // Cắt bớt 1-3 byte cuối nếu cắt trúng ký tự UTF-8 nhiều byte
        NSUInteger trim = MIN((NSUInteger)3, data.length);
        for (NSUInteger i = 1; i <= trim; i++) {
            NSData *sub = [data subdataWithRange:NSMakeRange(0, data.length - i)];
            str = [[NSString alloc] initWithData:sub encoding:NSUTF8StringEncoding];
            if (str) break;
        }
    }
    if (!str) {
        str = [[NSString alloc] initWithData:data encoding:NSISOLatin1StringEncoding];
    }
    return str ?: @"";
}

- (NSString *)readMassiveTextAtPath:(NSString *)path maxChars:(NSUInteger)maxChars {
    if (path.length == 0 || maxChars == 0) return nil;
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fh) return nil;

    unsigned long long fileSize = [fh seekToEndOfFile];
    if (fileSize == 0) {
        [fh closeFile];
        return nil;
    }

    NSUInteger targetBytes = MIN(maxChars * 3, (NSUInteger)6 * 1024 * 1024);
    if (fileSize <= targetBytes) {
        NSMutableString *out = [NSMutableString stringWithCapacity:(NSUInteger)fileSize];
        [fh seekToFileOffset:0];
        while (true) {
            NSData *chunk = [fh readDataOfLength:kFastChunkReadBytes];
            if (chunk.length == 0) break;
            NSString *part = [self decodeChunkToString:chunk];
            if (part.length > 0) [out appendString:part];
            if (out.length >= maxChars) break;
        }
        [fh closeFile];
        if (out.length > maxChars) {
            NSRange r = [out rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, maxChars)];
            return [out substringWithRange:r];
        }
        return out;
    }

    // Đọc chớp nhoáng theo từng chunk 4MB từ đầu và cuối file (hỗ trợ file từ vài MB tới hàng tỷ ký tự)
    NSUInteger halfBytes = MIN(targetBytes / 2, kFastChunkReadBytes);
    NSMutableString *headBuf = [NSMutableString stringWithCapacity:halfBytes];
    [fh seekToFileOffset:0];
    NSUInteger headRead = 0;
    while (headRead < halfBytes) {
        NSUInteger toRead = MIN(kFastChunkReadBytes, halfBytes - headRead);
        NSData *chunk = [fh readDataOfLength:toRead];
        if (chunk.length == 0) break;
        headRead += chunk.length;
        [headBuf appendString:[self decodeChunkToString:chunk]];
    }

    unsigned long long tailStart = fileSize > halfBytes ? (fileSize - halfBytes) : 0;
    [fh seekToFileOffset:tailStart];
    NSMutableString *tailBuf = [NSMutableString stringWithCapacity:halfBytes];
    while (true) {
        NSData *chunk = [fh readDataOfLength:kFastChunkReadBytes];
        if (chunk.length == 0) break;
        [tailBuf appendString:[self decodeChunkToString:chunk]];
        if (tailBuf.length >= maxChars / 2) break;
    }
    [fh closeFile];

    NSUInteger halfChars = MAX((NSUInteger)4096, maxChars / 2);
    NSString *headClean = headBuf;
    if (headClean.length > halfChars) {
        NSRange r = [headClean rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, halfChars)];
        headClean = [headClean substringWithRange:r];
    }
    NSString *tailClean = tailBuf;
    if (tailClean.length > halfChars) {
        NSUInteger start = tailClean.length - halfChars;
        NSRange r = [tailClean rangeOfComposedCharacterSequencesForRange:NSMakeRange(start, halfChars)];
        tailClean = [tailClean substringWithRange:r];
    }

    return [NSString stringWithFormat:@"%@\n\n[... ĐÃ NÉN/QUÉT NHANH %llu BYTES DỮ LIỆU ĐẦU + CUỐI ĐỂ ÉP TỐC ĐỘ XỬ LÝ TỨC THÌ ...]\n\n%@",
            headClean, fileSize, tailClean];
}

- (void)addPartsForAttachment:(NSDictionary *)att
                 conversation:(NSString *)cid
                    inlineIds:(NSSet *)inlineIds
                   charBudget:(NSUInteger *)charBudget
                           to:(NSMutableArray *)parts {
    if (![att isKindOfClass:[NSDictionary class]]) return;
    NSString *kind = att[@"kind"];
    NSString *name = [att[@"name"] isKindOfClass:[NSString class]] ? att[@"name"] : @"file";
    NSString *path = [AttachmentStore pathForFile:att[@"file"] conversation:cid];

    if ([kind isEqualToString:@"text"]) {
        NSUInteger allowed = (charBudget && *charBudget > 2048) ? (*charBudget - 1024) : 32768;
        NSString *content = [self readMassiveTextAtPath:path maxChars:allowed];
        if (charBudget && content.length > 0) {
            *charBudget = (*charBudget > content.length) ? (*charBudget - content.length) : 0;
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
                NSData *frameData = framePath ? [NSData dataWithContentsOfFile:framePath options:NSDataReadingMappedIfSafe error:nil] : nil;
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
        NSData *data = ([inlineIds containsObject:att[@"id"]] && path)
            ? [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil] : nil;
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

- (NSUInteger)resolvedContextCharLimit {
    NSUInteger contextLimit = MAX([AppSettings contextLimitChars], kForceMaxContextChars);
    AIProvider provider = [Provider forModelId:self.model];
    NSInteger inputTokenCap = [ModelStore maxInputTokensForModelId:self.model provider:provider];
    if (inputTokenCap > 0) {
        NSUInteger modelCharCap = (NSUInteger)inputTokenCap * 3;
        NSUInteger reservedChars = [self effectiveSystemPrompt].length + 8192;
        modelCharCap = modelCharCap > reservedChars ? (modelCharCap - reservedChars) : 16384;
        contextLimit = MIN(contextLimit, modelCharCap);
    }
    return MAX(contextLimit, (NSUInteger)24000);
}

- (NSArray *)buildTurns {
    NSString *cid = self.conversation[@"id"];
    NSArray *messages = self.conversation[@"messages"];
    NSUInteger contextLimit = [self resolvedContextCharLimit];
    NSUInteger remainingTextBudget = contextLimit;

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
        for (NSDictionary *att in atts) {
            [self addPartsForAttachment:att conversation:cid inlineIds:inlineIds charBudget:&remainingTextBudget to:parts];
        }
        if (text.length > 0) [parts addObject:@{ @"type": @"text", @"text": text }];
        if (parts.count == 0) continue;

        NSMutableDictionary *last = turns.lastObject;
        if (last && [last[@"role"] isEqualToString:turnRole]) {
            [last[@"parts"] addObjectsFromArray:parts];
        } else {
            [turns addObject:[@{ @"role": turnRole, @"parts": parts } mutableCopy]];
        }
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

    AIReasoningLevel rLevel = [AppSettings reasoningLevel];
    NSString *responseDirective = nil;
    if (rLevel == AIReasoningLevelLow) {
        responseDirective = @"\n\n[TURBO FAST MODE] Answer immediately, concisely, and directly to the point with maximum speed and zero filler.";
    } else if (rLevel == AIReasoningLevelMedium) {
        responseDirective = @"\n\n[FAST BALANCED MODE] Give a fast, clear, well-structured answer with practical accuracy and no fluff.";
    } else {
        responseDirective = @"\n\n[MAXIMUM REASONING & CREATIVITY MODE] Think deeply, explore sharp/creative solutions, identify exact root causes, verify edge cases, and deliver thorough, complete, actionable details without truncating or skipping steps.";
    }
    selectedPrompt = [selectedPrompt stringByAppendingString:responseDirective];

    if (codingTask) {
        NSString *codingDirective = @"\n\n[CODING RESPONSE REQUIREMENTS] Deliver complete, compilable code for every requested function or changed file section with all required declarations/imports. Never replace code with ellipses, placeholders, TODOs, or pseudo-code. When continuing across chunks, resume from the exact next character without repeating already-emitted text.";
        selectedPrompt = [selectedPrompt stringByAppendingString:codingDirective];
    }
    if ([AppSettings webSearchEnabled]) {
        selectedPrompt = [selectedPrompt stringByAppendingString:@"\n\n[WEB SEARCH ENABLED] A real provider-managed web search tool is attached to this request. When the user explicitly asks to search, or the answer depends on current, recent, external, or verifiable information, you MUST invoke the search tool before answering and base factual claims on the returned results."];
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

- (NSString *)stripRepeatedPrefixFrom:(NSString *)chunk againstExisting:(NSString *)existing {
    if (chunk.length == 0 || existing.length == 0) return chunk;
    NSUInteger checkLen = MIN((NSUInteger)400, MIN(existing.length, chunk.length));
    NSString *tail = [existing substringFromIndex:existing.length - checkLen];
    for (NSUInteger len = checkLen; len >= 16; len--) {
        NSString *suffix = [tail substringFromIndex:tail.length - len];
        if ([chunk hasPrefix:suffix]) {
            return [chunk substringFromIndex:len];
        }
    }
    return chunk;
}

- (void)launchRequestStreaming:(BOOL)useStreaming {
    self.attemptIsStreaming = useStreaming;
    AIProvider provider = [Provider forModelId:self.model];
    NSString *key = [KeyStore loadKeyForProvider:provider] ?: @"";
    NSString *modelId = [self.model copy];
    NSString *accumulated = [self.longReplyAccumulator copy];

    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        ChatViewController *me = weakSelf;
        if (!me || !me.streaming) return;

        NSMutableArray *turns = [[me buildTurns] mutableCopy];
        NSString *system = [me effectiveSystemPrompt];

        if (accumulated.length > 0) {
            [turns addObject:[@{ @"role": @"assistant", @"parts": @[@{ @"type": @"text", @"text": accumulated }] } mutableCopy]];
            NSUInteger tailLen = MIN((NSUInteger)160, accumulated.length);
            NSString *exactTail = [accumulated substringFromIndex:accumulated.length - tailLen];
            NSString *continueInstruction = [NSString stringWithFormat:
                @"Continue immediately from the exact end of your previous message without repeating a single word, line, or markdown fence. Last characters:\n<<<%@>>>\nOutput ONLY the remaining continuation.",
                exactTail];
            [turns addObject:[@{ @"role": @"user", @"parts": @[@{ @"type": @"text", @"text": continueInstruction }] } mutableCopy]];

            NSUInteger safeCharCap = [me resolvedContextCharLimit];
            while (turns.count > 3 && [me totalTextChars:turns] > safeCharCap) [turns removeObjectAtIndex:0];
            while (turns.count > 1 && [turns.firstObject[@"role"] isEqualToString:@"assistant"]) [turns removeObjectAtIndex:0];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            ChatViewController *strongMe = weakSelf;
            if (!strongMe || !strongMe.streaming) return;

            id<ChatStreaming> stream = (provider == AIProviderClaude)
                ? (id<ChatStreaming>)[[ClaudeStream alloc] initWithKey:key model:modelId turns:turns system:system]
                : (id<ChatStreaming>)[[GeminiStream alloc] initWithKey:key model:modelId turns:turns system:system];
            BOOL fastEnabled = [AppSettings fastModeEnabled] && !strongMe.didFallbackFromFastMode;
            if (provider == AIProviderClaude) {
                ((ClaudeStream *)stream).useFastSpeed = fastEnabled;
            } else if ([stream respondsToSelector:NSSelectorFromString(@"setUseFastSpeed:")]) {
                [(id)stream setValue:@(fastEnabled) forKey:@"useFastSpeed"];
            }
            stream.useStreaming = useStreaming;
            strongMe.stream = stream;
            if (!strongMe.streamGeneratedAttachments) strongMe.streamGeneratedAttachments = [NSMutableArray array];
            strongMe.requestStartTime = CFAbsoluteTimeGetCurrent();
            [DiagnosticLog log:@"request: %@ model=%@ mode=%@ fast=%d %@ systemChars=%lu", [Provider nameFor:provider], modelId,
                               useStreaming ? @"stream" : @"single", fastEnabled, [strongMe summaryOfTurns:turns], (unsigned long)system.length];

            __weak id<ChatStreaming> weakStream = stream;
            __block BOOL checkedOverlap = (strongMe.longReplyAccumulator.length == 0);
            stream.onDelta = ^(NSString *text) {
                ChatViewController *inner = weakSelf;
                if (!inner || inner.stream != weakStream || text.length == 0) return;

                NSString *cleanText = text;
                if (!checkedOverlap && inner.longReplyAccumulator.length > 0) {
                    NSString *probe = [inner.streamBuffer stringByAppendingString:text];
                    if (probe.length >= 32) {
                        NSString *deduped = [inner stripRepeatedPrefixFrom:probe againstExisting:inner.longReplyAccumulator];
                        if (deduped.length < probe.length) {
                            cleanText = deduped;
                            [inner.streamBuffer setString:@""];
                        }
                        checkedOverlap = YES;
                    }
                }
                if (cleanText.length == 0) return;

                [inner.streamBuffer appendString:cleanText];
                if (inner.pendingJSDelta) {
                    [inner.pendingJSDelta appendString:cleanText];
                } else {
                    [inner callJS:@"delta" args:@[cleanText]];
                }
            };
            stream.onImage = ^(NSData *data, NSString *mimeType) {
                ChatViewController *inner = weakSelf;
                if (!inner || inner.stream != weakStream || data.length == 0) return;
                NSString *errorKey = nil;
                NSString *imageName = @"generated-image.jpg";
                NSDictionary *attachment = [AttachmentStore importImageData:data name:imageName
                                                                 conversation:inner.conversation[@"id"] errorKey:&errorKey];
                if (attachment) {
                    [inner.streamGeneratedAttachments addObject:attachment];
                    [DiagnosticLog log:@"generated image saved: bytes=%@ mime=%@", attachment[@"bytes"], mimeType ?: @"image/*"];
                } else {
                    [DiagnosticLog log:@"generated image could not be stored: %@", errorKey ?: @"unknown"];
                }
            };
            stream.onUsage = ^(long long inputTokens, long long outputTokens) {
                ChatViewController *inner = weakSelf;
                if (!inner || inner.stream != weakStream) return;
                [AppSettings addDailyTokenUsage:(inputTokens + outputTokens)];
                [inner updateDailyTokenPrompt];
                [DiagnosticLog log:@"usage: input=%lld output=%lld dayTotal=%lld", inputTokens, outputTokens, [AppSettings dailyTokenUsage]];
            };
            stream.onFinish = ^(GeminiStreamError error, NSInteger status, NSString *detail) {
                ChatViewController *inner = weakSelf;
                if (!inner || inner.stream != weakStream) return;
                [inner flushPendingJSDelta];
                [inner streamFinishedWithError:error status:status detail:detail];
            };
            [stream start];
        });
    });
}

- (void)streamFinishedWithError:(GeminiStreamError)error status:(NSInteger)status detail:(NSString *)detail {
    NSString *partial = [self.streamBuffer copy] ?: @"";
    [DiagnosticLog log:@"reply: model=%@ mode=%@ result=%@ http=%ld textChars=%lu elapsed=%.0fms detail=%@", self.model,
                       self.attemptIsStreaming ? @"stream" : @"single", StreamErrorName(error), (long)status,
                       (unsigned long)partial.length, (CFAbsoluteTimeGetCurrent() - self.requestStartTime) * 1000, ClippedForLog(detail)];

    AIProvider currentProvider = [Provider forModelId:self.model];
    BOOL interruptedMidStream = (error == GeminiStreamErrorNetwork || error == GeminiStreamErrorServer) && partial.length > 0 && self.longReplyContinuationCount < 8;
    if (((error == GeminiStreamErrorNone && status == 200 && [detail isEqualToString:@"__OUTPUT_LIMIT_REACHED__"]) || interruptedMidStream) && partial.length > 0) {
        const NSUInteger kMaxAutomaticContinuations = 12;
        NSUInteger continuationCharCap = [self resolvedContextCharLimit];
        BOOL continuationFitsContext = continuationCharCap > 0 &&
            (self.longReplyAccumulator.length + partial.length) < ((continuationCharCap * 4) / 5);
        if (self.longReplyContinuationCount < kMaxAutomaticContinuations &&
            (self.longReplyAccumulator.length + partial.length) < 3000000 && continuationFitsContext) {
            if (!self.longReplyAccumulator) self.longReplyAccumulator = [NSMutableString string];
            [self.longReplyAccumulator appendString:partial];
            self.longReplyContinuationCount++;
            self.stream = nil;
            self.streamBuffer = [NSMutableString string];
            [self flushPendingJSDelta];
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
    BOOL fastRateLimited = wasFastRequest && !permanentQuota && (status == 429 || status == 529);
    BOOL fastRejected = wasFastRequest && (status == 400 || status == 403) &&
                        ([lowerDetail containsString:@"fast"] || [lowerDetail containsString:@"speed"]);
    if ((fastRateLimited || fastRejected) && partial.length == 0 &&
        self.streamGeneratedAttachments.count == 0 && !self.didFallbackFromFastMode) {
        self.didFallbackFromFastMode = YES;
        NSTimeInterval fastRetryAfter = self.stream.retryAfterSeconds;
        self.stream = nil;
        [DiagnosticLog log:@"Fast mode rejected/limited; retrying at standard speed"];
        NSTimeInterval fallbackDelay = fastRateLimited ? MAX(0.3, MIN(5.0, fastRetryAfter)) : 0.15;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(fallbackDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (self.streaming && self.stream == nil) [self launchRequestStreaming:self.attemptIsStreaming];
        });
        return;
    }

    BOOL retryableStatus = (status == 429 || status == 500 || status == 502 || status == 503 || status == 504 || status == 529);
    BOOL transientServer = (error == GeminiStreamErrorServer || error == GeminiStreamErrorRateLimited) && retryableStatus;
    NSInteger retryLimit = status == 429 ? 2 : 3;
    if (transientServer && !permanentQuota && partial.length == 0 && self.streamGeneratedAttachments.count == 0 && self.streamRetryCount < retryLimit) {
        NSTimeInterval providerDelay = self.stream.retryAfterSeconds;
        self.stream = nil;
        self.streamRetryCount++;
        NSTimeInterval backoff = status == 429 ? 1.5 : (0.5 * self.streamRetryCount);
        NSTimeInterval delay = providerDelay > 0 ? MIN(6.0, MAX(backoff, providerDelay)) : backoff;
        [DiagnosticLog log:@"server overload HTTP %ld: retry %ld after %.1fs", (long)status, (long)self.streamRetryCount, delay];
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
        [DiagnosticLog log:@"live stream failed before any text: retrying immediately as a single request"];
        [self launchRequestStreaming:NO];
        return;
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
    self.streamGeneratedAttachments = nil;
    [self callJS:@"end" args:@[(completeReply ?: @"")]];
    if (generatedAttachments.count > 0) [self renderConversation];
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
    [self renderConversation];
    [self startStreamingReply];
}

#pragma mark - Error text

- (NSString *)messageForError:(GeminiStreamError)error status:(NSInteger)status detail:(NSString *)detail {
    NSString *base = nil;
    BOOL showDetail = NO;
    BOOL usingGoogle = ([Provider forModelId:self.model] == AIProviderGemini) && [KeyStore geminiUsesGoogleAccount];
    switch (error) {
        case GeminiStreamErrorInvalidKey:       base = usingGoogle ? L(@"err_google_auth") : L(@"err_invalid_key"); break;
        case GeminiStreamErrorPermissionDenied: base = usingGoogle ? L(@"err_google_permission") : L(@"err_permission"); showDetail = YES; break;
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
