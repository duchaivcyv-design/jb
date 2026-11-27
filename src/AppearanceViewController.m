#import "AppearanceViewController.h"
#import "AppSettings.h"
#import "Strings.h"
#import "ChoicePopupViewController.h"
#import "Theme.h"
#import "DiagnosticLog.h"
#import "Material.h"
#import "AccentColorViewController.h"

typedef NS_ENUM(NSInteger, AppearanceSection) {
    AppearanceSectionMode = 0,    // light / dark pictures + "Tự động"      (root page)
    AppearanceSectionMenu,        // App icon / Chat theme / Accent colour  (root page)
    AppearanceSectionSkin,        // accent colours                         (accent page)
    AppearanceSectionWallpaper,   // chat wallpapers                        (chat theme page)
    AppearanceSectionIconStyle,   // light / dark icon pictures             (icon page)
    AppearanceSectionIcon,        // the icons                              (icon page)
    AppearanceSectionLayout,      // automatic / phone / iPhone Duo         (Duo page)
    AppearanceSectionSidebar      // width of the left pane                 (Duo page)
};

// Wallpaper rows: 0 = follow the skin, 1 = none, 2...7 = wallpaper 1...6.
static const NSInteger kWallpaperRowCount = 2 + (ThemeSkinCount - 1) + 1;   // + the moving gradient (choice = ThemeSkinCount)

#pragma mark - Light / dark picker cell (like iOS Settings > Display)

static UIImage *RadioImage(BOOL selected) {
    CGFloat side = 24;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        CGRect rect = CGRectMake(1.5, 1.5, side - 3, side - 3);
        if (selected) {
            [[Theme accent] setFill];
            [[UIBezierPath bezierPathWithOvalInRect:rect] fill];
            UIBezierPath *tick = [UIBezierPath bezierPath];
            [tick moveToPoint:CGPointMake(7, 12.5)];
            [tick addLineToPoint:CGPointMake(10.5, 16)];
            [tick addLineToPoint:CGPointMake(17, 8.5)];
            tick.lineWidth = 2.2;
            tick.lineCapStyle = kCGLineCapRound;
            tick.lineJoinStyle = kCGLineJoinRound;
            [[UIColor whiteColor] setStroke];
            [tick stroke];
        } else {
            UIBezierPath *ring = [UIBezierPath bezierPathWithOvalInRect:rect];
            ring.lineWidth = 1.5;
            [[Theme secondaryText] setStroke];
            [ring stroke];
        }
    }];
}

@interface AppearanceModeCell : UITableViewCell
@property (strong, nonatomic) UIButton *lightButton;
@property (strong, nonatomic) UIButton *darkButton;
@property (strong, nonatomic) UILabel *lightLabel;
@property (strong, nonatomic) UILabel *darkLabel;
@property (strong, nonatomic) UIImageView *lightRadio;
@property (strong, nonatomic) UIImageView *darkRadio;
// Transparent buttons covering the whole column (picture + label + tick), so any of them can be tapped.
@property (strong, nonatomic) UIButton *lightHit;
@property (strong, nonatomic) UIButton *darkHit;
@end

static const CGSize kModePreviewSize = { 84, 148 };

@implementation AppearanceModeCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.darkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.lightLabel = [[UILabel alloc] init];
        self.darkLabel = [[UILabel alloc] init];
        self.lightRadio = [[UIImageView alloc] init];
        self.darkRadio = [[UIImageView alloc] init];
        for (UILabel *label in @[self.lightLabel, self.darkLabel]) {
            label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
            label.textAlignment = NSTextAlignmentCenter;
            [self.contentView addSubview:label];
        }
        for (UIButton *button in @[self.lightButton, self.darkButton]) {
            button.adjustsImageWhenHighlighted = NO;
            [self.contentView addSubview:button];
        }
        [self.contentView addSubview:self.lightRadio];
        [self.contentView addSubview:self.darkRadio];
        self.lightHit = [UIButton buttonWithType:UIButtonTypeCustom];
        self.darkHit = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.contentView addSubview:self.lightHit];
        [self.contentView addSubview:self.darkHit];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = self.contentView.bounds.size.width;
    CGFloat centers[2] = { width * 0.25, width * 0.75 };
    UIButton *buttons[2] = { self.lightButton, self.darkButton };
    UILabel *labels[2] = { self.lightLabel, self.darkLabel };
    UIImageView *radios[2] = { self.lightRadio, self.darkRadio };
    for (int i = 0; i < 2; i++) {
        buttons[i].frame = CGRectMake(centers[i] - kModePreviewSize.width / 2, 16, kModePreviewSize.width, kModePreviewSize.height);
        labels[i].frame = CGRectMake(centers[i] - 60, 16 + kModePreviewSize.height + 8, 120, 20);
        radios[i].frame = CGRectMake(centers[i] - 12, 16 + kModePreviewSize.height + 36, 24, 24);
    }
    CGFloat colWidth = width / 2;
    CGFloat colHeight = self.contentView.bounds.size.height;
    self.lightHit.frame = CGRectMake(0, 0, colWidth, colHeight);
    self.darkHit.frame = CGRectMake(colWidth, 0, colWidth, colHeight);
    [self.contentView bringSubviewToFront:self.lightHit];
    [self.contentView bringSubviewToFront:self.darkHit];
}

@end

@interface AppearanceViewController ()
@property (strong, nonatomic) UITableView *tableView;
@property (assign, nonatomic) BOOL changingIcon;
@property (assign, nonatomic) BOOL hasAppearedOnce;
@property (assign, nonatomic) AppearancePage page;
@end

@implementation AppearanceViewController

- (instancetype)initWithPage:(AppearancePage)page {
    self = [super init];
    if (self) _page = page;
    return self;
}

- (instancetype)init {
    return [self initWithPage:AppearancePageRoot];
}

// The sections shown on this page, in order.
- (NSArray<NSNumber *> *)sections {
    switch (self.page) {
        case AppearancePageIcon:      return @[@(AppearanceSectionIconStyle), @(AppearanceSectionIcon)];
        case AppearancePageChatTheme: return @[@(AppearanceSectionSkin), @(AppearanceSectionWallpaper)];
        case AppearancePageAccent:    return @[@(AppearanceSectionSkin)];
        case AppearancePageDuo:       return @[@(AppearanceSectionLayout), @(AppearanceSectionSidebar)];
        default:                      return @[@(AppearanceSectionMode), @(AppearanceSectionMenu)];
    }
}

- (AppearanceSection)sectionAtIndex:(NSInteger)index {
    return (AppearanceSection)[[self sections][index] integerValue];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    switch (self.page) {
        case AppearancePageIcon:      self.title = L(@"appearance_menu_icon"); break;
        case AppearancePageChatTheme: self.title = L(@"appearance_menu_chat"); break;
        case AppearancePageAccent:    self.title = L(@"appearance_menu_accent"); break;
        case AppearancePageDuo:       self.title = L(@"appearance_menu_duo"); break;
        default:                      self.title = L(@"appearance_title"); break;
    }
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
    self.tableView.cellLayoutMarginsFollowReadableWidth = YES;   // wide screens: rows stay a comfortable width
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applyTheme) name:kNotifThemeChanged object:nil];
    [self applyTheme];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applyTheme {
    self.view.backgroundColor = [Theme background];
    self.tableView.backgroundColor = [Theme background];
    self.tableView.separatorColor = [Theme border];
    [self applyMaterialStyle];
    [self.tableView reloadData];
}

- (void)applyMaterialStyle {
    BOOL material = [Material active];
    self.tableView.separatorStyle = material ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine;
    if (material) [Material decorateTable:self.tableView];
    [Material layoutTable:self.tableView inBounds:self.view.bounds];
    [Material styleTitleForController:self];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [Material layoutTable:self.tableView inBounds:self.view.bounds];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyMaterialStyle];
    if (self.hasAppearedOnce) [self.tableView reloadData];   // the icon may have been changed from outside (e.g. the system reverted it)
    self.hasAppearedOnce = YES;
}

#pragma mark - Helpers

- (BOOL)iconsSupported {
    if ([Theme iconHelperAvailable]) return YES;   // rootful .deb: the root helper does the work
    if (@available(iOS 10.3, *)) return [UIApplication sharedApplication].supportsAlternateIcons;
    return NO;
}

// Which skin's icon is on the Home Screen now (ThemeSkinClaude = the default icon).
- (ThemeSkin)currentIconSkin {
    return [Theme activeIconSkin];
}

// Rendering these images is the slow part of rebuilding the list, and they never change: draw each one once.
static NSCache *ImageCache(void) {
    static NSCache *cache;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ cache = [[NSCache alloc] init]; });
    return cache;
}

- (UIImage *)cachedIconForSkin:(ThemeSkin)skin dark:(BOOL)dark side:(CGFloat)side {
    NSString *key = [NSString stringWithFormat:@"icon%ld-%d-%d", (long)skin, dark ? 1 : 0, (int)side];
    UIImage *image = [ImageCache() objectForKey:key];
    if (!image) {
        image = [self roundedIcon:[Theme iconPreviewForSkin:skin dark:dark] side:side];
        if (image) [ImageCache() setObject:image forKey:key];
    }
    return image;
}

- (UIImage *)cachedSwatchForSkin:(ThemeSkin)skin {
    NSString *key = [NSString stringWithFormat:@"swatch%ld", (long)skin];
    UIImage *image = [ImageCache() objectForKey:key];
    if (!image) {
        image = [self swatchImageWithColor:[Theme swatchColorForSkin:skin]];
        if (image) [ImageCache() setObject:image forKey:key];
    }
    return image;
}

- (UIImage *)cachedWallpaperThumb:(NSInteger)index {
    NSString *key = [NSString stringWithFormat:@"wp%ld", (long)index];
    UIImage *image = [ImageCache() objectForKey:key];
    if (!image) {
        image = [self roundedThumbnail:[Theme wallpaperThumbnail:index] size:CGSizeMake(28, 50)];
        if (image) [ImageCache() setObject:image forKey:key];
    }
    return image;
}

- (UIImage *)roundedIcon:(UIImage *)image side:(CGFloat)side {
    if (!image) return nil;
    CGRect rect = CGRectMake(0, 0, side, side);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:rect.size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:side * 0.225] addClip];
        [image drawInRect:rect];
    }];
}

- (UIImage *)gradientThumb {
    NSArray<UIColor *> *colors = [Theme gradientWallpaperColors];
    const CGSize size = CGSizeMake(34, 44);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    UIImage *image = [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:7] addClip];
        NSMutableArray *cg = [NSMutableArray array];
        for (UIColor *c in colors) [cg addObject:(id)c.CGColor];
        CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColors(space, (__bridge CFArrayRef)cg, NULL);
        CGColorSpaceRelease(space);
        if (gradient) {
            CGContextDrawLinearGradient(ctx.CGContext, gradient, CGPointMake(0, 0), CGPointMake(size.width, size.height), 0);
            CGGradientRelease(gradient);
        }
    }];
    return image;
}

- (UIImage *)swatchImageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 28, 28);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:rect.size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [color setFill];
        [[UIBezierPath bezierPathWithOvalInRect:rect] fill];
    }];
}

- (UIImage *)roundedThumbnail:(UIImage *)image size:(CGSize)size {
    if (!image) return nil;
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
        [[UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:6] addClip];
        // aspect-fill
        CGFloat scale = MAX(size.width / image.size.width, size.height / image.size.height);
        CGSize drawn = CGSizeMake(image.size.width * scale, image.size.height * scale);
        [image drawInRect:CGRectMake((size.width - drawn.width) / 2, (size.height - drawn.height) / 2, drawn.width, drawn.height)];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[self sections].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch ([self sectionAtIndex:section]) {
        case AppearanceSectionSkin:      return ThemeSkinCount;
        case AppearanceSectionMode:      return 2;   // picture row + "Tự động"
        case AppearanceSectionMenu:      return 5;   // icon, chat theme, accent, iPhone Duo, design
        case AppearanceSectionLayout:    return 3;
        case AppearanceSectionSidebar:   return 3;
        case AppearanceSectionWallpaper: return kWallpaperRowCount;
        case AppearanceSectionIconStyle: return 2;   // light / dark
        default:                         return ThemeSkinCount;   // icons: default + one per skin
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch ([self sectionAtIndex:section]) {
        case AppearanceSectionMode:      return L(@"appearance_mode_header");
        case AppearanceSectionSkin:      return L(@"appearance_skin_header");
        case AppearanceSectionWallpaper: return L(@"appearance_wallpaper_header");
        case AppearanceSectionIconStyle: return L(@"appearance_icon_style_header");
        case AppearanceSectionIcon:      return L(@"appearance_icon_header");
        case AppearanceSectionLayout:    return L(@"duo_layout_header");
        case AppearanceSectionSidebar:   return L(@"duo_sidebar_header");
        default:                         return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    switch ([self sectionAtIndex:section]) {
        case AppearanceSectionLayout:    return L(@"duo_layout_footer");
        case AppearanceSectionSidebar:   return L(@"duo_sidebar_footer");
        case AppearanceSectionSkin:      return L(@"appearance_skin_footer");
        case AppearanceSectionMode:      return L(@"appearance_auto_footer");
        case AppearanceSectionIcon:
            if ([Theme iconHelperAvailable]) return L(@"appearance_icon_footer_helper");
            return [self iconsSupported] ? L(@"appearance_icon_footer") : L(@"appearance_icon_unsupported");
        default:                         return nil;
    }
}

// Short name of what is chosen now, shown on the right of the three entries on the first page.
- (NSString *)wallpaperSummary {
    NSInteger choice = [Theme wallpaperChoice];
    if (choice == -1) return L(@"wallpaper_follow");
    if (choice == 0) return L(@"wallpaper_none");
    if (choice == [Theme gradientWallpaperChoice]) return L(@"wallpaper_gradient");
    return [Theme wallpaperName:choice];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.backgroundColor = [Theme surface];
    cell.textLabel.font = [UIFont systemFontOfSize:17];
    cell.textLabel.textColor = [Theme text];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.detailTextLabel.textColor = [Theme secondaryText];
    cell.tintColor = [Theme accent];
    UIView *selected = [[UIView alloc] init];
    selected.backgroundColor = [Material active] ? [Theme surface] : [Theme selection];
    cell.selectedBackgroundView = selected;

    switch ([self sectionAtIndex:indexPath.section]) {
        case AppearanceSectionMenu: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (indexPath.row == 0) {
                cell.imageView.image = [self cachedIconForSkin:[self currentIconSkin] dark:[Theme activeIconDark] side:34];
                cell.textLabel.text = L(@"appearance_menu_icon");
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ · %@", [Theme iconDisplayNameForSkin:[self currentIconSkin]], L([Theme activeIconDark] ? @"mode_dark" : @"mode_light")];
            } else if (indexPath.row == 1) {
                NSInteger index = [Theme effectiveWallpaperIndex];
                cell.imageView.image = index > 0 ? [self cachedWallpaperThumb:index] : [self cachedSwatchForSkin:[Theme skin]];
                cell.textLabel.text = L(@"appearance_menu_chat");
                cell.detailTextLabel.text = [self wallpaperSummary];
            } else if (indexPath.row == 2) {
                cell.imageView.image = [Theme customAccentActive] ? [self swatchImageWithColor:[Theme accent]] : [self cachedSwatchForSkin:[Theme skin]];
                cell.textLabel.text = L(@"appearance_menu_accent");
                CGFloat ah = 0, as = 0, ab = 0;
                [Theme getCustomHue:&ah saturation:&as brightness:&ab];
                cell.detailTextLabel.text = [Theme customAccentActive] ? [Theme hexStringForHue:ah saturation:as brightness:ab] : L(@"accent_default");
            } else if (indexPath.row == 4) {
                cell.imageView.image = [self swatchImageWithColor:[Theme accent]];
                cell.textLabel.text = L(@"appearance_menu_design");
                cell.detailTextLabel.text = L([Theme materialDesign] ? @"design_material" : @"design_classic");
            } else {
                cell.imageView.image = [self duoGlyphImage];
                cell.textLabel.text = L(@"appearance_menu_duo");
                cell.detailTextLabel.text = [self layoutModeName:[AppSettings layoutMode]];
            }
            break;
        }
        case AppearanceSectionLayout: {
            NSInteger mode = indexPath.row;
            cell.imageView.image = [self layoutGlyphForMode:mode];
            cell.textLabel.text = [self layoutModeName:mode];
            cell.detailTextLabel.text = L(mode == 0 ? @"duo_mode_auto_note" : (mode == 1 ? @"duo_mode_phone_note" : @"duo_mode_duo_note"));
            cell.accessoryType = ([AppSettings layoutMode] == mode) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
        case AppearanceSectionSidebar: {
            NSInteger size = indexPath.row;
            cell.imageView.image = [self sidebarGlyphForSize:size];
            cell.textLabel.text = L(size == 0 ? @"duo_sidebar_narrow" : (size == 1 ? @"duo_sidebar_medium" : @"duo_sidebar_wide"));
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d pt", (int)(size == 0 ? 260 : (size == 1 ? 320 : 380))];
            cell.accessoryType = ([AppSettings duoSidebarSize] == size) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
        case AppearanceSectionIconStyle: {
            BOOL dark = indexPath.row == 1;
            cell.imageView.image = [self cachedIconForSkin:[self currentIconSkin] dark:dark side:44];
            cell.textLabel.text = L(dark ? @"icon_style_dark" : @"icon_style_light");
            cell.detailTextLabel.text = L(dark ? @"icon_style_dark_note" : @"icon_style_light_note");
            cell.accessoryType = ([Theme iconStyleDark] == dark) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
        case AppearanceSectionSkin: {
            ThemeSkin skin = (ThemeSkin)indexPath.row;
            cell.imageView.image = [self cachedSwatchForSkin:skin];
            cell.textLabel.text = [Theme skinName:skin];
            cell.detailTextLabel.text = L([Theme skinColorKey:skin]);
            cell.accessoryType = (skin == [Theme skin] && ![Theme customAccentActive]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
        case AppearanceSectionMode: {
            if (indexPath.row == 0) {
                AppearanceModeCell *modeCell = [[AppearanceModeCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                modeCell.backgroundColor = [Theme surface];
                BOOL dark = [Theme darkMode];
                [modeCell.lightButton setImage:[Theme modePreviewImageDark:NO size:kModePreviewSize] forState:UIControlStateNormal];
                [modeCell.darkButton setImage:[Theme modePreviewImageDark:YES size:kModePreviewSize] forState:UIControlStateNormal];
                [modeCell.lightHit addTarget:self action:@selector(lightTapped) forControlEvents:UIControlEventTouchUpInside];
                [modeCell.darkHit addTarget:self action:@selector(darkTapped) forControlEvents:UIControlEventTouchUpInside];
                modeCell.lightLabel.text = L(@"mode_light");
                modeCell.darkLabel.text = L(@"mode_dark");
                modeCell.lightLabel.textColor = [Theme text];
                modeCell.darkLabel.textColor = [Theme text];
                modeCell.lightRadio.image = RadioImage(!dark);
                modeCell.darkRadio.image = RadioImage(dark);
                return modeCell;
            }
            cell.textLabel.text = L(@"mode_auto");
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            if ([Material active]) {
                MaterialSwitch *toggle = [[MaterialSwitch alloc] init];
                toggle.on = [Theme autoMode];
                [toggle addTarget:self action:@selector(autoToggled:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = toggle;
            } else {
                UISwitch *toggle = [[UISwitch alloc] init];
                toggle.on = [Theme autoMode];
                toggle.onTintColor = [Theme accent];
                [toggle addTarget:self action:@selector(autoToggled:) forControlEvents:UIControlEventValueChanged];
                cell.accessoryView = toggle;
            }
            break;
        }
        case AppearanceSectionWallpaper: {
            NSInteger choice = [Theme wallpaperChoice];
            BOOL isSelected = NO;
            if (indexPath.row == 0) {
                cell.textLabel.text = L(@"wallpaper_follow");
                cell.detailTextLabel.text = L(@"wallpaper_follow_note");
                isSelected = (choice == -1);
            } else if (indexPath.row == 1) {
                cell.textLabel.text = L(@"wallpaper_none");
                cell.detailTextLabel.text = L(@"wallpaper_none_note");
                isSelected = (choice == 0);
            } else if (indexPath.row - 1 == [Theme gradientWallpaperChoice]) {
                cell.textLabel.text = L(@"wallpaper_gradient");
                cell.detailTextLabel.text = L(@"wallpaper_gradient_note");
                cell.imageView.image = [self gradientThumb];
                isSelected = (choice == [Theme gradientWallpaperChoice]);
            } else {
                NSInteger index = indexPath.row - 1;   // rows 2...7 -> wallpapers 1...6
                cell.textLabel.text = [Theme wallpaperName:index];
                cell.detailTextLabel.text = L(@"wallpaper_item_note");
                cell.imageView.image = [self cachedWallpaperThumb:index];
                isSelected = (choice == index);
            }
            cell.accessoryType = isSelected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
        default: {
            ThemeSkin skin = (ThemeSkin)indexPath.row;
            BOOL styleDark = [Theme iconStyleDark];
            cell.imageView.image = [self cachedIconForSkin:skin dark:styleDark side:44];
            cell.textLabel.text = [Theme iconDisplayNameForSkin:skin];   // "SideStore", "LiveContainer"... without the word "Skin"
            cell.detailTextLabel.text = nil;
            BOOL current = (skin == [self currentIconSkin]) && ([Theme activeIconDark] == styleDark);
            cell.accessoryType = current ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        }
    }
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [Material decorateCell:cell atIndexPath:indexPath inTable:tableView];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *title = [self tableView:tableView titleForHeaderInSection:section];
    if (![Material active] || title.length == 0) return nil;
    return [Material headerViewWithTitle:title collapsed:NO collapsible:NO tap:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (![Material active]) return UITableViewAutomaticDimension;
    return [self tableView:tableView titleForHeaderInSection:section].length > 0 ? [Material headerHeight] : 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (![Material active]) return UITableViewAutomaticDimension;
    return [self tableView:tableView titleForFooterInSection:section].length > 0 ? UITableViewAutomaticDimension : 6;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UILabel *label = ((UITableViewHeaderFooterView *)view).textLabel;
        label.textColor = [Theme secondaryText];
        label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];   // UIKit makes this label itself, so the app font is set here
    }
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        UILabel *label = ((UITableViewHeaderFooterView *)view).textLabel;
        label.textColor = [Theme secondaryText];
        label.font = [UIFont systemFontOfSize:13];   // UIKit makes this label itself, so the app font is set here
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    AppearanceSection section = [self sectionAtIndex:indexPath.section];
    if (section == AppearanceSectionMode && indexPath.row == 0) return 16 + kModePreviewSize.height + 36 + 24 + 14;
    if (section == AppearanceSectionIcon || section == AppearanceSectionIconStyle) return 62;
    if (section == AppearanceSectionLayout || section == AppearanceSectionSidebar) return 62;
    if (section == AppearanceSectionWallpaper && indexPath.row >= 1) return 64;
    if (section == AppearanceSectionMenu) return 56;
    return 56;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch ([self sectionAtIndex:indexPath.section]) {
        case AppearanceSectionMenu: {
            if (indexPath.row == 2) {
                [self.navigationController pushViewController:[[AccentColorViewController alloc] init] animated:YES];
                break;
            }
            if (indexPath.row == 4) {
                [self chooseDesign];
                break;
            }
            AppearancePage next = indexPath.row == 0 ? AppearancePageIcon : (indexPath.row == 1 ? AppearancePageChatTheme : AppearancePageDuo);
            [self.navigationController pushViewController:[[AppearanceViewController alloc] initWithPage:next] animated:YES];
            break;
        }
        case AppearanceSectionIconStyle:
            [self chooseIconStyleDark:indexPath.row == 1];
            break;
        case AppearanceSectionLayout:
            [AppSettings setLayoutMode:indexPath.row];   // posts kNotifLayoutChanged: the chat and the allowed orientations follow
            [self.tableView reloadData];
            break;
        case AppearanceSectionSidebar:
            [AppSettings setDuoSidebarSize:indexPath.row];
            [self.tableView reloadData];
            break;
        case AppearanceSectionSkin:
            [self chooseSkin:(ThemeSkin)indexPath.row];
            break;
        case AppearanceSectionWallpaper: {
            NSInteger choice;
            if (indexPath.row == 0) choice = -1;
            else if (indexPath.row == 1) choice = 0;
            else choice = indexPath.row - 1;
            [Theme setWallpaperChoice:choice];
            [Theme postChange];
            break;
        }
        case AppearanceSectionIcon:
            [self changeIconToSkin:(ThemeSkin)indexPath.row dark:[Theme iconStyleDark]];
            break;
        default:
            break;
    }
}

#pragma mark - Actions

// Picking light or dark by hand turns "Tự động" off (like iOS).
- (void)lightTapped { [self chooseDark:NO]; }
- (void)darkTapped  { [self chooseDark:YES]; }

- (void)chooseDark:(BOOL)dark {
    if (![Theme autoMode] && [Theme darkMode] == dark) return;
    [Theme setAutoMode:NO];
    [Theme setDarkMode:dark];
    [Theme postChange];
}

- (void)autoToggled:(UIControl *)control {
    BOOL isOn = [(id)control isOn];   // UISwitch or MaterialSwitch
    if (!isOn) {
        [Theme setDarkMode:[Theme darkMode]];   // keep what is shown now as the manual choice
    }
    [Theme setAutoMode:isOn];
    [Theme postChange];
}

- (void)chooseDesign {
    if (self.presentedViewController) return;
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:L(@"appearance_menu_design") message:L(@"design_message")];
    __weak typeof(self) weakSelf = self;
    BOOL material = [Theme materialDesign];
    [alert addAction:[ChoiceAction actionWithTitle:[L(@"design_classic") stringByAppendingString:material ? @"" : @"  \u2713"] style:UIAlertActionStyleDefault handler:^(id a) { [weakSelf setDesign:NO]; }]];
    [alert addAction:[ChoiceAction actionWithTitle:[L(@"design_material") stringByAppendingString:material ? @"  \u2713" : @""] style:UIAlertActionStyleDefault handler:^(id a) { [weakSelf setDesign:YES]; }]];
    [alert addAction:[ChoiceAction actionWithTitle:L(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert presentFromViewController:self];
}

- (void)setDesign:(BOOL)material {
    if ([Theme materialDesign] == material) return;
    [Theme setMaterialDesign:material];
    [Material markTableForEntrance:self.tableView];   // the rows spring in after the switch
    [Theme postChange];
}

- (void)chooseSkin:(ThemeSkin)skin {
    if (skin == [Theme skin] && ![Theme customAccentActive]) return;
    [Theme resetCustomAccent];   // a skin brings its own accent: the picked colour is dropped
    [Theme setSkin:skin];
    [Theme postChange];

    // Each skin has its own icon: offer to switch the Home Screen icon too (iOS shows its own confirmation).
    BOOL iconDark = [Theme iconStyleDark];
    if (skin != ThemeSkinClaude && [self iconsSupported] && ([self currentIconSkin] != skin || [Theme activeIconDark] != iconDark)) {
        ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:L(@"icon_offer_title") message:[NSString stringWithFormat:L(@"icon_offer_msg"), [Theme iconDisplayNameForSkin:skin]]];
        [alert addAction:[ChoiceAction actionWithTitle:L(@"icon_offer_no") style:UIAlertActionStyleCancel handler:nil]];
        __weak typeof(self) weakSelf = self;
        [alert addAction:[ChoiceAction actionWithTitle:L(@"icon_offer_yes") style:UIAlertActionStyleDefault handler:^(id a) {
            [weakSelf changeIconToSkin:skin dark:iconDark];
        }]];
        [alert presentFromViewController:self];
    }
}

#pragma mark - iPhone Duo glyphs (drawn in code)

- (NSString *)layoutModeName:(NSInteger)mode {
    return L(mode == 0 ? @"duo_mode_auto" : (mode == 1 ? @"duo_mode_phone" : @"duo_mode_duo"));
}

// A small picture of the screen: a phone upright (one pane), a wide screen with a list on the left (two panes) or both.
- (UIImage *)drawnScreenWithPanes:(NSInteger)panes landscape:(BOOL)landscape {
    NSString *key = [NSString stringWithFormat:@"screen%ld-%d-%d-%ld", (long)panes, landscape ? 1 : 0, [Theme darkMode] ? 1 : 0, (long)[Theme skin]];
    UIImage *cached = [ImageCache() objectForKey:key];
    if (cached) return cached;
    CGSize size = CGSizeMake(44, 44);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    UIColor *accent = [Theme accent];
    UIColor *line = [Theme secondaryText];
    [[accent colorWithAlphaComponent:0.14] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 44, 44) cornerRadius:10] fill];
    CGRect body = landscape ? CGRectMake(7, 12, 30, 20) : CGRectMake(13, 7, 18, 30);
    UIBezierPath *outline = [UIBezierPath bezierPathWithRoundedRect:body cornerRadius:4];
    outline.lineWidth = 1.6;
    [line setStroke];
    [outline stroke];
    if (panes == 2 && landscape) {
        CGFloat x = body.origin.x + 11;
        UIBezierPath *divider = [UIBezierPath bezierPath];
        [divider moveToPoint:CGPointMake(x, body.origin.y + 1)];
        [divider addLineToPoint:CGPointMake(x, CGRectGetMaxY(body) - 1)];
        divider.lineWidth = 1.4;
        [line setStroke];
        [divider stroke];
        [accent setFill];
        for (int i = 0; i < 3; i++) {
            [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(body.origin.x + 3, body.origin.y + 4 + i * 4.5, 5, 2) cornerRadius:1] fill];
        }
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(x + 4, body.origin.y + 4, 11, 3) cornerRadius:1.5] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(x + 4, CGRectGetMaxY(body) - 6, 15, 3) cornerRadius:1.5] fill];
    } else {
        [accent setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(body.origin.x + 3, body.origin.y + 5, MIN(10, body.size.width - 6), 3) cornerRadius:1.5] fill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(body.origin.x + 3, CGRectGetMaxY(body) - 8, body.size.width - 6, 4) cornerRadius:2] fill];
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image) [ImageCache() setObject:image forKey:key];
    return image;
}

- (UIImage *)layoutGlyphForMode:(NSInteger)mode {
    if (mode == 1) return [self drawnScreenWithPanes:1 landscape:NO];
    return [self drawnScreenWithPanes:2 landscape:YES];   // automatic and iPhone Duo are both about the two-pane screen
}

- (UIImage *)duoGlyphImage {
    return [self drawnScreenWithPanes:([AppSettings layoutMode] == 1 ? 1 : 2) landscape:[AppSettings layoutMode] != 1];
}

// Width of the left pane drawn as a bar: the three sizes differ in how much of the screen the pane takes.
- (UIImage *)sidebarGlyphForSize:(NSInteger)size {
    NSString *key = [NSString stringWithFormat:@"sidebar%ld-%d-%ld", (long)size, [Theme darkMode] ? 1 : 0, (long)[Theme skin]];
    UIImage *cached = [ImageCache() objectForKey:key];
    if (cached) return cached;
    CGSize canvas = CGSizeMake(44, 44);
    UIGraphicsBeginImageContextWithOptions(canvas, NO, 0);
    [[[Theme accent] colorWithAlphaComponent:0.14] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 44, 44) cornerRadius:10] fill];
    CGRect body = CGRectMake(6, 12, 32, 20);
    UIBezierPath *outline = [UIBezierPath bezierPathWithRoundedRect:body cornerRadius:4];
    outline.lineWidth = 1.6;
    [[Theme secondaryText] setStroke];
    [outline stroke];
    CGFloat paneWidth = size == 0 ? 7 : (size == 1 ? 10 : 13);
    [[[Theme accent] colorWithAlphaComponent:0.85] setFill];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(body.origin.x + 2, body.origin.y + 2, paneWidth, body.size.height - 4) cornerRadius:2] fill];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    if (image) [ImageCache() setObject:image forKey:key];
    return image;
}

// Light or dark pictures: remembered, and the icon that is on the Home Screen switches to the same style.
- (void)chooseIconStyleDark:(BOOL)dark {
    if ([Theme iconStyleDark] == dark && [Theme activeIconDark] == dark) return;
    [Theme setIconStyleDark:dark];
    [self.tableView reloadData];
    if ([self iconsSupported] && !self.changingIcon) [self changeIconToSkin:[self currentIconSkin] dark:dark];
}

- (void)changeIconToSkin:(ThemeSkin)skin dark:(BOOL)dark {
    if (self.changingIcon) return;
    if (![self iconsSupported]) {
        [self showMessage:L(@"appearance_icon_unsupported")];
        return;
    }
    if (skin == [self currentIconSkin] && dark == [Theme activeIconDark]) return;

    if ([Theme iconHelperAvailable]) {
        self.changingIcon = YES;
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            NSString *failure = nil;
            BOOL ok = [Theme applyIconWithHelperForSkin:skin dark:dark message:&failure];
            dispatch_async(dispatch_get_main_queue(), ^{
                AppearanceViewController *me = weakSelf;
                if (!me) return;
                me.changingIcon = NO;
                [me.tableView reloadData];
                if (ok) {
                    [DiagnosticLog log:@"icon changed through the root helper"];
                    [Theme postChange];   // the picture on the empty chat follows the icon
                    [me offerRespring];
                } else {
                    [DiagnosticLog log:@"icon helper: %@", failure ?: @"-"];
                    [me showMessage:[NSString stringWithFormat:L(@"icon_error"), failure ?: @"-"]];
                }
            });
        });
        return;
    }
    if (@available(iOS 10.3, *)) {
        self.changingIcon = YES;
        NSString *name = [Theme iconNameForSkin:skin dark:dark];   // nil = back to the default (light) icon
        __weak typeof(self) weakSelf = self;
        [[UIApplication sharedApplication] setAlternateIconName:name completionHandler:^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                AppearanceViewController *me = weakSelf;
                if (!me) return;
                me.changingIcon = NO;
                if (error) {
                    [DiagnosticLog log:@"icon change failed: %@ (%ld)", error.localizedDescription, (long)error.code];
                    [me showMessage:[NSString stringWithFormat:L(@"icon_error"), error.localizedDescription ?: @"-"]];
                } else {
                    [Theme postChange];   // the picture on the empty chat follows the icon
                }
                [me.tableView reloadData];
            });
        }];
    }
}

// The new Home Screen icon often appears only after SpringBoard restarts: offer to do it right away.
- (void)offerRespring {
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:nil message:L(@"icon_helper_done")];
    [alert addAction:[ChoiceAction actionWithTitle:L(@"icon_later") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[ChoiceAction actionWithTitle:L(@"icon_respring") style:UIAlertActionStyleDefault handler:^(id a) {
        [DiagnosticLog log:@"respring requested after an icon change"];
        [Theme respringWithHelper];
    }]];
    [alert presentFromViewController:self];
}

- (void)showMessage:(NSString *)message {
    ChoicePopupViewController *alert = [ChoicePopupViewController alertWithTitle:nil message:message];
    [alert addAction:[ChoiceAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [alert presentFromViewController:self];
}

@end
