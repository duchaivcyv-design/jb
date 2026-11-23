#import <UIKit/UIKit.h>

// In-app updater. It looks at the GitHub repository this build came from, finds a newer .ipa / .deb and downloads the
// one that matches how the app is installed:
//   .ipa install (sideloaded, TrollStore, AppSync...) -> downloads the .ipa and opens it in the Files app, where the
//                                                        user picks the signing / installing app.
//   .deb install (jailbreak, in /Applications)       -> downloads the .deb and hands it to the package manager that is
//                                                        installed (Sileo, Zebra, Cydia, Installer, Filza...).
// The repository comes from the Info.plist key ClaudeMiniUpdateRepo ("owner/name"). The GitHub Action fills it in with the
// repository it runs in, so no setting is needed.

typedef NS_ENUM(NSInteger, UpdateInstallKind) {
    UpdateInstallKindIPA = 0,
    UpdateInstallKindDEB = 1,
};

typedef NS_ENUM(NSInteger, UpdateState) {
    UpdateStateIdle = 0,
    UpdateStateChecking,
    UpdateStateUpToDate,
    UpdateStateAvailable,
    UpdateStateDownloading,
    UpdateStateDownloaded,
    UpdateStateFailed,
};

extern NSString *const kNotifUpdateChanged;   // posted on the main thread whenever the state or the progress changes

@interface UpdateManager : NSObject <UIDocumentInteractionControllerDelegate>
+ (instancetype)shared;

@property (assign, nonatomic, readonly) UpdateState state;
@property (copy, nonatomic, readonly) NSString *repo;               // "owner/name" or empty
@property (assign, nonatomic, readonly) UpdateInstallKind installKind;
@property (copy, nonatomic, readonly) NSString *installKindName;    // "IPA" / "DEB"
@property (copy, nonatomic, readonly) NSString *currentVersion;
@property (assign, nonatomic, readonly) NSInteger currentBuild;
@property (copy, nonatomic, readonly) NSString *latestVersion;      // valid when Available / Downloading / Downloaded
@property (assign, nonatomic, readonly) NSInteger latestBuild;
@property (copy, nonatomic, readonly) NSString *latestLabel;        // "0.7.4" or "0.7.3 (build 46)"
@property (copy, nonatomic, readonly) NSString *releaseNotes;
@property (copy, nonatomic, readonly) NSString *assetName;
@property (assign, nonatomic, readonly) long long assetSize;        // bytes, 0 when unknown
@property (assign, nonatomic, readonly) double progress;            // 0...1 while downloading
@property (assign, nonatomic, readonly) long long receivedBytes;
@property (copy, nonatomic, readonly) NSString *downloadedPath;
@property (copy, nonatomic, readonly) NSString *errorMessage;
@property (assign, nonatomic, readonly) BOOL devChannel;            // YES while the password-protected developer channel is in use
@property (assign, nonatomic, readonly) BOOL updateAvailable;       // a newer version is known (Available, Downloading or Downloaded)

// Switches between the normal releases and the developer builds (tag dev-..., files encrypted with the developer
// password, see DevAccess). Cancels a running check / download and forgets the state of the other channel. The caller
// must have unlocked DevAccess before switching to the developer channel.
- (void)switchToDevChannel:(BOOL)dev;

// Checks GitHub. Without force it is skipped when a check ran in the last 10 minutes.
- (void)checkForUpdateForce:(BOOL)force;
- (void)startDownload;
- (void)cancelDownload;
// Opens the downloaded file the right way for this install kind. `from` is the screen that is on top, `anchor` the view
// the system sheet comes from.
- (void)installFromViewController:(UIViewController *)from anchor:(UIView *)anchor;
// Opens the file with the system "Open in..." sheet (IPA: choose the signing app; DEB: choose the package manager).
- (void)presentOpenInFromViewController:(UIViewController *)from anchor:(UIView *)anchor;
// YES once per found version per launch: the Settings screen uses it to show the update notice only once.
- (BOOL)consumePromptForCurrentVersion;
@end
