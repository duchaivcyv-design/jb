#import <Foundation/Foundation.h>

// Gate for the developer update channel.
//
// Protection layers (the password itself is never stored, neither in the app nor in the repository):
//   1. Only salted verifiers are in the binary, no password, no plain hash.
//   2. Verifier A: PBKDF2-HMAC-SHA256, 210 000 rounds, own salt.
//   3. Verifier B: PBKDF2-HMAC-SHA512, 150 000 rounds, independent salt.
//   4. Verifier C: an AES-256-CBC sealed blob with an HMAC-SHA256 tag; the key comes from a third PBKDF2 run.
//      A, B and C are always all computed and combined in constant time, so no single early exit leaks anything.
//   5. Developer builds in the repository are AES-256-CBC + HMAC-SHA256 encrypted (encrypt-then-MAC) with a key
//      derived from the password and a fresh salt per file. Without the password the file is useless, even to
//      someone who patches the app or downloads the release by hand.
//   6. There is no lock-out: a wrong password is simply refused (each attempt still takes at least 1.5 s).
//   7. The unlocked session exists only in memory, the password bytes are wiped on lock, when the app goes to the
//      background, when the device locks, when the update screen is left and after 15 minutes.
//   8. (Removed with the lock-out: attempt records left by older builds are only wiped now.)
//   9. (Removed with the lock-out.)
//  10. (Removed: no wrong-try counter, no timed lock. Old counters left by earlier builds are wiped on every attempt.)
//  11. A debugger attached to the process, or Frida / Cycript style instrumentation in the process, blocks the unlock
//      and the decryption.
//  12. Every attempt takes at least 1.5 s, so scripted guessing through the interface gains nothing.
//  13. The decrypted build is written with complete file protection and removed as soon as the channel is left.
//  14. Before a developer build is checked, downloaded or opened, the session must still be unlocked (checked again at
//      each step, not only at the door).

typedef NS_ENUM(NSInteger, DevAccessResult) {
    DevAccessResultOK = 0,
    DevAccessResultWrong,
    DevAccessResultLockedOut,   // short wait after wrong tries; wait = seconds left
    DevAccessResultLockedHour,  // 15 or more wrong tries: shut for an hour; wait = seconds left
    DevAccessResultBusy,
    DevAccessResultInvalid,     // empty or absurdly long input
    DevAccessResultTampered,    // a debugger or instrumentation is attached: refused without trying the password
};

@interface DevAccess : NSObject
+ (instancetype)shared;
@property (assign, nonatomic, readonly) BOOL unlocked;

// Checks the password off the main thread; the completion runs on the main thread.
- (void)unlockWithPassword:(NSString *)password completion:(void (^)(DevAccessResult result, NSTimeInterval wait))completion;
- (void)lock;

// Decrypts a developer build (format below) with the session password. Blocking: call it off the main thread.
// Returns NO and fills `reason` (a short English text for the log) when the session is locked, the file is damaged
// or has been tampered with.
- (BOOL)decryptFileAtPath:(NSString *)source toPath:(NSString *)destination reason:(NSString **)reason;
@end
