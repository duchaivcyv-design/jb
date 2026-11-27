#import "CMNative.h"
#import "DiagnosticLog.h"
#import "cmcore.h"
#include <stdlib.h>

BOOL CMNativeAvailable(void) { return YES; }

// Rust returns malloc'd NUL-terminated UTF-8: copy it into an NSString and free it.
static NSString *TakeMallocString(char *pointer, size_t length) {
    if (!pointer) return nil;
    NSString *result = [[NSString alloc] initWithBytes:pointer length:length encoding:NSUTF8StringEncoding];
    free(pointer);
    return result;
}

NSString *CMNativeJSStringLiteral(NSString *text) {
    text = text ?: @"";
    NSData *utf8 = [text dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];   // nil for unpaired surrogates
    if (utf8) {
        size_t length = 0;
        NSString *literal = TakeMallocString(cm_js_string_literal(utf8.bytes, utf8.length, &length), length);
        if (literal) return literal;
    }
    // Only reached for text that is not valid UTF-8: let JSON do the escaping and take off the surrounding brackets.
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
    NSData *promptData = [prompt dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSData *queryData = [(query ?: @"") dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    if (!promptData || !queryData) return nil;
    size_t length = 0;
    return TakeMallocString(cm_prompt_select(promptData.bytes, promptData.length, queryData.bytes, queryData.length, budget, &length), length);
}
