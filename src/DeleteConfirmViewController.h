#import <UIKit/UIKit.h>

// Material 3 confirmation before something that cannot be undone. Press Delete and the trash can plays its little film:
// the lid flips open, a sheet drops in, the lid snaps shut and the can settles; then the card goes away and the
// action runs. Outside the Material design (Classic) the same call shows the plain choice pop-up instead.
//
// Every place that deletes something gives its own title and message, e.g. "Delete the Gemini API key?".
@interface DeleteConfirmViewController : UIViewController <UIGestureRecognizerDelegate>

+ (void)presentFrom:(UIViewController *)host
              title:(NSString *)title
            message:(NSString *)message
       confirmTitle:(NSString *)confirmTitle
          onConfirm:(void (^)(void))onConfirm;

@end

// The trash can drawn in code (a 38 pt box): lid, body and the sheet that falls in. -playDeleteFilm runs the 1.25 s film.
@interface TrashCanView : UIView
@property (strong, nonatomic) UIColor *strokeColor;
@property (strong, nonatomic) UIColor *sheetColor;
- (void)playDeleteFilm;
@end
