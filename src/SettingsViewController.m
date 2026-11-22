#import "SettingsViewController.h"
#import "Strings.h"
#import "Theme.h"
#import "KeyStore.h"
#import "AppSettings.h"
#import "ConversationStore.h"
#import "RootViewController.h"
#import "SystemPromptViewController.h"
#import "DiagnosticsViewController.h"
#import "AppearanceViewController.h"
#import "KeyTier.h"
#import "ModelStore.h"
#import "UpdateManager.h"
#import "UpdatePopupViewController.h"

#pragma mark - Font / Message Preview Screen

@interface FontScalePreviewViewController : UIViewController
@property (strong, nonatomic) UISlider *scaleSlider;
@property (strong, nonatomic) UILabel *percentLabel;
@property (strong, nonatomic) UIView *previewContainer;
@property (strong, nonatomic) UIView *aiBubble;
@property (strong, nonatomic) UILabel *aiLabel;
@property (strong, nonatomic) UIView *userBubble;
@property (strong, nonatomic) UILabel *userLabel;
@property (strong, nonatomic) NSLayoutConstraint *aiBubbleMaxWidthConstraint;
@property (strong, nonatomic) NSLayoutConstraint *userBubbleMaxWidthConstraint;
@property (strong, nonatomic) NSLayoutConstraint *aiTopPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *aiBottomPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *aiLeftPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *aiRightPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *userTopPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *userBottomPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *userLeftPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *userRightPaddingConstraint;
@property (strong, nonatomic) NSLayoutConstraint *bubbleGapConstraint;
@end

@implementation FontScalePreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"C\u1EE1 ch\u1EEF";
    self.view.backgroundColor = [Theme background];

    CGFloat initialScale = [AppSettings uiScale];

    // Khung preview tin nhắn
    self.previewContainer = [[UIView alloc] init];
    self.previewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.previewContainer.backgroundColor = [Theme surface];
    self.previewContainer.layer.cornerRadius = 16;
    self.previewContainer.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    self.previewContainer.layer.borderColor = [Theme border].CGColor;
    [self.view addSubview:self.previewContainer];

    // Bong bóng tin nhắn AI
    self.aiBubble = [[UIView alloc] init];
    self.aiBubble.translatesAutoresizingMaskIntoConstraints = NO;
    self.aiBubble.backgroundColor = [Theme background];
    self.aiBubble.layer.cornerRadius = 14;
    self.aiBubble.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    self.aiBubble.layer.borderColor = [Theme border].CGColor;
    [self.previewContainer addSubview:self.aiBubble];

    self.aiLabel = [[UILabel alloc] init];
    self.aiLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.aiLabel.numberOfLines = 0;
    self.aiLabel.textColor = [Theme text];
    self.aiLabel.text = @"K\u00E9o thanh tr\u01B0\u1EE3t b\u00EAn d\u01B0\u1EDBi \u0111\u1EC3 xem tr\u01B0\u1EDBc c\u1EA3 c\u1EE1 ch\u1EEF v\u00E0 \u0111\u1ED9 r\u1ED9ng khung chat.";
    [self.aiBubble addSubview:self.aiLabel];

    // Bong bóng tin nhắn người dùng
    self.userBubble = [[UIView alloc] init];
    self.userBubble.translatesAutoresizingMaskIntoConstraints = NO;
    self.userBubble.backgroundColor = [Theme accent];
    self.userBubble.layer.cornerRadius = 14;
    [self.previewContainer addSubview:self.userBubble];

    self.userLabel = [[UILabel alloc] init];
    self.userLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.userLabel.numberOfLines = 0;
    self.userLabel.textColor = [UIColor whiteColor];
    self.userLabel.text = @"Khung n\u00E0y s\u1EBD co gi\u00E3n theo t\u1EF7 l\u1EC7 b\u1EA1n ch\u1ECDn.";
    [self.userBubble addSubview:self.userLabel];

    // Card điều khiển thanh trượt
    UIView *controlCard = [[UIView alloc] init];
    controlCard.translatesAutoresizingMaskIntoConstraints = NO;
    controlCard.backgroundColor = [Theme surface];
    controlCard.layer.cornerRadius = 14;
    controlCard.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    controlCard.layer.borderColor = [Theme border].CGColor;
    [self.view addSubview:controlCard];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.text = @"T\u1EF7 l\u1EC7 hi\u1EC3n th\u1ECB";
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    titleLabel.textColor = [Theme text];
    [controlCard addSubview:titleLabel];

    self.percentLabel = [[UILabel alloc] init];
    self.percentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.percentLabel.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightSemibold];
    self.percentLabel.textColor = [Theme accent];
    [controlCard addSubview:self.percentLabel];

    self.scaleSlider = [[UISlider alloc] init];
    self.scaleSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.scaleSlider.minimumValue = 0.7f;
    self.scaleSlider.maximumValue = 1.4f;
    self.scaleSlider.value = (float)initialScale;
    self.scaleSlider.tintColor = [Theme accent];
    [self.scaleSlider addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventValueChanged];
    [controlCard addSubview:self.scaleSlider];

    UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeSystem];
    resetButton.translatesAutoresizingMaskIntoConstraints = NO;
    [resetButton setTitle:@"M\u1EB7c \u0111\u1ECBnh (100%)" forState:UIControlStateNormal];
    [resetButton addTarget:self action:@selector(resetScale) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resetButton];

    // Ràng buộc padding động bên trong bong bóng
    self.aiTopPaddingConstraint = [self.aiLabel.topAnchor constraintEqualToAnchor:self.aiBubble.topAnchor constant:10];
    self.aiBottomPaddingConstraint = [self.aiLabel.bottomAnchor constraintEqualToAnchor:self.aiBubble.bottomAnchor constant:-10];
    self.aiLeftPaddingConstraint = [self.aiLabel.leadingAnchor constraintEqualToAnchor:self.aiBubble.leadingAnchor constant:14];
    self.aiRightPaddingConstraint = [self.aiLabel.trailingAnchor constraintEqualToAnchor:self.aiBubble.trailingAnchor constant:-14];
    self.aiBubbleMaxWidthConstraint = [self.aiBubble.widthAnchor constraintLessThanOrEqualToAnchor:self.previewContainer.widthAnchor multiplier:0.78];

    self.userTopPaddingConstraint = [self.userLabel.topAnchor constraintEqualToAnchor:self.userBubble.topAnchor constant:10];
    self.userBottomPaddingConstraint = [self.userLabel.bottomAnchor constraintEqualToAnchor:self.userBubble.bottomAnchor constant:-10];
    self.userLeftPaddingConstraint = [self.userLabel.leadingAnchor constraintEqualToAnchor:self.userBubble.leadingAnchor constant:14];
    self.userRightPaddingConstraint = [self.userLabel.trailingAnchor constraintEqualToAnchor:self.userBubble.trailingAnchor constant:-14];
    self.userBubbleMaxWidthConstraint = [self.userBubble.widthAnchor constraintLessThanOrEqualToAnchor:self.previewContainer.widthAnchor multiplier:0.78];

    self.bubbleGapConstraint = [self.userBubble.topAnchor constraintEqualToAnchor:self.aiBubble.bottomAnchor constant:12];

    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.previewContainer.topAnchor constraintEqualToAnchor:safe.topAnchor constant:16],
        [self.previewContainer.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.previewContainer.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.previewContainer.heightAnchor constraintGreaterThanOrEqualToConstant:210],

        [self.aiBubble.topAnchor constraintEqualToAnchor:self.previewContainer.topAnchor constant:14],
        [self.aiBubble.leadingAnchor constraintEqualToAnchor:self.previewContainer.leadingAnchor constant:14],
        self.aiBubbleMaxWidthConstraint,
        self.aiTopPaddingConstraint,
        self.aiBottomPaddingConstraint,
        self.aiLeftPaddingConstraint,
        self.aiRightPaddingConstraint,

        self.bubbleGapConstraint,
        [self.userBubble.trailingAnchor constraintEqualToAnchor:self.previewContainer.trailingAnchor constant:-14],
        [self.userBubble.bottomAnchor constraintLessThanOrEqualToAnchor:self.previewContainer.bottomAnchor constant:-14],
        self.userBubbleMaxWidthConstraint,
        self.userTopPaddingConstraint,
        self.userBottomPaddingConstraint,
        self.userLeftPaddingConstraint,
        self.userRightPaddingConstraint,

        [controlCard.topAnchor constraintEqualToAnchor:self.previewContainer.bottomAnchor constant:20],
        [controlCard.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [controlCard.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],

        [titleLabel.topAnchor constraintEqualToAnchor:controlCard.topAnchor constant:14],
        [titleLabel.leadingAnchor constraintEqualToAnchor:controlCard.leadingAnchor constant:16],

        [self.percentLabel.centerYAnchor constraintEqualToAnchor:titleLabel.centerYAnchor],
        [self.percentLabel.trailingAnchor constraintEqualToAnchor:controlCard.trailingAnchor constant:-16],

        [self.scaleSlider.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:10],
        [self.scaleSlider.leadingAnchor constraintEqualToAnchor:controlCard.leadingAnchor constant:16],
        [self.scaleSlider.trailingAnchor constraintEqualToAnchor:controlCard.trailingAnchor constant:-16],
        [self.scaleSlider.bottomAnchor constraintEqualToAnchor:controlCard.bottomAnchor constant:-14],

        [resetButton.topAnchor constraintEqualToAnchor:controlCard.bottomAnchor constant:10],
        [resetButton.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor]
    ]];

    [self applyScale:initialScale];
}

- (void)sliderChanged:(UISlider *)sender {
    // Làm tròn bước 0.05 (5%) để dễ căn chỉnh
    CGFloat stepped = roundf(sender.value * 20.0f) / 20.0f;
    [AppSettings setUiScale:stepped];
    [self applyScale:stepped];
}

- (void)resetScale {
    self.scaleSlider.value = 1.0f;
    [AppSettings setUiScale:1.0];
    [self applyScale:1.0];
}

- (void)applyScale:(CGFloat)scale {
    self.percentLabel.text = [NSString stringWithFormat:@"%ld%%", (long)llround(scale * 100.0)];

    CGFloat fontSize = 16.0 * scale;
    self.aiLabel.font = [UIFont systemFontOfSize:fontSize];
    self.userLabel.font = [UIFont systemFontOfSize:fontSize];

    CGFloat vPad = 10.0 * scale;
    CGFloat hPad = 14.0 * scale;
    self.aiTopPaddingConstraint.constant = vPad;
    self.aiBottomPaddingConstraint.constant = -vPad;
    self.aiLeftPaddingConstraint.constant = hPad;
    self.aiRightPaddingConstraint.constant = -hPad;

    self.userTopPaddingConstraint.constant = vPad;
    self.userBottomPaddingConstraint.constant = -vPad;
    self.userLeftPaddingConstraint.constant = hPad;
    self.userRightPaddingConstraint.constant = -hPad;

    self.bubbleGapConstraint.constant = 12.0 * scale;
    self.aiBubble.layer.cornerRadius = 14.0 * scale;
    self.userBubble.layer.cornerRadius = 14.0 * scale;

    // Thu hẹp/mở rộng độ rộng tối đa của bong bóng theo tỷ lệ cỡ chữ (giới hạn an toàn trong khung preview)
    CGFloat maxRatio = MIN(0.92, MAX(0.55, 0.78 * scale));
    [self.view layoutIfNeeded];
    self.aiBubbleMaxWidthConstraint.active = NO;
    self.userBubbleMaxWidthConstraint.active = NO;
    self.aiBubbleMaxWidthConstraint = [self.aiBubble.widthAnchor constraintLessThanOrEqualToAnchor:self.previewContainer.widthAnchor multiplier:maxRatio];
    self.userBubbleMaxWidthConstraint = [self.userBubble.widthAnchor constraintLessThanOrEqualToAnchor:self.previewContainer.widthAnchor multiplier:maxRatio];
    self.aiBubbleMaxWidthConstraint.active = YES;
    self.userBubbleMaxWidthConstraint.active = YES;

    [UIView animateWithDuration:0.08 animations:^{
        [self.view layoutIfNeeded];
    }];
}

@end

#pragma mark - SettingsViewController

// Order on screen: appearance & language on top, then the API keys, then the AI settings, then data & info, then credits.
typedef NS_ENUM(NSInteger, SettingsSection) {
    SettingsSectionUpdate = 0,
    SettingsSectionLook,
    SettingsSectionKeys,
    SettingsSectionAssistant,
    SettingsSectionData,
    SettingsSectionCredits,
    SettingsSectionCount
};

@interface SettingsViewController ()
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) BOOL hasAppearedOnce;
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"settings_title");
    self.view.backgroundColor = [Theme background];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    [self.view addSubview:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme) name:kNotifThemeChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUIScaleChanged) name:@"UIScaleDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStateChanged) name:kNotifUpdateChanged object:nil];
}

#pragma mark - App update

// The update row follows the checker (checking -> up to date / new version / downloading ...).
- (void)updateStateChanged {
    if (!self.isViewLoaded || !self.view.window) return;
    NSIndexPath *path = [NSIndexPath indexPathForRow:0 inSection:SettingsSectionUpdate];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    if (cell) [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    if ([UpdateManager shared].state == UpdateStateAvailable && self.view.window && !self.presentedViewController &&
        self.navigationController.topViewController == self && [[UpdateManager shared] consumePromptForCurrentVersion]) {
        [self presentUpdatePopupChecking:NO];   // a new version was just found: tell the user once
    }
}

- (void)presentUpdatePopupChecking:(BOOL)check {
    if (self.presentedViewController) return;
    UpdateManager *m = [UpdateManager shared];
    if (check && (m.state == UpdateStateIdle || m.state == UpdateStateFailed || m.state == UpdateStateUpToDate)) [m checkForUpdateForce:YES];
    [self presentViewController:[[UpdatePopupViewController alloc] init] animated:YES completion:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleUIScaleChanged {
    if (self.view.window) [self.tableView reloadData];
}

- (void)applyTheme {
    self.view.backgroundColor = [Theme background];
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    if (self.view.window) [self.tableView reloadData];   // hidden behind another screen: it reloads when it comes back (viewWillAppear)
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // The table was just built in viewDidLoad: only refresh when coming BACK from a sub-screen (keys / prompt may have changed).
    if (self.hasAppearedOnce) [self.tableView reloadData];
    self.hasAppearedOnce = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[UpdateManager shared] checkForUpdateForce:NO];   // quietly, at most every 10 minutes
    if ([UpdateManager shared].state == UpdateStateAvailable && !self.presentedViewController && [[UpdateManager shared] consumePromptForCurrentVersion]) {
        [self presentUpdatePopupChecking:NO];
    }
}

#pragma mark - Helpers

- (NSString *)maskedKeyFor:(AIProvider)provider {
    NSString *key = [KeyStore loadKeyForProvider:provider];
    if (key.length == 0) return L(@"api_key_none");
    NSString *tail = key.length > 4 ? [key substringFromIndex:key.length - 4] : key;
    return [@"\u2022\u2022\u2022\u2022" stringByAppendingString:tail];
}

- (NSString *)appearanceSummary {
    NSString *name = [Theme skinName:[Theme skin]];
    if ([Theme autoMode]) return [NSString stringWithFormat:@"%@ \u00B7 %@", name, L(@"mode_auto")];
    return [Theme darkMode] ? [NSString stringWithFormat:@"%@ \u00B7 %@", name, L(@"appearance_dark_short")] : name;
}

- (NSString *)languageName {
    NSString *preference = [Loc preference];
    if ([preference isEqualToString:@"vi"]) return @"Ti\u1EBFng Vi\u1EC7t";
    if ([preference isEqualToString:@"en"]) return @"English";
    return L(@"language_auto");
}

- (NSString *)fontSizeSummary {
    long pct = (long)llround([AppSettings uiScale] * 100.0);
    return [NSString stringWithFormat:@"%ld%%", pct];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return SettingsSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == SettingsSectionUpdate) return 1;
    if (section == SettingsSectionLook) return 3;      // look, language, font size
    if (section == SettingsSectionKeys) return 3;      // Gemini key, Claude key, kind of Gemini key
    if (section == SettingsSectionAssistant) return 4;
    if (section == SettingsSectionCredits) return 2;   // TaoJB, PucSaur
    return 3;   // data: clear history, version, diagnostics
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SettingsSectionUpdate:    return L(@"settings_header_update");
        case SettingsSectionLook:      return L(@"settings_header_look");
        case SettingsSectionKeys:      return L(@"settings_header_keys");
        case SettingsSectionAssistant: return L(@"settings_header_ai");
        case SettingsSectionCredits:   return L(@"settings_header_credits");
        default:                       return L(@"settings_header_data");
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == SettingsSectionUpdate) return [NSString stringWithFormat:L(@"update_footer"), [UpdateManager shared].installKindName];
    if (section == SettingsSectionKeys) return [NSString stringWithFormat:@"%@\n\n%@", L(@"keys_footer"), L(@"key_tier_footer")];
    if (section == SettingsSectionAssistant) return L(@"attach_memory_footer");
    if (section == SettingsSectionData) return L(@"privacy_footer");
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.backgroundColor = [Theme surface];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = [Theme text];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.textColor = [Theme secondaryText];

    switch (indexPath.section) {
        case SettingsSectionUpdate: {
            UpdateManager *m = [UpdateManager shared];
            cell.textLabel.text = L(@"update_row_title");
            cell.detailTextLabel.textColor = [Theme secondaryText];
            NSString *current = [NSString stringWithFormat:@"%@", m.currentVersion];
            switch (m.state) {
                case UpdateStateChecking:    cell.detailTextLabel.text = L(@"update_row_checking"); break;
                case UpdateStateUpToDate:    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ \u00B7 %@", current, L(@"update_row_latest")]; break;
                case UpdateStateAvailable:
                    cell.detailTextLabel.text = [NSString stringWithFormat:L(@"update_row_new"), m.latestLabel];
                    cell.detailTextLabel.textColor = [Theme accent];
                    break;
                case UpdateStateDownloading: cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %d%%", L(@"update_row_downloading"), (int)lround(m.progress * 100.0)]; cell.detailTextLabel.textColor = [Theme accent]; break;
                case UpdateStateDownloaded:
                    cell.detailTextLabel.text = [NSString stringWithFormat:L(@"update_row_ready"), m.latestLabel];
                    cell.detailTextLabel.textColor = [Theme accent];
                    break;
                case UpdateStateFailed:      cell.detailTextLabel.text = L(@"update_row_error"); break;
                default:                     cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ \u00B7 %@", current, L(@"update_row_check")]; break;
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case SettingsSectionCredits:
            cell.textLabel.text = indexPath.row == 0 ? @"TaoJB" : @"PucSaur";
            cell.detailTextLabel.text = L(@"main_developer");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        case SettingsSectionKeys: {
            if (indexPath.row == 2) {
                cell.textLabel.text = L(@"key_tier_title");
                cell.detailTextLabel.text = [self keyTierSummary];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            }
            AIProvider provider = indexPath.row == 0 ? AIProviderGemini : AIProviderClaude;
            cell.textLabel.text = provider == AIProviderClaude ? L(@"api_key_claude") : L(@"api_key_gemini");
            cell.detailTextLabel.text = [self maskedKeyFor:provider];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case SettingsSectionAssistant:
            if (indexPath.row == 0) {
                cell.textLabel.text = L(@"system_prompt_title");
                cell.detailTextLabel.text = [AppSettings systemPrompt].length > 0 ? L(@"system_prompt_set") : L(@"system_prompt_unset");
            } else if (indexPath.row == 1) {
                cell.textLabel.text = L(@"attach_memory_title");
                cell.detailTextLabel.text = [self attachmentMemoryName];
            } else if (indexPath.row == 2) {
                cell.textLabel.text = L(@"output_tokens_title");
                cell.detailTextLabel.text = [self outputTokensName];
            } else {
                cell.textLabel.text = L(@"context_memory_title");
                cell.detailTextLabel.text = [self contextMemoryName];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        case SettingsSectionLook:
            if (indexPath.row == 0) {
                cell.textLabel.text = L(@"settings_row_look");
                cell.detailTextLabel.text = [self appearanceSummary];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = L(@"language");
                cell.detailTextLabel.text = [self languageName];
            } else {
                cell.textLabel.text = @"C\u1EE1 ch\u1EEF";
                cell.detailTextLabel.text = [self fontSizeSummary];
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:   // SettingsSectionData
            if (indexPath.row == 0) {
                cell.textLabel.text = L(@"clear_history");
                cell.textLabel.textColor = [Theme error];
            } else if (indexPath.row == 1) {
                cell.textLabel.text = L(@"version");
                cell.detailTextLabel.text = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            } else {
                cell.textLabel.text = L(@"diagnostics_title");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) ((UITableViewHeaderFooterView *)view).textLabel.textColor = [Theme secondaryText];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) ((UITableViewHeaderFooterView *)view).textLabel.textColor = [Theme secondaryText];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
        case SettingsSectionUpdate:
            [self presentUpdatePopupChecking:YES];
            break;
        case SettingsSectionCredits:
            break;
        case SettingsSectionKeys: {
            if (indexPath.row == 2) {
                [self chooseKeyTier];
                break;
            }
            RootViewController *keyScreen = [[RootViewController alloc] init];
            keyScreen.embedded = YES;
            keyScreen.provider = indexPath.row == 0 ? AIProviderGemini : AIProviderClaude;
            [self.navigationController pushViewController:keyScreen animated:YES];
            break;
        }
        case SettingsSectionAssistant:
            if (indexPath.row == 0) {
                [self.navigationController pushViewController:[[SystemPromptViewController alloc] init] animated:YES];
            } else if (indexPath.row == 1) {
                [self chooseAttachmentMemory];
            } else if (indexPath.row == 2) {
                [self chooseOutputTokens];
            } else {
                [self chooseContextMemory];
            }
            break;
        case SettingsSectionLook:
            if (indexPath.row == 0) {
                [self.navigationController pushViewController:[[AppearanceViewController alloc] init] animated:YES];
            } else if (indexPath.row == 1) {
                [self chooseLanguage];
            } else {
                [self.navigationController pushViewController:[[FontScalePreviewViewController alloc] init] animated:YES];
            }
            break;
        default:   // SettingsSectionData
            if (indexPath.row == 0) {
                [self confirmClearHistory];
            } else if (indexPath.row == 2) {
                [self.navigationController pushViewController:[[DiagnosticsViewController alloc] init] animated:YES];
            }
            break;
    }
}

#pragma mark - Attachment memory and request limits

- (NSString *)attachmentMemoryName {
    NSInteger count = [AppSettings attachmentMemory];
    if (count == 1) return L(@"attach_memory_1");
    if (count == 0) return L(@"attach_memory_all");
    return L(@"attach_memory_3");
}

- (NSString *)outputTokensName {
    return [NSString stringWithFormat:@"%ld tokens", (long)[AppSettings maxOutputTokens]];
}


- (NSString *)reasoningLevelName {
    switch ([AppSettings reasoningLevel]) {
        case AIReasoningLevelLow: return @"Thấp";
        case AIReasoningLevelMedium: return @"Trung bình";
        case AIReasoningLevelHigh: return @"Cao";
        case AIReasoningLevelVeryHigh: return @"Siêu cao";
        case AIReasoningLevelMax: return @"MAX ×8 (nếu model hỗ trợ)";
    }
    return @"Trung bình";
}

- (void)chooseReasoningLevel {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:@"Mức suy luận AI"
                                                                   message:@"Mức thực tế phụ thuộc model và API. MAX ×8 không thể vượt giới hạn nhà cung cấp."
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *names = @[@"Thấp", @"Trung bình", @"Cao", @"Siêu cao", @"MAX ×8 (nếu model hỗ trợ)"];
    __weak typeof(self) weakSelf = self;
    [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        [sheet addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [AppSettings setReasoningLevel:(AIReasoningLevel)idx];
            [weakSelf.tableView reloadData];
        }]];
    }];
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:4 inSection:SettingsSectionAssistant];
    sheet.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:path] ?: self.view;
    sheet.popoverPresentationController.sourceRect = sheet.popoverPresentationController.sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (NSString *)contextMemoryName {
    return [NSString stringWithFormat:L(@"context_memory_value"), (unsigned long)([AppSettings contextLimitChars] / 1000)];
}

- (void)chooseOutputTokens {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:L(@"output_tokens_title")
                                                                   message:L(@"output_tokens_note")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[ @[@2048, @"2,048 tokens"], @[@4096, @"4,096 tokens"], @[@8192, @"8,192 tokens"], @[@16384, @"16,384 tokens"], @[@32768, @"32,768 tokens"], @[@65536, @"65,536 tokens"], @[@128000, @"128,000 tokens"] ];
    __weak typeof(self) weakSelf = self;
    for (NSArray *option in options) {
        NSInteger value = [option[0] integerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [AppSettings setMaxOutputTokens:value];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:2 inSection:SettingsSectionAssistant];
    sheet.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:path] ?: self.view;
    sheet.popoverPresentationController.sourceRect = sheet.popoverPresentationController.sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)chooseContextMemory {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:L(@"context_memory_title")
                                                                   message:L(@"context_memory_note")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[ @[@100000, [NSString stringWithFormat:L(@"context_memory_value"), 100]],
                          @[@200000, [NSString stringWithFormat:L(@"context_memory_value"), 200]],
                          @[@400000, [NSString stringWithFormat:L(@"context_memory_value"), 400]],
                          @[@600000, [NSString stringWithFormat:L(@"context_memory_value"), 600]] ];
    __weak typeof(self) weakSelf = self;
    for (NSArray *option in options) {
        NSUInteger value = [option[0] unsignedIntegerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [AppSettings setContextLimitChars:value];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:3 inSection:SettingsSectionAssistant];
    sheet.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:path] ?: self.view;
    sheet.popoverPresentationController.sourceRect = sheet.popoverPresentationController.sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)chooseAttachmentMemory {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:L(@"attach_memory_title")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[ @[@1, L(@"attach_memory_1")], @[@3, L(@"attach_memory_3")], @[@0, L(@"attach_memory_all")] ];
    __weak typeof(self) weakSelf = self;
    for (NSArray *option in options) {
        NSInteger value = [option[0] integerValue];
        [sheet addAction:[UIAlertAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            [AppSettings setAttachmentMemory:value];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:1 inSection:SettingsSectionAssistant];
    sheet.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:path] ?: self.view;
    sheet.popoverPresentationController.sourceRect = sheet.popoverPresentationController.sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - Language

#pragma mark - Kind of Gemini key (free / paid)

- (NSString *)tierName:(KeyTierLevel)tier {
    switch (tier) {
        case KeyTierFree: return L(@"key_tier_free");
        case KeyTierPaid: return L(@"key_tier_paid");
        default:          return L(@"key_tier_unknown");
    }
}

- (NSString *)keyTierSummary {
    if (![KeyStore hasKeyForProvider:AIProviderGemini]) return @"\u2014";
    NSInteger override = [KeyTier geminiOverride];
    if (override == 1) return L(@"key_tier_free");
    if (override == 2) return L(@"key_tier_paid");
    return [NSString stringWithFormat:@"%@ \u00B7 %@", L(@"key_tier_auto_short"), [self tierName:[KeyTier detectedGeminiTier]]];
}

- (void)chooseKeyTier {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:L(@"key_tier_title")
                                                                   message:L(@"key_tier_message")
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"key_tier_auto") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [KeyTier setGeminiOverride:0];
        [KeyTier invalidateGeminiDetection];
        [weakSelf redetectKeyTier];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"key_tier_free") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [KeyTier setGeminiOverride:1];
        [weakSelf.tableView reloadData];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"key_tier_paid") style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        [KeyTier setGeminiOverride:2];
        [weakSelf.tableView reloadData];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:2 inSection:SettingsSectionKeys];
    sheet.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:path] ?: self.view;
    sheet.popoverPresentationController.sourceRect = sheet.popoverPresentationController.sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

// Asks Google again (one tiny request) and tells the person what it found.
- (void)redetectKeyTier {
    [self.tableView reloadData];
    if (![KeyStore hasKeyForProvider:AIProviderGemini]) return;
    __weak typeof(self) weakSelf = self;
    [KeyTier forceDetectGeminiTierWithModels:[ModelStore cachedModelsForProvider:AIProviderGemini] completion:^(KeyTierLevel tier) {
        SettingsViewController *me = weakSelf;
        if (!me) return;
        [KeyTier consumePopupPending];   // no pop-up here: the person is in Settings and sees the result below
        [me.tableView reloadData];
        NSString *message = tier == KeyTierUnknown ? L(@"key_tier_failed")
                                                    : [NSString stringWithFormat:L(@"key_tier_result"), [me tierName:tier]];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [me presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)chooseLanguage {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:L(@"language")
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    NSArray *options = @[ @[@"auto", L(@"language_auto")], @[@"vi", @"Ti\u1EBFng Vi\u1EC7t"], @[@"en", @"English"] ];
    for (NSArray *option in options) {
        NSString *value = option[0];
        UIAlertAction *action = [UIAlertAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
            if ([[Loc preference] isEqualToString:value]) return;
            [Loc setPreference:value];
            // The app rebuilds its screens in the new language (the open chat starts fresh).
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifLanguageChanged object:nil];
        }];
        [sheet addAction:action];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    NSIndexPath *path = [NSIndexPath indexPathForRow:1 inSection:SettingsSectionLook];
    sheet.popoverPresentationController.sourceView = [self.tableView cellForRowAtIndexPath:path] ?: self.view;
    sheet.popoverPresentationController.sourceRect = sheet.popoverPresentationController.sourceView.bounds;
    [self presentViewController:sheet animated:YES completion:nil];
}

#pragma mark - History

- (void)confirmClearHistory {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"clear_history_confirm_title")
                                                                   message:L(@"clear_history_confirm_msg")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:L(@"delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [ConversationStore deleteAll];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifHistoryCleared object:nil];
        SettingsViewController *me = weakSelf;
        if (!me) return;
        UIAlertController *done = [UIAlertController alertControllerWithTitle:nil
                                                                      message:L(@"history_cleared")
                                                               preferredStyle:UIAlertControllerStyleAlert];
        [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [me presentViewController:done animated:YES completion:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
