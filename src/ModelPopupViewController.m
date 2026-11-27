#import "ModelPopupViewController.h"
#import "ModelCell.h"
#import "ModelStore.h"
#import "KeyStore.h"
#import "KeyTier.h"
#import "Provider.h"
#import "Strings.h"
#import "Theme.h"
#import "Material.h"

static NSString *const kCellId = @"model";

@interface ModelPopupViewController ()
@property (copy, nonatomic) NSString *selectedModelId;
@property (assign, nonatomic) BOOL intro;
@property (strong, nonatomic) NSArray *models;
@property (strong, nonatomic) UIView *card;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *noteLabel;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UILabel *emptyLabel;
@property (strong, nonatomic) UIButton *moreButton;
@property (strong, nonatomic) UIButton *doneButton;
@end

@implementation ModelPopupViewController

- (instancetype)initWithSelectedModel:(NSString *)modelId intro:(BOOL)intro {
    self = [super init];
    if (self) {
        _selectedModelId = [modelId copy];
        _intro = intro;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

#pragma mark - Text

- (NSString *)noteText {
    NSMutableArray *lines = [NSMutableArray array];
    if (self.intro) [lines addObject:L(@"popup_intro")];
    if ([KeyStore hasKeyForProvider:AIProviderGemini]) {
        [lines addObject:[KeyTier tierForProvider:AIProviderGemini] == KeyTierPaid ? L(@"tier_note_paid") : L(@"tier_note_free")];
    }
    if ([KeyStore hasKeyForProvider:AIProviderClaude]) [lines addObject:L(@"tier_note_claude")];
    return [lines componentsJoinedByString:@"\n"];
}

#pragma mark - View

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];   // the blur below replaces the plain dimming
    UIVisualEffectView *backdrop = [Theme backdropBlurView];
    backdrop.frame = self.view.bounds;
    [self.view addSubview:backdrop];
    self.models = [ModelStore recommendedModels];

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
    self.titleLabel.font = [Theme serifFontOfSize:23];
    self.titleLabel.textColor = [Theme text];
    self.titleLabel.text = self.intro ? L(@"popup_title_intro") : L(@"popup_title");
    [self.card addSubview:self.titleLabel];

    self.noteLabel = [[UILabel alloc] init];
    self.noteLabel.font = [UIFont systemFontOfSize:13];
    self.noteLabel.textColor = [Theme secondaryText];
    self.noteLabel.numberOfLines = 0;
    self.noteLabel.text = [self noteText];
    [self.card addSubview:self.noteLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [Material installTableEffects:self.tableView];   // Material 3 press feedback (does nothing in the Classic design)
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [Theme surface];
    self.tableView.separatorColor = [Theme border];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 68, 0, 0);
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.layer.cornerRadius = MR(16, 20);
    self.tableView.clipsToBounds = YES;
    self.tableView.layer.borderWidth = 1;
    self.tableView.layer.borderColor = [Theme border].CGColor;
    self.tableView.rowHeight = [ModelCell rowHeight];
    [self.card addSubview:self.tableView];

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.text = L(@"loading_models");
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.textColor = [Theme secondaryText];
    self.emptyLabel.font = [UIFont systemFontOfSize:14];
    self.emptyLabel.hidden = self.models.count > 0;
    [self.card addSubview:self.emptyLabel];

    self.moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.moreButton setTitle:L(@"popup_more") forState:UIControlStateNormal];
    [self.moreButton setTitleColor:[Theme accent] forState:UIControlStateNormal];
    self.moreButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.moreButton.layer.cornerRadius = MR(14, 24);
    self.moreButton.layer.borderWidth = 1.5;
    self.moreButton.layer.borderColor = [Theme accent].CGColor;
    [self.moreButton addTarget:self action:@selector(moreTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.card addSubview:self.moreButton];

    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.doneButton setTitle:L(@"popup_done") forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.doneButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.doneButton.backgroundColor = [Theme accent];
    self.doneButton.layer.cornerRadius = MR(14, 24);
    [self.doneButton addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.card addSubview:self.doneButton];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doneTapped)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets safe = self.view.safeAreaInsets;
    CGFloat cardWidth = MIN(bounds.size.width - 32, 400);
    CGFloat inner = cardWidth - 40;

    CGFloat y = 22;
    self.titleLabel.frame = CGRectMake(20, y, inner, 28);
    y += 32;
    CGSize noteSize = [self.noteLabel sizeThatFits:CGSizeMake(inner, CGFLOAT_MAX)];
    self.noteLabel.frame = CGRectMake(20, y, inner, ceil(noteSize.height));
    y += ceil(noteSize.height) + 14;

    CGFloat buttonsHeight = 48 + 14 + 20;   // buttons + gap + bottom margin
    CGFloat availableHeight = bounds.size.height - safe.top - safe.bottom - 60;
    CGFloat maxTable = MAX(120, availableHeight - y - buttonsHeight);
    CGFloat wanted = self.models.count > 0 ? self.models.count * [ModelCell rowHeight] : 64;
    CGFloat tableHeight = MIN(wanted, maxTable);
    self.tableView.frame = CGRectMake(20, y, inner, tableHeight);
    self.tableView.scrollEnabled = wanted > maxTable;
    self.emptyLabel.frame = self.tableView.frame;
    y += tableHeight + 14;

    CGFloat gap = 10;
    CGFloat doneWidth = 96;
    self.moreButton.frame = CGRectMake(20, y, inner - doneWidth - gap, 48);
    self.doneButton.frame = CGRectMake(20 + inner - doneWidth, y, doneWidth, 48);
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

#pragma mark - Table

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.models.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ModelCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellId];
    if (!cell) cell = [[ModelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kCellId];
    NSDictionary *model = self.models[indexPath.row];
    [cell configureWithModel:model selected:[model[@"id"] isEqualToString:self.selectedModelId]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *modelId = self.models[indexPath.row][@"id"];
    self.selectedModelId = modelId;
    [tableView reloadData];
    void (^onSelect)(NSString *) = self.onSelect;
    [self dismissViewControllerAnimated:YES completion:^{
        if (onSelect) onSelect(modelId);
    }];
}

#pragma mark - Actions

- (void)doneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)moreTapped {
    void (^onMore)(void) = self.onMore;
    [self dismissViewControllerAnimated:YES completion:^{
        if (onMore) onMore();
    }];
}

// A tap outside the card closes the pop-up; taps on the card do not.
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return touch.view == self.view;
}

@end
