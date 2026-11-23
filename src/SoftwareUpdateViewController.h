#import <UIKit/UIKit.h>

// Settings > Software Update. One screen for the normal updates and the password protected developer (beta) channel,
// laid out like the iOS "Software Update" screen: two rows on top (automatic updates, beta channel) and a card with the
// app icon, the version, its size, the notes and the blue "Update now" button.
// The developer channel is only entered through the password gate (DevAccess); leaving the screen closes the gate again.
@interface SoftwareUpdateViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>
@end
