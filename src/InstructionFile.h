#import <UIKit/UIKit.h>

// Instruction files: a plain UTF-8 text file whose extension is .clmn (a renamed .txt works). ClaudeMini reads it and puts
// the text into the AI instructions, either from the "import" button of the instructions screen or when the file is
// opened with ClaudeMini from Files / the share sheet.
@interface InstructionFile : NSObject

// Reads the file and puts it into the instructions. `existing` is what is there now (empty = it is simply set; otherwise the
// person chooses to replace it or add to its end). `apply` receives the final text. Messages and errors are ClaudeMini pop-ups.
+ (void)importFromURL:(NSURL *)url presenter:(UIViewController *)presenter existing:(NSString *)existing apply:(void (^)(NSString *finalText))apply;

// A file opened with the app from outside: goes into the open instructions screen, or into the general instructions.
+ (void)handleOpenedURL:(NSURL *)url;

@end
