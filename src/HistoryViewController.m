#import "HistoryViewController.h"
#import "Strings.h"
#import "ChoicePopupViewController.h"
#import "Theme.h"
#import "Material.h"
#import "ConversationStore.h"
#import "SettingsViewController.h"
#import "MiniNavigationController.h"

@interface HistoryViewController () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UILabel *emptyLabel;
@property (copy, nonatomic) NSArray *entries;
@property (assign, nonatomic) NSInteger searchGeneration;
@end

@implementation HistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"history_title");
    self.view.backgroundColor = [Theme background];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    // Settings is a cog wheel (no text). The screen slides in from the left, so "back" slides it out to the left again.
    UIBarButtonItem *gear = [[UIBarButtonItem alloc] initWithImage:[Theme iconGear] style:UIBarButtonItemStylePlain target:self action:@selector(settingsTapped)];
    gear.accessibilityLabel = L(@"settings");
    self.navigationItem.rightBarButtonItem = gear;
    self.navigationItem.hidesBackButton = YES;
    UIBarButtonItem *back = [[UIBarButtonItem alloc] initWithImage:[Theme iconBack] style:UIBarButtonItemStylePlain target:self action:@selector(closeTapped)];
    back.accessibilityLabel = L(@"close");
    self.navigationItem.leftBarButtonItem = back;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    [Material installTableEffects:self.tableView];   // Material 3 press feedback (does nothing in the Classic design)
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];

    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 52)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = L(@"search_placeholder");
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.tintColor = [Theme accent];
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.tableView.tableHeaderView = self.searchBar;

    self.emptyLabel = [[UILabel alloc] init];
    self.emptyLabel.font = [UIFont systemFontOfSize:16];
    self.emptyLabel.textColor = [Theme secondaryText];
    self.emptyLabel.textAlignment = NSTextAlignmentCenter;
    self.emptyLabel.numberOfLines = 0;
    [self.view addSubview:self.emptyLabel];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme) name:kNotifThemeChanged object:nil];
    [self applyTheme];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Skin, dark mode or wallpaper changed in Settings (this screen is still in the navigation stack).
- (void)applyTheme {
    self.view.backgroundColor = [Theme background];
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    self.searchBar.tintColor = [Theme accent];
    self.searchBar.barStyle = [Theme darkMode] ? UIBarStyleBlack : UIBarStyleDefault;
    self.searchBar.keyboardAppearance = [Theme keyboardAppearance];
    self.emptyLabel.textColor = [Theme secondaryText];
    if (self.view.window) [self.tableView reloadData];   // cells use a reuse identifier that includes the skin, so they are rebuilt
    // (hidden behind Settings: viewWillAppear reloads the list when it comes back)
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadEntries];
}

// The system's edge-swipe would slide this screen out to the right: MiniNavigationController asks here and we say no,
// so closing always goes left. (The gesture itself is never switched on and off: that left the navigation stuck.)
- (BOOL)allowsBackSwipe {
    return NO;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    self.emptyLabel.frame = CGRectMake(32, 140, width - 64, 60);
}

#pragma mark - Data

- (void)reloadEntries {
    NSString *query = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (query.length == 0) {
        self.searchGeneration++;
        self.entries = [ConversationStore allEntries];
        [self.tableView reloadData];
        [self updateEmptyState];
        return;
    }
    // Searching reads every conversation file, so do it off the main thread.
    NSInteger generation = ++self.searchGeneration;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSArray *matches = [ConversationStore entriesMatching:query];
        dispatch_async(dispatch_get_main_queue(), ^{
            HistoryViewController *me = weakSelf;
            if (!me || me.searchGeneration != generation) return;   // a newer search superseded this one
            me.entries = matches;
            [me.tableView reloadData];
            [me updateEmptyState];
        });
    });
}

- (void)updateEmptyState {
    BOOL searching = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length > 0;
    self.emptyLabel.text = searching ? L(@"no_results") : L(@"history_empty");
    self.emptyLabel.hidden = self.entries.count > 0;
}

#pragma mark - Actions

- (void)settingsTapped {
    [self.navigationController pushViewController:[[SettingsViewController alloc] init] animated:YES];
}

- (void)closeTapped {
    [self closeToLeft];
}

// Leaves this screen by sliding it out to the left (the chat slides in from the right): the opposite of how it came in.
- (void)closeToLeft {
    UINavigationController *navigation = self.navigationController;
    if (!navigation) return;
    [self.view endEditing:YES];
    CATransition *transition = [CATransition animation];
    transition.duration = 0.3;
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFromRight;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [navigation.view.layer addAnimation:transition forKey:@"historyClose"];
    [navigation popViewControllerAnimated:NO];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [self reloadEntries];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)self.entries.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = [@"conversation-" stringByAppendingString:[Theme signature]];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
        cell.backgroundColor = [Theme background];
        cell.textLabel.font = [UIFont systemFontOfSize:17];
        cell.textLabel.textColor = [Theme text];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
        cell.detailTextLabel.textColor = [Theme secondaryText];
        UIView *selected = [[UIView alloc] init];
        selected.backgroundColor = [Material active] ? [UIColor clearColor] : [Theme selection];
        cell.selectedBackgroundView = selected;
    }
    NSDictionary *entry = self.entries[indexPath.row];
    NSString *title = entry[@"title"];
    cell.textLabel.text = ([title isKindOfClass:[NSString class]] && title.length > 0) ? title : L(@"untitled");

    static NSDateFormatter *formatter = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateStyle = NSDateFormatterMediumStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
    });
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[entry[@"updated"] doubleValue]];
    cell.detailTextLabel.text = [formatter stringFromDate:date];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSString *cid = self.entries[indexPath.row][@"id"];
    if (self.onSelect) self.onSelect(cid);
    [self closeToLeft];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *entry = self.entries[indexPath.row];
    NSString *cid = entry[@"id"];
    NSString *currentTitle = [entry[@"title"] isKindOfClass:[NSString class]] ? entry[@"title"] : @"";
    __weak typeof(self) weakSelf = self;

    UIContextualAction *remove =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive
                                                title:L(@"delete")
                                              handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        HistoryViewController *me = weakSelf;
        if (!me) { completionHandler(NO); return; }
        [ConversationStore deleteConversationWithId:cid];
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotifConversationDeleted object:nil userInfo:@{ @"id": cid }];
        NSMutableArray *remaining = [me.entries mutableCopy];
        NSInteger index = (NSInteger)[remaining indexOfObjectPassingTest:^BOOL(NSDictionary *e, NSUInteger i, BOOL *stop) {
            return [e[@"id"] isEqualToString:cid];
        }];
        if (index >= 0 && index < (NSInteger)remaining.count) {
            [remaining removeObjectAtIndex:index];
            me.entries = remaining;
            [me.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]]
                                withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [me updateEmptyState];
        completionHandler(YES);
    }];

    UIContextualAction *rename =
        [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal
                                                title:L(@"rename")
                                              handler:^(UIContextualAction *action, UIView *sourceView, void (^completionHandler)(BOOL)) {
        HistoryViewController *me = weakSelf;
        if (!me) { completionHandler(NO); return; }
        ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:L(@"rename_title") message:nil];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
            field.text = currentTitle;
            field.clearButtonMode = UITextFieldViewModeWhileEditing;
            field.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        }];
        [alert addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[ChoiceAction actionWithTitle:L(@"save") style:UIAlertActionStyleDefault handler:^(id a) {
            NSString *newTitle = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (newTitle.length > 0) {
                [ConversationStore renameConversationWithId:cid title:newTitle];
                [me reloadEntries];
            }
        }]];
        [alert presentFromViewController:me];
        completionHandler(YES);
    }];
    rename.backgroundColor = [Theme accent];

    return [UISwipeActionsConfiguration configurationWithActions:@[remove, rename]];
}

@end
