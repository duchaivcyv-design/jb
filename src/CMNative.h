#import <Foundation/Foundation.h>

// Accelerators written in Rust (rust/cmcore). The Objective-C code below is only used for text that is not valid UTF-8.

BOOL CMNativeAvailable(void);

// JavaScript string literal for the text (quotes included): used for every piece of a streaming reply sent to the page.
NSString *CMNativeJSStringLiteral(NSString *text);

// For a very long instruction text: the parts that fit the budget, chosen for the question. nil = not available, so the
// caller uses its own implementation.
NSString *CMNativeSelectPrompt(NSString *prompt, NSString *query, NSUInteger budget);
