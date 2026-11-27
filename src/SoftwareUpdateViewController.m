#import "SoftwareUpdateViewController.h"
#import "UpdateManager.h"
#import "DevAccess.h"
#import "AppSettings.h"
#import "ChoicePopupViewController.h"
#import "Strings.h"
#import "Theme.h"
#import "Material.h"

static NSString *SizeText(long long bytes) {
    if (bytes <= 0) return @"";
    double mb = (double)bytes / (1024.0 * 1024.0);
    if (mb >= 1024.0) return [NSString stringWithFormat:@"%.2f GB", mb / 1024.0];
    return [NSString stringWithFormat:@"%.1f MB", mb];
}

#pragma mark - The card

@interface SoftwareUpdateCard : UIView
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *subtitleLabel;
@property (strong, nonatomic) UILabel *bodyLabel;
@property (strong, nonatomic) UIActivityIndicatorView *spinner;
@property (strong, nonatomic) UIView *progressTrack;
@property (strong, nonatomic) UIView *progressFill;
@property (strong, nonatomic) UIButton *primaryButton;
@property (strong, nonatomic) UIButton *secondaryButton;
@property (assign, nonatomic) BOOL showsProgress;
@property (assign, nonatomic) BOOL showsSpinner;
@property (assign, nonatomic) double progress;
@property (copy, nonatomic) void (^onPrimary)(void);
@property (copy, nonatomic) void (^onSecondary)(void);
- (CGFloat)heightForWidth:(CGFloat)width;
@end

static const CGFloat kCardPad = 16;
static const CGFloat kCardIcon = 60;

@implementation SoftwareUpdateCard

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    self.backgroundColor = [UIColor clearColor];

    self.iconView = [[UIImageView alloc] init];
    self.iconView.contentMode = UIViewContentModeScaleAspectFill;
    self.iconView.clipsToBounds = YES;
    self.iconView.layer.cornerRadius = 14;
    self.iconView.layer.borderWidth = 0.5;
    self.iconView.layer.borderColor = [Theme border].CGColor;
    [self addSubview:self.iconView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [Theme text];
    [self addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.font = [UIFont systemFontOfSize:15];
    self.subtitleLabel.textColor = [Theme secondaryText];
    self.subtitleLabel.numberOfLines = 2;
    [self addSubview:self.subtitleLabel];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.hidesWhenStopped = YES;
    [self addSubview:self.spinner];

    self.bodyLabel = [[UILabel alloc] init];
    self.bodyLabel.font = [UIFont systemFontOfSize:15];
    self.bodyLabel.textColor = [Theme text];
    self.bodyLabel.numberOfLines = 0;
    [self addSubview:self.bodyLabel];

    self.progressTrack = [[UIView alloc] init];
    self.progressTrack.backgroundColor = [Theme border];
    self.progressTrack.layer.cornerRadius = 3;
    self.progressTrack.clipsToBounds = YES;
    [self addSubview:self.progressTrack];
    self.progressFill = [[UIView alloc] init];
    self.progressFill.backgroundColor = [Theme accent];
    [self.progressTrack addSubview:self.progressFill];

    // iOS style: a wide filled blue button, and a plain text button under it.
    self.primaryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.primaryButton.backgroundColor = [Theme accent];
    self.primaryButton.layer.cornerRadius = MR(12, 24);   // half of the 48 pt height
    self.primaryButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.primaryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.primaryButton.titleLabel.minimumScaleFactor = 0.8;
    [self.primaryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.primaryButton addTarget:self action:@selector(primaryTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.primaryButton];

    self.secondaryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secondaryButton.titleLabel.font = [UIFont systemFontOfSize:17];
    self.secondaryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.secondaryButton.titleLabel.minimumScaleFactor = 0.8;
    [self.secondaryButton setTitleColor:[Theme accent] forState:UIControlStateNormal];
    [self.secondaryButton addTarget:self action:@selector(secondaryTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.secondaryButton];
    return self;
}

- (void)primaryTapped { if (self.onPrimary) self.onPrimary(); }
- (void)secondaryTapped { if (self.onSecondary) self.onSecondary(); }

- (void)restyle {
    self.titleLabel.textColor = [Theme text];
    self.subtitleLabel.textColor = [Theme secondaryText];
    self.bodyLabel.textColor = [Theme text];
    self.progressTrack.backgroundColor = [Theme border];
    self.progressFill.backgroundColor = [Theme accent];
    self.primaryButton.backgroundColor = [Theme accent];
    [self.secondaryButton setTitleColor:[Theme accent] forState:UIControlStateNormal];
    self.iconView.layer.borderColor = [Theme border].CGColor;
}

// Lays the content out for this width and returns the total height. Frames are only set when `apply` is YES.
- (CGFloat)layoutForWidth:(CGFloat)width apply:(BOOL)apply {
    CGFloat inner = MAX(100, width - kCardPad * 2);
    CGFloat textX = kCardPad + kCardIcon + 14;
    CGFloat textW = MAX(60, width - textX - kCardPad - (self.showsSpinner ? 28 : 0));
    CGFloat titleH = ceil([self.titleLabel sizeThatFits:CGSizeMake(textW, CGFLOAT_MAX)].height);
    CGFloat subH = self.subtitleLabel.text.length > 0 ? ceil([self.subtitleLabel sizeThatFits:CGSizeMake(textW, CGFLOAT_MAX)].height) : 0;
    CGFloat block = titleH + (subH > 0 ? 3 + subH : 0);
    CGFloat headH = MAX(kCardIcon, block);
    CGFloat y = kCardPad;
    if (apply) {
        self.iconView.frame = CGRectMake(kCardPad, y + (headH - kCardIcon) / 2, kCardIcon, kCardIcon);
        CGFloat ty = y + (headH - block) / 2;
        self.titleLabel.frame = CGRectMake(textX, ty, textW, titleH);
        self.subtitleLabel.frame = CGRectMake(textX, ty + titleH + 3, textW, subH);
        self.spinner.center = CGPointMake(width - kCardPad - 10, y + headH / 2);
    }
    y += headH;

    if (self.bodyLabel.text.length > 0) {
        y += 14;
        CGFloat bodyH = ceil([self.bodyLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)].height);
        if (apply) self.bodyLabel.frame = CGRectMake(kCardPad, y, inner, bodyH);
        y += bodyH;
    } else if (apply) {
        self.bodyLabel.frame = CGRectZero;
    }
    if (self.showsProgress) {
        y += 14;
        if (apply) self.progressTrack.frame = CGRectMake(kCardPad, y, inner, 6);
        y += 6;
    }
    BOOL hasPrimary = self.primaryButton.currentTitle.length > 0;
    BOOL hasSecondary = self.secondaryButton.currentTitle.length > 0;
    if (hasPrimary) {
        y += 18;
        if (apply) self.primaryButton.frame = CGRectMake(kCardPad, y, inner, 48);
        y += 48;
    }
    if (hasSecondary) {
        y += hasPrimary ? 6 : 14;
        if (apply) self.secondaryButton.frame = CGRectMake(kCardPad, y, inner, 42);
        y += 42;
    }
    y += hasSecondary ? 8 : 16;
    if (apply) {
        self.progressTrack.hidden = !self.showsProgress;
        self.primaryButton.hidden = !hasPrimary;
        self.secondaryButton.hidden = !hasSecondary;
        double p = MIN(1.0, MAX(0.0, self.progress));
        self.progressFill.frame = CGRectMake(0, 0, inner * p, 6);
    }
    return y;
}

- (CGFloat)heightForWidth:(CGFloat)width { return [self layoutForWidth:width apply:NO]; }

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutForWidth:self.bounds.size.width apply:YES];
}

@end

#pragma mark - The screen

typedef NS_ENUM(NSInteger, SUSection) { SUSectionOptions = 0, SUSectionCard, SUSectionCount };

@interface SoftwareUpdateViewController ()
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) SoftwareUpdateCard *card;
@property (strong, nonatomic) UITableViewCell *cardCell;
@property (assign, nonatomic) CGFloat cardHeight;
@property (assign, nonatomic) BOOL started;
@property (strong, nonatomic) UIActivityIndicatorView *gateSpinner;
@end

@implementation SoftwareUpdateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"update_row_title");
    self.view.backgroundColor = [Theme background];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    [self.view addSubview:self.tableView];
    [self applyMaterialStyle];
    [Material markTableForEntrance:self.tableView];

    __weak typeof(self) weakSelf = self;
    self.card = [[SoftwareUpdateCard alloc] initWithFrame:CGRectZero];
    self.card.onPrimary = ^{ [weakSelf primaryAction]; };
    self.card.onSecondary = ^{ [weakSelf secondaryAction]; };

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(stateChanged) name:kNotifUpdateChanged object:nil];
    [center addObserver:self selector:@selector(appBecameActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(themeChanged) name:kNotifThemeChanged object:nil];
    [self refreshCard];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applyMaterialStyle {
    BOOL material = [Material active];
    self.tableView.separatorStyle = material ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    if (material) [Material decorateTable:self.tableView];
    [Material layoutTable:self.tableView inBounds:self.view.bounds];
    [Material styleTitleForController:self];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [Material decorateCell:cell atIndexPath:indexPath inTable:tableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyMaterialStyle];
    if (!self.started) {
        self.started = YES;
        UpdateManager *m = [UpdateManager shared];
        [m switchToDevChannel:NO];   // this screen always starts on the normal releases; the beta channel needs the password
        if (m.state == UpdateStateIdle || m.state == UpdateStateFailed || m.state == UpdateStateUpToDate) [m checkForUpdateForce:YES];
    }
}

// Leaving the screen closes the developer gate: no decrypted build, no open session, the password is asked again next time.
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController || self.isBeingDismissed) {
        [[UpdateManager shared] switchToDevChannel:NO];
        [[DevAccess shared] lock];
    }
}

- (void)themeChanged {
    self.view.backgroundColor = [Theme background];
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    [self applyMaterialStyle];
    [self.card restyle];
    [self.tableView reloadData];
}

// The developer session ends by itself (background, device lock, 15 minutes): fall back to the normal channel.
- (void)appBecameActive {
    UpdateManager *m = [UpdateManager shared];
    if (m.devChannel && ![DevAccess shared].unlocked) {
        [m switchToDevChannel:NO];
        [m checkForUpdateForce:YES];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SUSectionOptions] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - State -> card

- (void)stateChanged {
    if (!self.isViewLoaded) return;
    UpdateManager *m = [UpdateManager shared];
    if (m.devChannel && ![DevAccess shared].unlocked) { [self appBecameActive]; return; }
    CGFloat before = self.cardHeight;
    [self refreshCard];
    if (fabs(self.cardHeight - before) > 0.5) {
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SUSectionOptions] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSString *)primaryActionTitle:(NSInteger *)code secondary:(NSString **)secondary secondaryCode:(NSInteger *)secondaryCode forState:(UpdateState)state {
    UpdateManager *m = [UpdateManager shared];
    NSString *primary = nil;
    *secondary = nil;
    *code = 0;
    *secondaryCode = 0;
    switch (state) {
        case UpdateStateUpToDate:
            *secondary = L(@"update_check_again"); *secondaryCode = 1;
            break;
        case UpdateStateAvailable:
            primary = L(@"su_update_now"); *code = 2;
            *secondary = L(@"update_check_again"); *secondaryCode = 1;
            break;
        case UpdateStateDownloading:
            *secondary = L(@"update_cancel"); *secondaryCode = 3;
            break;
        case UpdateStateDownloaded:
            if (m.installKind == UpdateInstallKindIPA) {
                primary = L(@"update_open_files"); *code = 4;
                *secondary = L(@"update_open_in"); *secondaryCode = 5;
            } else {
                primary = L(@"update_install_now"); *code = 4;
            }
            break;
        case UpdateStateFailed:
            primary = L(@"update_retry"); *code = 1;
            break;
        default:
            break;
    }
    return primary;
}

- (void)refreshCard {
    UpdateManager *m = [UpdateManager shared];
    SoftwareUpdateCard *card = self.card;
    card.iconView.image = [Theme activeIconImage];
    BOOL haveNew = m.state == UpdateStateAvailable || m.state == UpdateStateDownloading || m.state == UpdateStateDownloaded;
    NSString *version = haveNew ? m.latestLabel : m.currentVersion;
    card.titleLabel.text = [NSString stringWithFormat:@"ClaudeMini %@", version ?: @""];
    NSString *subtitle = @"", *body = @"";
    NSString *dev = m.devChannel ? L(@"dev_badge") : nil;
    BOOL progress = NO, spinner = NO;
    NSString *size = SizeText(m.assetSize);

    switch (m.state) {
        case UpdateStateAvailable: {
            NSString *kind = [NSString stringWithFormat:L(@"update_kind_line"), m.installKindName, size.length > 0 ? [@" · " stringByAppendingString:size] : @""];
            subtitle = size.length > 0 ? size : m.installKindName;
            NSMutableString *text = [NSMutableString string];
            if (dev) [text appendFormat:@"%@\n\n", dev];
            [text appendString:m.releaseNotes.length > 0 ? m.releaseNotes : L(@"su_no_notes")];
            [text appendFormat:@"\n\n%@", kind];
            body = text;
            break;
        }
        case UpdateStateDownloading:
            subtitle = [NSString stringWithFormat:@"%d%%%@", (int)lround(m.progress * 100.0),
                        size.length > 0 ? [NSString stringWithFormat:@" · %@ / %@", SizeText(m.receivedBytes), size] : @""];
            body = L(@"update_downloading");
            progress = YES;
            break;
        case UpdateStateDownloaded:
            subtitle = L(@"update_downloaded");
            body = m.installKind == UpdateInstallKindIPA ? L(@"update_ipa_msg") : L(@"update_deb_msg");
            break;
        case UpdateStateFailed:
            subtitle = L(@"update_failed");
            body = m.errorMessage.length > 0 ? m.errorMessage : L(@"update_err_network");
            break;
        case UpdateStateUpToDate:
            subtitle = L(@"update_uptodate");
            body = dev ? [NSString stringWithFormat:@"%@\n\n%@", dev, [NSString stringWithFormat:L(@"update_uptodate_msg"), m.currentVersion]]
                       : [NSString stringWithFormat:L(@"update_uptodate_msg"), m.currentVersion];
            break;
        default:   // Idle, Checking
            subtitle = L(m.devChannel ? @"dev_checking" : @"update_checking");
            body = m.devChannel ? @"" : L(@"update_checking_msg");
            spinner = YES;
            break;
    }
    card.subtitleLabel.text = subtitle;
    card.bodyLabel.text = body;
    NSInteger code = 0, code2 = 0;
    NSString *secondary = nil;
    NSString *primary = [self primaryActionTitle:&code secondary:&secondary secondaryCode:&code2 forState:m.state];
    [card.primaryButton setTitle:primary forState:UIControlStateNormal];
    [card.secondaryButton setTitle:secondary forState:UIControlStateNormal];
    card.primaryButton.tag = code;
    card.secondaryButton.tag = code2;
    card.showsProgress = progress;
    card.progress = m.progress;
    card.showsSpinner = spinner;
    if (spinner) [card.spinner startAnimating]; else [card.spinner stopAnimating];
    CGFloat width = self.tableView.bounds.size.width > 0 ? self.tableView.bounds.size.width : self.view.bounds.size.width;
    self.cardHeight = [card heightForWidth:width];
    [card setNeedsLayout];
}

// 1 check again, 2 download, 3 cancel download, 4 install, 5 open with...
- (void)runCode:(NSInteger)code sender:(UIView *)sender {
    UpdateManager *m = [UpdateManager shared];
    switch (code) {
        case 1: [m checkForUpdateForce:YES]; break;
        case 2: [m startDownload]; break;
        case 3: [m cancelDownload]; break;
        case 4: [m installFromViewController:self anchor:sender]; break;
        case 5: [m presentOpenInFromViewController:self anchor:sender]; break;
        default: break;
    }
}

- (void)primaryAction { [self runCode:self.card.primaryButton.tag sender:self.card.primaryButton]; }
- (void)secondaryAction { [self runCode:self.card.secondaryButton.tag sender:self.card.secondaryButton]; }

#pragma mark - Table

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView { return SUSectionCount; }

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;   // the beta channel lives in its own Settings row (password, then the update pop-up)
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == SUSectionOptions) return nil;
    UpdateManager *m = [UpdateManager shared];
    return [NSString stringWithFormat:L(@"su_footer"), m.currentVersion ?: @"", m.installKindName ?: @""];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SUSectionCard) {
        if (!self.cardCell) {
            self.cardCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            self.cardCell.selectionStyle = UITableViewCellSelectionStyleNone;
            self.cardCell.separatorInset = UIEdgeInsetsMake(0, 10000, 0, 0);
            [self.cardCell.contentView addSubview:self.card];
            self.card.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
        self.cardCell.backgroundColor = [Theme surface];
        self.card.frame = self.cardCell.contentView.bounds;
        return self.cardCell;
    }
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.backgroundColor = [Theme surface];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = [Theme text];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.textColor = [Theme secondaryText];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    UIView *selected = [[UIView alloc] init];
    selected.backgroundColor = [Material active] ? [Theme surface] : [[Theme accent] colorWithAlphaComponent:0.12];
    cell.selectedBackgroundView = selected;
    cell.textLabel.text = L(@"su_auto_title");
    cell.detailTextLabel.text = L([AppSettings autoUpdateCheckEnabled] ? @"su_on" : @"su_off");
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SUSectionCard) {
        CGFloat width = tableView.bounds.size.width;
        return MAX(96, [self.card heightForWidth:width]);
    }
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section != SUSectionOptions) return;
    [self chooseAutomatic];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [Material layoutTable:self.tableView inBounds:self.view.bounds];
    CGFloat height = [self.card heightForWidth:self.tableView.bounds.size.width];
    if (fabs(height - self.cardHeight) > 0.5) {
        self.cardHeight = height;
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

#pragma mark - Automatic updates

- (void)chooseAutomatic {
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"su_auto_title") message:L(@"su_auto_msg")];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"su_on") style:UIAlertActionStyleDefault handler:^(id a) {
        [AppSettings setAutoUpdateCheckEnabled:YES];
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:SUSectionOptions] withRowAnimation:UITableViewRowAnimationNone];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"su_off") style:UIAlertActionStyleDefault handler:^(id a) {
        [AppSettings setAutoUpdateCheckEnabled:NO];
        [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:SUSectionOptions] withRowAnimation:UITableViewRowAnimationNone];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

#pragma mark - Beta (developer) channel, behind the password

- (void)chooseBetaChannel {
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"su_beta_title") message:L(@"su_beta_msg")];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"su_beta_off_option") style:UIAlertActionStyleDefault handler:^(id a) {
        [weakSelf leaveDeveloperChannel];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"su_beta_dev_option") style:UIAlertActionStyleDefault handler:^(id a) {
        [weakSelf enterDeveloperChannel];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

- (void)leaveDeveloperChannel {
    UpdateManager *m = [UpdateManager shared];
    if (!m.devChannel) return;
    [m switchToDevChannel:NO];
    [[DevAccess shared] lock];
    [m checkForUpdateForce:YES];
}

- (void)enterDeveloperChannel {
    UpdateManager *m = [UpdateManager shared];
    if (m.devChannel) return;
    if ([DevAccess shared].unlocked) { [self startDeveloperChannel]; return; }
    [self presentPasswordPrompt];
}

- (void)startDeveloperChannel {
    UpdateManager *m = [UpdateManager shared];
    [m switchToDevChannel:YES];
    if (m.devChannel) [m checkForUpdateForce:YES];
}

- (void)presentPasswordPrompt {
    if (self.presentedViewController) return;
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:L(@"dev_prompt_title") message:L(@"dev_prompt_msg")];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = L(@"dev_prompt_placeholder");
        field.secureTextEntry = YES;
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.spellCheckingType = UITextSpellCheckingTypeNo;
        field.keyboardType = UIKeyboardTypeASCIICapable;
        field.returnKeyType = UIReturnKeyDone;
    }];
    __weak typeof(self) weakSelf = self;
    __weak ChoicePopupViewController *weakAlert = alert;
    [alert addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[ChoiceAction actionWithTitle:L(@"dev_prompt_ok") style:UIAlertActionStyleDefault handler:^(id action) {
        UITextField *field = weakAlert.textFields.firstObject;
        NSString *typed = [field.text copy];
        field.text = @"";   // do not keep the password in the field
        [weakSelf submitPassword:typed];
    }]];
    [alert presentFromViewController:self];
}

- (void)submitPassword:(NSString *)password {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.color = [Theme secondaryText];
    spinner.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    [self.view addSubview:spinner];
    [spinner startAnimating];
    self.view.userInteractionEnabled = NO;
    __weak typeof(self) weakSelf = self;
    [[DevAccess shared] unlockWithPassword:password completion:^(DevAccessResult result, NSTimeInterval wait) {
        [spinner removeFromSuperview];
        SoftwareUpdateViewController *me = weakSelf;
        if (!me) return;
        me.view.userInteractionEnabled = YES;
        if (result == DevAccessResultOK) {
            [me startDeveloperChannel];
            return;
        }
        NSString *message;
        if (result == DevAccessResultLockedHour) {
            message = L(@"dev_err_lockout");          // "Ai biểu spam cho cố vô, ..."
        } else if (result == DevAccessResultLockedOut) {
            message = L(@"dev_err_throttle");         // short wait
        } else if (result == DevAccessResultBusy) {
            message = L(@"dev_err_busy");
        } else if (result == DevAccessResultTampered) {
            message = L(@"dev_err_tamper");
        } else {
            message = L(@"dev_err_wrong");
        }
        ChoicePopupViewController *fail = [ChoicePopupViewController alertWithTitle:L(@"dev_prompt_title") message:message];
        [fail addAction:[ChoiceAction actionWithTitle:L(@"update_close") style:UIAlertActionStyleCancel handler:nil]];
        if (!me.presentedViewController) [fail presentFromViewController:me];
    }];
}

@end
