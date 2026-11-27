#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, VoiceDictationIssue) {
    VoiceDictationIssueDenied = 0,    // chưa cho phép micro hoặc nhận dạng giọng nói
    VoiceDictationIssueUnavailable,   // máy/ngôn ngữ không hỗ trợ, hoặc đang không có kết nối
    VoiceDictationIssueNoSpeech,      // không nghe thấy gì
    VoiceDictationIssueFailed         // lỗi khác
};

// Nói thành văn bản (dictation): bấm mic, nói, chữ hiện trong ô nhập, người dùng tự bấm gửi.
// Mọi callback chạy trên main queue.
@interface VoiceChatManager : NSObject

+ (instancetype)shared;

// Xin quyền (micro + nhận dạng giọng nói) nếu cần.
- (void)requestAuthorization:(void (^)(BOOL granted))completion;

// Bắt đầu nghe. partial: văn bản tạm, gọi liên tục. final: văn bản cuối, gọi đúng 1 lần khi kết thúc (có thể rỗng).
// issue: gọi khi có sự cố (trước final).
- (void)startDictationWithPartial:(void (^)(NSString *text))partial
                            final:(void (^)(NSString *text))final
                            issue:(void (^)(VoiceDictationIssue issue))issue;

// Dừng nói nhưng vẫn lấy nốt phần chữ đang xử lý (final sẽ được gọi trong tối đa ~2 giây).
- (void)finishDictation;
// Dừng ngay, bỏ phần đang xử lý (final vẫn được gọi một lần với chữ đã nhận).
- (void)cancelDictation;
- (BOOL)isRecording;

@end

NS_ASSUME_NONNULL_END
