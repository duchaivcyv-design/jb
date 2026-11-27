#import "CMNative.h"
#import "DiagnosticLog.h"

#if CM_USE_RUST
#import "claudemini_core.h"
#endif

BOOL CMNativeAvailable(void) {
#if CM_USE_RUST
    return cm_core_abi_version() == 1;
#else
    return NO;
#endif
}

#if CM_USE_RUST
static NSString *TakeRustString(uint8_t *pointer, size_t length) {
    if (!pointer) return nil;
    NSString *result = [[NSString alloc] initWithBytes:pointer length:length encoding:NSUTF8StringEncoding];
    cm_free(pointer, length);
    return result;
}
#endif

NSString *CMNativeJSStringLiteral(NSString *text) {
    text = text ?: @"";
#if CM_USE_RUST
    NSData *utf8 = [text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];   // nil for unpaired surrogates
    if (utf8) {
        size_t length = 0;
        NSString *literal = TakeRustString(cm_js_string_literal(utf8.bytes, utf8.length, &length), length);
        if (literal) return literal;
    }
#endif
    // Objective-C version: let JSON do the escaping and take off the surrounding brackets.
    @try {
        NSData *data = [NSJSONSerialization dataWithJSONObject:@[text] options:0 error:nil];
        NSString *json = data ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : nil;
        if (json.length >= 2) {
            json = [json substringWithRange:NSMakeRange(1, json.length - 2)];
            json = [json stringByReplacingOccurrencesOfString:@"\u2028" withString:@"\\u2028"];
            json = [json stringByReplacingOccurrencesOfString:@"\u2029" withString:@"\\u2029"];
            return json;
        }
    } @catch (NSException *exception) {
        [DiagnosticLog log:@"JS literal skipped: %@", exception.reason];
    }
    return @"\"\"";
}

NSString *CMNativeSelectPrompt(NSString *prompt, NSString *query, NSUInteger budget) {
#if CM_USE_RUST
    NSData *promptData = [prompt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSData *queryData = [(query ?: @"") dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (!promptData || !queryData) return nil;
    size_t length = 0;
    return TakeRustString(cm_prompt_select(promptData.bytes, promptData.length, queryData.bytes, queryData.length, budget, &length), length);
#else
    return nil;
#endif
}
