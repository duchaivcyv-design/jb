#import "InstructionFile.h"
#import "AppSettings.h"
#import "ChoicePopupViewController.h"
#import "Strings.h"
#import "SystemPromptViewController.h"

static const unsigned long long kMaxInstructionFileBytes = 16ull * 1024 * 1024;

@implementation InstructionFile

// The text of the file, or nil with a reason (already localised).
+ (NSString *)textFromURL:(NSURL *)url reason:(NSString **)reason {
    BOOL scoped = [url startAccessingSecurityScopedResource];
    NSError *error = nil;
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
    NSData *data = nil;
    if ([attrs fileSize] <= kMaxInstructionFileBytes) data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:&error];
    BOOL tooBig = [attrs fileSize] > kMaxInstructionFileBytes;
    if (scoped) [url stopAccessingSecurityScopedResource];
    if (tooBig) { if (reason) *reason = L(@"instr_err_big"); return nil; }
    if (!data) { if (reason) *reason = L(@"instr_err_read"); return nil; }

    NSString *text = nil;
    const unsigned char *bytes = data.bytes;
    if (data.length >= 2 && ((bytes[0] == 0xFF && bytes[1] == 0xFE) || (bytes[0] == 0xFE && bytes[1] == 0xFF))) {
        text = [[NSString alloc] initWithData:data encoding:NSUTF16StringEncoding];   // the BOM decides the byte order
    }
    if (!text) text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!text) text = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
    if (!text) { if (reason) *reason = L(@"instr_err_read"); return nil; }

    if ([text hasPrefix:@"﻿"]) text = [text substringFromIndex:1];
    text = [text stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    text = [text stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    text = [text stringByReplacingOccurrencesOfString:@"\0" withString:@""];
    text = [text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) { if (reason) *reason = L(@"instr_err_empty"); return nil; }
    return text;
}

+ (void)showMessage:(NSString *)message title:(NSString *)title from:(UIViewController *)presenter {
    ChoicePopupViewController *popup = [ChoicePopupViewController alertWithTitle:title message:message];
    [popup addAction:[ChoiceAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [popup presentFromViewController:presenter];
}

+ (void)importFromURL:(NSURL *)url presenter:(UIViewController *)presenter existing:(NSString *)existing apply:(void (^)(NSString *))apply {
    if (!url || !presenter || !apply) return;
    NSString *reason = nil;
    NSString *text = [self textFromURL:url reason:&reason];
    if (!text) {
        [self showMessage:reason ?: L(@"instr_err_read") title:L(@"instr_import_title") from:presenter];
        return;
    }
    BOOL cut = text.length > kMaxSystemPromptChars;
    NSString *incoming = cut ? [AppSettings cleanedPrompt:text] : text;
    NSUInteger count = incoming.length;
    __weak UIViewController *weakPresenter = presenter;
    void (^finish)(NSString *) = ^(NSString *finalText) {
        NSString *result = [AppSettings cleanedPrompt:finalText];
        apply(result);
        UIViewController *host = weakPresenter;
        if (!host) return;
        NSString *done = [NSString stringWithFormat:L(@"instr_import_done"), (unsigned long)count];
        if (cut || result.length >= kMaxSystemPromptChars) done = [done stringByAppendingFormat:@"\n%@", L(@"instr_import_truncated")];
        [self showMessage:done title:L(@"instr_import_title") from:host];
    };

    NSString *current = [existing stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (current.length == 0) { finish(incoming); return; }

    ChoicePopupViewController *popup = [ChoicePopupViewController popupWithTitle:L(@"instr_import_title")
                                                                         message:[NSString stringWithFormat:L(@"instr_import_ask"), (unsigned long)count]];
    [popup addAction:[ChoiceAction actionWithTitle:L(@"instr_import_replace") style:UIAlertActionStyleDefault handler:^(id a) {
        finish(incoming);
    }]];
    [popup addAction:[ChoiceAction actionWithTitle:L(@"instr_import_append") style:UIAlertActionStyleDefault handler:^(id a) {
        finish([NSString stringWithFormat:@"%@\n\n%@", current, incoming]);
    }]];
    [popup addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [popup presentFromViewController:presenter];
}

+ (UIViewController *)topViewController {
    UIViewController *top = [UIApplication sharedApplication].delegate.window.rootViewController;
    for (int guard = 0; guard < 20 && top; guard++) {
        UIViewController *presented = top.presentedViewController;
        if (presented && !presented.isBeingDismissed) { top = presented; continue; }
        if ([top isKindOfClass:[UINavigationController class]]) {
            UIViewController *visible = [(UINavigationController *)top topViewController];
            if (visible && visible != top) { top = visible; continue; }
        }
        break;
    }
    return top;
}

+ (void)handleOpenedURL:(NSURL *)url {
    if (!url.isFileURL) return;
    UIViewController *top = [self topViewController];
    if (!top) return;
    if ([top isKindOfClass:[SystemPromptViewController class]]) {
        [(SystemPromptViewController *)top importFromURL:url];
        return;
    }
    // A pop-up that is open (for instance the previous message) stays; this one goes on top of it.
    [self importFromURL:url presenter:top existing:[AppSettings systemPrompt] apply:^(NSString *finalText) {
        [AppSettings setSystemPrompt:finalText];
    }];
}

@end
