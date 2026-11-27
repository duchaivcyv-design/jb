#import "ImageViewerViewController.h"
#import "Strings.h"

@interface ImageViewerViewController ()
@property (copy, nonatomic) NSString *path;
@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIImageView *imageView;
@property (strong, nonatomic) UIButton *closeButton;
@end

@implementation ImageViewerViewController

- (instancetype)initWithImagePath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.image = [UIImage imageWithContentsOfFile:self.path];

    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale = 1;
    self.scrollView.maximumZoomScale = 4;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self.view addSubview:self.scrollView];

    self.imageView = [[UIImageView alloc] initWithImage:self.image];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.scrollView addSubview:self.imageView];

    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.scrollView addGestureRecognizer:doubleTap];
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    [singleTap requireGestureRecognizerToFail:doubleTap];
    [self.scrollView addGestureRecognizer:singleTap];

    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2];
    self.closeButton.layer.cornerRadius = 18;
    self.closeButton.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightLight];
    [self.closeButton setTitle:@"\u00D7" forState:UIControlStateNormal];
    [self.closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.closeButton addTarget:self action:@selector(close) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.closeButton];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.scrollView.frame = self.view.bounds;
    if (self.scrollView.zoomScale <= 1.001) [self fitImage];
    CGFloat top = 12;
    if (@available(iOS 11.0, *)) top += self.view.safeAreaInsets.top;
    self.closeButton.frame = CGRectMake(12, top, 36, 36);
}

// Lays the image out to fit the screen at zoom 1.
- (void)fitImage {
    CGSize bounds = self.scrollView.bounds.size;
    CGSize size = self.image.size;
    if (size.width < 1 || size.height < 1 || bounds.width < 1) return;
    CGFloat scale = MIN(bounds.width / size.width, bounds.height / size.height);
    CGSize fit = CGSizeMake(floor(size.width * scale), floor(size.height * scale));
    self.imageView.frame = CGRectMake(0, 0, fit.width, fit.height);
    self.scrollView.contentSize = fit;
    [self centerImage];
}

- (void)centerImage {
    CGSize bounds = self.scrollView.bounds.size;
    CGRect frame = self.imageView.frame;
    frame.origin.x = frame.size.width < bounds.width ? (bounds.width - frame.size.width) / 2 : 0;
    frame.origin.y = frame.size.height < bounds.height ? (bounds.height - frame.size.height) / 2 : 0;
    self.imageView.frame = frame;
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self centerImage];
}

- (void)doubleTapped:(UITapGestureRecognizer *)gesture {
    if (self.scrollView.zoomScale > 1.01) {
        [self.scrollView setZoomScale:1 animated:YES];
        return;
    }
    CGPoint point = [gesture locationInView:self.imageView];
    CGFloat scale = 2.5;
    CGSize size = self.scrollView.bounds.size;
    CGRect rect = CGRectMake(point.x - size.width / (2 * scale), point.y - size.height / (2 * scale), size.width / scale, size.height / scale);
    [self.scrollView zoomToRect:rect animated:YES];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
