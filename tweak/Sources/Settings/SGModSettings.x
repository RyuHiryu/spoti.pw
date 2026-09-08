// Settings: a Mod Settings row at the end of Spotify's settings list opens the mod's own pages:
// UI Tweaks, Home, Playlist and Now Playing, each sections of switches (the mod's own and a few of
// Spotify's remote-config flags), Navbar, the tab bar's own composition, and All flags, a
// searchable list of every flag with an override per flag. The tweaks read the switches when they
// run, so a change shows after Spotify restarts; the Navbar page is the exception and applies as
// soon as the bar lays out again.
//
// Tree (trees/settings.txt): SettingsListViewController.view > SettingsListCollectionView of
//   Element_List cells 402x56: 24pt icon at x 12, 13pt white title and 11pt grey subtitle at
//   x 48, 12pt chevron on the right. A pushed page (trees/settings notifications opened.txt) is a
//   UITableView bg #121212: header with an 11pt grey description at (16, 24), 53pt cells with the
#import "Core/SGCore.h"
#import "SGPage.h"
#import "SGPageStyle.h"
#import "SGModPage.h"
#import "Features/Appearance/Appearance.h"
#import "Features/Navbar/Navbar.h"
#import "Features/Home/Home.h"
#import "Features/Playlist/Playlist.h"
#import "Features/NowPlaying/NowPlaying.h"
#import "Features/Flags/Flags.h"
#import "Features/Privacy/Privacy.h"
#import "Features/About/About.h"

static const CGFloat kRowHeight = 56;
static char kRowKey, kInsetKey;

static UIViewController *modSettingsPage(void) {
    // Opening the page is the only thing that asks; the cache keeps it to once every six hours.
    SGCheckForUpdate(NO);
    NSMutableArray<SGModSection *> *sections = [NSMutableArray array];
    // A build the lock screen cannot open leads the page, above the tweaks: it is the one thing here
    // that no switch can put right, and it is worth reading before anything else.
    SGModRow *signing = SGSigningWarningRow();
    if (signing) [sections addObject:SGSection(nil, @[signing])];
    [sections addObjectsFromArray:@[
        SGSection(nil, @[
            SGPageRow(@"UI Tweaks", ^UIViewController *{ return SGAppearanceSettingsPage(); }),
            SGPageRow(@"Navbar", ^UIViewController *{ return SGNavbarSettingsPage(); }),
            SGPageRow(@"Home & Library", ^UIViewController *{ return SGHomeSettingsPage(); }),
            SGPageRow(@"Playlist", ^UIViewController *{ return SGPlaylistSettingsPage(); }),
            SGPageRow(@"Now Playing", ^UIViewController *{ return SGNowPlayingSettingsPage(); }),
            SGPageRow(@"Lock screen widget", ^UIViewController *{ return SGLockScreenSettingsPage(); }),
            SGPageRow(@"Playback", ^UIViewController *{ return SGPlaybackSettingsPage(); }),
            SGPageRow(@"Ads & nags", ^UIViewController *{ return SGAdsSettingsPage(); }),
            SGPageRow(@"Unreleased", ^UIViewController *{ return SGUnreleasedSettingsPage(); }),
            SGPageRow(@"Experimental", ^UIViewController *{ return SGExperimentalSettingsPage(); }),
            SGPageRow(@"Privacy", ^UIViewController *{ return SGPrivacySettingsPage(); }),
            SGPageRow(@"All flags", ^UIViewController *{ return SGAllFlagsPage(); }),
        ]),
        SGAboutSection(),
    ]];
    return [[SGModPage alloc] initWithTitle:@"Mod Settings" intro:nil sections:sections footer:nil];
}

#pragma mark - row in the settings list

@interface SGModSettingsRow : UIControl
@end

@implementation SGModSettingsRow {
    UIImageView *_icon;
    UILabel *_title;
    UIImageView *_chevron;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (!(self = [super initWithFrame:frame])) return nil;
    _icon = SGSymbolView(@"slider.horizontal.3", 20, UIImageSymbolWeightRegular, 24);
    _title = [UILabel new];
    _title.text = @"Mod Settings";
    _title.textColor = UIColor.whiteColor;
    _chevron = SGSymbolView(@"chevron.right", 11, UIImageSymbolWeightSemibold, 12);
    for (UIView *v in @[_icon, _title, _chevron]) [self addSubview:v];
    [self addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _title.font = SGTitleFont();
    CGFloat width = self.bounds.size.width, height = self.bounds.size.height;
    _icon.frame = CGRectMake(12, (height - 24) / 2, 24, 24);
    _title.frame = CGRectMake(48, 0, width - 96, height);
    _chevron.frame = CGRectMake(width - 24, (height - 12) / 2, 12, 12);
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.alpha = highlighted ? 0.5 : 1;
}

- (void)open {
    UIViewController *owner = nil;
    for (UIResponder *r = self; r && !owner; r = r.nextResponder) {
        if ([r isKindOfClass:UIViewController.class]) owner = (UIViewController *)r;
    }
    SGShowPage(owner, modSettingsPage());
}

@end

static void placeRow(UICollectionView *list, SGModSettingsRow *row) {
    SGAdoptFonts(list, row);
    CGFloat bottom = list.contentSize.height;
    row.hidden = bottom <= 0;
    row.frame = CGRectMake(0, bottom, list.bounds.size.width, kRowHeight);

    // Room to scroll to the row, added again whenever Spotify resets the inset.
    UIEdgeInsets inset = list.contentInset;
    NSValue *applied = objc_getAssociatedObject(list, &kInsetKey);
    if (applied && UIEdgeInsetsEqualToEdgeInsets(inset, applied.UIEdgeInsetsValue)) return;
    inset.bottom += kRowHeight;
    objc_setAssociatedObject(list, &kInsetKey, [NSValue valueWithUIEdgeInsets:inset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    list.contentInset = inset;
}

// Media quality, Playback, Account and most of the rest of settings are the same controller class
// as the list they were opened from, which is why the row turned up at the end of all of them.
// What is on the navigation stack is not that controller though: every page in the app is wrapped
// in a MusicAppPageHostingViewController (trees/settings notifications opened.txt), and Spotify
// pushes a settings sub page as a page of its own, leaving the list it came from on the stack
// underneath. So the settings list inside the lowest wrapper that holds one is the list the row
// belongs at the end of, and a controller with no stack to be found on keeps the row rather than
// losing it.
static UIViewController *settingsListIn(UIViewController *page, Class kind) {
    if ([page isKindOfClass:kind]) return page;
    for (UIViewController *child in page.childViewControllers) {
        UIViewController *found = settingsListIn(child, kind);
        if (found) return found;
    }
    return nil;
}

static BOOL isSettingsRoot(UIViewController *list) {
    for (UIViewController *page in list.navigationController.viewControllers) {
        UIViewController *found = settingsListIn(page, list.class);
        if (found) return found == list;
    }
    return YES;
}

%hook _TtC21Settings_PlatformImpl26SettingsListViewController
- (void)viewDidLayoutSubviews {
    %orig;
    BOOL root = isSettingsRoot((UIViewController *)self);
    for (UIView *sub in ((UIViewController *)self).view.subviews) {
        if (![sub isKindOfClass:UICollectionView.class]) continue;
        SGModSettingsRow *row = objc_getAssociatedObject(sub, &kRowKey);
        // A page that laid itself out before it was on the stack looked like the list for as long
        // as that took; the row goes again as soon as it can be seen for what it is.
        if (!root) {
            [row removeFromSuperview];
            objc_setAssociatedObject(sub, &kRowKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            continue;
        }
        if (row) continue;
        row = [[SGModSettingsRow alloc] initWithFrame:CGRectZero];
        objc_setAssociatedObject(sub, &kRowKey, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [sub addSubview:row];
    }
}
%end

// The list lays out after its controller and again whenever its content changes.
%hook UICollectionView
- (void)layoutSubviews {
    %orig;
    SGModSettingsRow *row = objc_getAssociatedObject(self, &kRowKey);
    if (row) placeRow(self, row);
}
%end

%ctor {
    %init;
    SGRequireClasses(@[@"_TtC21Settings_PlatformImpl26SettingsListViewController"]);
    SGRegisterPages();
    SGCheckSigningOnce();
}
