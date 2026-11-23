#import "RootViewController.h"
#import "Theme.h"
#import "KeyStore.h"
#import "GeminiClient.h"
#import "ClaudeClient.h"
#import "GoogleAuth.h"
#import "Provider.h"
#import "DiagnosticLog.h"
#import "Strings.h"

typedef NS_ENUM(NSInteger, StatusKind) {
    StatusNeutral = 0,
    StatusSuccess,
    StatusError
};

@interface RootViewController ()
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *logoView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UISegmentedControl *providerControl;   // first launch only
@property (strong, nonatomic) UILabel *subtitleLabel;
@property (strong, nonatomic) UIView *fieldContainer;
@property (strong, nonatomic) UITextField *keyField;
@property (strong, nonatomic) UIButton *pasteButton;
@property (strong, nonatomic) UIButton *primaryButton;
@property (strong, nonatomic) UILabel *statusLabel;
@property (strong, nonatomic) UIButton *deleteButton;
@property (strong, nonatomic) UIButton *googleButton;      // Gemini only: sign in with Google
@property (strong, nonatomic) UIButton *googleOutButton;   // Gemini only, when signed in
@property (strong, nonatomic) UIButton *helpButton;
@property (assign, nonatomic) BOOL hasSavedKey;
@property (assign, nonatomic) BOOL busy;
@end

@implementation RootViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [Theme background];
    if (self.embedded) self.title = (self.provider == AIProviderClaude) ? L(@"api_key_claude") : L(@"api_key_gemini");

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tap.cancelsTouchesInView = NO;
    [self.scrollView addGestureRecognizer:tap];

    // Logo
    self.logoView = [[UIImageView alloc] initWithImage:[Theme activeIconImage]];
    self.logoView.contentMode = UIViewContentModeScaleAspectFill;
    self.logoView.layer.cornerRadius = 88 * 0.2237;   // same corner shape as the Home Screen icon
    self.logoView.clipsToBounds = YES;
    [self.scrollView addSubview:self.logoView];

    // Title
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"ClaudeMini";
    self.titleLabel.font = [Theme serifFontOfSize:32];
    self.titleLabel.textColor = [Theme text];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.scrollView addSubview:self.titleLabel];

    // Provider switch (first launch only: from Settings the provider is already fixed)
    if (!self.embedded) {
        self.providerControl = [[UISegmentedControl alloc] initWithItems:@[@"Gemini", @"Claude"]];
        self.providerControl.selectedSegmentIndex = (NSInteger)self.provider;
        self.providerControl.tintColor = [Theme accent];
        [self.providerControl addTarget:self action:@selector(providerChanged) forControlEvents:UIControlEventValueChanged];
        [self.scrollView addSubview:self.providerControl];
    }

    // Subtitle
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = [self subtitleText];
    self.subtitleLabel.font = [UIFont systemFontOfSize:16];
    self.subtitleLabel.textColor = [Theme secondaryText];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.numberOfLines = 0;
    [self.scrollView addSubview:self.subtitleLabel];

    // Key field (container + text field + paste button)
    self.fieldContainer = [[UIView alloc] init];
    self.fieldContainer.backgroundColor = [Theme surface];
    self.fieldContainer.layer.cornerRadius = 12;
    self.fieldContainer.layer.borderWidth = 1;
    self.fieldContainer.layer.borderColor = [Theme border].CGColor;
    [self.scrollView addSubview:self.fieldContainer];

    self.keyField = [[UITextField alloc] init];
    self.keyField.placeholder = [self placeholderText];
    self.keyField.font = [UIFont systemFontOfSize:16];
    self.keyField.textColor = [Theme text];
    self.keyField.keyboardAppearance = [Theme keyboardAppearance];
    self.keyField.secureTextEntry = YES;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.keyField.returnKeyType = UIReturnKeyGo;
    self.keyField.delegate = self;
    [self.keyField addTarget:self action:@selector(fieldChanged) forControlEvents:UIControlEventEditingChanged];
    [self.fieldContainer addSubview:self.keyField];

    self.pasteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.pasteButton setTitle:L(@"paste") forState:UIControlStateNormal];
    [self.pasteButton setTitleColor:[Theme accent] forState:UIControlStateNormal];
    self.pasteButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.pasteButton addTarget:self action:@selector(pasteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.fieldContainer addSubview:self.pasteButton];

    // Primary button
    self.primaryButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.primaryButton setBackgroundImage:[Theme imageWithColor:[Theme accent]] forState:UIControlStateNormal];
    [self.primaryButton setBackgroundImage:[Theme imageWithColor:[Theme accentPressed]] forState:UIControlStateHighlighted];
    [self.primaryButton setBackgroundImage:[Theme imageWithColor:[Theme accentDisabled]] forState:UIControlStateDisabled];
    [self.primaryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.primaryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateDisabled];
    self.primaryButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.primaryButton.layer.cornerRadius = 12;
    self.primaryButton.clipsToBounds = YES;
    [self.primaryButton addTarget:self action:@selector(verifyTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.primaryButton];

    // Google sign-in (Gemini only)
    self.googleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.googleButton.backgroundColor = [Theme surface];
    self.googleButton.layer.cornerRadius = 12;
    self.googleButton.layer.borderWidth = 1;
    self.googleButton.layer.borderColor = [Theme border].CGColor;
    [self.googleButton setTitleColor:[Theme text] forState:UIControlStateNormal];
    self.googleButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.googleButton addTarget:self action:@selector(googleTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.googleButton];

    self.googleOutButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.googleOutButton setTitle:L(@"google_sign_out") forState:UIControlStateNormal];
    [self.googleOutButton setTitleColor:[Theme error] forState:UIControlStateNormal];
    self.googleOutButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.googleOutButton addTarget:self action:@selector(googleSignOutTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.googleOutButton];

    // Status
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:15];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.scrollView addSubview:self.statusLabel];

    // Delete key
    self.deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.deleteButton setTitle:L(@"delete_key") forState:UIControlStateNormal];
    [self.deleteButton setTitleColor:[Theme error] forState:UIControlStateNormal];
    self.deleteButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    [self.deleteButton addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.deleteButton];

    // Help link
    self.helpButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.helpButton setTitle:[self helpTitle] forState:UIControlStateNormal];
    [self.helpButton setTitleColor:[Theme accent] forState:UIControlStateNormal];
    self.helpButton.titleLabel.font = [UIFont systemFontOfSize:15];
    self.helpButton.titleLabel.numberOfLines = 0;
    self.helpButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.helpButton addTarget:self action:@selector(helpTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:self.helpButton];

    // Keyboard handling
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChange:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];

    [self refreshSavedState];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    UIImage *icon = [Theme activeIconImage];   // the icon may have been changed in Settings meanwhile
    if (icon && icon != self.logoView.image) self.logoView.image = icon;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDefault;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.frame = self.view.bounds;

    CGFloat width = self.view.bounds.size.width;
    CGFloat contentWidth = MIN(width - 48, 440);
    CGFloat x = (width - contentWidth) / 2;
    CGFloat safeTop = 20, safeBottom = 0;
    if (@available(iOS 11.0, *)) {
        safeTop = self.view.safeAreaInsets.top;
        safeBottom = self.view.safeAreaInsets.bottom;
    }
    CGFloat y = safeTop + 36;

    self.logoView.frame = CGRectMake((width - 88) / 2, y, 88, 88);
    y += 88 + 18;

    self.titleLabel.frame = CGRectMake(x, y, contentWidth, 40);
    y += 40 + 8;

    if (self.providerControl) {
        self.providerControl.frame = CGRectMake(x, y, contentWidth, 32);
        y += 32 + 14;
    }

    CGSize subtitleSize = [self.subtitleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    self.subtitleLabel.frame = CGRectMake(x, y, contentWidth, ceil(subtitleSize.height));
    y += ceil(subtitleSize.height) + 28;

    self.fieldContainer.frame = CGRectMake(x, y, contentWidth, 52);
    CGFloat pasteWidth = 64;
    self.pasteButton.frame = CGRectMake(contentWidth - pasteWidth - 4, 0, pasteWidth, 52);
    self.keyField.frame = CGRectMake(14, 0, contentWidth - pasteWidth - 22, 52);
    y += 52 + 12;

    self.primaryButton.frame = CGRectMake(x, y, contentWidth, 52);
    y += 52 + 14;

    BOOL showGoogle = (self.provider == AIProviderGemini);
    self.googleButton.hidden = !showGoogle;
    BOOL googleIn = showGoogle && [GoogleAuth isSignedIn];
    self.googleOutButton.hidden = !googleIn;
    if (showGoogle) {
        self.googleButton.frame = CGRectMake(x, y, contentWidth, 52);
        y += 52 + 8;
        if (googleIn) {
            self.googleOutButton.frame = CGRectMake(x, y, contentWidth, 36);
            y += 36 + 6;
        }
        y += 6;
    }

    if (self.statusLabel.text.length > 0) {
        CGSize statusSize = [self.statusLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
        self.statusLabel.frame = CGRectMake(x, y, contentWidth, ceil(statusSize.height));
        y += ceil(statusSize.height) + 12;
    } else {
        self.statusLabel.frame = CGRectMake(x, y, contentWidth, 0);
    }

    if (self.hasSavedKey) {
        self.deleteButton.hidden = NO;
        self.deleteButton.frame = CGRectMake(x, y, contentWidth, 40);
        y += 40;
    } else {
        self.deleteButton.hidden = YES;
    }

    y += 20;
    CGSize helpSize = [self.helpButton.titleLabel sizeThatFits:CGSizeMake(contentWidth, CGFLOAT_MAX)];
    CGFloat helpHeight = MAX(44, ceil(helpSize.height) + 16);
    self.helpButton.frame = CGRectMake(x, y, contentWidth, helpHeight);
    y += helpHeight;

    self.scrollView.contentSize = CGSizeMake(width, y + safeBottom + 24);
}

#pragma mark - State

- (void)refreshSavedState {
    NSString *saved = [KeyStore loadRawKeyForProvider:self.provider];
    self.hasSavedKey = saved.length > 0;
    if (self.statusLabel.text.length == 0) {
        if (self.provider == AIProviderGemini && [GoogleAuth isSignedIn] && (!self.hasSavedKey || [GoogleAuth prefersGoogle])) {
            NSString *who = [GoogleAuth accountEmail].length ? [GoogleAuth accountEmail] : @"Google";
            [self setStatus:[NSString stringWithFormat:L(@"google_signed_in_as"), who] kind:StatusNeutral];
        } else if (self.hasSavedKey) {
            NSString *tail = saved.length > 4 ? [saved substringFromIndex:saved.length - 4] : saved;
            [self setStatus:[NSString stringWithFormat:L(@"status_saved"), tail] kind:StatusNeutral];
        }
    }
    [self updateGoogleButtonTitle];
    [self updateButtonTitle];
    [self.view setNeedsLayout];
}

- (void)updateButtonTitle {
    if (self.busy) {
        [self.primaryButton setTitle:L(@"verifying") forState:UIControlStateNormal];
        [self.primaryButton setTitle:L(@"verifying") forState:UIControlStateDisabled];
        self.primaryButton.enabled = NO;
        return;
    }
    self.primaryButton.enabled = YES;
    BOOL googleOnly = (self.provider == AIProviderGemini && [GoogleAuth isSignedIn]);
    BOOL recheck = (self.hasSavedKey || googleOnly) && self.keyField.text.length == 0;
    NSString *title = recheck ? L(@"verify_again") : L(@"verify_save");
    [self.primaryButton setTitle:title forState:UIControlStateNormal];
}

- (void)setStatus:(NSString *)text kind:(StatusKind)kind {
    self.statusLabel.text = text;
    switch (kind) {
        case StatusSuccess: self.statusLabel.textColor = [Theme success]; break;
        case StatusError:   self.statusLabel.textColor = [Theme error]; break;
        default:            self.statusLabel.textColor = [Theme secondaryText]; break;
    }
    [self.view setNeedsLayout];
}

#pragma mark - Actions

#pragma mark - Provider texts

- (NSString *)subtitleText {
    if (self.provider == AIProviderClaude) return L(@"subtitle_claude");
    return L(@"subtitle_gemini");
}

- (NSString *)placeholderText {
    if (self.provider == AIProviderClaude) return L(@"placeholder_claude");
    return L(@"placeholder_gemini");
}

- (NSString *)helpTitle {
    if (self.provider == AIProviderClaude) return L(@"get_key_claude");
    return L(@"get_key_gemini");
}

- (void)providerChanged {
    self.provider = (AIProvider)self.providerControl.selectedSegmentIndex;
    self.keyField.text = @"";
    [self setStatus:@"" kind:StatusNeutral];
    self.subtitleLabel.text = [self subtitleText];
    self.keyField.placeholder = [self placeholderText];
    [self.helpButton setTitle:[self helpTitle] forState:UIControlStateNormal];
    [self refreshSavedState];
    [self.view setNeedsLayout];
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)fieldChanged {
    [self updateButtonTitle];
}

- (void)pasteTapped {
    NSString *clip = [UIPasteboard generalPasteboard].string;
    if (clip.length > 0) {
        self.keyField.text = [clip stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        [self updateButtonTitle];
    }
}

- (void)helpTapped {
    NSURL *url = [NSURL URLWithString:(self.provider == AIProviderClaude) ? @"https://console.anthropic.com/settings/keys"
                                                                         : @"https://aistudio.google.com/apikey"];
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}

- (void)verifyTapped {
    if (self.busy) return;
    [self.view endEditing:YES];

    NSString *typed = [self.keyField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL fromField = typed.length > 0;
    NSString *key = fromField ? typed : [KeyStore loadRawKeyForProvider:self.provider];
    if (key.length == 0 && self.provider == AIProviderGemini && [GoogleAuth isSignedIn]) key = kGoogleOAuthKeyMarker;   // re-check the Google session
    if (key.length == 0) {
        [self setStatus:L(@"status_empty") kind:StatusError];
        return;
    }

    self.busy = YES;
    [self setStatus:@"" kind:StatusNeutral];
    [self updateButtonTitle];

    __weak typeof(self) weakSelf = self;
    GeminiVerifyCompletion completion = ^(GeminiCheckResult result, NSInteger count, NSInteger httpStatus) {
        RootViewController *strongSelf = weakSelf;
        if (!strongSelf) return;
        strongSelf.busy = NO;
        [DiagnosticLog log:@"key check: %@ result=%ld http=%ld models=%ld", [Provider nameFor:strongSelf.provider], (long)result, (long)httpStatus, (long)count];

        switch (result) {
            case GeminiCheckOK: {
                if (fromField) {
                    if (![KeyStore saveKey:key forProvider:strongSelf.provider]) {
                        [strongSelf setStatus:L(@"status_save_failed") kind:StatusError];
                        break;
                    }
                    strongSelf.keyField.text = @"";
                }
                strongSelf.hasSavedKey = YES;
                [strongSelf setStatus:[NSString stringWithFormat:L(@"status_ok"), (long)count] kind:StatusSuccess];
                if (!strongSelf.embedded) {
                    // Let the person see "key is valid" for a moment, then open the chat.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
                    });
                }
                break;
            }
            case GeminiCheckInvalidKey:
                if ([key isEqualToString:kGoogleOAuthKeyMarker]) {
                    NSString *msg = (httpStatus == 0) ? L(@"google_err_expired")
                                                      : [NSString stringWithFormat:L(@"google_status_denied"), (long)httpStatus];
                    [strongSelf setStatus:msg kind:StatusError];
                } else {
                    [strongSelf setStatus:L(@"status_invalid") kind:StatusError];
                }
                break;
            case GeminiCheckRateLimited:
                [strongSelf setStatus:L(@"status_rate") kind:StatusError];
                break;
            case GeminiCheckNetworkError:
                [strongSelf setStatus:L(@"status_network") kind:StatusError];
                break;
            default:
                [strongSelf setStatus:[NSString stringWithFormat:L(@"status_unknown"), (long)httpStatus] kind:StatusError];
                break;
        }
        [strongSelf updateButtonTitle];
        [strongSelf.view setNeedsLayout];
    };

    if (self.provider == AIProviderClaude) {
        [ClaudeClient verifyKey:key completion:completion];
    } else {
        [GeminiClient verifyKey:key completion:completion];
    }
}

#pragma mark - Google sign-in

- (void)updateGoogleButtonTitle {
    NSString *title = [GoogleAuth isSignedIn] ? L(@"google_sign_in_again") : L(@"google_sign_in");
    [self.googleButton setTitle:title forState:UIControlStateNormal];
}

- (void)googleTapped {
    if (self.busy) return;
    [self.view endEditing:YES];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"google_setup_title")
                                                                   message:L(@"google_setup_msg")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = L(@"google_client_id_placeholder");
        field.text = [GoogleAuth savedClientID];
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
        field.keyboardType = UIKeyboardTypeURL;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = L(@"google_project_placeholder");
        field.text = [GoogleAuth savedProjectID];
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:L(@"google_continue") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        RootViewController *me = weakSelf;
        if (!me) return;
        [me startGoogleSignInWithClientID:alert.textFields[0].text projectID:alert.textFields[1].text];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)startGoogleSignInWithClientID:(NSString *)clientID projectID:(NSString *)projectID {
    self.busy = YES;
    [self setStatus:@"" kind:StatusNeutral];
    [self updateButtonTitle];
    __weak typeof(self) weakSelf = self;
    [GoogleAuth signInWithClientID:clientID projectID:projectID presenter:self completion:^(BOOL ok, NSString *message) {
        RootViewController *me = weakSelf;
        if (!me) return;
        if (!ok) {
            me.busy = NO;
            if (message.length > 0) [me setStatus:message kind:StatusError];
            [me updateButtonTitle];
            [me.view setNeedsLayout];
            return;
        }
        // Signed in: check that Gemini really answers for this account/project and count the models.
        [GeminiClient verifyKey:kGoogleOAuthKeyMarker completion:^(GeminiCheckResult result, NSInteger count, NSInteger httpStatus) {
            RootViewController *strongSelf = weakSelf;
            if (!strongSelf) return;
            strongSelf.busy = NO;
            [DiagnosticLog log:@"google gemini check: result=%ld http=%ld models=%ld", (long)result, (long)httpStatus, (long)count];
            if (result == GeminiCheckOK) {
                [strongSelf setStatus:[NSString stringWithFormat:L(@"status_ok"), (long)count] kind:StatusSuccess];
                if (!strongSelf.embedded) {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
                    });
                }
            } else if (result == GeminiCheckRateLimited) {
                [strongSelf setStatus:L(@"status_rate") kind:StatusError];
            } else if (result == GeminiCheckNetworkError) {
                [strongSelf setStatus:L(@"status_network") kind:StatusError];
            } else {
                [strongSelf setStatus:[NSString stringWithFormat:L(@"google_status_denied"), (long)httpStatus] kind:StatusError];
            }
            [strongSelf updateGoogleButtonTitle];
            [strongSelf updateButtonTitle];
            [strongSelf.view setNeedsLayout];
        }];
    }];
}

- (void)googleSignOutTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:L(@"google_sign_out")
                                                                   message:L(@"google_sign_out_confirm")
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:L(@"google_sign_out") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        RootViewController *me = weakSelf;
        if (!me) return;
        [GoogleAuth signOut];
        [me setStatus:L(@"status_deleted") kind:StatusNeutral];
        [me updateGoogleButtonTitle];
        [me updateButtonTitle];
        [me.view setNeedsLayout];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteTapped {
    UIAlertController *alert =
        [UIAlertController alertControllerWithTitle:L(@"delete_confirm_title")
                                            message:L(@"delete_confirm_msg")
                                     preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:L(@"delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        RootViewController *strongSelf = weakSelf;
        if (!strongSelf) return;
        [KeyStore deleteKeyForProvider:strongSelf.provider];
        strongSelf.hasSavedKey = NO;
        [strongSelf setStatus:L(@"status_deleted") kind:StatusNeutral];
        [strongSelf updateButtonTitle];
        [strongSelf.view setNeedsLayout];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifKeyChanged object:nil];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self verifyTapped];
    return YES;
}

#pragma mark - Keyboard

- (void)keyboardWillChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect local = [self.view convertRect:endFrame fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.view.bounds) - local.origin.y);
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, overlap, 0);
    self.scrollView.contentInset = insets;
    self.scrollView.scrollIndicatorInsets = insets;
    if (overlap > 0) {
        [self.scrollView scrollRectToVisible:CGRectInset(self.primaryButton.frame, 0, -16) animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)note {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

@end
