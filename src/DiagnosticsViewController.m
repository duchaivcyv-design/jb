#import "DiagnosticsViewController.h"
#import "Strings.h"
#import "ChoicePopupViewController.h"
#import "Theme.h"
#import "DiagnosticLog.h"

@interface DiagnosticsViewController ()
@property (strong, nonatomic) UILabel *noteLabel;
@property (strong, nonatomic) UITextView *textView;
@end

@implementation DiagnosticsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = L(@"diagnostics_title");
    self.view.backgroundColor = [Theme background];
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithTitle:L(@"copy") style:UIBarButtonItemStylePlain target:self action:@selector(copyTapped)],
        [[UIBarButtonItem alloc] initWithTitle:L(@"delete") style:UIBarButtonItemStylePlain target:self action:@selector(clearTapped)]
    ];

    self.noteLabel = [[UILabel alloc] init];
    self.noteLabel.text = L(@"diagnostics_note");
    self.noteLabel.font = [UIFont systemFontOfSize:13];
    self.noteLabel.textColor = [Theme secondaryText];
    self.noteLabel.numberOfLines = 0;
    [self.view addSubview:self.noteLabel];

    self.textView = [[UITextView alloc] init];
    self.textView.editable = NO;
    self.textView.backgroundColor = [Theme surface];
    self.textView.layer.cornerRadius = 10;
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor = [Theme border].CGColor;
    self.textView.font = [UIFont fontWithName:@"Menlo-Regular" size:10.5] ?: [UIFont systemFontOfSize:10.5];
    self.textView.textColor = [Theme text];
    self.textView.textContainerInset = UIEdgeInsetsMake(10, 8, 10, 8);
    [self.view addSubview:self.textView];
    [self reload];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width, height = self.view.bounds.size.height;
    CGFloat safeBottom = 0;
    if (@available(iOS 11.0, *)) safeBottom = self.view.safeAreaInsets.bottom;
    CGSize note = [self.noteLabel sizeThatFits:CGSizeMake(width - 32, CGFLOAT_MAX)];
    self.noteLabel.frame = CGRectMake(16, 12, width - 32, ceil(note.height));
    CGFloat top = CGRectGetMaxY(self.noteLabel.frame) + 10;
    self.textView.frame = CGRectMake(16, top, width - 32, MAX(80, height - top - safeBottom - 16));
}

- (void)reload {
    NSString *text = [DiagnosticLog contents];
    self.textView.text = text.length > 0 ? text : L(@"diagnostics_empty");
    if (text.length > 0) {   // newest lines are at the bottom
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length - 1, 1)];
        });
    }
}

- (void)copyTapped {
    NSString *text = [DiagnosticLog contents];
    if (text.length == 0) return;
    [UIPasteboard generalPasteboard].string = text;
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:nil message:L(@"copied")];
    [alert addAction:[ChoiceAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [alert presentFromViewController:self];
}

- (void)clearTapped {
    [DiagnosticLog clear];
    [self reload];
}

@end
