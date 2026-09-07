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
//   title and subtitle at (16, 10) and a 16pt disclosure chevron at x 370.
#import "SGCommon.h"

static const CGFloat kRowHeight = 56;
static char kRowKey, kInsetKey;
static UIFont *sg_titleFont, *sg_subtitleFont;

static UIColor *grey(void) { return [UIColor colorWithWhite:0xB3 / 255.0 alpha:1]; }
static UIFont *titleFont(void) { return sg_titleFont ?: [UIFont systemFontOfSize:13 weight:UIFontWeightBold]; }
static UIFont *subtitleFont(void) { return sg_subtitleFont ?: [UIFont systemFontOfSize:11]; }

static UIImageView *symbol(NSString *name, CGFloat size, UIImageSymbolWeight weight, CGFloat box) {
    UIImage *image = [UIImage systemImageNamed:name withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:size weight:weight]];
    UIImageView *view = [[UIImageView alloc] initWithImage:image];
    view.tintColor = UIColor.whiteColor;
    view.contentMode = UIViewContentModeCenter;
    view.frame = CGRectMake(0, 0, box, box);
    return view;
}

// A grey note in a wrapper view, for the table header and footer.
static UIView *note(NSString *text) {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = subtitleFont();
    label.textColor = grey();
    label.numberOfLines = 0;
    UIView *wrapper = [UIView new];
    [wrapper addSubview:label];
    return wrapper;
}

// Header and footer views keep the height they are given, so size them to their text. Only the
// size is compared: the table moves the footer's origin itself, and reassigning on that would
// loop forever.
static void fitNote(UITableView *table, UIView *wrapper, CGFloat top, CGFloat bottom) {
    UILabel *label = wrapper.subviews.firstObject;
    CGFloat width = table.bounds.size.width - 32;
    CGFloat height = ceil([label sizeThatFits:CGSizeMake(width, CGFLOAT_MAX)].height);
    label.frame = CGRectMake(16, top, width, height);
    CGSize size = CGSizeMake(table.bounds.size.width, top + height + bottom);
    if (CGSizeEqualToSize(wrapper.bounds.size, size)) return;
    wrapper.frame = (CGRect){wrapper.frame.origin, size};
    if (wrapper == table.tableHeaderView) table.tableHeaderView = wrapper;
    else table.tableFooterView = wrapper;
}

static CGFloat barsHeight(UIView *view) {
    UIWindow *window = view.window;
    __block CGFloat top = window.bounds.size.height;
    SGForEachView(window, ^(UIView *v) {
        NSString *name = NSStringFromClass(v.class);
        BOOL bar = [name containsString:@"NowPlaying_BarPageImpl"] || [name isEqualToString:@"_TtC23NavigationUI_TabBarImpl10TabBarView"];
        if (!bar || v.hidden || v.alpha == 0 || v.bounds.size.height == 0) return;
        top = MIN(top, SGFrameIn(v, window).origin.y);
    });
    return window.bounds.size.height - top;
}

// The now playing bar and the tab bar float over the content, and the safe area does not cover
// them, so the pages inset themselves by however much of the window the bars take.
static void insetForBars(UITableView *table) {
    CGFloat bottom = MAX(0, barsHeight(table) - table.safeAreaInsets.bottom);
    if (table.contentInset.bottom == bottom) return;
    UIEdgeInsets inset = table.contentInset;
    inset.bottom = bottom;
    table.contentInset = inset;
    table.verticalScrollIndicatorInsets = inset;
}

static UIColor *green(void) { return [UIColor colorWithRed:0x1E / 255.0 green:0xD7 / 255.0 blue:0x60 / 255.0 alpha:1]; }
static UIColor *pageBackground(void) { return [UIColor colorWithWhite:0x12 / 255.0 alpha:1]; }

#pragma mark - pages

// Spotify's navigation controller asserts that everything on its stack is one of its own pages
// (SPNavigationController.m:645, "[viewController conformsToProtocol:@protocol(SPTPageController)]"),
// and the tab bar asks it for that page on every tab tap to log the interaction. A plain view
// controller of the mod's pushed onto that stack therefore takes the app down the next time a tab
// is pressed, from wherever it was left. The pages below answer the protocol's two questions
// instead and are registered as conforming at load; if the protocol is gone they are presented
// rather than pushed, so a rename in some later Spotify costs the push, not the app.
static BOOL sg_pagesConform;

@interface SGPage : UITableViewController
@end

@implementation SGPage

- (NSString *)spt_pageIdentifier {
    return @"spotifyglass";
}

- (NSURL *)spt_pageURI {
    return [NSURL URLWithString:@"spotify:internal:spotifyglass"];
}

@end

// A row is a switch when it has a key and a link to another page when it has a page. A flag row
// switches one of Spotify's remote-config flags: on forces it (off for a forceOff row, which is how
// a flag Spotify ships on is turned off), the switch off leaves Spotify's own value. A row
// with a value reads one out on the right and is asked again while the page is open; a row with an
// action runs it when tapped.
@interface SGModRow : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *key;
@property (nonatomic) BOOL defaultOn;
@property (nonatomic) BOOL flag;
@property (nonatomic) BOOL forceOff;
@property (nonatomic, copy) UIViewController *(^page)(void);
@property (nonatomic, copy) NSString *(^value)(void);
@property (nonatomic, copy) void (^action)(void);
@end

@implementation SGModRow
@end

@interface SGModSection : NSObject
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<SGModRow *> *rows;
@end

@implementation SGModSection
@end

static SGModRow *switchRow(NSString *title, NSString *subtitle, NSString *key) {
    SGModRow *row = [SGModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.key = key;
    row.defaultOn = YES;
    return row;
}

static SGModRow *hideRow(NSString *title, NSString *subtitle, NSString *key) {
    SGModRow *row = switchRow(title, subtitle, key);
    row.defaultOn = NO;
    return row;
}

// A switch for something the mod adds rather than takes away: off until it is asked for.
static SGModRow *optionRow(NSString *title, NSString *subtitle, NSString *key) {
    SGModRow *row = switchRow(title, subtitle, key);
    row.defaultOn = NO;
    return row;
}

static SGModRow *flagRow(NSString *title, NSString *key) {
    SGModRow *row = hideRow(title, [key substringFromIndex:[key rangeOfString:@"."].location + 1], key);
    row.flag = YES;
    return row;
}

// A flag Spotify ships on: the switch forces it off.
static SGModRow *killRow(NSString *title, NSString *key) {
    SGModRow *row = flagRow(title, key);
    row.forceOff = YES;
    return row;
}

static SGModRow *statRow(NSString *title, NSString *(^value)(void)) {
    SGModRow *row = [SGModRow new];
    row.title = title;
    row.value = value;
    return row;
}

static SGModRow *actionRow(NSString *title, NSString *subtitle, void (^action)(void)) {
    SGModRow *row = [SGModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.action = action;
    return row;
}

// No subtitle: a list of pages reads as a list, not as a wall of explanations.
static SGModRow *pageRow(NSString *title, UIViewController *(^page)(void)) {
    SGModRow *row = [SGModRow new];
    row.title = title;
    row.page = page;
    return row;
}

static SGModRow *linkRow(NSString *title, NSString *subtitle, NSString *url) {
    return actionRow(title, subtitle, ^{ SGOpenURL(url); });
}

// A value on the right and a tap: the Updates row reads its status out of SGUpdate.m every tick,
// and a tap asks the site again instead of waiting for the six hour cache to lapse.
static SGModRow *statActionRow(NSString *title, NSString *subtitle, NSString *(^value)(void), void (^action)(void)) {
    SGModRow *row = [SGModRow new];
    row.title = title;
    row.subtitle = subtitle;
    row.value = value;
    row.action = action;
    return row;
}

static SGModSection *section(NSString *title, NSArray<SGModRow *> *rows) {
    SGModSection *s = [SGModSection new];
    s.title = title;
    s.rows = rows;
    return s;
}

// On means the row's own override is in place; anything else, including the opposite override
// somebody set from the All flags page, reads as off.
static BOOL flagRowOn(SGModRow *row) {
    id value = SGFlagOverride(row.key);
    return value && [value boolValue] != row.forceOff;
}

// A flag the Spotify's own Liquid Glass switch owns: its row shows what that switch forces and
// takes no touch, so the flag has one place to change. An override from All flags still wins.
static BOOL flagRowLocked(SGModRow *row) {
    return row.flag && SGGlassOwnsFlag(row.key) && SGEnabled(SGKeySpotifyGlass);
}

static const CGFloat kSectionHeaderHeight = 38;

// Every page below draws Spotify's own list row: a 13pt white title over an 11pt grey subtitle,
// with an optional symbol in the leading slot.
static void fillCell(UITableViewCell *cell, NSString *title, NSString *subtitle, UIColor *color, NSString *symbolName) {
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = title;
    content.secondaryText = subtitle;
    content.textProperties.font = titleFont();
    content.textProperties.color = color ?: UIColor.whiteColor;
    content.secondaryTextProperties.font = subtitleFont();
    content.secondaryTextProperties.color = grey();
    content.textToSecondaryTextVerticalPadding = 0;
    content.directionalLayoutMargins = NSDirectionalEdgeInsetsMake(10, 16, 10, 16);
    if (symbolName) {
        content.image = [UIImage systemImageNamed:symbolName withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:15 weight:UIImageSymbolWeightRegular]];
        content.imageProperties.tintColor = color ?: UIColor.whiteColor;
        content.imageToTextPadding = 14;
    }
    cell.contentConfiguration = content;
    cell.backgroundColor = UIColor.clearColor;
    cell.accessoryView = nil;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

static UIView *sectionHeader(UITableView *table, NSString *title) {
    UILabel *label = [UILabel new];
    label.text = title.uppercaseString;
    label.font = subtitleFont();
    label.textColor = grey();
    label.frame = CGRectMake(16, 20, table.bounds.size.width - 32, 14);
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, table.bounds.size.width, kSectionHeaderHeight)];
    [header addSubview:label];
    return header;
}

static UITableViewCell *dequeue(UITableView *table, NSString *identifier) {
    return [table dequeueReusableCellWithIdentifier:identifier]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
}

@interface SGModPage : SGPage
- (instancetype)initWithTitle:(NSString *)title intro:(NSString *)intro sections:(NSArray<SGModSection *> *)sections footer:(NSString *)footer;
@end

@implementation SGModPage {
    NSArray<SGModSection *> *_sections;
    UIView *_intro;
    UIView *_footer;
    NSTimer *_ticker;
    BOOL _live;
}

- (instancetype)initWithTitle:(NSString *)title intro:(NSString *)intro sections:(NSArray<SGModSection *> *)sections footer:(NSString *)footer {
    if (!(self = [super initWithStyle:UITableViewStyleGrouped])) return nil;
    self.title = title;
    _sections = sections;
    _intro = intro ? note(intro) : nil;
    _footer = footer ? note(footer) : nil;
    for (SGModSection *s in sections) for (SGModRow *row in s.rows) _live |= row.value != nil;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.tableView.backgroundColor = pageBackground();
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderTopPadding = 0;
    self.tableView.tableHeaderView = _intro;
    self.tableView.tableFooterView = _footer;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (_intro) fitNote(self.tableView, _intro, 24, 0);
    if (_footer) fitNote(self.tableView, _footer, 16, 24);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    insetForBars(self.tableView);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!_live) return;
    [self.tableView reloadData];
    // The counters climb while the page is open; the labels are written straight into the cells so
    // that a reload never lands under a switch being dragged.
    _ticker = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(readValues) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_ticker invalidate];
    _ticker = nil;
}

- (void)readValues {
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        SGModRow *row = [self rowAt:[self.tableView indexPathForCell:cell]];
        UILabel *label = (UILabel *)cell.accessoryView;
        if (!row.value || ![label isKindOfClass:UILabel.class]) continue;
        label.text = row.value();
        [label sizeToFit];
        [cell setNeedsLayout];
    }
}

- (SGModRow *)rowAt:(NSIndexPath *)path {
    return _sections[(NSUInteger)path.section].rows[(NSUInteger)path.row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return (NSInteger)_sections.count;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)_sections[(NSUInteger)section].rows.count;
}

- (UIView *)tableView:(UITableView *)table viewForHeaderInSection:(NSInteger)section {
    NSString *title = _sections[(NSUInteger)section].title;
    return title ? sectionHeader(table, title) : nil;
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section {
    return _sections[(NSUInteger)section].title ? kSectionHeaderHeight : CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = dequeue(table, @"row");
    SGModRow *row = [self rowAt:path];
    fillCell(cell, row.title, row.subtitle, nil, nil);

    if (row.key) {
        UISwitch *toggle = [UISwitch new];
        toggle.onTintColor = green();
        BOOL locked = flagRowLocked(row);
        toggle.on = row.flag ? (locked && !SGFlagOverride(row.key) ? YES : flagRowOn(row)) : SGFlag(row.key, row.defaultOn);
        toggle.enabled = !locked;
        toggle.tag = path.section * 1000 + path.row;
        [toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else if (row.page) {
        cell.accessoryView = symbol(@"chevron.right", 13, UIImageSymbolWeightSemibold, 16);
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else if (row.value) {
        UILabel *label = [UILabel new];
        label.font = titleFont();
        label.textColor = grey();
        label.text = row.value();
        [label sizeToFit];
        cell.accessoryView = label;
        cell.selectionStyle = row.action ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
    } else if (row.action) {
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    SGModRow *row = [self rowAt:path];
    if (row.page) [self.navigationController pushViewController:row.page() animated:YES];
    if (!row.action) return;
    row.action();
    [table deselectRowAtIndexPath:path animated:YES];
    [self readValues];
}

- (void)toggled:(UISwitch *)toggle {
    SGModRow *row = [self rowAt:[NSIndexPath indexPathForRow:toggle.tag % 1000 inSection:toggle.tag / 1000]];
    if (row.flag) SGSetFlagOverride(row.key, toggle.on ? @(!row.forceOff) : nil);
    else SGSetEnabled(row.key, toggle.on);
}

@end

#pragma mark - flags page

static NSString *flagState(const SGFlagDef *flag, id value) {
    if (value) return [NSString stringWithFormat:@"forced %@", flag->type == SGFlagBool ? ([value boolValue] ? @"on" : @"off") : value];
    switch (flag->type) {
        case SGFlagBool: return flag->value ? @"on by default" : @"off by default";
        case SGFlagInt: return [NSString stringWithFormat:@"%ld by default, %ld to %ld", flag->value, flag->lower, flag->upper];
        case SGFlagEnum: return @"text value";
        default: return @"type unknown";
    }
}

// Every flag in SGFlagTable, filtered by the search words; forced flags first while the search
// is empty. Bool flags get an Auto / Off / On control, the others a text field in an alert.
@interface SGFlagsPage : SGPage <UISearchBarDelegate>
@end

@implementation SGFlagsPage {
    NSArray<NSNumber *> *_shown;
    NSDictionary<NSString *, id> *_overrides;
    UISearchBar *_search;
    UIView *_header;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStylePlain])) return nil;
    self.title = @"Flags";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.tableView.backgroundColor = pageBackground();
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    _search = [UISearchBar new];
    _search.placeholder = [NSString stringWithFormat:@"Search %lu flags", (unsigned long)SGFlagCount];
    _search.searchBarStyle = UISearchBarStyleMinimal;
    _search.delegate = self;
    _header = note(@"Spotify's remote config, read once at startup. Auto keeps the value Spotify sends; a change applies after you restart Spotify.");
    [_header addSubview:_search];
    self.tableView.tableHeaderView = _header;
    [self reload];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    _search.frame = CGRectMake(8, 4, self.tableView.bounds.size.width - 16, 44);
    fitNote(self.tableView, _header, 52, 8);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    insetForBars(self.tableView);
}

- (void)reload {
    NSMutableDictionary *overrides = [NSMutableDictionary dictionary];
    NSDictionary *defaults = NSUserDefaults.standardUserDefaults.dictionaryRepresentation;
    for (NSString *key in defaults) {
        if ([key hasPrefix:SGFlagOverridePrefix]) overrides[[key substringFromIndex:SGFlagOverridePrefix.length]] = defaults[key];
    }
    NSArray<NSString *> *words = [_search.text.lowercaseString componentsSeparatedByString:@" "];
    NSMutableArray *forced = [NSMutableArray array], *rest = [NSMutableArray array];
    for (NSUInteger i = 0; i < SGFlagCount; i++) {
        NSString *key = @(SGFlagTable[i].key);
        BOOL match = YES;
        for (NSString *word in words) match = match && (!word.length || [key containsString:word]);
        if (match) [overrides[key] ? forced : rest addObject:@(i)];
    }
    _overrides = overrides;
    _shown = [forced arrayByAddingObjectsFromArray:rest];
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)bar textDidChange:(NSString *)text {
    [self reload];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)bar {
    [bar resignFirstResponder];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)_shown.count;
}

- (const SGFlagDef *)flagAt:(NSInteger)row {
    return &SGFlagTable[_shown[(NSUInteger)row].unsignedIntegerValue];
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = dequeue(table, @"flag");
    const SGFlagDef *flag = [self flagAt:path.row];
    NSString *key = @(flag->key);
    NSUInteger dot = [key rangeOfString:@"."].location;
    id value = _overrides[key];

    fillCell(cell, [key substringFromIndex:dot + 1],
             [NSString stringWithFormat:@"%@ · %@", [key substringToIndex:dot], flagState(flag, value)],
             value ? green() : nil, nil);
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    if (flag->type == SGFlagBool) {
        UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"Auto", @"Off", @"On"]];
        control.selectedSegmentIndex = value ? ([value boolValue] ? 2 : 1) : 0;
        control.selectedSegmentTintColor = green();
        [control setTitleTextAttributes:@{NSForegroundColorAttributeName: UIColor.whiteColor, NSFontAttributeName: subtitleFont()} forState:UIControlStateNormal];
        control.tag = path.row;
        [control addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        [control sizeToFit];
        cell.accessoryView = control;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return cell;
}

- (void)segmentChanged:(UISegmentedControl *)control {
    NSString *key = @([self flagAt:control.tag]->key);
    NSInteger index = control.selectedSegmentIndex;
    [self store:index == 0 ? nil : @(index == 2) forKey:key row:control.tag];
}

- (void)store:(id)value forKey:(NSString *)key row:(NSInteger)row {
    SGSetFlagOverride(key, value);
    NSMutableDictionary *overrides = [_overrides mutableCopy];
    overrides[key] = value;
    _overrides = overrides;
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:row inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    const SGFlagDef *flag = [self flagAt:path.row];
    if (flag->type == SGFlagBool) return;
    NSString *key = @(flag->key);
    id value = _overrides[key];
    NSString *hint = flag->type == SGFlagUnknown ? @"true or false, a number, or a text value" : flagState(flag, value);
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[key substringFromIndex:[key rangeOfString:@"."].location + 1] message:hint preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.text = value ? [value description] : @"";
        field.keyboardType = flag->type == SGFlagInt ? UIKeyboardTypeNumbersAndPunctuation : UIKeyboardTypeDefault;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Auto" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a) {
        [self store:nil forKey:key row:path.row];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Force" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a) {
        NSString *text = alert.textFields.firstObject.text;
        if (!text.length) return;
        [self store:flag->type == SGFlagInt ? @(text.integerValue) : text forKey:key row:path.row];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

#pragma mark - navbar page

// What "Add a tab" offers: URIs Spotify's own router resolves to a page of its own, each with the
// name of the SPTEncoreIcon class method that draws its glyph.
static NSArray<NSDictionary *> *tabPresets(void) {
    return @[
        @{SGNavbarTitle: @"Home", SGNavbarURI: @"spotify:home", SGNavbarIcon: @"home"},
        @{SGNavbarTitle: @"Search", SGNavbarURI: @"spotify:search", SGNavbarIcon: @"search"},
        @{SGNavbarTitle: @"Your Library", SGNavbarURI: @"spotify:collection", SGNavbarIcon: @"collection"},
        @{SGNavbarTitle: @"Liked Songs", SGNavbarURI: @"spotify:collection:tracks", SGNavbarIcon: @"heart"},
        @{SGNavbarTitle: @"Playlists", SGNavbarURI: @"spotify:collection:playlists", SGNavbarIcon: @"playlist"},
        @{SGNavbarTitle: @"Albums", SGNavbarURI: @"spotify:collection:albums", SGNavbarIcon: @"album"},
        @{SGNavbarTitle: @"Artists", SGNavbarURI: @"spotify:collection:artists", SGNavbarIcon: @"artist"},
        @{SGNavbarTitle: @"Podcasts", SGNavbarURI: @"spotify:collection:podcasts", SGNavbarIcon: @"podcasts"},
        @{SGNavbarTitle: @"Audiobooks", SGNavbarURI: @"spotify:collection:audiobooks", SGNavbarIcon: @"audiobook"},
        @{SGNavbarTitle: @"Downloads", SGNavbarURI: @"spotify:collection:downloads", SGNavbarIcon: @"downloaded"},
        @{SGNavbarTitle: @"Your Episodes", SGNavbarURI: @"spotify:collection:your-episodes", SGNavbarIcon: @"bookmark"},
        @{SGNavbarTitle: @"Browse", SGNavbarURI: @"spotify:browse", SGNavbarIcon: @"browse"},
        @{SGNavbarTitle: @"New Releases", SGNavbarURI: @"spotify:new-releases", SGNavbarIcon: @"star"},
        @{SGNavbarTitle: @"Made For You", SGNavbarURI: @"spotify:made-for-you", SGNavbarIcon: @"user"},
        @{SGNavbarTitle: @"Concerts", SGNavbarURI: @"spotify:concerts", SGNavbarIcon: @"events"},
        @{SGNavbarTitle: @"Queue", SGNavbarURI: @"spotify:now-playing:queue", SGNavbarIcon: @"queue"},
        @{SGNavbarTitle: @"Create", SGNavbarURI: @"spotify:create-menu", SGNavbarIcon: @"plus"},
    ];
}

// The list the Navbar page edits: the saved order first, then every tab of Spotify's it does not
// name, in Spotify's order. Entries for tabs Spotify no longer has drop out.
static NSMutableArray<NSMutableDictionary *> *navbarEntries(void) {
    NSArray<NSString *> *stock = SGNavbarStock();
    NSMutableArray<NSMutableDictionary *> *entries = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (NSDictionary *entry in SGNavbarLayout()) {
        NSString *ident = entry[SGNavbarID];
        if (![ident isKindOfClass:NSString.class] || [seen containsObject:ident]) continue;
        if (!entry[SGNavbarURI] && ![stock containsObject:ident]) continue;
        [seen addObject:ident];
        [entries addObject:[entry mutableCopy]];
    }
    for (NSString *ident in stock) {
        if ([seen containsObject:ident]) continue;
        [entries addObject:[@{SGNavbarID: ident, SGNavbarTitle: ident} mutableCopy]];
    }
    return entries;
}

// A tab of the mod's own carries an identity of its own, so the same page can sit on the bar twice
// and renaming one does not shuffle the order.
static void appendTab(NSDictionary *tab) {
    NSMutableDictionary *entry = [tab mutableCopy];
    entry[SGNavbarID] = NSUUID.UUID.UUIDString;
    SGSetNavbarLayout([navbarEntries() arrayByAddingObject:entry]);
    SGRefreshTabBar();
}

@interface SGTabPickerPage : SGPage
@end

@implementation SGTabPickerPage {
    UIView *_footer;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleGrouped])) return nil;
    self.title = @"Add a Tab";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.tableView.backgroundColor = pageBackground();
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderTopPadding = 0;
    _footer = note(@"Anything Spotify can open by link works, so a playlist, an artist or a page of "
                   "your own goes on the bar the same way. Icons are Spotify's own: home, search, "
                   "collection, heart, playlist, album, artist, podcasts, audiobook, downloaded, "
                   "bookmark, browse, star, user, events, queue, plus, radio, gears, spotifyLogo.");
    self.tableView.tableFooterView = _footer;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    fitNote(self.tableView, _footer, 16, 24);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    insetForBars(self.tableView);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 2;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? (NSInteger)tabPresets().count : 1;
}

- (UIView *)tableView:(UITableView *)table viewForHeaderInSection:(NSInteger)section {
    return sectionHeader(table, section == 0 ? @"Spotify's pages" : @"Anywhere else");
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section {
    return kSectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = dequeue(table, @"pick");
    if (path.section == 0) {
        NSDictionary *tab = tabPresets()[(NSUInteger)path.row];
        fillCell(cell, tab[SGNavbarTitle], tab[SGNavbarURI], nil, nil);
    } else {
        fillCell(cell, @"Any link…", @"A name, a URI of your own and an icon", nil, @"link");
    }
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    return cell;
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    if (path.section == 0) {
        appendTab(tabPresets()[(NSUInteger)path.row]);
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Any link" message:@"Where the tab goes, and the glyph on it." preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) { field.placeholder = @"Name"; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"spotify:playlist:…";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *field) {
        field.placeholder = @"Icon";
        field.text = @"star";
        field.autocapitalizationType = UITextAutocapitalizationTypeNone;
        field.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSString *title = alert.textFields[0].text, *uri = alert.textFields[1].text, *icon = alert.textFields[2].text;
        if (!uri.length) return;
        appendTab(@{SGNavbarTitle: title.length ? title : uri, SGNavbarURI: uri, SGNavbarIcon: icon.length ? icon : @"star"});
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

// The tabs, in the order the bar shows them: drag to reorder, tap to show or hide, swipe a tab of
// your own away. Spotify's own tabs can only be hidden, never removed.
@interface SGNavbarPage : SGPage
@end

@implementation SGNavbarPage {
    NSMutableArray<NSMutableDictionary *> *_entries;
    UIView *_intro;
}

- (instancetype)init {
    if (!(self = [super initWithStyle:UITableViewStyleGrouped])) return nil;
    self.title = @"Navbar";
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.tableView.backgroundColor = pageBackground();
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderTopPadding = 0;
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.editing = YES;
    _intro = note(@"Drag a tab by the handle to move it, tap it to show or hide it. The bar follows straight away.");
    self.tableView.tableHeaderView = _intro;
    _entries = navbarEntries();
}

// The Add page writes straight to the layout, so the list is read again on the way back.
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _entries = navbarEntries();
    [self.tableView reloadData];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    fitNote(self.tableView, _intro, 24, 0);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    insetForBars(self.tableView);
}

- (void)save {
    SGSetNavbarLayout(_entries);
    SGRefreshTabBar();
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 4;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    return section == 1 ? (NSInteger)_entries.count : 1;
}

- (UIView *)tableView:(UITableView *)table viewForHeaderInSection:(NSInteger)section {
    return section == 1 ? sectionHeader(table, @"Tabs") : nil;
}

- (CGFloat)tableView:(UITableView *)table heightForHeaderInSection:(NSInteger)section {
    return section == 1 ? kSectionHeaderHeight : CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)table heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
    UITableViewCell *cell = dequeue(table, @"navbar");
    switch (path.section) {
        case 0: {
            fillCell(cell, @"Custom navbar", @"Off leaves the bar exactly as Spotify built it", nil, nil);
            UISwitch *toggle = [UISwitch new];
            toggle.onTintColor = green();
            toggle.on = SGEnabled(SGKeyNavbar);
            [toggle addTarget:self action:@selector(toggled:) forControlEvents:UIControlEventValueChanged];
            cell.accessoryView = toggle;
            break;
        }
        case 1: {
            NSDictionary *entry = _entries[(NSUInteger)path.row];
            BOOL hidden = [entry[SGNavbarHidden] boolValue];
            NSString *uri = entry[SGNavbarURI];
            fillCell(cell, entry[SGNavbarTitle], hidden ? @"Hidden" : (uri ?: @"Spotify's own tab"),
                     hidden ? grey() : nil, hidden ? @"eye.slash" : @"eye");
            break;
        }
        case 2:
            fillCell(cell, @"Add a tab…", @"A page of Spotify's, or any link", nil, @"plus");
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
        default:
            fillCell(cell, @"Use Spotify's order", @"Forgets the order and the tabs you added", nil, @"arrow.uturn.backward");
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            break;
    }
    return cell;
}

- (BOOL)tableView:(UITableView *)table canMoveRowAtIndexPath:(NSIndexPath *)path {
    return path.section == 1;
}

- (BOOL)tableView:(UITableView *)table canEditRowAtIndexPath:(NSIndexPath *)path {
    return path.section == 1;
}

// Spotify's own tabs stay on the list to be switched back on; only the mod's own can go.
- (UITableViewCellEditingStyle)tableView:(UITableView *)table editingStyleForRowAtIndexPath:(NSIndexPath *)path {
    if (path.section != 1) return UITableViewCellEditingStyleNone;
    return _entries[(NSUInteger)path.row][SGNavbarURI] ? UITableViewCellEditingStyleDelete : UITableViewCellEditingStyleNone;
}

- (NSIndexPath *)tableView:(UITableView *)table targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)from toProposedIndexPath:(NSIndexPath *)to {
    return to.section == 1 ? to : from;
}

- (void)tableView:(UITableView *)table moveRowAtIndexPath:(NSIndexPath *)from toIndexPath:(NSIndexPath *)to {
    NSMutableDictionary *entry = _entries[(NSUInteger)from.row];
    [_entries removeObjectAtIndex:(NSUInteger)from.row];
    [_entries insertObject:entry atIndex:(NSUInteger)to.row];
    [self save];
}

- (void)tableView:(UITableView *)table commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)path {
    if (style != UITableViewCellEditingStyleDelete) return;
    [_entries removeObjectAtIndex:(NSUInteger)path.row];
    [self save];
    [table deleteRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)path {
    [table deselectRowAtIndexPath:path animated:YES];
    if (path.section == 1) {
        NSMutableDictionary *entry = _entries[(NSUInteger)path.row];
        entry[SGNavbarHidden] = [entry[SGNavbarHidden] boolValue] ? nil : @YES;
        [self save];
        [table reloadRowsAtIndexPaths:@[path] withRowAnimation:UITableViewRowAnimationNone];
    } else if (path.section == 2) {
        [self.navigationController pushViewController:[SGTabPickerPage new] animated:YES];
    } else if (path.section == 3) {
        [self reset];
    }
}

- (void)toggled:(UISwitch *)toggle {
    SGSetEnabled(SGKeyNavbar, toggle.on);
    SGRefreshTabBar();
}

- (void)reset {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Use Spotify's order"
                                                                  message:@"Every tab of Spotify's comes back where Spotify put it, and the tabs you added go."
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Reset" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        SGSetNavbarLayout(@[]);
        SGRefreshTabBar();
        self->_entries = navbarEntries();
        [self.tableView reloadData];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

static NSString *const kRestart = @"Changes apply after you restart Spotify.";

static UIViewController *uiTweaksPage(void) {
    return [[SGModPage alloc] initWithTitle:@"UI Tweaks" intro:kRestart sections:@[
        section(@"Liquid Glass", @[
            switchRow(@"Tab bar", @"Glass pill behind the tabs, no labels", SGKeyTabBar),
            switchRow(@"Search field", @"Glass capsule instead of the white field", SGKeySearchField),
            switchRow(@"Spotify's own Liquid Glass", @"The glass navigation bar, the new player slider and the new sheets, all shipped switched off", SGKeySpotifyGlass),
        ]),
        section(@"Theme", @[
            switchRow(@"AMOLED background", @"Pure black instead of Spotify's dark grey", SGKeyAmoled),
        ]),
    ] footer:nil];
}

static UIViewController *homePage(void) {
    return [[SGModPage alloc] initWithTitle:@"Home & Library" intro:kRestart sections:@[
        section(@"Background", @[
            optionRow(@"Gradient", @"A green wash behind the top of the page, fading into the background", SGKeyHomeGradient),
        ]),
        section(@"Hide", @[
            hideRow(@"Filter pills", @"Music and Podcasts next to your avatar", SGHideHomePills),
            hideRow(@"Shortcuts grid", @"The tiles at the top", SGHideHomeShortcuts),
            hideRow(@"Promo cards", @"Single cards such as the next episode of a podcast", SGHideHomePromo),
            hideRow(@"Preview cards", @"Album, playlist and video previews with a play button", SGHideHomePreviews),
            hideRow(@"DJ card", @"Your own personal DJ", SGHideHomeDJ),
        ]),
        section(@"Spotify's flags", @[
            flagRow(@"Pull to refresh", @"ios-home-evopage-impl.pull_to_refresh_enabled"),
            flagRow(@"Hide items from Recents", @"ios-system-home-hidefromhome.is_hide_from_recents_enabled"),
            flagRow(@"Hide items from Shortcuts", @"ios-system-home-hidefromhome.is_hide_from_shortcuts_enabled"),
        ]),
        section(@"Library", @[
            flagRow(@"Denser rows", @"ios-feature-yourlibaryx.denser_rows_enabled"),
            flagRow(@"Recents", @"ios-feature-yourlibaryx.recents_enabled"),
            flagRow(@"Recents sort order", @"ios-feature-yourlibaryx.recents_sort_order_enabled"),
            flagRow(@"Sort playlists by recently updated", @"ios-feature-yourlibaryx.recently_updated_playlists_sort_enabled"),
            flagRow(@"Sort artists by recently updated", @"ios-feature-yourlibaryx.recently_updated_artists_sort_enabled"),
            flagRow(@"Library settings", @"ios-feature-yourlibaryx.library_settings_enabled"),
            flagRow(@"Library Pro", @"ios-feature-yourlibaryx.your_library_pro_enabled"),
        ]),
    ] footer:nil];
}

static UIViewController *playlistPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Playlist" intro:kRestart sections:@[
        section(@"Hide in the header", @[
            hideRow(@"Cover artwork", @"The square cover over the title", SGHidePlaylistArtwork),
            hideRow(@"Description", @"The text under the title", SGHidePlaylistDescription),
            hideRow(@"Creator and collaborators", @"The faces, the name and Message", SGHidePlaylistCreator),
            hideRow(@"Length and saves", @"The line under the creator", SGHidePlaylistLength),
        ]),
        section(@"Hide header buttons", @[
            hideRow(@"Video", @"The stack of clips at the start of the row", SGHidePlaylistVideo),
            hideRow(@"Add to library", @"The plus", SGHidePlaylistAddTo),
            hideRow(@"Download", @"The download arrow", SGHidePlaylistDownload),
            hideRow(@"Share", @"The button that opens the share sheet", SGHidePlaylistShare),
            hideRow(@"More", @"The three dots at the end of the row", SGHidePlaylistMore),
        ]),
        section(@"Hide over the tracks", @[
            hideRow(@"Curation pills", @"Add, Mix, Video, Edit, Sort and the rest", SGHidePlaylistPills),
            hideRow(@"Find and sort bar", @"Find on page and Sort, under the header", SGHidePlaylistFind),
        ]),
    ] footer:nil];
}

static UIViewController *lyricsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Lyrics" intro:kRestart sections:@[
        section(@"Spotify's flags", @[
            flagRow(@"Translations in the player", @"ios-feature-lyrics.enable_lyrics_multilanguage_npv"),
            flagRow(@"Translations full screen", @"ios-feature-lyrics.enable_lyrics_multilanguage_fullscreen"),
            flagRow(@"Keep lyrics offline", @"ios-feature-lyrics.lyrics_offline_enabled"),
            flagRow(@"Vocal removal", @"ios-feature-lyrics.enable_vocal_removal"),
            flagRow(@"Lyrics toggle in the context menu", @"ios-feature-lyrics.lyrics_context_menu_toggle_enabled"),
            flagRow(@"Dynamic colours", @"ios-feature-lyrics.enable_dynamic_colors"),
            flagRow(@"Centre a single line", @"ios-feature-lyrics.is_single_line_centering_enabled"),
            flagRow(@"Full screen on track change", @"ios-feature-lyrics.enable_fullscreen_track_change"),
            flagRow(@"Edit lyrics", @"ios-feature-lyrics.lyrics_edit_enabled"),
        ]),
    ] footer:nil];
}

static UIViewController *nowPlayingPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Now Playing" intro:kRestart sections:@[
        section(@"Liquid Glass", @[
            switchRow(@"Now playing bar", @"Glass card with round artwork", SGKeyNowPlayingBar),
            optionRow(@"Artwork background", @"The cover blurred and dimmed behind the player instead of the flat album colour", SGKeyPlayerBackdrop),
            switchRow(@"Header buttons", @"Glass circles behind close and more, over the artwork", SGKeyPlayer),
            switchRow(@"Lyrics", @"Glass card, and the page it expands into", SGKeyLyricsCard),
        ]),
        section(@"Spotify's flags", @[
            flagRow(@"Sheet style player", @"ios-feature-nowplaying.sheet_style_npv"),
            flagRow(@"Queue as a bottom sheet", @"ios-feature-nowplaying.bottom_sheet_queue_enabled"),
            flagRow(@"Queue flip transition", @"ios-feature-nowplaying.queue_flip_transition_enabled"),
            flagRow(@"Mini player transition animations", @"ios-feature-nowplaying.miniplayer_transition_animations"),
            flagRow(@"Bar to cover art animation", @"ios-feature-nowplaying.bartocoverart_animation_enabled"),
            flagRow(@"White heart button", @"ios-feature-nowplaying.white_heart_button_in_nowplaying_screen"),
            flagRow(@"Expand the sticky header on tap", @"ios-feature-nowplaying.expand_sticky_header_on_tap"),
            flagRow(@"Cover art in the header", @"ios-feature-nowplaying.show_header_context_cover_art"),
            flagRow(@"Redesigned header with context menu", @"ios-feature-nowplaying.new_redesign_header_with_context_menu_enabled"),
            flagRow(@"Picture in picture", @"ios-feature-nowplaying.picture_in_picture"),
            flagRow(@"Video in the mini player", @"ios-feature-nowplaying.video_in_miniplayer"),
        ]),
        section(@"Lock screen", @[
            flagRow(@"Like and dislike buttons", @"ios-feature-lockscreen.like_dislike_enabled"),
        ]),
        section(@"Hide buttons", @[
            hideRow(@"Shuffle", @"Left of the playback controls", SGHideShuffle),
            hideRow(@"Repeat", @"Right of the playback controls", SGHideRepeat),
            hideRow(@"Connect to a device", @"The speaker and device name in the bottom row", SGHideConnect),
            hideRow(@"Share", @"The share button in the bottom row", SGHideShare),
            hideRow(@"Queue", @"The queue button in the bottom row", SGHideQueue),
            hideRow(@"Add to playlist", @"The plus next to the track title", SGHideAddTo),
        ]),
        section(@"Under the artwork", @[
            hideRow(@"Lyrics preview", @"The lyric lines shown under the artwork", SGHideLyricsInline),
        ]),
        section(@"Hide cards below the player", @[
            hideRow(@"Lyrics", @"The lyrics card", SGHideLyricsCard),
            hideRow(@"About the artist", @"Photo, listeners and biography", SGHideAboutArtist),
            hideRow(@"Related videos", @"The video carousel", SGHideRelatedVideos),
            hideRow(@"SongDNA", @"Discover the people behind the song", SGHideSongDNA),
            hideRow(@"Live events", @"Concerts and tickets", SGHideLiveEvents),
            hideRow(@"Explore the artist", @"The vertical video cards", SGHideExploreArtist),
            hideRow(@"Credits", @"Performers and writers", SGHideCredits),
            hideRow(@"Merch", @"The artist's shop", SGHideMerch),
            hideRow(@"Recommendations", @"\"Artist: what you might like\", the episode and track rows", SGHideRecommendations),
        ]),
        section(nil, @[
            pageRow(@"Lyrics", ^UIViewController *{ return lyricsPage(); }),
        ]),
    ] footer:nil];
}

static UIViewController *lockScreenPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Lock screen widget" intro:kRestart sections:@[
        section(@"Spotify's flags", @[
            flagRow(@"Like and dislike buttons", @"ios-feature-lockscreen.like_dislike_enabled"),
            flagRow(@"Animated artwork", @"ios-feature-lockscreen.animated_artwork_enabled"),
            flagRow(@"Video artwork", @"ios-feature-lockscreen.vit_artwork_enabled"),
            flagRow(@"Companion content", @"ios-feature-lockscreen.companion_content_enabled"),
            flagRow(@"Burst skip", @"ios-feature-lockscreen.burst_skip_enabled"),
            flagRow(@"Chapter skip controls", @"ios-feature-lockscreen.enable_chapter_skip_controls"),
            flagRow(@"Skip button on podcasts", @"ios-feature-lockscreen.skip_button_on_podcasts"),
        ]),
    ] footer:nil];
}

static UIViewController *playbackPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Playback" intro:kRestart sections:@[
        section(@"Speed", @[
            flagRow(@"Speed control for music", @"ios-playbackcontrol-playbackspeed-impl.enable_playback_speed_for_music"),
            flagRow(@"Trim silence", @"ios-playbackcontrol-playbackspeed-impl.enable_trim_silence"),
            flagRow(@"Speed shortcuts", @"ios-playbackcontrol-playbackspeed-impl.enable_speed_shortcuts_v2"),
        ]),
        section(@"Queue", @[
            flagRow(@"Swipe a row to play next", @"ios-feature-queue.is_swipe_to_play_next_enabled"),
            flagRow(@"Play next in the context menu", @"ios-feature-queue.is_play_next_context_menu_enabled"),
            flagRow(@"Reshuffle", @"ios-feature-queue.is_reshuffle_enabled"),
            flagRow(@"Peek the queue when adding", @"ios-feature-queue.is_queue_peek_on_add_enabled"),
        ]),
        section(@"Player", @[
            flagRow(@"Pinch to zoom", @"ios-feature-nowplaying-fullscreen.pinch_to_zoom"),
            flagRow(@"Audio settings in the menu", @"ios-nowplaying-contextmenusettings-impl.audio_settings"),
            flagRow(@"Playback settings in the menu", @"ios-nowplaying-contextmenusettings-impl.playback_settings"),
            flagRow(@"Video settings in the menu", @"ios-nowplaying-contextmenusettings-impl.video_settings"),
            flagRow(@"New progress slider", @"ios-feature-encoreexperiments.new_npv_slider_enabled"),
            flagRow(@"Tilt the cover art", @"ios-creativeworkcommons-cover-art-tilt-configuration-kit.cover_art_tilt_enabled"),
            flagRow(@"Tilt it on album and playlist pages", @"ios-creativeworkcommons-cover-art-tilt-configuration-kit.album_playlist_and_podcast_pages_enabled"),
            flagRow(@"Lyrics over Canvas", @"ios-feature-canvas.lyrics_on_canvas_enabled"),
            flagRow(@"Mixing transitions", @"ios-feature-canvas.mixing_transition_enabled"),
            flagRow(@"Picture in picture in the app", @"ios-feature-picture-in-picture.picture_in_picture_in_app"),
            flagRow(@"Connect as a bottom sheet", @"ios-feature-nowplaying-elements.enable_connect_bottom_sheet"),
            flagRow(@"Connect sheet from the video switcher", @"ios-playbackcontrol-audiovideoswitcher-impl.enable_connect_bottom_sheet"),
        ]),
        section(@"Now playing bar", @[
            flagRow(@"Hold and drag to resize", @"ios-feature-nowplayingbar.hold_and_drag_to_resize"),
            flagRow(@"Save button", @"ios-feature-nowplayingbar.add_button"),
            flagRow(@"Queue badge", @"ios-feature-nowplayingbar.queue_badge"),
            flagRow(@"Two lines of track info", @"ios-feature-nowplayingbar.two_lines_information_unit"),
        ]),
        section(@"Spotify's settings", @[
            flagRow(@"Offline listening toggle", @"ios-feature-settings.enable_offline_listening_toggle"),
            flagRow(@"Gapless in Playback settings", @"ios-feature-settings.use_playback_settings_gapless"),
        ]),
    ] footer:nil];
}

// Every switch here forces a flag Spotify ships on to off, so the switch off is Spotify's own value.
static UIViewController *adsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Ads & nags" intro:kRestart sections:@[
        section(@"Ads", @[
            killRow(@"Ad when the app opens", @"ios-feature-adonappopen.enabled"),
            killRow(@"Its CTA card", @"ios-feature-adonappopen.cta_card_enabled"),
        ]),
        section(@"Upsells", @[
            killRow(@"Shuffle toggle upsell", @"ios-feature-shuffletoggleupsell.is_enabled_pt2"),
            killRow(@"Shuffle upsell in the video player", @"ios-feature-nowplaying-modes.video_first_shuffle_upsell_enabled"),
        ]),
        section(@"Badges", @[
            killRow(@"DJ beta badge", @"ios-home-evopage-impl.dj_mdc_beta_badge_enabled"),
            killRow(@"DJ button on Home", @"ios-home-evopage-impl.idj_show_dj_button"),
        ]),
        section(@"Tooltips", @[
            killRow(@"Data saver", @"ios-feature-nowplayingbar.data_saver_tooltip"),
            killRow(@"Smart shuffle helper", @"ios-messaging-reduceinterventions-impl.enable_message_smart_shuffle_helper_tooltip"),
            killRow(@"Watch feed explorer", @"ios-messaging-reduceinterventions-impl.enable_message_watch_feed_entity_explorer_tooltip"),
            killRow(@"AI playlist creation", @"ios-messaging-reduceinterventions-impl.enable_message_your_library_ai_playlist_creation_tooltip"),
            killRow(@"Account switching", @"ios-messaging-reduceinterventions-impl.enable_message_account_switching_tooltip"),
            killRow(@"Concert notifications", @"ios-messaging-reduceinterventions-impl.enable_message_live_events_concert_notifications_tooltip"),
            killRow(@"Live event", @"ios-messaging-reduceinterventions-impl.enable_message_live_events_event_entity_safe_tooltip"),
            killRow(@"Live event venue", @"ios-messaging-reduceinterventions-impl.enable_message_live_events_event_entity_venuename_header_tooltip"),
            killRow(@"Player suggestions upsell", @"ios-messaging-reduceinterventions-impl.enable_message_reinvent_free_n_p_v_suggestions_upsell"),
            killRow(@"Puffin nudge", @"ios-messaging-reduceinterventions-impl.enable_message_puffin_nudge_end_optimization"),
        ]),
        section(nil, @[
            flagRow(@"Reduce interventions", @"ios-messaging-reduceinterventions-impl.enabled"),
        ]),
    ] footer:@"The tooltip switches belong to Spotify's own intervention-reduction system, which the last switch turns on."];
}

static UIViewController *unreleasedPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Unreleased" intro:kRestart sections:@[
        section(@"Player", @[
            flagRow(@"Snake on the cover art", @"ios-feature-cover-art-snake.enabled"),
            flagRow(@"SongDNA", @"ios-songdna-featureproperties.is_song_dna_enabled"),
            flagRow(@"SongDNA covers playlist", @"ios-songdna-featureproperties.enable_go_to_covers_playlist"),
        ]),
        section(@"Podcast comments", @[
            flagRow(@"Comments card", @"ios-feature-comments.enable_comments_card"),
            flagRow(@"Pinned comments", @"ios-feature-comments.enable_pinned_comments"),
            flagRow(@"Several reactions", @"ios-feature-comments.enable_multi_reactions"),
        ]),
        section(@"Sleep timer", @[
            flagRow(@"Fade out", @"ios-feature-sleeptimer.enable_fade_out"),
            flagRow(@"One minute option", @"ios-feature-sleeptimer.enable_one_minute_option"),
            flagRow(@"Options sheet", @"ios-feature-sleeptimer.use_options_sheet"),
        ]),
        section(@"Elsewhere", @[
            flagRow(@"Local files from the Files app", @"ios-feature-localfiles.documents_enabled"),
            flagRow(@"Progress bar in the home screen widget", @"ios-widgets-widgetremoteconfig-impl.progress_bar_enabled"),
        ]),
    ] footer:nil];
}

static UIViewController *martiniPage(void) {
    return [[SGModPage alloc] initWithTitle:@"AI Chat (Martini)" intro:kRestart sections:@[
        section(@"On Home", @[
            flagRow(@"Chat entry point", @"ios-home-evopage-impl.interactive_entrypoint_enabled"),
            flagRow(@"Martini behind it", @"ios-home-evopage-impl.interactive_entrypoint_martini_enabled"),
            flagRow(@"Floating chat", @"ios-home-evopage-impl.interactive_entrypoint_floating_chat_enabled"),
            flagRow(@"Microphone", @"ios-home-evopage-impl.interactive_entrypoint_mic_enabled"),
            flagRow(@"Glowing pill", @"ios-home-evopage-impl.interactive_entrypoint_pill_glow_enabled"),
        ]),
        section(@"The chat", @[
            flagRow(@"Intent pills", @"ios-martini-floatingchat-impl.intent_pills_enabled"),
            flagRow(@"Thinking states", @"ios-martini-floatingchat-impl.thinking_states_enabled"),
            flagRow(@"Voice recording", @"ios-martini-floatingchat-impl.voice_recording_enabled"),
        ]),
        section(@"In the player", @[
            flagRow(@"Chat entry point", @"ios-martini-npvcardprovider-impl.floating_chat_entry_point_enabled"),
        ]),
    ] footer:nil];
}

static UIViewController *experimentalPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Experimental" intro:nil sections:@[
        section(nil, @[
            pageRow(@"AI Chat (Martini)", ^UIViewController *{ return martiniPage(); }),
        ]),
    ] footer:nil];
}

static UIViewController *privacyPage(void) {
    NSMutableArray<SGModRow *> *counts = [NSMutableArray array];
    for (NSString *label in SGBlockedLabels()) {
        [counts addObject:statRow(label, ^NSString *{
            return @(SGBlockedCount(label)).stringValue;
        })];
    }
    [counts addObject:statRow(@"Total", ^NSString *{
        return @(SGBlockedCount(nil)).stringValue;
    })];
    return [[SGModPage alloc] initWithTitle:@"Privacy" intro:kRestart sections:@[
        section(@"Telemetry", @[
            switchRow(@"Block telemetry", @"Answer the analytics endpoints with an empty reply instead of letting the request out", SGKeyBlockTelemetry),
        ]),
        section(@"Blocked so far", counts),
        section(nil, @[
            actionRow(@"Reset the counters", @"Start counting from zero", ^{ SGResetBlocked(); }),
        ]),
    ] footer:nil];
}

// Which build this is, whether the site has a newer one, and where to reach the mod: without these
// rows a build that is already installed has no way of telling its user that anything moved on.
static SGModSection *aboutSection(void) {
    NSString *spotify = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown";
    return section(@"About", @[
        statRow(@"Version", ^NSString *{ return @(SG_VERSION); }),
        statRow(@"Spotify", ^NSString *{ return spotify; }),
        statActionRow(@"Updates", @"Asks the site for the newest build; tap to check now", ^NSString *{
            return SGUpdateStatus();
        }, ^{ SGCheckForUpdate(YES); }),
        linkRow(@"Website", @"Downloads, and the source to add to AltStore or SideStore", SGSiteURL),
        linkRow(@"GitHub", @"Source, releases and issues", SGRepoURL),
    ]);
}

static UIViewController *modSettingsPage(void) {
    // Opening the page is the only thing that asks; the cache keeps it to once every six hours.
    SGCheckForUpdate(NO);
    return [[SGModPage alloc] initWithTitle:@"Mod Settings" intro:nil sections:@[
        section(nil, @[
            pageRow(@"UI Tweaks", ^UIViewController *{ return uiTweaksPage(); }),
            pageRow(@"Navbar", ^UIViewController *{ return [SGNavbarPage new]; }),
            pageRow(@"Home & Library", ^UIViewController *{ return homePage(); }),
            pageRow(@"Playlist", ^UIViewController *{ return playlistPage(); }),
            pageRow(@"Now Playing", ^UIViewController *{ return nowPlayingPage(); }),
            pageRow(@"Lock screen widget", ^UIViewController *{ return lockScreenPage(); }),
            pageRow(@"Playback", ^UIViewController *{ return playbackPage(); }),
            pageRow(@"Ads & nags", ^UIViewController *{ return adsPage(); }),
            pageRow(@"Unreleased", ^UIViewController *{ return unreleasedPage(); }),
            pageRow(@"Experimental", ^UIViewController *{ return experimentalPage(); }),
            pageRow(@"Privacy", ^UIViewController *{ return privacyPage(); }),
            pageRow(@"All flags", ^UIViewController *{ return [SGFlagsPage new]; }),
        ]),
        aboutSection(),
    ] footer:nil];
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
    _icon = symbol(@"slider.horizontal.3", 20, UIImageSymbolWeightRegular, 24);
    _title = [UILabel new];
    _title.text = @"Mod Settings";
    _title.textColor = UIColor.whiteColor;
    _chevron = symbol(@"chevron.right", 11, UIImageSymbolWeightSemibold, 12);
    for (UIView *v in @[_icon, _title, _chevron]) [self addSubview:v];
    [self addTarget:self action:@selector(open) forControlEvents:UIControlEventTouchUpInside];
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _title.font = titleFont();
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
    UIViewController *page = modSettingsPage();
    if (owner.navigationController && sg_pagesConform) [owner.navigationController pushViewController:page animated:YES];
    else [owner presentViewController:[[UINavigationController alloc] initWithRootViewController:page] animated:YES completion:nil];
}

@end

static CGFloat brightness(UIColor *color) {
    CGFloat white = 0;
    [color getWhite:&white alpha:NULL];
    return white;
}

// Spotify's list labels carry its typeface: 13pt titles and 11pt grey subtitles.
static void captureFonts(UIView *list, UIView *row) {
    SGForEachView(list, ^(UIView *v) {
        if (![v isKindOfClass:UILabel.class] || SGIsInside(v, row)) return;
        UILabel *label = (UILabel *)v;
        if (label.text.length < 2) return;
        CGFloat size = label.font.pointSize, white = brightness(label.textColor);
        if (size == 13 && !sg_titleFont) sg_titleFont = label.font;
        if (size == 11 && !sg_subtitleFont && white > 0.3 && white < 0.95) sg_subtitleFont = label.font;
    });
}

static void placeRow(UICollectionView *list, SGModSettingsRow *row) {
    if (!sg_titleFont || !sg_subtitleFont) captureFonts(list, row);
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
    // Swift's own name for the protocol, which is what the runtime registers it under.
    Protocol *page = objc_getProtocol("_TtP19Tome_PageAttributes17SPTPageController_") ?: objc_getProtocol("SPTPageController");
    sg_pagesConform = page && class_addProtocol(SGPage.class, page);
    if (!sg_pagesConform) SGLog(@"SPTPageController not found, the mod's pages are presented instead of pushed");
}
