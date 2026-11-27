#import <Foundation/Foundation.h>
#import "Loc.h"

// Localized string lookup. Follows the language chosen in Settings (default: the device language).
#define L(key) [Loc string:key]

// Notification names shared across screens.
#define kNotifKeyChanged          @"ClaudeMiniKeyChanged"
#define kNotifHistoryCleared      @"ClaudeMiniHistoryCleared"
#define kNotifConversationDeleted @"ClaudeMiniConversationDeleted"
#define kNotifLanguageChanged     @"ClaudeMiniLanguageChanged"
#define kNotifThemeChanged        @"ClaudeMiniThemeChanged"
#define kNotifLayoutChanged       @"ClaudeMiniLayoutChanged"   // screen layout (phone / iPhone Duo) changed in Settings
