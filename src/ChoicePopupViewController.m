#import "ChoicePopupViewController.h"
#import "Strings.h"
#import "Theme.h"
#import "Material.h"

@interface ChoiceAction ()
@property (copy, nonatomic) NSString *title;
@property (assign, nonatomic) UIAlertActionStyle style;
@property (copy, nonatomic) void (^handler)(id action);
@end

@implementation ChoiceAction
+ (instancetype)actionWithTitle:(NSString *)title style:(UIAlertActionStyle)style handler:(void (^)(id))handler {
    ChoiceAction *action = [[ChoiceAction alloc] init];
    action.title = title ?: @"";
    action.style = style;
    action.handler = handler;
    return action;
}
@end

@interface ChoicePopupViewController ()
@property (copy, nonatomic) NSString *titleText;
@property (copy, nonatomic) NSString *messageText;
@property (assign, nonatomic) BOOL alertMode;
@property (strong, nonatomic) NSMutableArray<ChoiceAction *> *options;   // everything except the cancel action
@property (strong, nonatomic) ChoiceAction *cancelAction;
@property (strong, nonatomic, readwrite) NSMutableArray<UITextField *> *textFields;
@property (strong, nonatomic) NSMutableArray<UIButton *> *buttons;        // alert mode: in display order
@property (strong, nonatomic) NSMutableArray<ChoiceAction *> *buttonActions;
@property (strong, nonatomic) UIView *card;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIScrollView *list;
@property (strong, nonatomic) UIButton *cancelButton;
@property (assign, nonatomic) CGFloat keyboardHeight;
@property (assign, nonatomic) BOOL finished;   // a second tap while closing does nothing
@end

static const CGFloat kRowHeight = 50;
static const CGFloat kRowGap = 8;
static const CGFloat kFieldHeight = 46;
static const CGFloat kButtonHeight = 48;

@implementation ChoicePopupViewController

+ (instancetype)popupWithTitle:(NSString *)title message:(NSString *)message {
    ChoicePopupViewController *popup = [[ChoicePopupViewController alloc] init];
    popup.titleText = title;
    popup.messageText = message;
    return popup;
}

+ (instancetype)alertWithTitle:(NSString *)title message:(NSString *)message {
    ChoicePopupViewController *popup = [self popupWithTitle:title message:message];
    popup.alertMode = YES;
    return popup;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _options = [NSMutableArray array];
        _textFields = [NSMutableArray array];
        _buttons = [NSMutableArray array];
        _buttonActions = [NSMutableArray array];
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)addAction:(ChoiceAction *)action {
    if (!action) return;
    if (action.style == UIAlertActionStyleCancel) self.cancelAction = action;
    else [self.options addObject:action];
}

- (void)addTextFieldWithConfigurationHandler:(void (^)(UITextField *))configure {
    UITextField *field = [[UITextField alloc] init];
    field.font = [UIFont systemFontOfSize:16];
    field.textColor = [Theme text];
    field.tintColor = [Theme accent];
    field.backgroundColor = [Theme surface];
    field.layer.cornerRadius = MR(12, 16);
    field.layer.borderWidth = 1;
    field.layer.borderColor = [Theme border].CGColor;
    field.keyboardAppearance = [Theme keyboardAppearance];
    field.returnKeyType = UIReturnKeyDone;
    field.delegate = self;
    UIView *pad = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 10)];
    field.leftView = pad;
    field.leftViewMode = UITextFieldViewModeAlways;
    if (configure) configure(field);
    if (field.placeholder.length > 0) {
        field.attributedPlaceholder = [[NSAttributedString alloc] initWithString:field.placeholder attributes:@{ NSForegroundColorAttributeName: [Theme secondaryText] }];
    }
    [self.textFields addObject:field];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)presentFromViewController:(UIViewController *)host {
    // Over a pop-up that is still on screen the new one goes on top of it.
    UIViewController *top = host;
    while (top.presentedViewController && !top.presentedViewController.isBeingDismissed) top = top.presentedViewController;
    [top presentViewController:self animated:YES completion:nil];
}

- (UIButton *)makeButtonForAction:(ChoiceAction *)action primary:(BOOL)primary {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:action.title forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    button.titleLabel.numberOfLines = 2;
    button.titleLabel.textAlignment = NSTextAlignmentCenter;
    button.layer.cornerRadius = MR(14, 24);
    button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    if (primary) {
        UIColor *fill = action.style == UIAlertActionStyleDestructive ? [UIColor colorWithRed:0.86 green:0.22 blue:0.22 alpha:1.0] : [Theme accent];
        button.backgroundColor = fill;
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    } else {
        button.backgroundColor = [UIColor clearColor];
        [button setTitleColor:[Theme accent] forState:UIControlStateNormal];
        button.layer.borderWidth = 1.5;
        button.layer.borderColor = [Theme accent].CGColor;
    }
    return button;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    UIVisualEffectView *blur = [Theme backdropBlurView];
    blur.frame = self.view.bounds;
    [self.view addSubview:blur];

    self.card = [[UIView alloc] init];
    self.card.backgroundColor = [Theme background];
    self.card.layer.cornerRadius = MR(24, 28);
    self.card.layer.borderWidth = 1;
    self.card.layer.borderColor = [Theme border].CGColor;
    self.card.layer.shadowColor = [UIColor blackColor].CGColor;
    self.card.layer.shadowOpacity = 0.28;
    self.card.layer.shadowRadius = 24;
    self.card.layer.shadowOffset = CGSizeMake(0, 10);
    [self.view addSubview:self.card];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [Theme serifFontOfSize:22];
    self.titleLabel.textColor = [Theme text];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = self.titleText;
    [self.card addSubview:self.titleLabel];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont systemFontOfSize:14];
    self.messageLabel.textColor = [Theme secondaryText];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.text = self.messageText;
    [self.card addSubview:self.messageLabel];

    if (self.alertMode) {
        for (UITextField *field in self.textFields) [self.card addSubview:field];
        // Buttons: cancel (outlined) first, then the other actions (filled). More than two are stacked.
        NSMutableArray<ChoiceAction *> *ordered = [NSMutableArray array];
        if (self.cancelAction) [ordered addObject:self.cancelAction];
        [ordered addObjectsFromArray:self.options];
        if (ordered.count == 0) [ordered addObject:[ChoiceAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        for (ChoiceAction *action in ordered) {
            UIButton *button = [self makeButtonForAction:action primary:action != self.cancelAction];
            button.tag = (NSInteger)self.buttons.count;
            [button addTarget:self action:@selector(alertButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [self.card addSubview:button];
            [self.buttons addObject:button];
            [self.buttonActions addObject:action];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillHideNotification object:nil];
    } else {
        self.list = [[UIScrollView alloc] init];
        self.list.showsVerticalScrollIndicator = NO;
        self.list.alwaysBounceVertical = NO;
        [self.card addSubview:self.list];

        for (NSUInteger i = 0; i < self.options.count; i++) {
            ChoiceAction *action = self.options[i];
            UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
            row.tag = (NSInteger)i;
            row.backgroundColor = [Theme surface];
            row.layer.cornerRadius = MR(14, 20);
            row.layer.borderWidth = 1;
            row.layer.borderColor = [Theme border].CGColor;
            UIColor *color = action.style == UIAlertActionStyleDestructive ? [UIColor colorWithRed:0.90 green:0.22 blue:0.22 alpha:1.0] : [Theme text];
            [row setTitleColor:color forState:UIControlStateNormal];
            [row setTitle:action.title forState:UIControlStateNormal];
            row.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
            row.titleLabel.numberOfLines = 2;
            row.titleLabel.textAlignment = NSTextAlignmentCenter;
            row.contentEdgeInsets = UIEdgeInsetsMake(0, 14, 0, 14);
            [row addTarget:self action:@selector(optionTapped:) forControlEvents:UIControlEventTouchUpInside];
            [row addTarget:self action:@selector(rowDown:) forControlEvents:UIControlEventTouchDown | UIControlEventTouchDragEnter];
            [row addTarget:self action:@selector(rowUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel | UIControlEventTouchDragExit];
            [self.list addSubview:row];
        }

        self.cancelButton = [self makeButtonForAction:(self.cancelAction ?: [ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]) primary:NO];
        [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.card addSubview:self.cancelButton];
    }

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTapped)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.alertMode && self.textFields.count > 0 && !self.finished) [self.textFields.firstObject becomeFirstResponder];
}

- (void)keyboardChanged:(NSNotification *)note {
    CGRect frame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect local = [self.view convertRect:frame fromView:nil];
    BOOL hiding = [note.name isEqualToString:UIKeyboardWillHideNotification];
    self.keyboardHeight = hiding ? 0 : MAX(0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(local));
    NSTimeInterval duration = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:duration > 0 ? duration : 0.25 animations:^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat cardWidth = MIN(bounds.size.width - 48, 340);
    CGFloat inner = cardWidth - 32;
    CGFloat bottomInset = MAX(safe.bottom, self.keyboardHeight);
    CGFloat available = bounds.size.height - safe.top - bottomInset - 40;

    CGFloat y = 22;
    if (self.titleText.length > 0) {
        CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)];
        self.titleLabel.frame = CGRectMake(16, y, inner, ceil(titleSize.height));
        y += ceil(titleSize.height) + 6;
    } else {
        self.titleLabel.frame = CGRectZero;
    }
    if (self.messageText.length > 0) {
        CGSize messageSize = [self.messageLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)];
        self.messageLabel.frame = CGRectMake(16, y, inner, ceil(messageSize.height));
        y += ceil(messageSize.height) + 6;
    } else {
        self.messageLabel.frame = CGRectZero;
    }
    y += 10;

    if (self.alertMode) {
        for (UITextField *field in self.textFields) {
            field.frame = CGRectMake(16, y, inner, kFieldHeight);
            y += kFieldHeight + 10;
        }
        BOOL sideBySide = self.buttons.count <= 2;
        if (sideBySide) {
            CGFloat gap = 10;
            CGFloat width = (inner - gap * (self.buttons.count - 1)) / self.buttons.count;
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                self.buttons[i].frame = CGRectMake(16 + i * (width + gap), y, width, kButtonHeight);
            }
            y += kButtonHeight;
        } else {
            // stacked: the filled actions first, the outlined cancel last
            NSMutableArray<UIButton *> *stack = [NSMutableArray array];
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                if (self.buttonActions[i] != self.cancelAction) [stack addObject:self.buttons[i]];
            }
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                if (self.buttonActions[i] == self.cancelAction) [stack addObject:self.buttons[i]];
            }
            for (UIButton *button in stack) {
                button.frame = CGRectMake(16, y, inner, kButtonHeight);
                y += kButtonHeight + 8;
            }
            y -= 8;
        }
        y += 18;
    } else {
        CGFloat contentHeight = self.options.count > 0 ? self.options.count * kRowHeight + (self.options.count - 1) * kRowGap : 0;
        CGFloat footer = 12 + kButtonHeight + 18;   // gap, cancel button, bottom margin
        CGFloat listHeight = MIN(contentHeight, MAX(kRowHeight, available - y - footer));
        self.list.frame = CGRectMake(16, y, inner, listHeight);
        self.list.contentSize = CGSizeMake(inner, contentHeight);
        self.list.scrollEnabled = contentHeight > listHeight + 0.5;
        for (UIView *view in self.list.subviews) {
            if (![view isKindOfClass:[UIButton class]]) continue;
            view.frame = CGRectMake(0, view.tag * (kRowHeight + kRowGap), inner, kRowHeight);
        }
        y += listHeight + 12;
        self.cancelButton.frame = CGRectMake(16, y, inner, kButtonHeight);
        y += kButtonHeight + 18;
    }

    CGFloat centerY = safe.top + (bounds.size.height - safe.top - bottomInset) / 2;
    self.card.frame = CGRectMake((bounds.size.width - cardWidth) / 2, centerY - y / 2, cardWidth, y);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([Material active]) { [Material presentDialogCard:self.card]; return; }
    self.card.transform = CGAffineTransformMakeScale(0.94, 0.94);
    [UIView animateWithDuration:0.28 delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0 options:0 animations:^{
        self.card.transform = CGAffineTransformIdentity;
    } completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [Material dismissDialogCard:self.card];
}

- (void)rowDown:(UIButton *)row { if (![Material active]) row.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.14]; }   // Material 3: the spring dip and ripple show the press, no colour flash
- (void)rowUp:(UIButton *)row { row.backgroundColor = [Theme surface]; }

- (void)optionTapped:(UIButton *)row {
    if (self.finished || row.tag < 0 || row.tag >= (NSInteger)self.options.count) return;
    ChoiceAction *action = self.options[(NSUInteger)row.tag];
    [self closeThenRun:action.handler action:action];
}

- (void)alertButtonTapped:(UIButton *)button {
    if (self.finished || button.tag < 0 || button.tag >= (NSInteger)self.buttonActions.count) return;
    ChoiceAction *action = self.buttonActions[(NSUInteger)button.tag];
    [self closeThenRun:action.handler action:action];
}

- (void)cancelTapped {
    if (self.finished) return;
    [self closeThenRun:self.cancelAction.handler action:self.cancelAction];
}

// A tap outside the card cancels a list; an alert with buttons only closes through its buttons (like a system alert),
// except that it closes without a choice when it has no cancel button and a single plain button.
- (void)backgroundTapped {
    if (self.alertMode) {
        [self.view endEditing:YES];
        return;
    }
    [self cancelTapped];
}

- (void)closeThenRun:(void (^)(id))handler action:(ChoiceAction *)action {
    self.finished = YES;
    [self.view endEditing:YES];
    ChoicePopupViewController *keep = self;   // the handler may read the text fields: keep them alive until it ran
    [self dismissViewControllerAnimated:YES completion:^{
        if (handler) handler(action);
        (void)keep;
    }];
}

// A tap outside the card is handled by the background recogniser; taps on the card are not.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return touch.view == self.view;
}

@end
