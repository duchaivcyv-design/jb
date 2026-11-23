#import "ModelPickerViewController.h"
#import "Strings.h"
#import "Theme.h"
#import "Material.h"
#import "KeyStore.h"
#import "GeminiClient.h"
#import "ClaudeClient.h"
#import "ModelStore.h"
#import "ModelCell.h"
#import "KeyTier.h"
#import "SystemPromptViewController.h"

@interface ModelPickerViewController ()
@property (copy, nonatomic) NSString *selectedModel;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UILabel *statusLabel;
@property (assign, nonatomic) NSInteger pendingFetches;
@property (assign, nonatomic) BOOL fetchFailed;
@property (copy, nonatomic) NSArray *groups;   // @[ @{ @"title": ..., @"items": @[model dicts] } ], empty groups omitted
@end

@implementation ModelPickerViewController

- (instancetype)initWithSelectedModel:(NSString *)modelId {
    self = [super init];
    if (self) _selectedModel = [modelId copy];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"models_title");
    self.view.backgroundColor = [Theme background];
    [self rebuildGroups];

    // A refresh icon (circular arrow) instead of the word "Làm mới".
    UIBarButtonItem *refreshItem = [[UIBarButtonItem alloc] initWithImage:[Theme iconRefresh] style:UIBarButtonItemStylePlain target:self action:@selector(refresh)];
    refreshItem.accessibilityLabel = L(@"refresh");
    self.navigationItem.rightBarButtonItem = refreshItem;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    [Material installTableEffects:self.tableView];   // Material 3 press feedback (does nothing in the Classic design)
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    [self.view addSubview:self.tableView];

    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.font = [UIFont systemFontOfSize:15];
    self.statusLabel.textColor = [Theme secondaryText];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.numberOfLines = 0;
    [self.view addSubview:self.statusLabel];

    [self updateStatus];
    [self refresh];
    [self updateBanner];
}

// A rounded note at the top that says what kind of key this is and what that means for the list.
- (void)updateBanner {
    NSMutableArray *lines = [NSMutableArray array];
    if ([KeyStore hasKeyForProvider:AIProviderGemini]) {
        [lines addObject:[KeyTier tierForProvider:AIProviderGemini] == KeyTierPaid ? L(@"tier_note_paid") : L(@"tier_note_free")];
    }
    if ([KeyStore hasKeyForProvider:AIProviderClaude]) [lines addObject:L(@"tier_note_claude")];
    if (lines.count == 0) { self.tableView.tableHeaderView = nil; return; }

    CGFloat width = self.view.bounds.size.width;
    UIView *holder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 10)];
    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:13.5];
    label.textColor = [Theme text];
    label.text = [lines componentsJoinedByString:@"\n"];
    CGSize size = [label sizeThatFits:CGSizeMake(width - 32 - 28, CGFLOAT_MAX)];
    UIView *box = [[UIView alloc] initWithFrame:CGRectMake(16, 14, width - 32, ceil(size.height) + 24)];
    box.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.12];
    box.layer.cornerRadius = MR(14, 20);
    box.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.frame = CGRectMake(14, 12, box.bounds.size.width - 28, ceil(size.height));
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [box addSubview:label];
    [holder addSubview:box];
    holder.frame = CGRectMake(0, 0, width, CGRectGetMaxY(box.frame) + 4);
    self.tableView.tableHeaderView = holder;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.statusLabel.frame = CGRectMake(32, 230, self.view.bounds.size.width - 64, 60);
}

// Groups: the models the user can actually use (paid Gemini models are left out for a free key), by family.
- (void)rebuildGroups {
    NSMutableArray *groups = [NSMutableArray array];
    for (NSNumber *value in [Provider all]) {
        AIProvider provider = (AIProvider)value.integerValue;
        if (![KeyStore hasKeyForProvider:provider]) continue;
        NSArray *models = [ModelStore visibleModelsForProvider:provider];
        if (models.count == 0) continue;
        if (provider == AIProviderClaude) {
            [groups addObject:@{ @"title": L(@"models_group_claude"), @"items": models }];
            continue;
        }
        if ([KeyTier hidesPaidModelsForProvider:provider]) {
            [groups addObject:@{ @"title": L(@"models_group_gemini_free2"), @"items": models }];
            continue;
        }
        NSMutableArray *pro = [NSMutableArray array], *flash = [NSMutableArray array], *other = [NSMutableArray array];
        for (NSDictionary *model in models) {
            NSString *modelId = model[@"id"];
            if ([modelId rangeOfString:@"flash"].location != NSNotFound) [flash addObject:model];
            else if ([modelId rangeOfString:@"pro"].location != NSNotFound) [pro addObject:model];
            else [other addObject:model];
        }
        if (pro.count > 0) [groups addObject:@{ @"title": L(@"models_group_gemini_pro"), @"items": pro }];
        if (flash.count > 0) [groups addObject:@{ @"title": L(@"models_group_gemini_flash"), @"items": flash }];
        if (other.count > 0) [groups addObject:@{ @"title": L(@"models_group_gemini_more"), @"items": other }];
    }
    self.groups = groups;
}

// Section 0 is the "instructions for this chat" row; the model groups follow.
- (NSDictionary *)modelAtIndexPath:(NSIndexPath *)indexPath {
    return self.groups[indexPath.section - 1][@"items"][indexPath.row];
}

- (void)updateStatus {
    if (self.groups.count > 0) {
        self.statusLabel.hidden = YES;
    } else {
        self.statusLabel.hidden = NO;
        if (self.pendingFetches > 0) self.statusLabel.text = L(@"loading_models");
        else if (![KeyStore hasAnyKey]) self.statusLabel.text = L(@"models_no_key");
        else self.statusLabel.text = L(@"models_error");
    }
}

- (void)refresh {
    if (self.pendingFetches > 0) return;
    self.fetchFailed = NO;
    for (NSNumber *value in [Provider all]) {
        AIProvider provider = (AIProvider)value.integerValue;
        NSString *key = [KeyStore loadKeyForProvider:provider];
        if (key.length == 0) continue;
        self.pendingFetches++;
        __weak typeof(self) weakSelf = self;
        GeminiModelsCompletion completion = ^(NSArray *models, GeminiCheckResult result) {
            ModelPickerViewController *me = weakSelf;
            if (!me) return;
            me.pendingFetches--;
            if (result == GeminiCheckOK && models.count > 0) {
                [ModelStore saveModels:models forProvider:provider];
            } else {
                me.fetchFailed = YES;
            }
            if (me.pendingFetches == 0) {
                [me rebuildGroups];
                [me updateBanner];
                [me.tableView reloadData];
                [me updateStatus];
            }
        };
        if (provider == AIProviderClaude) [ClaudeClient fetchModelsWithKey:key completion:completion];
        else [GeminiClient fetchModelsWithKey:key completion:completion];
    }
    [self updateStatus];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)self.groups.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : (NSInteger)[self.groups[section - 1][@"items"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? nil : self.groups[section - 1][@"title"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.backgroundColor = [Theme surface];
        cell.textLabel.font = [UIFont systemFontOfSize:17];
        cell.textLabel.textColor = [Theme text];
        cell.textLabel.text = L(@"chat_prompt_title");
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15];
        cell.detailTextLabel.textColor = [Theme secondaryText];
        cell.detailTextLabel.text = self.chatPrompt.length > 0 ? L(@"system_prompt_set") : L(@"chat_prompt_default");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }

    ModelCell *cell = [tableView dequeueReusableCellWithIdentifier:@"model"];
    if (!cell) cell = [[ModelCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"model"];
    NSDictionary *model = [self modelAtIndexPath:indexPath];
    [cell configureWithModel:model selected:[model[@"id"] isEqualToString:self.selectedModel]];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? 52 : [ModelCell rowHeight];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (self.groups.count == 0 || section != (NSInteger)self.groups.count) return nil;
    if ([KeyStore hasKeyForProvider:AIProviderGemini] && [KeyTier hidesPaidModelsForProvider:AIProviderGemini]) {
        return [NSString stringWithFormat:@"%@\n%@", L(@"models_footer"), L(@"models_footer_free")];
    }
    return L(@"models_footer");
}

#pragma mark - UITableViewDelegate

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
    if (indexPath.section == 0) {
        SystemPromptViewController *editor = [[SystemPromptViewController alloc] init];
        editor.perConversation = YES;
        editor.initialText = self.chatPrompt;
        __weak typeof(self) weakSelf = self;
        editor.onSave = ^(NSString *text) {
            ModelPickerViewController *me = weakSelf;
            if (!me) return;
            me.chatPrompt = text;
            if (me.onChatPromptChange) me.onChatPromptChange(text);
            [me.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        };
        [self.navigationController pushViewController:editor animated:YES];
        return;
    }
    NSString *modelId = [self modelAtIndexPath:indexPath][@"id"];
    if (self.onSelect) self.onSelect(modelId);
    [self.navigationController popViewControllerAnimated:YES];
}

@end
