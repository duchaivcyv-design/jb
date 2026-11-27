#import <Foundation/Foundation.h>

// Accelerators written in Rust (core/). When the Rust library is not part of the build (no Rust toolchain, or it failed to
// build) every function below still works through the Objective-C code it replaces, so the app behaves the same.

BOOL CMNativeAvailable(void);

// JavaScript string literal for the text (quotes included): used for every piece of a streaming reply sent to the page.
NSString *CMNativeJSStringLiteral(NSString *text);

// For a very long instruction text: the parts that fit the budget, chosen for the question. nil = not available, so the
// caller uses its own implementation.
NSString *CMNativeSelectPrompt(NSString *prompt, NSString *query, NSUInteger budget);
