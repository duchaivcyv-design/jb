#import "OfficeExport.h"
#import <zlib.h>
#include <stdint.h>

static void AppendLE16(NSMutableData *data, uint16_t value) {
    uint8_t bytes[2] = { (uint8_t)(value & 0xFF), (uint8_t)((value >> 8) & 0xFF) };
    [data appendBytes:bytes length:sizeof(bytes)];
}

static void AppendLE32(NSMutableData *data, uint32_t value) {
    uint8_t bytes[4] = { (uint8_t)(value & 0xFF), (uint8_t)((value >> 8) & 0xFF),
                         (uint8_t)((value >> 16) & 0xFF), (uint8_t)((value >> 24) & 0xFF) };
    [data appendBytes:bytes length:sizeof(bytes)];
}

static NSString *XMLSafe(NSString *text) {
    NSMutableString *filtered = [NSMutableString stringWithCapacity:(text ?: @"").length];
    NSString *source = text ?: @"";
    for (NSUInteger i = 0; i < source.length; i++) {
        unichar c = [source characterAtIndex:i];
        if (c == 0x9 || c == 0xA || c == 0xD || c >= 0x20) [filtered appendFormat:@"%C", c];
    }
    NSMutableString *result = filtered;
    [result replaceOccurrencesOfString:@"&" withString:@"&amp;" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"<" withString:@"&lt;" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@">" withString:@"&gt;" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"\"" withString:@"&quot;" options:0 range:NSMakeRange(0, result.length)];
    [result replaceOccurrencesOfString:@"'" withString:@"&apos;" options:0 range:NSMakeRange(0, result.length)];
    return result;
}

static NSData *MinimalDOCXData(NSString *text) {
    NSMutableString *paragraphs = [NSMutableString string];
    NSArray *lines = [(text ?: @"") componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    for (NSString *line in lines) {
        [paragraphs appendFormat:@"<w:p><w:r><w:t xml:space=\"preserve\">%@</w:t></w:r></w:p>", XMLSafe(line)];
    }

    NSString *document = [NSString stringWithFormat:
        @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
         @"<w:document xmlns:w=\"http://schemas.openxmlformats.org/wordprocessingml/2006/main\">"
         @"<w:body>%@<w:sectPr><w:pgSz w:w=\"11906\" w:h=\"16838\"/>"
         @"<w:pgMar w:top=\"1440\" w:right=\"1440\" w:bottom=\"1440\" w:left=\"1440\" w:header=\"720\" w:footer=\"720\" w:gutter=\"0\"/>"
         @"</w:sectPr></w:body></w:document>", paragraphs];

    NSString *contentTypes =
        @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
         @"<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
         @"<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
         @"<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
         @"<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>"
         @"</Types>";
    NSString *relationships =
        @"<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>"
         @"<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
         @"<Relationship Id=\"rId1\" Type=\"http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument\" Target=\"word/document.xml\"/>"
         @"</Relationships>";

    NSArray *entries = @[
        @{ @"name": @"[Content_Types].xml", @"data": [contentTypes dataUsingEncoding:NSUTF8StringEncoding] },
        @{ @"name": @"_rels/.rels", @"data": [relationships dataUsingEncoding:NSUTF8StringEncoding] },
        @{ @"name": @"word/document.xml", @"data": [document dataUsingEncoding:NSUTF8StringEncoding] }
    ];

    NSMutableData *archive = [NSMutableData data];
    NSMutableData *central = [NSMutableData data];
    for (NSDictionary *entry in entries) {
        NSData *name = [entry[@"name"] dataUsingEncoding:NSUTF8StringEncoding];
        NSData *payload = entry[@"data"];
        if (name.length > UINT16_MAX || payload.length > UINT32_MAX) return nil;
        uint32_t crc = (uint32_t)crc32(0L, (const Bytef *)payload.bytes, (uInt)payload.length);
        uint32_t offset = (uint32_t)archive.length;

        AppendLE32(archive, 0x04034b50);
        AppendLE16(archive, 20);
        AppendLE16(archive, 0x0800); // UTF-8 file name
        AppendLE16(archive, 0);      // stored, no compression
        AppendLE16(archive, 0);
        AppendLE16(archive, 0);
        AppendLE32(archive, crc);
        AppendLE32(archive, (uint32_t)payload.length);
        AppendLE32(archive, (uint32_t)payload.length);
        AppendLE16(archive, (uint16_t)name.length);
        AppendLE16(archive, 0);
        [archive appendData:name];
        [archive appendData:payload];

        AppendLE32(central, 0x02014b50);
        AppendLE16(central, 20);
        AppendLE16(central, 20);
        AppendLE16(central, 0x0800);
        AppendLE16(central, 0);
        AppendLE16(central, 0);
        AppendLE16(central, 0);
        AppendLE32(central, crc);
        AppendLE32(central, (uint32_t)payload.length);
        AppendLE32(central, (uint32_t)payload.length);
        AppendLE16(central, (uint16_t)name.length);
        AppendLE16(central, 0);
        AppendLE16(central, 0);
        AppendLE16(central, 0);
        AppendLE16(central, 0);
        AppendLE32(central, 0);
        AppendLE32(central, offset);
        [central appendData:name];
    }

    uint32_t centralOffset = (uint32_t)archive.length;
    [archive appendData:central];
    AppendLE32(archive, 0x06054b50);
    AppendLE16(archive, 0);
    AppendLE16(archive, 0);
    AppendLE16(archive, (uint16_t)entries.count);
    AppendLE16(archive, (uint16_t)entries.count);
    AppendLE32(archive, (uint32_t)central.length);
    AppendLE32(archive, centralOffset);
    AppendLE16(archive, 0);
    return archive;
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
