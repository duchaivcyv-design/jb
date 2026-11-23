#import "SettingsViewController.h"
#import "Strings.h"
#import "ChoicePopupViewController.h"
#import "Theme.h"
#import "KeyStore.h"
#import "GoogleAuth.h"
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
#import "SoftwareUpdateViewController.h"
#import "DevAccess.h"
#import "Material.h"

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
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UISlider *weightSlider;
@property (strong, nonatomic) UILabel *weightValueLabel;
@property (strong, nonatomic) NSArray<UIImageView *> *fontChecks;   // tick of the Claude font / system font row
@end

// Claude font (serif) or the iOS system font, whichever is chosen.
static UIFont *PreviewFont(CGFloat size, BOOL bold) {
    if ([AppSettings fontStyle] != 0) return [UIFont systemFontOfSize:size weight:bold ? UIFontWeightSemibold : UIFontWeightRegular];   // the app-wide font hook adds the rounded design / weight
    return [UIFont fontWithName:@"Georgia" size:size] ?: [UIFont systemFontOfSize:size weight:bold ? UIFontWeightSemibold : UIFontWeightRegular];
}

// Font of each row of the font list, drawn in its own design whatever is chosen now (system rows ignore the rounded hook).
static UIFont *FontPreviewRowFont(NSInteger row) {
    if (row == 0) return [UIFont fontWithName:@"Georgia" size:19] ?: [UIFont systemFontOfSize:19];
    UIFont *plain = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];   // not touched by the font hook
    UIFontDescriptor *descriptor = [plain.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    if (row == 2) {
        if (@available(iOS 13.0, *)) {
            UIFontDescriptor *rounded = [(descriptor ?: plain.fontDescriptor) fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
            if (rounded) return [UIFont fontWithDescriptor:rounded size:19];
        }
    }
    return [UIFont fontWithDescriptor:(descriptor ?: plain.fontDescriptor) size:19];
}

static UIImage *TickImage(UIColor *color) {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(20, 20)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        UIBezierPath *tick = [UIBezierPath bezierPath];
        [tick moveToPoint:CGPointMake(3.5, 10.5)];
        [tick addLineToPoint:CGPointMake(8, 15)];
        [tick addLineToPoint:CGPointMake(16.5, 5.5)];
        tick.lineWidth = 2.4;
        tick.lineCapStyle = kCGLineCapRound;
        tick.lineJoinStyle = kCGLineJoinRound;
        [color setStroke];
        [tick stroke];
    }];
}

// A low-priority "height == value": it settles an otherwise open height without fighting the real limits.
static NSLayoutConstraint *PreferredHeight(UIView *view, CGFloat value) {
    NSLayoutConstraint *constraint = [view.heightAnchor constraintEqualToConstant:value];
    constraint.priority = UILayoutPriorityDefaultLow;
    return constraint;
}

@implementation FontScalePreviewViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"C\u1EE1 ch\u1EEF";
    self.view.backgroundColor = [Theme background];

    CGFloat initialScale = [AppSettings uiScale];

    // Everything sits in a scroll view: with the font and weight rows the page is taller than a phone screen.
    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    scroll.showsVerticalScrollIndicator = NO;
    scroll.delaysContentTouches = NO;
    if (@available(iOS 11.0, *)) scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    [self.view addSubview:scroll];
    UIView *content = [[UIView alloc] init];
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];
    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        // The content is tied to the scroll view's content layout guide and its width to the frame guide:
        // this is what lets the scroll view work out its own content size and scroll.
        [content.topAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.topAnchor],
        [content.bottomAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.leadingAnchor],
        [content.trailingAnchor constraintEqualToAnchor:scroll.contentLayoutGuide.trailingAnchor],
        [content.widthAnchor constraintEqualToAnchor:scroll.frameLayoutGuide.widthAnchor],
    ]];
    self.scrollView = scroll;

    // Khung preview tin nhắn
    self.previewContainer = [[UIView alloc] init];
    self.previewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.previewContainer.backgroundColor = [Theme surface];
    self.previewContainer.layer.cornerRadius = MR(16, 28);
    self.previewContainer.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    self.previewContainer.layer.borderColor = [Theme border].CGColor;
    [content addSubview:self.previewContainer];

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
    controlCard.layer.cornerRadius = MR(14, 28);
    controlCard.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    controlCard.layer.borderColor = [Theme border].CGColor;
    [content addSubview:controlCard];

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
    [content addSubview:resetButton];

    UILayoutGuide *safe0 = self.view.safeAreaLayoutGuide;
    // Font chữ: Claude font or system font, each row shown in its own font
    UILabel *fontHeader = [[UILabel alloc] init];
    fontHeader.translatesAutoresizingMaskIntoConstraints = NO;
    fontHeader.text = [L(@"font_header") uppercaseString];
    fontHeader.font = [UIFont systemFontOfSize:13];
    fontHeader.textColor = [Theme secondaryText];
    [content addSubview:fontHeader];

    UIView *fontCard = [[UIView alloc] init];
    fontCard.translatesAutoresizingMaskIntoConstraints = NO;
    fontCard.backgroundColor = [Theme surface];
    fontCard.layer.cornerRadius = MR(14, 28);
    fontCard.layer.masksToBounds = YES;
    fontCard.layer.borderWidth = 1.0 / [UIScreen mainScreen].scale;
    fontCard.layer.borderColor = [Theme border].CGColor;
    [content addSubview:fontCard];

    NSMutableArray<UIImageView *> *checks = [NSMutableArray array];
    NSMutableArray<NSLayoutConstraint *> *fontConstraints = [NSMutableArray array];
    UIView *previousRow = nil;
    for (NSInteger i = 0; i < 3; i++) {
        UIButton *row = [UIButton buttonWithType:UIButtonTypeCustom];
        row.translatesAutoresizingMaskIntoConstraints = NO;
        row.tag = i;
        [row addTarget:self action:@selector(fontRowTapped:) forControlEvents:UIControlEventTouchUpInside];
        [fontCard addSubview:row];

        UILabel *name = [[UILabel alloc] init];
        name.translatesAutoresizingMaskIntoConstraints = NO;
        name.userInteractionEnabled = NO;
        name.text = L(i == 1 ? @"font_system" : (i == 2 ? @"font_rounded" : @"font_claude"));
        name.textColor = [Theme text];
        name.font = FontPreviewRowFont(i);
        [row addSubview:name];

        UIImageView *tick = [[UIImageView alloc] initWithImage:TickImage([Theme accent])];
        tick.translatesAutoresizingMaskIntoConstraints = NO;
        tick.userInteractionEnabled = NO;
        [row addSubview:tick];
        [checks addObject:tick];

        [fontConstraints addObjectsFromArray:@[
            [row.leadingAnchor constraintEqualToAnchor:fontCard.leadingAnchor],
            [row.trailingAnchor constraintEqualToAnchor:fontCard.trailingAnchor],
            [row.heightAnchor constraintEqualToConstant:46],
            [row.topAnchor constraintEqualToAnchor:previousRow ? previousRow.bottomAnchor : fontCard.topAnchor constant:previousRow ? 1.0 / [UIScreen mainScreen].scale : 0],
            [name.leadingAnchor constraintEqualToAnchor:row.leadingAnchor constant:16],
            [name.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            [tick.trailingAnchor constraintEqualToAnchor:row.trailingAnchor constant:-16],
            [tick.centerYAnchor constraintEqualToAnchor:row.centerYAnchor],
            [tick.widthAnchor constraintEqualToConstant:20],
            [tick.heightAnchor constraintEqualToConstant:20],
        ]];
        if (i < 2) {
            UIView *line = [[UIView alloc] init];
            line.translatesAutoresizingMaskIntoConstraints = NO;
            line.backgroundColor = [Theme border];
            [fontCard addSubview:line];
            [fontConstraints addObjectsFromArray:@[
                [line.leadingAnchor constraintEqualToAnchor:fontCard.leadingAnchor constant:16],
                [line.trailingAnchor constraintEqualToAnchor:fontCard.trailingAnchor],
                [line.topAnchor constraintEqualToAnchor:row.bottomAnchor],
                [line.heightAnchor constraintEqualToConstant:1.0 / [UIScreen mainScreen].scale],
            ]];
        }
        previousRow = row;
    }
    // Font weight: lighter ... bolder, in seven steps.
    UIView *weightDivider = [[UIView alloc] init];
    weightDivider.translatesAutoresizingMaskIntoConstraints = NO;
    weightDivider.backgroundColor = [Theme border];
    [fontCard addSubview:weightDivider];
    UILabel *weightTitle = [[UILabel alloc] init];
    weightTitle.translatesAutoresizingMaskIntoConstraints = NO;
    weightTitle.text = L(@"font_weight_title");
    weightTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    weightTitle.textColor = [Theme text];
    [fontCard addSubview:weightTitle];
    self.weightValueLabel = [[UILabel alloc] init];
    self.weightValueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.weightValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightSemibold];
    self.weightValueLabel.textColor = [Theme accent];
    [fontCard addSubview:self.weightValueLabel];
    self.weightSlider = [[UISlider alloc] init];
    self.weightSlider.translatesAutoresizingMaskIntoConstraints = NO;
    self.weightSlider.minimumValue = -3;
    self.weightSlider.maximumValue = 3;
    self.weightSlider.value = (float)[AppSettings fontWeightStep];
    self.weightSlider.tintColor = [Theme accent];
    [self.weightSlider addTarget:self action:@selector(weightChanged:) forControlEvents:UIControlEventValueChanged];
    [self.weightSlider addTarget:self action:@selector(weightReleased:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    [fontCard addSubview:self.weightSlider];
    [fontConstraints addObjectsFromArray:@[
        [weightDivider.leadingAnchor constraintEqualToAnchor:fontCard.leadingAnchor constant:16],
        [weightDivider.trailingAnchor constraintEqualToAnchor:fontCard.trailingAnchor],
        [weightDivider.topAnchor constraintEqualToAnchor:previousRow.bottomAnchor],
        [weightDivider.heightAnchor constraintEqualToConstant:1.0 / [UIScreen mainScreen].scale],
        [weightTitle.topAnchor constraintEqualToAnchor:weightDivider.bottomAnchor constant:12],
        [weightTitle.leadingAnchor constraintEqualToAnchor:fontCard.leadingAnchor constant:16],
        [self.weightValueLabel.centerYAnchor constraintEqualToAnchor:weightTitle.centerYAnchor],
        [self.weightValueLabel.trailingAnchor constraintEqualToAnchor:fontCard.trailingAnchor constant:-16],
        [self.weightSlider.topAnchor constraintEqualToAnchor:weightTitle.bottomAnchor constant:6],
        [self.weightSlider.leadingAnchor constraintEqualToAnchor:fontCard.leadingAnchor constant:16],
        [self.weightSlider.trailingAnchor constraintEqualToAnchor:fontCard.trailingAnchor constant:-16],
        [self.weightSlider.bottomAnchor constraintEqualToAnchor:fontCard.bottomAnchor constant:-10],
    ]];
    [self updateWeightLabel];
    self.fontChecks = checks;
    [NSLayoutConstraint activateConstraints:fontConstraints];
    [NSLayoutConstraint activateConstraints:@[
        [fontHeader.topAnchor constraintEqualToAnchor:resetButton.bottomAnchor constant:8],
        [fontHeader.leadingAnchor constraintEqualToAnchor:safe0.leadingAnchor constant:32],
        [fontCard.topAnchor constraintEqualToAnchor:fontHeader.bottomAnchor constant:8],
        [fontCard.leadingAnchor constraintEqualToAnchor:safe0.leadingAnchor constant:16],
        [fontCard.trailingAnchor constraintEqualToAnchor:safe0.trailingAnchor constant:-16],
        [content.bottomAnchor constraintEqualToAnchor:fontCard.bottomAnchor constant:24],   // room under the card for the home bar
    ]];
    [self updateFontChecks];

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
        [self.previewContainer.topAnchor constraintEqualToAnchor:safe.topAnchor constant:12],
        [self.previewContainer.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor constant:16],
        [self.previewContainer.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor constant:-16],
        [self.previewContainer.heightAnchor constraintGreaterThanOrEqualToConstant:140],
        PreferredHeight(self.previewContainer, 140),   // no slack: the card is as tall as its bubbles need (at least 170), so the page height is exact

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

        [controlCard.topAnchor constraintEqualToAnchor:self.previewContainer.bottomAnchor constant:12],
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

        [resetButton.topAnchor constraintEqualToAnchor:controlCard.bottomAnchor constant:6],
        [resetButton.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor]
    ]];

    [self applyScale:initialScale];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // Extra room under the last card (an inset, so no card is stretched to make it): the weight row can be lifted clear of the bottom edge.
    CGFloat bottom = 90;
    if (@available(iOS 11.0, *)) bottom += self.view.safeAreaInsets.bottom;
    // When the content is shorter than the screen, the inset also covers the gap, so there is always about 100 pt to scroll.
    CGFloat contentHeight = self.scrollView.contentSize.height;
    if (contentHeight < 1) {   // the scroll view has not measured its content yet: look again on the next pass
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf.view setNeedsLayout]; });
    } else {
        CGFloat gap = self.scrollView.bounds.size.height - contentHeight;
        if (gap + 100 > bottom) bottom = gap + 100;
    }
    UIEdgeInsets inset = self.scrollView.contentInset;
    if (fabs(inset.bottom - bottom) > 0.5) {
        inset.bottom = bottom;
        self.scrollView.contentInset = inset;
        self.scrollView.scrollIndicatorInsets = inset;
    }
}

- (void)updateWeightLabel {
    NSInteger step = [AppSettings fontWeightStep];
    self.weightValueLabel.text = step == 0 ? L(@"font_weight_normal") : [NSString stringWithFormat:@"%+ld", (long)step];
}

- (void)weightChanged:(UISlider *)slider {
    NSInteger step = (NSInteger)lround(slider.value);
    slider.value = (float)step;   // snaps to the seven steps
    if (step == [AppSettings fontWeightStep]) return;
    [AppSettings setFontWeightStep:step];
    [self updateWeightLabel];
    [self applyScale:[AppSettings uiScale]];
}

- (void)weightReleased:(UISlider *)slider {
    [Theme postChange];   // bars and titles pick the new weight up
}

- (void)updateFontChecks {
    NSInteger style = [AppSettings fontStyle];
    for (NSInteger i = 0; i < (NSInteger)self.fontChecks.count; i++) self.fontChecks[i].hidden = (i != style);
}

- (void)fontRowTapped:(UIButton *)sender {
    NSInteger style = sender.tag;
    if ([AppSettings fontStyle] == style) return;
    [AppSettings setFontStyle:style];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UIScaleDidChangeNotification" object:nil];
    [Theme postChange];   // bars and titles pick the new font up
    [self updateFontChecks];
    [self applyScale:[AppSettings uiScale]];
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
    self.aiLabel.font = PreviewFont(fontSize, NO);
    self.userLabel.font = PreviewFont(fontSize, NO);

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

#pragma mark - Row icons (iOS Settings style: colored rounded tile with a white glyph, all drawn in code)

typedef NS_ENUM(NSInteger, SettingsIconKind) {
    SIAppearance = 0, SILanguage, SIFontSize, SIKeyGemini, SIKeyClaude, SIKeyTier, SIPrompt, SIPhoto, SITokens,
    SIContext, SITrash, SIInfo, SIUpdate, SIDeveloper, SIDiagnostics, SIKindCount
};

static UIColor *SettingsRGB(uint32_t hex) {
    return [UIColor colorWithRed:((hex >> 16) & 0xFF) / 255.0 green:((hex >> 8) & 0xFF) / 255.0 blue:(hex & 0xFF) / 255.0 alpha:1];
}

static UIColor *SettingsTileColor(SettingsIconKind kind) {
    switch (kind) {
        case SIAppearance: return SettingsRGB(0x007AFF);
        case SILanguage:   return SettingsRGB(0xAF52DE);
        case SIFontSize:   return SettingsRGB(0x5856D6);
        case SIKeyGemini:  return SettingsRGB(0x4285F4);
        case SIKeyClaude:  return SettingsRGB(0xD97757);
        case SIKeyTier:    return SettingsRGB(0x34C759);
        case SIPrompt:     return SettingsRGB(0xFF9500);
        case SIPhoto:      return SettingsRGB(0xFF2D55);
        case SITokens:     return SettingsRGB(0x30B0C7);
        case SIContext:    return SettingsRGB(0x8E8E93);
        case SITrash:      return SettingsRGB(0xFF3B30);
        case SIInfo:       return SettingsRGB(0x8E8E93);
        case SIUpdate:     return SettingsRGB(0x007AFF);
        case SIDeveloper:  return SettingsRGB(0x3A3A3C);
        default:           return SettingsRGB(0xFF9500);   // diagnostics
    }
}

static void StrokeLine(CGPoint a, CGPoint b, CGFloat width) {
    UIBezierPath *line = [UIBezierPath bezierPath];
    [line moveToPoint:a];
    [line addLineToPoint:b];
    line.lineWidth = width;
    line.lineCapStyle = kCGLineCapRound;
    [line stroke];
}

// Draws the glyph of a row icon in a 30 x 30 box with the given ink colour.
static void DrawSettingsGlyph(SettingsIconKind kind, UIColor *ink) {
    UIColor *white = ink;
        [white setStroke];
        [white setFill];
        CGPoint c = CGPointMake(15, 15);
        switch (kind) {
            case SIAppearance: {   // half-filled circle (display brightness)
                UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:c radius:8 startAngle:0 endAngle:2 * M_PI clockwise:YES];
                ring.lineWidth = 1.8;
                [ring stroke];
                UIBezierPath *half = [UIBezierPath bezierPathWithArcCenter:c radius:8 startAngle:M_PI_2 endAngle:3 * M_PI_2 clockwise:YES];
                [half closePath];
                [half fill];
                break;
            }
            case SILanguage: {   // globe
                UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:c radius:8.5 startAngle:0 endAngle:2 * M_PI clockwise:YES];
                ring.lineWidth = 1.6;
                [ring stroke];
                UIBezierPath *meridian = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(15 - 3.6, 15 - 8.5, 7.2, 17)];
                meridian.lineWidth = 1.5;
                [meridian stroke];
                StrokeLine(CGPointMake(6.5, 15), CGPointMake(23.5, 15), 1.5);
                break;
            }
            case SIFontSize: {   // "Aa"
                UIFont *big = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
                UIFont *small = [UIFont systemFontOfSize:11 weight:UIFontWeightBold];
                NSDictionary *bigAttrs = @{ NSFontAttributeName: big, NSForegroundColorAttributeName: white };
                NSDictionary *smallAttrs = @{ NSFontAttributeName: small, NSForegroundColorAttributeName: white };
                CGFloat baseline = 21;
                [@"A" drawAtPoint:CGPointMake(5, baseline - big.ascender) withAttributes:bigAttrs];
                [@"a" drawAtPoint:CGPointMake(16.2, baseline - small.ascender) withAttributes:smallAttrs];
                break;
            }
            case SIKeyGemini:
            case SIKeyClaude: {   // key
                UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:CGPointMake(10.5, 15) radius:4.3 startAngle:0 endAngle:2 * M_PI clockwise:YES];
                ring.lineWidth = 2.1;
                [ring stroke];
                StrokeLine(CGPointMake(14.8, 15), CGPointMake(24, 15), 2.1);
                StrokeLine(CGPointMake(19.8, 15), CGPointMake(19.8, 19), 2.1);
                StrokeLine(CGPointMake(23.6, 15), CGPointMake(23.6, 18.4), 2.1);
                break;
            }
            case SIKeyTier: {   // rising bars
                CGFloat heights[3] = { 6, 10.5, 15 };
                for (int i = 0; i < 3; i++) {
                    CGRect bar = CGRectMake(7 + i * 6.2, 22.5 - heights[i], 4.6, heights[i]);
                    [[UIBezierPath bezierPathWithRoundedRect:bar cornerRadius:1.4] fill];
                }
                break;
            }
            case SIPrompt: {   // document with lines
                UIBezierPath *page = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(8.5, 6.5, 13, 17) cornerRadius:2.5];
                page.lineWidth = 1.8;
                [page stroke];
                StrokeLine(CGPointMake(11.8, 11.5), CGPointMake(18.2, 11.5), 1.6);
                StrokeLine(CGPointMake(11.8, 15), CGPointMake(18.2, 15), 1.6);
                StrokeLine(CGPointMake(11.8, 18.5), CGPointMake(15.6, 18.5), 1.6);
                break;
            }
            case SIPhoto: {   // picture: frame, mountains and sun
                UIBezierPath *frame = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(6.5, 8.5, 17, 13) cornerRadius:2.6];
                frame.lineWidth = 1.8;
                [frame stroke];
                UIBezierPath *hills = [UIBezierPath bezierPath];
                [hills moveToPoint:CGPointMake(8.5, 19.5)];
                [hills addLineToPoint:CGPointMake(13, 14.5)];
                [hills addLineToPoint:CGPointMake(16.5, 18)];
                [hills addLineToPoint:CGPointMake(18.5, 16)];
                [hills addLineToPoint:CGPointMake(21.5, 19.5)];
                hills.lineWidth = 1.6;
                hills.lineJoinStyle = kCGLineJoinRound;
                hills.lineCapStyle = kCGLineCapRound;
                [hills stroke];
                [[UIBezierPath bezierPathWithArcCenter:CGPointMake(19.2, 12.4) radius:1.5 startAngle:0 endAngle:2 * M_PI clockwise:YES] fill];
                break;
            }
            case SITokens: {   // gauge
                UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:CGPointMake(15, 18.5) radius:8.5 startAngle:M_PI endAngle:2 * M_PI clockwise:YES];
                arc.lineWidth = 2;
                arc.lineCapStyle = kCGLineCapRound;
                [arc stroke];
                StrokeLine(CGPointMake(15, 18.5), CGPointMake(19.6, 12.8), 2);
                [[UIBezierPath bezierPathWithArcCenter:CGPointMake(15, 18.5) radius:1.8 startAngle:0 endAngle:2 * M_PI clockwise:YES] fill];
                break;
            }
            case SIContext: {   // chip
                UIBezierPath *body = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(10, 10, 10, 10) cornerRadius:2];
                body.lineWidth = 1.8;
                [body stroke];
                [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(13, 13, 4, 4) cornerRadius:0.8] fill];
                CGFloat pins[2] = { 12.5, 17.5 };
                for (int i = 0; i < 2; i++) {
                    StrokeLine(CGPointMake(pins[i], 6.6), CGPointMake(pins[i], 10), 1.6);
                    StrokeLine(CGPointMake(pins[i], 20), CGPointMake(pins[i], 23.4), 1.6);
                    StrokeLine(CGPointMake(6.6, pins[i]), CGPointMake(10, pins[i]), 1.6);
                    StrokeLine(CGPointMake(20, pins[i]), CGPointMake(23.4, pins[i]), 1.6);
                }
                break;
            }
            case SITrash: {
                StrokeLine(CGPointMake(8.5, 10.5), CGPointMake(21.5, 10.5), 2);
                UIBezierPath *handle = [UIBezierPath bezierPath];
                [handle moveToPoint:CGPointMake(12.5, 10.5)];
                [handle addLineToPoint:CGPointMake(12.5, 8.4)];
                [handle addLineToPoint:CGPointMake(17.5, 8.4)];
                [handle addLineToPoint:CGPointMake(17.5, 10.5)];
                handle.lineWidth = 1.7;
                handle.lineJoinStyle = kCGLineJoinRound;
                [handle stroke];
                UIBezierPath *can = [UIBezierPath bezierPath];
                [can moveToPoint:CGPointMake(10, 13)];
                [can addLineToPoint:CGPointMake(11, 22.4)];
                [can addLineToPoint:CGPointMake(19, 22.4)];
                [can addLineToPoint:CGPointMake(20, 13)];
                can.lineWidth = 1.8;
                can.lineJoinStyle = kCGLineJoinRound;
                [can stroke];
                StrokeLine(CGPointMake(13.6, 15.5), CGPointMake(13.9, 20), 1.5);
                StrokeLine(CGPointMake(16.4, 15.5), CGPointMake(16.1, 20), 1.5);
                break;
            }
            case SIInfo: {
                UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:c radius:9 startAngle:0 endAngle:2 * M_PI clockwise:YES];
                ring.lineWidth = 1.8;
                [ring stroke];
                [[UIBezierPath bezierPathWithArcCenter:CGPointMake(15, 10.8) radius:1.2 startAngle:0 endAngle:2 * M_PI clockwise:YES] fill];
                StrokeLine(CGPointMake(15, 14), CGPointMake(15, 20.2), 2);
                break;
            }
            case SIUpdate: {   // circular arrow
                UIBezierPath *arc = [UIBezierPath bezierPathWithArcCenter:c radius:7.5 startAngle:-0.1 * M_PI endAngle:1.5 * M_PI clockwise:YES];
                arc.lineWidth = 2;
                arc.lineCapStyle = kCGLineCapRound;
                [arc stroke];
                UIBezierPath *head = [UIBezierPath bezierPath];
                [head moveToPoint:CGPointMake(19.6, 7.5)];
                [head addLineToPoint:CGPointMake(14.4, 3.8)];
                [head addLineToPoint:CGPointMake(14.4, 11.2)];
                [head closePath];
                [head fill];
                break;
            }
            case SIDeveloper: {   // ">_"
                UIBezierPath *chevron = [UIBezierPath bezierPath];
                [chevron moveToPoint:CGPointMake(8.5, 10.5)];
                [chevron addLineToPoint:CGPointMake(13.5, 15)];
                [chevron addLineToPoint:CGPointMake(8.5, 19.5)];
                chevron.lineWidth = 2;
                chevron.lineCapStyle = kCGLineCapRound;
                chevron.lineJoinStyle = kCGLineJoinRound;
                [chevron stroke];
                StrokeLine(CGPointMake(15.5, 20), CGPointMake(22, 20), 2);
                break;
            }
            default: {   // diagnostics: pulse line
                UIBezierPath *pulse = [UIBezierPath bezierPath];
                [pulse moveToPoint:CGPointMake(5, 15)];
                [pulse addLineToPoint:CGPointMake(10, 15)];
                [pulse addLineToPoint:CGPointMake(12.5, 8.5)];
                [pulse addLineToPoint:CGPointMake(16.5, 21.5)];
                [pulse addLineToPoint:CGPointMake(19, 15)];
                [pulse addLineToPoint:CGPointMake(25, 15)];
                pulse.lineWidth = 1.9;
                pulse.lineCapStyle = kCGLineCapRound;
                pulse.lineJoinStyle = kCGLineJoinRound;
                [pulse stroke];
                break;
            }
        }
}

static UIImage *SettingsIcon(SettingsIconKind kind) {
    static NSMutableDictionary<NSString *, UIImage *> *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [NSMutableDictionary dictionary]; });
    BOOL material = [Theme materialDesign];
    NSString *cacheKey = [NSString stringWithFormat:@"%ld|%d|%@", (long)kind, material ? 1 : 0, material ? [Theme signature] : @""];
    UIImage *cached = cache[cacheKey];
    if (cached) return cached;
    if (material) {
        UIColor *ink = [Theme accent];
        UIImage *circle = [Material circleIconWithGlyph:^(CGContextRef ctx) { DrawSettingsGlyph(kind, ink); }];
        cache[cacheKey] = circle;
        return circle;
    }

    const CGFloat side = 30;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [SettingsTileColor(kind) setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, side, side) cornerRadius:6.9] fill];
        DrawSettingsGlyph(kind, [UIColor whiteColor]);
    }];
    cache[cacheKey] = image;
    return image;
}

#pragma mark - SettingsViewController

// Order on screen: appearance & language on top, then the API keys, then the AI settings, then data & info, then credits.
typedef NS_ENUM(NSInteger, SettingsSection) {
    SettingsSectionLook = 0,
    SettingsSectionKeys,
    SettingsSectionAssistant,
    SettingsSectionData,
    SettingsSectionCredits,
    SettingsSectionCount
};

@interface SettingsViewController ()
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) BOOL hasAppearedOnce;
@property (strong, nonatomic) NSMutableSet<NSNumber *> *collapsedSections;   // Material 3: sections folded by their header
@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"settings_title");
    self.view.backgroundColor = [Theme background];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;   // wide screens: rows stay a comfortable width
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    [self.view addSubview:self.tableView];
    self.collapsedSections = [NSMutableSet set];
    [self applyMaterialStyle];
    [Material markTableForEntrance:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme) name:kNotifThemeChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleUIScaleChanged) name:@"UIScaleDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateStateChanged) name:kNotifUpdateChanged object:nil];
}

#pragma mark - App update

// The update row follows the checker (checking -> up to date / new version / downloading ...).
- (void)updateStateChanged {
    if (!self.isViewLoaded || !self.view.window) return;
    NSIndexPath *path = [NSIndexPath indexPathForRow:2 inSection:SettingsSectionData];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
    if (cell) [self.tableView reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    if ([UpdateManager shared].state == UpdateStateAvailable && ![UpdateManager shared].devChannel && self.view.window && !self.presentedViewController &&
        self.navigationController.topViewController == self && [[UpdateManager shared] consumePromptForCurrentVersion]) {
        [self presentUpdatePopupChecking:NO];   // a new version was just found: tell the user once
    }
}

- (void)presentUpdatePopupChecking:(BOOL)check {
    if (self.presentedViewController) return;
    UpdateManager *m = [UpdateManager shared];
    if (check) {
        // The developer channel always starts a fresh look (it has no background check, its state is Idle after unlocking).
        BOOL needsCheck = m.devChannel ? (m.state != UpdateStateChecking && m.state != UpdateStateDownloading)
                                       : (m.state == UpdateStateIdle || m.state == UpdateStateFailed || m.state == UpdateStateUpToDate);
        if (needsCheck) [m checkForUpdateForce:YES];
    }
    [self presentViewController:[[UpdatePopupViewController alloc] init] animated:YES completion:nil];
}

#pragma mark - Beta update (password protected, shown in the update pop-up)

- (void)betaUpdateTapped {
    if (self.presentedViewController) return;
    if ([DevAccess shared].unlocked) { [self openBetaPopup]; return; }
    [self presentDevPasswordPrompt];
}

- (void)openBetaPopup {
    [[UpdateManager shared] switchToDevChannel:YES];
    if (![UpdateManager shared].devChannel) { [self presentDevPasswordPrompt]; return; }
    [self presentUpdatePopupChecking:YES];
}

- (void)presentDevPasswordPrompt {
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
        [weakSelf submitDevPassword:typed];
    }]];
    [alert presentFromViewController:self];
}

- (void)submitDevPassword:(NSString *)password {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinner.color = [Theme secondaryText];
    spinner.center = CGPointMake(self.view.bounds.size.width / 2.0, self.view.bounds.size.height / 2.0);
    [self.view addSubview:spinner];
    [spinner startAnimating];
    self.view.userInteractionEnabled = NO;
    __weak typeof(self) weakSelf = self;
    [[DevAccess shared] unlockWithPassword:password completion:^(DevAccessResult result, NSTimeInterval wait) {
        [spinner removeFromSuperview];
        SettingsViewController *me = weakSelf;
        if (!me) return;
        me.view.userInteractionEnabled = YES;
        if (result == DevAccessResultOK) {
            [me openBetaPopup];
            return;
        }
        NSString *message;
        if (result == DevAccessResultLockedHour) message = L(@"dev_err_lockout");
        else if (result == DevAccessResultLockedOut) message = L(@"dev_err_throttle");
        else if (result == DevAccessResultBusy) message = L(@"dev_err_busy");
        else if (result == DevAccessResultTampered) message = L(@"dev_err_tamper");
        else message = L(@"dev_err_wrong");
        ChoicePopupViewController *fail = [ChoicePopupViewController alertWithTitle:L(@"dev_prompt_title") message:message];
        [fail addAction:[ChoiceAction actionWithTitle:L(@"update_close") style:UIAlertActionStyleCancel handler:nil]];
        if (!me.presentedViewController) [fail presentFromViewController:me];
    }];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleUIScaleChanged {
    if (self.view.window) [self.tableView reloadData];
}

- (void)applyMaterialStyle {
    BOOL material = [Material active];
    self.tableView.separatorStyle = material ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    self.tableView.rowHeight = material ? 64 : UITableViewAutomaticDimension;
    if (material) [Material decorateTable:self.tableView];
    [Material layoutTable:self.tableView inBounds:self.view.bounds];
    [Material styleTitleForController:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [Material layoutTable:self.tableView inBounds:self.view.bounds];
}

- (void)applyTheme {
    self.view.backgroundColor = [Theme background];
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    [self applyMaterialStyle];
    if (self.view.window) [self.tableView reloadData];   // hidden behind another screen: it reloads when it comes back (viewWillAppear)
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyMaterialStyle];
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
    if (provider == AIProviderGemini && [KeyStore geminiUsesGoogleAccount]) {
        NSString *email = [GoogleAuth accountEmail];
        return [NSString stringWithFormat:L(@"google_signed_in_as"), email.length > 0 ? email : @"Google"];
    }
    NSString *key = [KeyStore loadRawKeyForProvider:provider];
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
    if ([Material active] && [self.collapsedSections containsObject:@(section)]) return 0;
    if (section == SettingsSectionLook) return 3;      // look, language, font size
    if (section == SettingsSectionKeys) return 3;      // Gemini key, Claude key, kind of Gemini key
    if (section == SettingsSectionAssistant) return 4;
    if (section == SettingsSectionCredits) return 3;   // TaoJB, PucSaur, ND Phonqq
    return 5;   // data: clear history, version, software update, beta update (password), diagnostics
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case SettingsSectionLook:      return L(@"settings_header_look");
        case SettingsSectionKeys:      return L(@"settings_header_keys");
        case SettingsSectionAssistant: return L(@"settings_header_ai");
        case SettingsSectionCredits:   return L(@"settings_header_credits");
        default:                       return L(@"settings_header_data");
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return nil;   // no descriptions under the groups: the screen stays compact
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:[Material cellStyle:UITableViewCellStyleValue1] reuseIdentifier:nil];
    cell.backgroundColor = [Theme surface];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = [Theme text];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:16];
    cell.detailTextLabel.textColor = [Theme secondaryText];

    switch (indexPath.section) {
        case SettingsSectionCredits:
            cell.textLabel.text = indexPath.row == 0 ? @"TaoJB" : (indexPath.row == 1 ? @"PucSaur" : @"ND Phonqq");
            cell.detailTextLabel.text = indexPath.row < 2 ? L(@"main_developer") : L(@"manual_tester");
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
            } else if (indexPath.row == 2) {
                {
                UpdateManager *m = [UpdateManager shared];
                cell.textLabel.text = L(@"update_row_title");
                cell.detailTextLabel.textColor = [Theme secondaryText];
                switch (m.state) {
                    case UpdateStateChecking:    cell.detailTextLabel.text = L(@"update_row_checking"); break;
                    case UpdateStateUpToDate:    cell.detailTextLabel.text = L(@"update_row_latest"); break;
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
                    default:                     cell.detailTextLabel.text = L(@"update_row_check"); break;
                }
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
            } else if (indexPath.row == 3) {
                cell.textLabel.text = L(@"su_beta_title");
                cell.detailTextLabel.text = nil;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            } else {
                cell.textLabel.text = L(@"diagnostics_title");
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            break;
    }
    NSInteger iconKind = -1;
    switch (indexPath.section) {
        case SettingsSectionLook:      iconKind = indexPath.row == 0 ? SIAppearance : (indexPath.row == 1 ? SILanguage : SIFontSize); break;
        case SettingsSectionKeys:      iconKind = indexPath.row == 0 ? SIKeyGemini : (indexPath.row == 1 ? SIKeyClaude : SIKeyTier); break;
        case SettingsSectionAssistant: {
            static const SettingsIconKind assistantIcons[4] = { SIPrompt, SIPhoto, SITokens, SIContext };
            iconKind = indexPath.row >= 0 && indexPath.row < 4 ? assistantIcons[indexPath.row] : -1;
            break;
        }
        case SettingsSectionData: {
            static const SettingsIconKind dataIcons[5] = { SITrash, SIInfo, SIUpdate, SIDeveloper, SIDiagnostics };
            iconKind = indexPath.row >= 0 && indexPath.row < 5 ? dataIcons[indexPath.row] : -1;
            break;
        }
        default: break;
    }
    if (iconKind >= 0) {
        cell.imageView.image = SettingsIcon((SettingsIconKind)iconKind);
        cell.separatorInset = UIEdgeInsetsMake(0, 62, 0, 0);   // the line starts under the text, like iOS Settings
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [Material decorateCell:cell atIndexPath:indexPath inTable:tableView];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (![Material active]) return nil;
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    BOOL collapsed = [self.collapsedSections containsObject:@(section)];
    __weak typeof(self) weakSelf = self;
    __block __weak UIView *headerRef = nil;
    UIView *header = [Material headerViewWithTitle:title collapsed:collapsed collapsible:YES tap:^{
        SettingsViewController *me = weakSelf;
        if (!me) return;
        [Material toggleSection:section collapsed:me.collapsedSections inTable:me.tableView header:headerRef];
    }];
    headerRef = header;
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [Material active] ? [Material headerHeight] : UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return [Material active] ? 6 : UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UILabel *label = ((UITableViewHeaderFooterView *)view).textLabel;
        label.textColor = [Theme secondaryText];
        label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];   // UIKit makes this label itself, so the app font is set here
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UILabel *label = ((UITableViewHeaderFooterView *)view).textLabel;
        label.textColor = [Theme secondaryText];
        label.font = [UIFont systemFontOfSize:13];   // UIKit makes this label itself, so the app font is set here
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.section) {
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
                [self.navigationController pushViewController:[[SoftwareUpdateViewController alloc] init] animated:YES];
            } else if (indexPath.row == 3) {
                [self betaUpdateTapped];
            } else if (indexPath.row == 4) {
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
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:@"Mức suy luận AI" message:@"Mức thực tế phụ thuộc model và API. MAX ×8 không thể vượt giới hạn nhà cung cấp."];
    NSArray *names = @[@"Thấp", @"Trung bình", @"Cao", @"Siêu cao", @"MAX ×8 (nếu model hỗ trợ)"];
    __weak typeof(self) weakSelf = self;
    [names enumerateObjectsUsingBlock:^(NSString *name, NSUInteger idx, BOOL *stop) {
        [sheet addAction:[ChoiceAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(id a) {
            [AppSettings setReasoningLevel:(AIReasoningLevel)idx];
            [weakSelf.tableView reloadData];
        }]];
    }];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

- (NSString *)contextMemoryName {
    return [NSString stringWithFormat:L(@"context_memory_value"), (unsigned long)([AppSettings contextLimitChars] / 1000)];
}

- (void)chooseOutputTokens {
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"output_tokens_title") message:L(@"output_tokens_note")];
    NSArray *options = @[ @[@2048, @"2,048 tokens"], @[@4096, @"4,096 tokens"], @[@8192, @"8,192 tokens"], @[@16384, @"16,384 tokens"], @[@32768, @"32,768 tokens"], @[@65536, @"65,536 tokens"], @[@128000, @"128,000 tokens"] ];
    __weak typeof(self) weakSelf = self;
    for (NSArray *option in options) {
        NSInteger value = [option[0] integerValue];
        [sheet addAction:[ChoiceAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(id a) {
            [AppSettings setMaxOutputTokens:value];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

- (void)chooseContextMemory {
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"context_memory_title") message:L(@"context_memory_note")];
    NSArray *options = @[ @[@200000, [NSString stringWithFormat:L(@"context_memory_value"), 200]],
                          @[@400000, [NSString stringWithFormat:L(@"context_memory_value"), 400]],
                          @[@600000, [NSString stringWithFormat:L(@"context_memory_value"), 600]] ];
    __weak typeof(self) weakSelf = self;
    for (NSArray *option in options) {
        NSUInteger value = [option[0] unsignedIntegerValue];
        [sheet addAction:[ChoiceAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(id a) {
            [AppSettings setContextLimitChars:value];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

- (void)chooseAttachmentMemory {
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"attach_memory_title") message:nil];
    NSArray *options = @[ @[@1, L(@"attach_memory_1")], @[@3, L(@"attach_memory_3")], @[@0, L(@"attach_memory_all")] ];
    __weak typeof(self) weakSelf = self;
    for (NSArray *option in options) {
        NSInteger value = [option[0] integerValue];
        [sheet addAction:[ChoiceAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(id a) {
            [AppSettings setAttachmentMemory:value];
            [weakSelf.tableView reloadData];
        }]];
    }
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
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
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"key_tier_title") message:L(@"key_tier_message")];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"key_tier_auto") style:UIAlertActionStyleDefault handler:^(id a) {
        [KeyTier setGeminiOverride:0];
        [KeyTier invalidateGeminiDetection];
        [weakSelf redetectKeyTier];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"key_tier_free") style:UIAlertActionStyleDefault handler:^(id a) {
        [KeyTier setGeminiOverride:1];
        [weakSelf.tableView reloadData];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"key_tier_paid") style:UIAlertActionStyleDefault handler:^(id a) {
        [KeyTier setGeminiOverride:2];
        [weakSelf.tableView reloadData];
    }]];
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
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
        ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:nil message:message];
        [alert addAction:[ChoiceAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [alert presentFromViewController:me];
    }];
}

- (void)chooseLanguage {
    ChoicePopupViewController *sheet = [ChoicePopupViewController popupWithTitle:L(@"language") message:nil];
    NSArray *options = @[ @[@"auto", L(@"language_auto")], @[@"vi", @"Ti\u1EBFng Vi\u1EC7t"], @[@"en", @"English"] ];
    for (NSArray *option in options) {
        NSString *value = option[0];
        ChoiceAction *action = [ChoiceAction actionWithTitle:option[1] style:UIAlertActionStyleDefault handler:^(id a) {
            if ([[Loc preference] isEqualToString:value]) return;
            [Loc setPreference:value];
            // The app rebuilds its screens in the new language (the open chat starts fresh).
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotifLanguageChanged object:nil];
        }];
        [sheet addAction:action];
    }
    [sheet addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [sheet presentFromViewController:self];
}

#pragma mark - History

- (void)confirmClearHistory {
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:L(@"clear_history_confirm_title") message:L(@"clear_history_confirm_msg")];
    [alert addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[ChoiceAction actionWithTitle:L(@"delete") style:UIAlertActionStyleDestructive handler:^(id action) {
        [ConversationStore deleteAll];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifHistoryCleared object:nil];
        SettingsViewController *me = weakSelf;
        if (!me) return;
        ChoicePopupViewController *done = [ChoicePopupViewController alertWithTitle:nil message:L(@"history_cleared")];
        [done addAction:[ChoiceAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [done presentFromViewController:me];
    }]];
    [alert presentFromViewController:self];
}

@end
