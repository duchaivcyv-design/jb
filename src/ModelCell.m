#import "ModelCell.h"
#import "ModelStore.h"
#import "Provider.h"
#import "Theme.h"
#import "Material.h"

static const CGFloat kRowHeight = 68;

#pragma mark - Logos and capability chips

// Claude: the orange starburst (bundled PNG).
static UIImage *ClaudeLogoImage(void) {
    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ image = [UIImage imageNamed:@"logo_claude_mark.png"]; });
    return image;
}

// Gemini: the four-point sparkle with Google's blue -> violet -> coral gradient, drawn in code (no asset needed).
static UIImage *GeminiLogoImage(void) {
    static UIImage *image;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        CGFloat side = 44;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
        image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *rc) {
            CGContextRef c = rc.CGContext;
            CGFloat m = side / 2, k = side * 0.07;   // k: how far the curves are pulled toward the centre (smaller = sharper arms)
            UIBezierPath *star = [UIBezierPath bezierPath];
            [star moveToPoint:CGPointMake(m, 0)];
            [star addQuadCurveToPoint:CGPointMake(side, m) controlPoint:CGPointMake(m + k, m - k)];
            [star addQuadCurveToPoint:CGPointMake(m, side) controlPoint:CGPointMake(m + k, m + k)];
            [star addQuadCurveToPoint:CGPointMake(0, m) controlPoint:CGPointMake(m - k, m + k)];
            [star addQuadCurveToPoint:CGPointMake(m, 0) controlPoint:CGPointMake(m - k, m - k)];
            [star closePath];
            CGContextSaveGState(c);
            [star addClip];
            CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
            NSArray *colors = @[ (id)[UIColor colorWithRed:0.26 green:0.52 blue:0.96 alpha:1].CGColor,    // #4285F4
                                 (id)[UIColor colorWithRed:0.61 green:0.45 blue:0.80 alpha:1].CGColor,    // #9B72CB
                                 (id)[UIColor colorWithRed:0.85 green:0.40 blue:0.44 alpha:1].CGColor ];  // #D96570
            CGFloat locations[3] = { 0, 0.55, 1 };
            CGGradientRef gradient = CGGradientCreateWithColors(space, (CFArrayRef)colors, locations);
            CGContextDrawLinearGradient(c, gradient, CGPointMake(0, side), CGPointMake(side, 0), 0);
            CGGradientRelease(gradient);
            CGColorSpaceRelease(space);
            CGContextRestoreGState(c);
        }];
    });
    return image;
}

typedef NS_ENUM(NSInteger, ModelCapability) {
    ModelCapabilityNone = 0, ModelCapabilityImage, ModelCapabilityVideo, ModelCapabilityPro, ModelCapabilityUltra
};

// Gemini models only. Image / video generators first, then the "Ultra" and "Pro" tiers.
static ModelCapability CapabilityForModelId(NSString *modelId) {
    NSString *id_ = modelId.lowercaseString;
    if ([Provider forModelId:modelId] == AIProviderClaude) return ModelCapabilityNone;
    if ([id_ rangeOfString:@"veo"].location != NSNotFound || [id_ rangeOfString:@"video"].location != NSNotFound) return ModelCapabilityVideo;
    if ([id_ rangeOfString:@"image"].location != NSNotFound || [id_ rangeOfString:@"imagen"].location != NSNotFound) return ModelCapabilityImage;
    if ([id_ rangeOfString:@"ultra"].location != NSNotFound) return ModelCapabilityUltra;
    if ([id_ rangeOfString:@"-pro"].location != NSNotFound || [id_ hasSuffix:@"pro"]) return ModelCapabilityPro;
    return ModelCapabilityNone;
}

// A tiny round chip: accent circle with a white glyph (picture, camera, diamond, bolt). Minimal on purpose.
static UIImage *CapabilityChipImage(ModelCapability capability) {
    CGFloat side = 18;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *rc) {
        CGContextRef c = rc.CGContext;
        // Ring in the row colour so the chip separates cleanly from the logo behind it.
        [[Theme surface] setFill];
        CGContextFillEllipseInRect(c, CGRectMake(0, 0, side, side));
        [[Theme accent] setFill];
        CGContextFillEllipseInRect(c, CGRectMake(1.5, 1.5, side - 3, side - 3));
        [[UIColor whiteColor] setFill];
        [[UIColor whiteColor] setStroke];
        switch (capability) {
            case ModelCapabilityImage: {   // framed picture: rounded square, a sun and a hill
                UIBezierPath *frame = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(4.5, 5, 9, 8) cornerRadius: 1.6];
                frame.lineWidth = 1.2;
                [frame stroke];
                CGContextFillEllipseInRect(c, CGRectMake(6.6, 6.8, 1.8, 1.8));
                UIBezierPath *hill = [UIBezierPath bezierPath];
                [hill moveToPoint:CGPointMake(5.2, 12.4)];
                [hill addLineToPoint:CGPointMake(8.2, 9.8)];
                [hill addLineToPoint:CGPointMake(10, 11.4)];
                [hill addLineToPoint:CGPointMake(11.2, 10.4)];
                [hill addLineToPoint:CGPointMake(12.8, 12.4)];
                hill.lineWidth = 1.1; hill.lineJoinStyle = kCGLineJoinRound; [hill stroke];
                break;
            }
            case ModelCapabilityVideo: {   // play triangle
                UIBezierPath *play = [UIBezierPath bezierPath];
                [play moveToPoint:CGPointMake(7.2, 5.4)];
                [play addLineToPoint:CGPointMake(13, 9)];
                [play addLineToPoint:CGPointMake(7.2, 12.6)];
                [play closePath];
                play.lineJoinStyle = kCGLineJoinRound; play.lineWidth = 1; [play fill]; [play stroke];
                break;
            }
            case ModelCapabilityPro: {     // diamond
                UIBezierPath *d = [UIBezierPath bezierPath];
                [d moveToPoint:CGPointMake(9, 4.6)];
                [d addLineToPoint:CGPointMake(13, 9)];
                [d addLineToPoint:CGPointMake(9, 13.4)];
                [d addLineToPoint:CGPointMake(5, 9)];
                [d closePath];
                d.lineJoinStyle = kCGLineJoinRound; d.lineWidth = 0.8; [d fill]; [d stroke];
                break;
            }
            case ModelCapabilityUltra: {   // lightning bolt
                UIBezierPath *b = [UIBezierPath bezierPath];
                [b moveToPoint:CGPointMake(10.2, 4.4)];
                [b addLineToPoint:CGPointMake(6.2, 9.8)];
                [b addLineToPoint:CGPointMake(8.7, 9.8)];
                [b addLineToPoint:CGPointMake(7.8, 13.6)];
                [b addLineToPoint:CGPointMake(11.8, 8.2)];
                [b addLineToPoint:CGPointMake(9.3, 8.2)];
                [b closePath];
                b.lineJoinStyle = kCGLineJoinRound; b.lineWidth = 0.6; [b fill]; [b stroke];
                break;
            }
            default: break;
        }
    }];
}

@interface ModelCell ()
@property (strong, nonatomic) UIView *badge;
@property (strong, nonatomic) UIImageView *logoView;
@property (strong, nonatomic) UIImageView *chipView;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *idLabel;
@property (strong, nonatomic) UILabel *tagLabel;
@property (strong, nonatomic) UIImageView *checkView;
@end

@implementation ModelCell

+ (CGFloat)rowHeight { return kRowHeight; }

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        self.badge = [[UIView alloc] init];
        self.badge.layer.cornerRadius = 20;
        self.logoView = [[UIImageView alloc] init];
        self.logoView.contentMode = UIViewContentModeScaleAspectFit;
        [self.badge addSubview:self.logoView];
        self.chipView = [[UIImageView alloc] init];

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        self.idLabel = [[UILabel alloc] init];
        self.idLabel.font = [UIFont systemFontOfSize:12];
        self.idLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

        self.tagLabel = [[UILabel alloc] init];
        self.tagLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        self.tagLabel.textAlignment = NSTextAlignmentCenter;
        self.tagLabel.layer.cornerRadius = 8;
        self.tagLabel.clipsToBounds = YES;

        self.checkView = [[UIImageView alloc] init];
        for (UIView *view in @[self.badge, self.chipView, self.titleLabel, self.idLabel, self.tagLabel, self.checkView]) {
            [self.contentView addSubview:view];
        }
    }
    return self;
}

- (UIImage *)checkImage {
    CGFloat side = 24;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[Theme accent] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(1, 1, side - 2, side - 2)] fill];
        UIBezierPath *tick = [UIBezierPath bezierPath];
        [tick moveToPoint:CGPointMake(7, 12.5)];
        [tick addLineToPoint:CGPointMake(10.5, 16)];
        [tick addLineToPoint:CGPointMake(17, 8.5)];
        tick.lineWidth = 2.2;
        tick.lineCapStyle = kCGLineCapRound;
        tick.lineJoinStyle = kCGLineJoinRound;
        [[UIColor whiteColor] setStroke];
        [tick stroke];
    }];
}

- (void)configureWithModel:(NSDictionary *)model selected:(BOOL)selected {
    NSString *modelId = model[@"id"] ?: @"";
    BOOL claude = [Provider forModelId:modelId] == AIProviderClaude;
    self.backgroundColor = [Theme surface];
    self.selectionStyle = UITableViewCellSelectionStyleDefault;
    UIView *highlight = [[UIView alloc] init];
    highlight.backgroundColor = [Material active] ? [UIColor clearColor] : [Theme selection];
    self.selectedBackgroundView = highlight;

    // The provider's own logo on a soft round badge; a chosen model gets an accent ring.
    self.badge.backgroundColor = selected ? [[Theme accent] colorWithAlphaComponent:0.16] : [Theme selection];
    self.badge.layer.borderWidth = selected ? 2 : 0;
    self.badge.layer.borderColor = [Theme accent].CGColor;
    self.logoView.image = claude ? ClaudeLogoImage() : GeminiLogoImage();

    ModelCapability capability = CapabilityForModelId(modelId);
    self.chipView.hidden = capability == ModelCapabilityNone;
    self.chipView.image = capability == ModelCapabilityNone ? nil : CapabilityChipImage(capability);

    self.titleLabel.text = [ModelStore friendlyNameForModel:model];
    self.titleLabel.textColor = [Theme text];
    self.idLabel.text = modelId;
    self.idLabel.textColor = [Theme secondaryText];

    NSString *tag = [ModelStore tagForModelId:modelId];
    self.tagLabel.hidden = tag.length == 0;
    self.tagLabel.text = tag;
    self.tagLabel.textColor = [Theme accent];
    self.tagLabel.backgroundColor = [[Theme accent] colorWithAlphaComponent:0.14];

    self.checkView.image = selected ? [self checkImage] : nil;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat height = self.contentView.bounds.size.height;
    self.badge.frame = CGRectMake(16, (height - 40) / 2, 40, 40);
    CGFloat logoSide = 22;
    self.logoView.frame = CGRectMake((40 - logoSide) / 2, (40 - logoSide) / 2, logoSide, logoSide);
    // Small chip on the top-right corner of the logo badge.
    self.chipView.frame = CGRectMake(CGRectGetMaxX(self.badge.frame) - 12, CGRectGetMinY(self.badge.frame) - 3, 18, 18);

    CGFloat left = 68;
    CGFloat right = width - 16 - 24 - 8;   // room for the check mark
    self.checkView.frame = CGRectMake(width - 16 - 24, (height - 24) / 2, 24, 24);
    self.titleLabel.frame = CGRectMake(left, 12, MAX(0, right - left), 21);

    CGFloat x = left;
    if (!self.tagLabel.hidden) {
        CGSize tagSize = [self.tagLabel sizeThatFits:CGSizeMake(200, 18)];
        CGFloat tagWidth = ceil(tagSize.width) + 14;
        self.tagLabel.frame = CGRectMake(x, 38, tagWidth, 17);
        x += tagWidth + 6;
    }
    self.idLabel.frame = CGRectMake(x, 38, MAX(0, right - x), 17);
}

@end
