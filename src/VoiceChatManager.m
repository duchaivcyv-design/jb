#import "VoiceChatManager.h"
#import "Loc.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@interface VoiceChatManager ()
@property (strong, nonatomic) SFSpeechRecognizer *recognizer;
@property (strong, nonatomic) SFSpeechAudioBufferRecognitionRequest *request;
@property (strong, nonatomic) SFSpeechRecognitionTask *task;
@property (strong, nonatomic) AVAudioEngine *engine;
@property (copy, nonatomic) void (^partialBlock)(NSString *);
@property (copy, nonatomic) void (^finalBlock)(NSString *);
@property (copy, nonatomic) void (^issueBlock)(VoiceDictationIssue);
@property (copy, nonatomic) NSString *lastText;
@property (assign, nonatomic) BOOL recording;      // the microphone is open
@property (assign, nonatomic) BOOL active;         // a dictation session exists (also while the last words are processed)
@property (assign, nonatomic) NSUInteger session;  // ignores callbacks of an older session
@property (assign, nonatomic) BOOL observing;
@end

@implementation VoiceChatManager

+ (instancetype)shared {
    static VoiceChatManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ instance = [[VoiceChatManager alloc] init]; });
    return instance;
}

- (BOOL)isRecording {
    return self.active;
}

// Recognizer for the app language (vi / en); "auto" follows the device language.
- (SFSpeechRecognizer *)makeRecognizer {
    NSString *pref = [Loc preference];
    NSMutableArray<NSString *> *candidates = [NSMutableArray array];
    if ([pref isEqualToString:@"vi"]) [candidates addObject:@"vi-VN"];
    else if ([pref isEqualToString:@"en"]) [candidates addObject:@"en-US"];
    else {
        NSString *device = [NSLocale preferredLanguages].firstObject;
        if (device.length > 0) [candidates addObject:device];
    }
    [candidates addObject:[NSLocale currentLocale].localeIdentifier ?: @"en-US"];
    [candidates addObject:@"vi-VN"];
    for (NSString *identifier in candidates) {
        SFSpeechRecognizer *recognizer = [[SFSpeechRecognizer alloc] initWithLocale:[NSLocale localeWithLocaleIdentifier:identifier]];
        if (recognizer) return recognizer;
    }
    return nil;
}

- (void)requestAuthorization:(void (^)(BOOL granted))completion {
    void (^finish)(BOOL) = ^(BOOL ok) { dispatch_async(dispatch_get_main_queue(), ^{ if (completion) completion(ok); }); };
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        if (status != SFSpeechRecognizerAuthorizationStatusAuthorized) { finish(NO); return; }
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL micOK) { finish(micOK); }];
    }];
}

#pragma mark - Dictation

- (void)startDictationWithPartial:(void (^)(NSString *))partial
                            final:(void (^)(NSString *))final
                            issue:(void (^)(VoiceDictationIssue))issue {
    if (self.active) [self cancelDictation];

    self.recognizer = [self makeRecognizer];
    if (!self.recognizer || !self.recognizer.isAvailable) {
        if (issue) issue(VoiceDictationIssueUnavailable);
        if (final) final(@"");
        return;
    }
    self.session++;
    NSUInteger mySession = self.session;
    self.partialBlock = partial;
    self.finalBlock = final;
    self.issueBlock = issue;
    self.lastText = @"";
    self.active = YES;

    NSError *sessionError = nil;
    AVAudioSession *audio = [AVAudioSession sharedInstance];
    [audio setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:0 error:&sessionError];
    [audio setActive:YES withOptions:0 error:&sessionError];
    if (sessionError) {
        [self endSessionReportingIssue:VoiceDictationIssueFailed];
        return;
    }

    self.engine = [[AVAudioEngine alloc] init];
    self.request = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    self.request.shouldReportPartialResults = YES;
    if (@available(iOS 16.0, *)) self.request.addsPunctuation = YES;

    __weak typeof(self) weakSelf = self;
    self.task = [self.recognizer recognitionTaskWithRequest:self.request resultHandler:^(SFSpeechRecognitionResult *result, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            VoiceChatManager *me = weakSelf;
            if (!me || me.session != mySession || !me.active) return;
            if (result) {
                NSString *text = result.bestTranscription.formattedString ?: @"";
                me.lastText = text;
                if (!result.isFinal && me.partialBlock) me.partialBlock(text);
                if (result.isFinal) { [me endSessionReportingIssue:-1]; return; }
            }
            if (error) {
                // 1110 / 203 = nothing was heard; when some words arrived the text is simply kept
                BOOL noSpeech = (error.code == 1110 || error.code == 203);
                if (me.lastText.length > 0) [me endSessionReportingIssue:-1];
                else [me endSessionReportingIssue:noSpeech ? VoiceDictationIssueNoSpeech : VoiceDictationIssueFailed];
            }
        });
    }];
    if (!self.task) { [self endSessionReportingIssue:VoiceDictationIssueFailed]; return; }

    AVAudioInputNode *node = self.engine.inputNode;
    AVAudioFormat *format = [node outputFormatForBus:0];
    if (format.sampleRate <= 0 || format.channelCount == 0) { [self endSessionReportingIssue:VoiceDictationIssueFailed]; return; }
    SFSpeechAudioBufferRecognitionRequest *request = self.request;
    [node installTapOnBus:0 bufferSize:1024 format:format block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when) {
        [request appendAudioPCMBuffer:buffer];   // safe to call from the audio thread
    }];
    [self.engine prepare];
    NSError *startError = nil;
    if (![self.engine startAndReturnError:&startError]) {
        [self endSessionReportingIssue:VoiceDictationIssueFailed];
        return;
    }
    self.recording = YES;
    [self observeInterruptions:YES];
}

// The user stopped talking: close the microphone but let the recognizer finish the last words.
- (void)finishDictation {
    if (!self.active) return;
    [self closeMicrophone];
    [self.request endAudio];
    NSUInteger mySession = self.session;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        VoiceChatManager *me = weakSelf;
        if (me && me.session == mySession && me.active) [me endSessionReportingIssue:-1];   // the recognizer was slow: keep what we have
    });
}

- (void)cancelDictation {
    if (!self.active) return;
    [self endSessionReportingIssue:-1];
}

- (void)closeMicrophone {
    if (!self.recording) return;
    self.recording = NO;
    if (self.engine.isRunning) [self.engine stop];
    @try { [self.engine.inputNode removeTapOnBus:0]; } @catch (__unused NSException *exception) {}
}

// Ends the session once: releases audio, then reports the issue (if any) and the final text.
- (void)endSessionReportingIssue:(NSInteger)issue {
    if (!self.active) return;
    self.active = NO;
    [self observeInterruptions:NO];
    [self closeMicrophone];
    [self.request endAudio];
    [self.task cancel];
    self.task = nil;
    self.request = nil;
    self.engine = nil;
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];

    void (^issueBlock)(VoiceDictationIssue) = self.issueBlock;
    void (^finalBlock)(NSString *) = self.finalBlock;
    NSString *text = self.lastText ?: @"";
    self.partialBlock = nil;
    self.issueBlock = nil;
    self.finalBlock = nil;
    self.lastText = nil;
    if (issue >= 0 && issueBlock) issueBlock((VoiceDictationIssue)issue);
    if (finalBlock) finalBlock(text);
}

#pragma mark - Interruptions (a call, Siri, the app going to the background)

- (void)observeInterruptions:(BOOL)on {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (on && !self.observing) {
        self.observing = YES;
        [center addObserver:self selector:@selector(interrupted:) name:AVAudioSessionInterruptionNotification object:nil];
        [center addObserver:self selector:@selector(interrupted:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    } else if (!on && self.observing) {
        self.observing = NO;
        [center removeObserver:self name:AVAudioSessionInterruptionNotification object:nil];
        [center removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
}

- (void)interrupted:(NSNotification *)note {
    if ([note.name isEqualToString:AVAudioSessionInterruptionNotification]) {
        NSUInteger type = [note.userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
        if (type != AVAudioSessionInterruptionTypeBegan) return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{ [self cancelDictation]; });
}

@end
