#import "ConfirmPopupViewController.h"
#import "Strings.h"
#import "Theme.h"
#import "Material.h"

@interface ConfirmPopupViewController ()
@property (copy, nonatomic) NSString *titleText;
@property (copy, nonatomic) NSString *messageText;
@property (copy, nonatomic) NSString *confirmText;
@property (strong, nonatomic) UIView *card;
@property (strong, nonatomic) UIView *iconBadge;
@property (strong, nonatomic) UIImageView *iconView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *messageLabel;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *confirmButton;
@end

@implementation ConfirmPopupViewController

- (instancetype)initWithTitle:(NSString *)title message:(NSString *)message confirmTitle:(NSString *)confirmTitle {
    self = [super init];
    if (self) {
        _titleText = [title copy];
        _messageText = [message copy];
        _confirmText = [confirmTitle copy];
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];   // the blur below replaces the plain dimming
    UIVisualEffectView *backdrop = [Theme backdropBlurView];
    backdrop.frame = self.view.bounds;
    [self.view addSubview:backdrop];

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

    self.iconBadge = [[UIView alloc] init];
    self.iconBadge.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.14];
    self.iconBadge.layer.cornerRadius = 28;
    [self.card addSubview:self.iconBadge];
    self.iconView = [[UIImageView alloc] initWithImage:[Theme iconCompose]];
    self.iconView.tintColor = [Theme accent];
    self.iconView.contentMode = UIViewContentModeCenter;
    [self.iconBadge addSubview:self.iconView];

    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.font = [Theme serifFontOfSize:23];
    self.titleLabel.textColor = [Theme text];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.text = self.titleText;
    [self.card addSubview:self.titleLabel];

    self.messageLabel = [[UILabel alloc] init];
    self.messageLabel.font = [UIFont systemFontOfSize:15];
    self.messageLabel.textColor = [Theme secondaryText];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.numberOfLines = 0;
    self.messageLabel.text = self.messageText;
    [self.card addSubview:self.messageLabel];

    self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.cancelButton setTitle:L(@"cancel") forState:UIControlStateNormal];
    [self.cancelButton setTitleColor:[Theme accent] forState:UIControlStateNormal];
    self.cancelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.cancelButton.layer.cornerRadius = MR(14, 24);
    self.cancelButton.layer.borderWidth = 1.5;
    self.cancelButton.layer.borderColor = [Theme accent].CGColor;
    [self.cancelButton addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.card addSubview:self.cancelButton];

    self.confirmButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.confirmButton setTitle:self.confirmText forState:UIControlStateNormal];
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.confirmButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    self.confirmButton.backgroundColor = [Theme accent];
    self.confirmButton.layer.cornerRadius = MR(14, 24);
    [self.confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.card addSubview:self.confirmButton];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelTapped)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat cardWidth = MIN(bounds.size.width - 48, 340);
    CGFloat inner = cardWidth - 40;

    CGFloat y = 24;
    self.iconBadge.frame = CGRectMake((cardWidth - 56) / 2, y, 56, 56);
    self.iconView.frame = self.iconBadge.bounds;
    y += 56 + 14;

    CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)];
    self.titleLabel.frame = CGRectMake(20, y, inner, ceil(titleSize.height));
    y += ceil(titleSize.height) + 8;

    CGSize messageSize = [self.messageLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)];
    self.messageLabel.frame = CGRectMake(20, y, inner, ceil(messageSize.height));
    y += ceil(messageSize.height) + 22;

    CGFloat gap = 10;
    CGFloat buttonWidth = (inner - gap) / 2;
    self.cancelButton.frame = CGRectMake(20, y, buttonWidth, 48);
    self.confirmButton.frame = CGRectMake(20 + buttonWidth + gap, y, buttonWidth, 48);
    y += 48 + 20;

    CGFloat centerY = safe.top + (bounds.size.height - safe.top - safe.bottom) / 2;
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

- (void)cancelTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)confirmTapped {
    void (^onConfirm)(void) = self.onConfirm;
    [self dismissViewControllerAnimated:YES completion:^{
        if (onConfirm) onConfirm();
    }];
}

// A tap outside the card cancels; taps on the card do not.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return touch.view == self.view;
}

@end
