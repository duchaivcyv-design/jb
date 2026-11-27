#import "OfficeExport.h"
#import "cmcore.h"

// The .docx package itself (XML parts, ZIP container, CRC-32) is built by the Rust core: rust/cmcore/src/docx_build.rs.
static NSData *MinimalDOCXData(NSString *text) {
    NSData *utf8 = [(text ?: @"") dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    size_t outLength = 0;
    uint8_t *bytes = cm_docx_build((const uint8_t *)utf8.bytes, utf8.length, &outLength);
    if (!bytes || outLength == 0) return nil;
    return [NSData dataWithBytesNoCopy:bytes length:outLength freeWhenDone:YES];   // malloc'd by Rust: released with free()
}

static NSURL *WriteExport(NSData *data, NSString *extension, NSError **error) {
    if (data.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"ClaudeMini.Export" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Empty export"}];
        return nil;
    }
    NSString *directory = NSTemporaryDirectory();
    NSString *name = [NSString stringWithFormat:@"ClaudeMini-Reply-%@.%@", [[NSUUID UUID] UUIDString], extension];
    NSURL *url = [NSURL fileURLWithPath:[directory stringByAppendingPathComponent:name]];
    if (![data writeToURL:url options:NSDataWritingAtomic error:error]) return nil;
    return url;
}

@implementation OfficeExport

+ (NSURL *)writeTextFile:(NSString *)text error:(NSError **)error {
    NSData *data = [(text ?: @"") dataUsingEncoding:NSUTF8StringEncoding];
    return WriteExport(data, @"txt", error);
}

+ (NSURL *)writeWordFile:(NSString *)text error:(NSError **)error {
    NSData *data = MinimalDOCXData(text ?: @"");
    if (!data && error) *error = [NSError errorWithDomain:@"ClaudeMini.Export" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Could not build DOCX package"}];
    return data ? WriteExport(data, @"docx", error) : nil;
}

@end
