#import "AttachmentStore.h"
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>
#import <math.h>
#import "OfficeText.h"

const NSInteger  kMaxAttachmentsPerMessage = 25;
const NSUInteger kMaxInlineBytesPerMessage = 13 * 1024 * 1024;   // base64 adds a third: ~17.4 MB of the 20 MB request cap

// Ép mạnh ảnh & video để tiết kiệm dung lượng/token tối đa
static const CGFloat    kImageMaxSide      = 1024;
static const CGFloat    kThumbMaxSide      = 128;
static const NSUInteger kMaxPDFBytes       = 10 * 1024 * 1024;
static const NSUInteger kMaxOfficeBytes    = 15 * 1024 * 1024;     // .docx / .pptx archive size
static const NSUInteger kMaxImageFileBytes = 40 * 1024 * 1024;
static const unsigned long long kMaxVideoFileBytes = 100ULL * 1024ULL * 1024ULL;
static const NSTimeInterval kMaxVideoDuration = 120.0;
static const NSUInteger kMaxVideoFrames = 4;

// Ép trần cực cao theo yêu cầu (1 tỷ ký tự / 1GB) kết hợp streaming tránh OOM
const NSUInteger kMaxTextFileBytes  = 1024ULL * 1024ULL * 1024ULL;
const NSUInteger kMaxTextChars      = 1000000000ULL;               // 1 tỷ ký tự
static const unsigned long long kMaxZipFileBytes = 500ULL * 1024ULL * 1024ULL;
static const NSUInteger kStreamWriteChunkBytes = 1024 * 1024;      // Ghi từng khối 1MB

// Ép mạnh chuỗi: gộp dòng trống liên tiếp (tối đa 1 dòng trống) và gộp nhiều space/tab liên tiếp thành 1 space
static NSString *CompactTextAggressive(NSString *input, NSUInteger maxChars) {
    if (!input || input.length == 0) return @"";
    NSUInteger limit = MIN(input.length, maxChars);
    NSRange safeRange = [input rangeOfComposedCharacterSequencesForRange:NSMakeRange(0, limit)];
    NSString *src = [input substringWithRange:safeRange];

    NSMutableString *out = [NSMutableString stringWithCapacity:MIN(src.length, (NSUInteger)(src.length * 0.75))];
    BOOL prevNewline = NO;
    BOOL prevSpace = NO;

    for (NSUInteger i = 0; i < src.length; i++) {
        unichar ch = [src characterAtIndex:i];
        if (ch == '\r') {
            continue;
        }
        if (ch == '\n') {
            if (!prevNewline) {
                // Xóa space thừa ngay trước xuống dòng
                while (out.length > 0 && [out characterAtIndex:out.length - 1] == ' ') {
                    [out deleteCharactersInRange:NSMakeRange(out.length - 1, 1)];
                }
                [out appendString:@"\n"];
                prevNewline = YES;
                prevSpace = NO;
            }
            continue;
        }
        if (ch == ' ' || ch == '\t') {
            if (!prevSpace && !prevNewline) {
                [out appendString:@" "];
                prevSpace = YES;
            }
            continue;
        }
        [out appendFormat:@"%C", ch];
        prevNewline = NO;
        prevSpace = NO;
    }

    return [out stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSString *RootDir(void) {
    static NSString *dir = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSString *base = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
        dir = [[base stringByAppendingPathComponent:@"ClaudeMini"] stringByAppendingPathComponent:@"attachments"];
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    });
    return dir;
}

static BOOL SafeComponent(id value) {
    if (![value isKindOfClass:[NSString class]]) return NO;
    NSString *s = value;
    return s.length > 0 && [s rangeOfString:@"/"].location == NSNotFound && [s rangeOfString:@".."].location == NSNotFound;
}

static BOOL WriteUTF8StringToPath(NSString *string, NSString *filePath) {
    if (!string || !filePath) return NO;
    NSData *utf8 = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!utf8) return NO;
    if (utf8.length <= kStreamWriteChunkBytes * 4) {
        return [utf8 writeToFile:filePath options:NSDataWritingAtomic error:nil];
    }
    [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];
    NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!handle) return NO;
    @try {
        NSUInteger offset = 0;
        while (offset < utf8.length) {
            @autoreleasepool {
                NSUInteger len = MIN(kStreamWriteChunkBytes, utf8.length - offset);
                NSData *chunk = [NSData dataWithBytesNoCopy:(void *)((const uint8_t *)utf8.bytes + offset)
                                                     length:len
                                               freeWhenDone:NO];
                [handle writeData:chunk];
                offset += len;
            }
        }
        [handle synchronizeFile];
        return YES;
    } @catch (__unused NSException *ex) {
        return NO;
    } @finally {
        [handle closeFile];
    }
}

@implementation AttachmentStore

#pragma mark - Folders

+ (NSString *)directoryForConversation:(NSString *)conversationId create:(BOOL)create {
    if (!SafeComponent(conversationId)) return nil;
    NSString *dir = [RootDir() stringByAppendingPathComponent:conversationId];
    if (create) {
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return dir;
}

+ (void)deleteDirectoryForConversation:(NSString *)conversationId {
    NSString *dir = [self directoryForConversation:conversationId create:NO];
    if (dir) [[NSFileManager defaultManager] removeItemAtPath:dir error:nil];
}

+ (void)deleteAll {
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *item in [fm contentsOfDirectoryAtPath:RootDir() error:nil]) {
        [fm removeItemAtPath:[RootDir() stringByAppendingPathComponent:item] error:nil];
    }
}

+ (void)removeOrphansKeepingConversationIds:(NSSet *)conversationIds {
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *item in [fm contentsOfDirectoryAtPath:RootDir() error:nil]) {
        if (![conversationIds containsObject:item]) {
            [fm removeItemAtPath:[RootDir() stringByAppendingPathComponent:item] error:nil];
        }
    }
}

+ (NSString *)pathForFile:(NSString *)file conversation:(NSString *)conversationId {
    if (!SafeComponent(file)) return nil;
    NSString *dir = [self directoryForConversation:conversationId create:NO];
    return dir ? [dir stringByAppendingPathComponent:file] : nil;
}

+ (void)deleteAttachment:(NSDictionary *)attachment conversation:(NSString *)conversationId {
    NSFileManager *fm = [NSFileManager defaultManager];
    for (NSString *key in @[@"file", @"thumb"]) {
        NSString *path = [self pathForFile:attachment[key] conversation:conversationId];
        if (path) [fm removeItemAtPath:path error:nil];
    }
    NSArray *frames = [attachment[@"frames"] isKindOfClass:[NSArray class]] ? attachment[@"frames"] : @[];
    for (NSString *file in frames) {
        NSString *path = [self pathForFile:file conversation:conversationId];
        if (path) [fm removeItemAtPath:path error:nil];
    }
}

+ (NSString *)thumbnailDataURIForAttachment:(NSDictionary *)attachment conversation:(NSString *)conversationId {
    NSString *path = [self pathForFile:attachment[@"thumb"] conversation:conversationId];
    NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
    if (data.length == 0) return @"";
    return [@"data:image/jpeg;base64," stringByAppendingString:[data base64EncodedStringWithOptions:0]];
}

#pragma mark - Images

+ (NSData *)jpegFromImage:(UIImage *)image maxSide:(CGFloat)maxSide quality:(CGFloat)quality {
    CGSize size = image.size;
    if (size.width < 1 || size.height < 1) return nil;
    CGFloat scale = MIN(1.0, maxSide / MAX(size.width, size.height));
    CGSize target = CGSizeMake(MAX(1, floor(size.width * scale)), MAX(1, floor(size.height * scale)));

    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = 1;
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:target format:format];
    UIImage *flat = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[UIColor whiteColor] setFill];
        UIRectFill(CGRectMake(0, 0, target.width, target.height));
        [image drawInRect:CGRectMake(0, 0, target.width, target.height)];
    }];
    return UIImageJPEGRepresentation(flat, quality);
}

+ (NSDictionary *)importImageData:(NSData *)data name:(NSString *)name conversation:(NSString *)conversationId errorKey:(NSString **)errorKey {
    if (data.length == 0) { if (errorKey) *errorKey = @"att_err_empty"; return nil; }
    if (data.length > kMaxImageFileBytes) { if (errorKey) *errorKey = @"att_err_too_large"; return nil; }
    NSString *dir = [self directoryForConversation:conversationId create:YES];
    if (!dir) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }
    NSDictionary *options = @{ (__bridge id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
                               (__bridge id)kCGImageSourceCreateThumbnailWithTransform: @YES,
                               (__bridge id)kCGImageSourceThumbnailMaxPixelSize: @(kImageMaxSide) };
    CGImageRef cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
    CFRelease(source);
    if (!cgImage) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);

    // Ép chất lượng JPEG xuống 0.55 để giảm dung lượng
    NSData *jpeg = [self jpegFromImage:image maxSide:kImageMaxSide quality:0.55];
    NSData *thumb = [self jpegFromImage:image maxSide:kThumbMaxSide quality:0.55];
    if (jpeg.length == 0 || thumb.length == 0) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }

    NSString *attachmentId = [[NSUUID UUID] UUIDString];
    NSString *file = [attachmentId stringByAppendingString:@".jpg"];
    NSString *thumbFile = [attachmentId stringByAppendingString:@"_t.jpg"];
    BOOL ok = [jpeg writeToFile:[dir stringByAppendingPathComponent:file] options:NSDataWritingAtomic error:nil]
           && [thumb writeToFile:[dir stringByAppendingPathComponent:thumbFile] options:NSDataWritingAtomic error:nil];
    if (!ok) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }

    NSString *display = name.length > 0 ? name : @"photo.jpg";
    return @{ @"id": attachmentId, @"kind": @"image", @"name": display, @"mime": @"image/jpeg",
              @"file": file, @"thumb": thumbFile, @"bytes": @(jpeg.length) };
}

#pragma mark - Documents

+ (NSSet *)imageExtensions {
    return [NSSet setWithObjects:@"jpg", @"jpeg", @"png", @"gif", @"heic", @"heif", @"webp", @"tif", @"tiff", @"bmp", nil];
}

+ (NSSet *)unsupportedExtensions {
    return [NSSet setWithObjects:@"doc", @"xls", @"xlsx", @"ppt", @"odt", @"ods", @"odp", @"pages", @"numbers", @"key", @"rtf",
            @"rar", @"7z", @"mp3", @"m4a", @"wav", @"avi", @"exe", @"dmg", @"ipa", @"deb", nil];
}

+ (NSString *)decodeText:(NSData *)data {
    if (data.length == 0) return nil;
    const uint8_t *bytes = data.bytes;
    NSUInteger probe = MIN(data.length, (NSUInteger)65536);
    BOOL utf16BOM = probe >= 2 && ((bytes[0] == 0xFF && bytes[1] == 0xFE) || (bytes[0] == 0xFE && bytes[1] == 0xFF));
    if (!utf16BOM) {
        for (NSUInteger i = 0; i < probe; i++) {
            if (bytes[i] == 0) return nil;
        }
    }
    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (text) return text;
    if (data.length <= 16 * 1024 * 1024) {
        NSString *converted = nil;
        [NSString stringEncodingForData:data encodingOptions:nil convertedString:&converted usedLossyConversion:NULL];
        if (converted.length > 0) return converted;
    }
    return [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
}

+ (NSDictionary *)saveText:(NSString *)text name:(NSString *)name conversation:(NSString *)conversationId errorKey:(NSString **)errorKey {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) {
        if (errorKey) *errorKey = @"att_err_no_text";
        return nil;
    }

    NSString *payload = CompactTextAggressive(text, kMaxTextChars);
    if (payload.length == 0) {
        if (errorKey) *errorKey = @"att_err_no_text";
        return nil;
    }

    NSString *dir = [self directoryForConversation:conversationId create:YES];
    if (!dir) {
        if (errorKey) *errorKey = @"att_err_unreadable";
        return nil;
    }

    NSString *attachmentId = [[NSUUID UUID] UUIDString];
    NSString *file = [attachmentId stringByAppendingString:@".txt"];
    NSString *fullPath = [dir stringByAppendingPathComponent:file];
    if (!WriteUTF8StringToPath(payload, fullPath)) {
        if (errorKey) *errorKey = @"att_err_unreadable";
        return nil;
    }

    unsigned long long writtenBytes = [[[NSFileManager defaultManager] attributesOfItemAtPath:fullPath error:nil][NSFileSize] unsignedLongLongValue];
    return @{ @"id": attachmentId, @"kind": @"text", @"name": name, @"mime": @"text/plain", @"file": file, @"bytes": @(writtenBytes) };
}

+ (NSDictionary *)importOffice:(NSData *)data isPPTX:(BOOL)isPPTX name:(NSString *)name conversation:(NSString *)conversationId errorKey:(NSString **)errorKey {
    int err = OFFICE_OK;
    char *raw = isPPTX ? office_pptx_text(data.bytes, data.length, &err) : office_docx_text(data.bytes, data.length, &err);
    if (!raw) {
        if (errorKey) *errorKey = (err == OFFICE_ERR_UNSUPPORTED) ? @"att_err_encrypted" : @"att_err_unreadable";
        return nil;
    }
    NSString *text = [NSString stringWithUTF8String:raw];
    free(raw);
    if (!text) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }
    return [self saveText:text name:name conversation:conversationId errorKey:errorKey];
}

+ (NSDictionary *)importVideoAtURL:(NSURL *)url conversation:(NSString *)conversationId errorKey:(NSString **)errorKey {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
    unsigned long long fileBytes = [attributes[NSFileSize] unsignedLongLongValue];
    if (fileBytes == 0 || fileBytes > kMaxVideoFileBytes) {
        if (errorKey) *errorKey = fileBytes == 0 ? @"att_err_unreadable" : @"att_err_too_large";
        return nil;
    }

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:@{ AVURLAssetPreferPreciseDurationAndTimingKey: @NO }];
    NSTimeInterval duration = CMTimeGetSeconds(asset.duration);
    if (!isfinite(duration) || duration <= 0 || duration > kMaxVideoDuration) {
        if (errorKey) *errorKey = @"att_err_video";
        return nil;
    }

    NSString *dir = [self directoryForConversation:conversationId create:YES];
    if (!dir) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }

    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    generator.maximumSize = CGSizeMake(kImageMaxSide, kImageMaxSide);
    NSUInteger frameCount = MIN(kMaxVideoFrames, MAX((NSUInteger)2, (NSUInteger)ceil(duration / 15.0)));
    NSString *attachmentId = [[NSUUID UUID] UUIDString];
    NSMutableArray *frameFiles = [NSMutableArray array];
    NSUInteger totalBytes = 0;

    for (NSUInteger i = 0; i < frameCount; i++) {
        @autoreleasepool {
            NSTimeInterval seconds = frameCount == 1 ? 0 : (duration - 0.05) * ((double)i / (double)(frameCount - 1));
            NSError *frameError = nil;
            CGImageRef cgImage = [generator copyCGImageAtTime:CMTimeMakeWithSeconds(MAX(0, seconds), 600)
                                                   actualTime:NULL error:&frameError];
            if (!cgImage) continue;
            UIImage *image = [UIImage imageWithCGImage:cgImage];
            CGImageRelease(cgImage);
            NSData *jpeg = [self jpegFromImage:image maxSide:kImageMaxSide quality:0.55];
            if (jpeg.length == 0) continue;

            NSString *frameFile = [NSString stringWithFormat:@"%@_v%lu.jpg", attachmentId, (unsigned long)i];
            if (![jpeg writeToFile:[dir stringByAppendingPathComponent:frameFile] options:NSDataWritingAtomic error:nil]) continue;
            [frameFiles addObject:frameFile];
            totalBytes += jpeg.length;
        }
    }

    if (frameFiles.count == 0) {
        if (errorKey) *errorKey = @"att_err_video";
        return nil;
    }
    NSString *ext = url.pathExtension.lowercaseString;
    NSString *mime = [ext isEqualToString:@"mov"] ? @"video/quicktime" : @"video/mp4";
    return @{ @"id": attachmentId, @"kind": @"video", @"name": url.lastPathComponent ?: @"video.mp4",
              @"mime": mime, @"frames": frameFiles, @"duration": @(duration), @"bytes": @(totalBytes) };
}

+ (NSDictionary *)importDocumentAtURL:(NSURL *)url conversation:(NSString *)conversationId errorKey:(NSString **)errorKey {
    NSString *name = url.lastPathComponent.length > 0 ? url.lastPathComponent : @"file";
    NSString *ext = name.pathExtension.lowercaseString;

    BOOL scoped = [url startAccessingSecurityScopedResource];
    if ([ext isEqualToString:@"zip"]) {
        NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:url.path error:nil];
        unsigned long long zipBytes = [attributes[NSFileSize] unsignedLongLongValue];
        if (zipBytes > kMaxZipFileBytes) {
            if (scoped) [url stopAccessingSecurityScopedResource];
            if (errorKey) *errorKey = @"att_err_too_large";
            return nil;
        }
    }
    if ([ext isEqualToString:@"mp4"] || [ext isEqualToString:@"mov"] || [ext isEqualToString:@"m4v"]) {
        NSDictionary *video = [self importVideoAtURL:url conversation:conversationId errorKey:errorKey];
        if (scoped) [url stopAccessingSecurityScopedResource];
        return video;
    }
    NSData *data = [NSData dataWithContentsOfURL:url options:NSDataReadingMappedIfSafe error:nil];
    if (scoped) [url stopAccessingSecurityScopedResource];

    if (!data) { if (errorKey) *errorKey = @"att_err_unreadable"; return nil; }
    if (data.length == 0) { if (errorKey) *errorKey = @"att_err_empty"; return nil; }

    if ([[self imageExtensions] containsObject:ext]) {
        return [self importImageData:data name:name conversation:conversationId errorKey:errorKey];
    }

    if ([ext isEqualToString:@"pdf"]) {
        if (data.length > kMaxPDFBytes) { if (errorKey) *errorKey = @"att_err_too_large"; return nil; }
        NSData *head = [data subdataWithRange:NSMakeRange(0, MIN(data.length, (NSUInteger)1024))];
        if ([head rangeOfData:[NSData dataWithBytes:"%PDF" length:4] options:0 range:NSMakeRange(0, head.length)].location == NSNotFound) {
            if (errorKey) *errorKey = @"att_err_unreadable";
            return nil;
        }
        NSString *dir = [self directoryForConversation:conversationId create:YES];
        NSString *attachmentId = [[NSUUID UUID] UUIDString];
        NSString *file = [attachmentId stringByAppendingString:@".pdf"];
        if (!dir || ![data writeToFile:[dir stringByAppendingPathComponent:file] options:NSDataWritingAtomic error:nil]) {
            if (errorKey) *errorKey = @"att_err_unreadable";
            return nil;
        }
        return @{ @"id": attachmentId, @"kind": @"pdf", @"name": name, @"mime": @"application/pdf", @"file": file, @"bytes": @(data.length) };
    }

    if ([ext isEqualToString:@"docx"] || [ext isEqualToString:@"pptx"]) {
        if (data.length > kMaxOfficeBytes) { if (errorKey) *errorKey = @"att_err_too_large"; return nil; }
        return [self importOffice:data isPPTX:[ext isEqualToString:@"pptx"] name:name conversation:conversationId errorKey:errorKey];
    }

    if ([ext isEqualToString:@"zip"]) {
        if (data.length > kMaxZipFileBytes) { if (errorKey) *errorKey = @"att_err_too_large"; return nil; }
        int zipError = OFFICE_OK;
        char *rawText = office_zip_text(data.bytes, data.length, &zipError);
        NSString *archiveText = rawText ? [NSString stringWithUTF8String:rawText] : nil;
        if (rawText) free(rawText);
        if (archiveText.length == 0) {
            NSString *sizeStr = [NSByteCountFormatter stringFromByteCount:data.length countStyle:NSByteCountFormatterCountStyleFile];
            archiveText = [NSString stringWithFormat:@"[Tệp ZIP đính kèm]\nTên: %@\nDung lượng: %@\nLưu ý: archive chứa nội dung nhị phân hoặc đã mã hóa, không trích xuất được văn bản. Người dùng đã gửi file này đính kèm.", name, sizeStr];
        }
        return [self saveText:archiveText name:[NSString stringWithFormat:@"%@ (nội dung ZIP)", name]
                 conversation:conversationId errorKey:errorKey];
    }

    if ([[self unsupportedExtensions] containsObject:ext]) {
        if (errorKey) *errorKey = @"att_err_unsupported";
        return nil;
    }

    if (data.length > kMaxTextFileBytes) { if (errorKey) *errorKey = @"att_err_too_large"; return nil; }
    NSString *text = [self decodeText:data];
    if (!text) { if (errorKey) *errorKey = @"att_err_unsupported"; return nil; }
    return [self saveText:text name:name conversation:conversationId errorKey:errorKey];
}

@end
