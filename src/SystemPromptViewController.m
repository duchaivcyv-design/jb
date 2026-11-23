#import "SystemPromptViewController.h"
#import "Strings.h"
#import "Theme.h"
#import "Material.h"
#import "AppSettings.h"
#import "InstructionFile.h"

@interface SystemPromptViewController () <UITextViewDelegate, UIDocumentPickerDelegate>
@property (strong, nonatomic) UIButton *importButton;
@property (strong, nonatomic) UILabel *hintLabel;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UILabel *placeholderLabel;
@property (strong, nonatomic) UILabel *counterLabel;
@property (assign, nonatomic) CGFloat keyboardOverlap;
@end

@implementation SystemPromptViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.perConversation ? L(@"chat_prompt_title") : L(@"system_prompt_title");
    self.view.backgroundColor = [Theme background];
    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithTitle:L(@"done") style:UIBarButtonItemStyleDone target:self action:@selector(doneTapped)];

    self.hintLabel = [[UILabel alloc] init];
    self.hintLabel.text = self.perConversation ? L(@"chat_prompt_hint") : L(@"system_prompt_hint");
    self.hintLabel.font = [UIFont systemFontOfSize:14];
    self.hintLabel.textColor = [Theme secondaryText];
    self.hintLabel.numberOfLines = 0;
    [self.view addSubview:self.hintLabel];

    self.importButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.importButton setTitle:L(@"instr_import_button") forState:UIControlStateNormal];
    [self.importButton setTitleColor:[Theme accent] forState:UIControlStateNormal];
    self.importButton.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.importButton.layer.cornerRadius = MR(12, 21);   // half of the 42 pt height
    self.importButton.layer.borderWidth = 1.5;
    self.importButton.layer.borderColor = [Theme accent].CGColor;
    [self.importButton addTarget:self action:@selector(importTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.importButton];

    self.textView = [[UITextView alloc] init];
    self.textView.backgroundColor = [Theme surface];
    self.textView.layer.cornerRadius = MR(12, 16);
    self.textView.layer.borderWidth = 1;
    self.textView.layer.borderColor = [Theme border].CGColor;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.textColor = [Theme text];
    self.textView.tintColor = [Theme accent];
    self.textView.keyboardAppearance = [Theme keyboardAppearance];
    self.textView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
    self.textView.delegate = self;
    NSString *rawInitial = self.perConversation ? (self.initialText ?: @"") : [AppSettings systemPrompt];
    self.textView.text = [AppSettings cleanedPrompt:rawInitial];
    [self.view addSubview:self.textView];

    self.placeholderLabel = [[UILabel alloc] init];
    self.placeholderLabel.text = L(@"system_prompt_placeholder");
    self.placeholderLabel.font = [UIFont systemFontOfSize:16];
    self.placeholderLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    self.placeholderLabel.numberOfLines = 0;
    self.placeholderLabel.hidden = self.textView.text.length > 0;
    [self.textView addSubview:self.placeholderLabel];

    self.counterLabel = [[UILabel alloc] init];
    self.counterLabel.font = [UIFont systemFontOfSize:12];
    self.counterLabel.textAlignment = NSTextAlignmentRight;
    [self.view addSubview:self.counterLabel];
    [self updateCounter];

    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.perConversation) {
        if (self.onSave) self.onSave([AppSettings cleanedPrompt:self.textView.text]);
    } else {
        [AppSettings setSystemPrompt:self.textView.text];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat width = self.view.bounds.size.width;
    CGFloat height = self.view.bounds.size.height;
    CGFloat safeBottom = 0;
    if (@available(iOS 11.0, *)) safeBottom = self.view.safeAreaInsets.bottom;
    CGFloat bottom = MAX(self.keyboardOverlap, safeBottom);

    CGSize hint = [self.hintLabel sizeThatFits:CGSizeMake(width - 32, CGFLOAT_MAX)];
    self.hintLabel.frame = CGRectMake(16, 14, width - 32, ceil(hint.height));
    self.importButton.frame = CGRectMake(16, CGRectGetMaxY(self.hintLabel.frame) + 12, width - 32, 42);
    CGFloat top = CGRectGetMaxY(self.importButton.frame) + 12;
    self.counterLabel.frame = CGRectMake(16, height - bottom - 24, width - 32, 18);
    self.textView.frame = CGRectMake(16, top, width - 32, MAX(80, height - bottom - 30 - top));
    CGSize ph = [self.placeholderLabel sizeThatFits:CGSizeMake(width - 32 - 32, CGFLOAT_MAX)];
    self.placeholderLabel.frame = CGRectMake(15, 12, width - 32 - 30, ceil(ph.height));
}

- (void)updateCounter {
    NSUInteger count = self.textView.text.length;
    if (kMaxSystemPromptChars == 1000000) {
        self.counterLabel.text = [NSString stringWithFormat:@"%lu / 1 triệu", (unsigned long)count];
    } else {
        self.counterLabel.text = [NSString stringWithFormat:@"%lu / %lu", (unsigned long)count, (unsigned long)kMaxSystemPromptChars];
    }
    self.counterLabel.textColor = count >= kMaxSystemPromptChars ? [Theme error] : [Theme secondaryText];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *currentText = textView.text ?: @"";
    NSUInteger current = currentText.length;
    NSUInteger safeLoc = MIN(range.location, current);
    NSUInteger safeLen = MIN(range.length, current - safeLoc);
    NSRange safeRange = NSMakeRange(safeLoc, safeLen);

    NSUInteger remainingAfterDelete = current - safeLen;
    if (remainingAfterDelete >= kMaxSystemPromptChars && text.length > 0) {
        [self updateCounter];
        return NO;
    }

    if (remainingAfterDelete + text.length > kMaxSystemPromptChars) {
        NSUInteger allowedLen = kMaxSystemPromptChars - remainingAfterDelete;
        NSRange seqRange = [text rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, MIN(allowedLen, text.length))];
        NSString *fitted = [text substringWithRange:seqRange];
        NSString *updated = [currentText stringByReplacingCharactersInRange:safeRange withString:fitted];
        textView.text = updated;
        NSUInteger caret = safeLoc + fitted.length;
        textView.selectedRange = NSMakeRange(caret, 0);
        [self textViewDidChange:textView];
        return NO;
    }

    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > kMaxSystemPromptChars) {
        NSString *cleaned = [AppSettings cleanedPrompt:textView.text];
        textView.text = cleaned;
    }
    self.placeholderLabel.hidden = textView.text.length > 0;
    [self updateCounter];
}

#pragma mark - Import from a file

- (void)importTapped {
    [self.view endEditing:YES];
    // .clmn is a plain text file under another name: any file can be picked, the content is read as text.
    UIDocumentPickerViewController *picker =
        [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[@"public.data", @"public.text", @"public.content"] inMode:UIDocumentPickerModeImport];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    if (urls.firstObject) [self importFromURL:urls.firstObject];
}

- (void)documentPickerWasCancelled:(UIDocumentPickerViewController *)controller {}

- (void)importFromURL:(NSURL *)url {
    __weak typeof(self) weakSelf = self;
    [InstructionFile importFromURL:url presenter:self existing:self.textView.text apply:^(NSString *finalText) {
        SystemPromptViewController *me = weakSelf;
        if (!me) return;
        me.textView.text = finalText;
        [me textViewDidChange:me.textView];
        me.textView.selectedRange = NSMakeRange(0, 0);
        [me.textView scrollRangeToVisible:NSMakeRange(0, 0)];
    }];
}

- (void)doneTapped {
    [self.view endEditing:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Keyboard

- (void)keyboardWillChange:(NSNotification *)note {
    CGRect endFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect local = [self.view convertRect:endFrame fromView:nil];
    self.keyboardOverlap = MAX(0, CGRectGetMaxY(self.view.bounds) - local.origin.y);
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

- (void)keyboardWillHide:(NSNotification *)note {
    self.keyboardOverlap = 0;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

@end
