#import "MiniNavigationController.h"
#import "Theme.h"
#import "Strings.h"
#import "AppSettings.h"
#import "Material.h"
#import "TopBlurView.h"

// Material 3 "shared axis" (X) transition between two screens: the new screen slides in 30 pt along the axis while it
// fades in (emphasized decelerate, 400 ms); the old one slides out 30 pt the other way while it fades out faster
// (emphasized accelerate, 200 ms). A pop runs the same motion backwards.
@interface MaterialSharedAxisAnimator : NSObject <UIViewControllerAnimatedTransitioning>
@property (assign, nonatomic) BOOL pushing;
@end

@implementation MaterialSharedAxisAnimator

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext { return MaterialDurationMedium4; }

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)context {
    UIView *container = context.containerView;
    UIViewController *fromController = [context viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toController = [context viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = [context viewForKey:UITransitionContextFromViewKey] ?: fromController.view;
    UIView *toView = [context viewForKey:UITransitionContextToViewKey] ?: toController.view;
    if (!fromView || !toView) { [context completeTransition:![context transitionWasCancelled]]; return; }

    CGFloat shift = 30;
    CGFloat inFrom = self.pushing ? shift : -shift;    // where the new screen starts
    CGFloat outTo = self.pushing ? -shift : shift;     // where the old screen goes

    container.backgroundColor = [Theme background];     // nothing dark shows through while both screens are partly transparent
    toView.frame = [context finalFrameForViewController:toController];
    if (toView.superview != container) [container addSubview:toView];
    toView.alpha = 0;
    toView.transform = CGAffineTransformMakeTranslation(inFrom, 0);

    [Material animateEmphasizedAccelerate:MaterialDurationShort4 animations:^{
        fromView.alpha = 0;
        fromView.transform = CGAffineTransformMakeTranslation(outTo, 0);
    } completion:nil];
    [Material animateEmphasizedDecelerate:MaterialDurationMedium4 animations:^{
        toView.alpha = 1;
        toView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        fromView.alpha = 1;                             // the old screen is reused when the user comes back
        fromView.transform = CGAffineTransformIdentity;
        toView.alpha = 1;
        toView.transform = CGAffineTransformIdentity;
        [context completeTransition:![context transitionWasCancelled]];
    }];
}

@end

@interface MiniNavigationController ()
@property (assign, nonatomic) BOOL transitioning;
@property (copy, nonatomic) NSString *barSignature;
@property (strong, nonatomic) TopBlurView *topBlur;
@end

@implementation MiniNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.delegate = self;
    self.interactivePopGestureRecognizer.delegate = self;
    self.topBlur = [[TopBlurView alloc] init];
    [self.view insertSubview:self.topBlur belowSubview:self.navigationBar];
    for (UIViewController *root in self.viewControllers) [self applyBarLayoutForController:root];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(topBlurStyleChanged) name:kNotifThemeChanged object:nil];
}

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }

- (void)topBlurStyleChanged { [self.topBlur refreshStyle]; }

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // The blur covers the status bar and the bar, and goes on for a little more so that it can fade out below the buttons.
    CGFloat barBottom = CGRectGetMaxY(self.navigationBar.frame);
    self.topBlur.hidden = self.navigationBarHidden;
    self.topBlur.frame = CGRectMake(0, 0, self.view.bounds.size.width, barBottom + 48);
    [self.view insertSubview:self.topBlur belowSubview:self.navigationBar];
}

// The screens that scroll (tables, lists, the chat page) run under the see-through bar; the others keep their own layout
// from the bottom of the bar.
- (void)applyBarLayoutForController:(UIViewController *)controller {
    static NSSet *under;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        under = [NSSet setWithArray:@[@"ChatViewController", @"HistoryViewController", @"SettingsViewController", @"GoogleAccountViewController",
                                      @"AppearanceViewController", @"SoftwareUpdateViewController", @"ModelPickerViewController", @"AccentColorViewController"]];
    });
    if ([under containsObject:NSStringFromClass([controller class])]) {
        controller.edgesForExtendedLayout = UIRectEdgeAll;
    } else {
        controller.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeRight | UIRectEdgeBottom;
    }
}

#pragma mark - Back button

- (UIBarButtonItem *)makeBackItem {
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithImage:[Theme iconBack] style:UIBarButtonItemStylePlain target:self action:@selector(backTapped)];
    item.accessibilityLabel = L(@"close");
    return item;
}

- (void)backTapped {
    if (self.viewControllers.count > 1) [self popViewControllerAnimated:YES];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.transitioning = YES;
    [self applyBarLayoutForController:viewController];
    // Screens above the first one get the plain back button unless they bring their own left item (the history list does).
    if (navigationController.viewControllers.count > 1 && viewController.navigationItem.leftBarButtonItem == nil && !viewController.navigationItem.hidesBackButton) {
        viewController.navigationItem.leftBarButtonItem = [self makeBackItem];
        viewController.navigationItem.hidesBackButton = YES;
    }
    // If the transition is cancelled (a half-done swipe), UIKit tells us through the coordinator.
    id<UIViewControllerTransitionCoordinator> coordinator = navigationController.transitionCoordinator;
    if (coordinator) {
        __weak typeof(self) weakSelf = self;
        [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            if (context.isCancelled) weakSelf.transitioning = NO;
        }];
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    self.transitioning = NO;
    self.interactivePopGestureRecognizer.enabled = YES;   // always back to a known state
    [self applyPendingBarStyle];
}

#pragma mark - Material 3 transitions

// Taps on "back" and pushes use the shared axis transition. An edge swipe that is in progress keeps UIKit's own
// interactive pop (a custom animator would take the finger tracking away).
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    if (![Material active] || [Material reduceMotion] || operation == UINavigationControllerOperationNone) return nil;
    UIGestureRecognizerState swipe = self.interactivePopGestureRecognizer.state;
    if (operation == UINavigationControllerOperationPop && (swipe == UIGestureRecognizerStateBegan || swipe == UIGestureRecognizerStateChanged)) return nil;
    MaterialSharedAxisAnimator *animator = [[MaterialSharedAxisAnimator alloc] init];
    animator.pushing = (operation == UINavigationControllerOperationPush);
    return animator;
}

#pragma mark - Safe pushes

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.transitionCoordinator) animated = NO;   // pushing during a transition would be dropped or crash
    [super pushViewController:viewController animated:animated];
}

#pragma mark - UIGestureRecognizerDelegate (edge swipe)

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer != self.interactivePopGestureRecognizer) return YES;
    if (self.viewControllers.count < 2) return NO;   // nothing to go back to: a swipe here would wedge the controller
    if (self.transitionCoordinator) return NO;
    UIViewController *top = self.topViewController;
    if ([top respondsToSelector:@selector(allowsBackSwipe)] && ![(id<MiniBackSwipeControl>)top allowsBackSwipe]) return NO;
    return YES;
}

#pragma mark - Bar style

// Restyles the bar only when the look really changed, and never in the middle of a push or pop.
- (void)restyleBarWhenIdle {
    if (self.transitionCoordinator) {
        __weak typeof(self) weakSelf = self;
        [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> c) {
            [weakSelf applyPendingBarStyle];
        }];
        return;
    }
    [self applyPendingBarStyle];
}

- (void)applyPendingBarStyle {
    NSString *signature = [NSString stringWithFormat:@"%ld|%d|%ld|%ld|%d|%@", (long)[Theme skin], [Theme darkMode] ? 1 : 0, (long)[AppSettings fontStyle], (long)[AppSettings fontWeightStep], [Theme materialDesign] ? 1 : 0, [Theme signature]];
    if ([signature isEqualToString:self.barSignature]) return;   // e.g. only the wallpaper changed
    self.barSignature = signature;
    [Theme styleNavigationBar:self.navigationBar];
    [self setNeedsStatusBarAppearanceUpdate];
}

@end
