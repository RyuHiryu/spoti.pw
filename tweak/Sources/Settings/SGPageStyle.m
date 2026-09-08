#import "SGPageStyle.h"
#import "Core/SGCore.h"

static UIFont *sg_titleFont, *sg_subtitleFont;

UIColor *SGGrey(void) { return [UIColor colorWithWhite:0xB3 / 255.0 alpha:1]; }
UIFont *SGTitleFont(void) { return sg_titleFont ?: [UIFont systemFontOfSize:13 weight:UIFontWeightBold]; }
UIFont *SGSubtitleFont(void) { return sg_subtitleFont ?: [UIFont systemFontOfSize:11]; }

UIImageView *SGSymbolView(NSString *name, CGFloat size, UIImageSymbolWeight weight, CGFloat box) {
    UIImage *image = [UIImage systemImageNamed:name withConfiguration:[UIImageSymbolConfiguration configurationWithPointSize:size weight:weight]];
    UIImageView *view = [[UIImageView alloc] initWithImage:image];
    view.tintColor = UIColor.whiteColor;
    view.contentMode = UIViewContentModeCenter;
    view.frame = CGRectMake(0, 0, box, box);
    return view;
}

// A grey note in a wrapper view, for the table header and footer.
UIView *SGNote(NSString *text) {
    UILabel *label = [UILabel new];
    label.text = text;
    label.font = SGSubtitleFont();
    label.textColor = SGGrey();
    label.numberOfLines = 0;
    UIView *wrapper = [UIView new];
    [wrapper addSubview:label];
    return wrapper;
}

// Header and footer views keep the height they are given, so size them to their text. Only the
// size is compared: the table moves the footer's origin itself, and reassigning on that would
// loop forever.
void SGFitNote(UITableView *table, UIView *wrapper, CGFloat top, CGFloat bottom) {
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
void SGInsetForBars(UITableView *table) {
    CGFloat bottom = MAX(0, barsHeight(table) - table.safeAreaInsets.bottom);
    if (table.contentInset.bottom == bottom) return;
    UIEdgeInsets inset = table.contentInset;
    inset.bottom = bottom;
    table.contentInset = inset;
    table.verticalScrollIndicatorInsets = inset;
}

UIColor *SGGreen(void) { return [UIColor colorWithRed:0x1E / 255.0 green:0xD7 / 255.0 blue:0x60 / 255.0 alpha:1]; }
UIColor *SGRed(void) { return [UIColor colorWithRed:0xF1 / 255.0 green:0x5E / 255.0 blue:0x6B / 255.0 alpha:1]; }
UIColor *SGPageBackground(void) { return [UIColor colorWithWhite:0x12 / 255.0 alpha:1]; }

const CGFloat SGSectionHeaderHeight = 38;

// Every page below draws Spotify's own list row: a 13pt white title over an 11pt grey subtitle,
// with an optional symbol in the leading slot.
void SGFillCell(UITableViewCell *cell, NSString *title, NSString *subtitle, UIColor *color, NSString *symbolName) {
    UIListContentConfiguration *content = [UIListContentConfiguration subtitleCellConfiguration];
    content.text = title;
    content.secondaryText = subtitle;
    content.textProperties.font = SGTitleFont();
    content.textProperties.color = color ?: UIColor.whiteColor;
    content.secondaryTextProperties.font = SGSubtitleFont();
    content.secondaryTextProperties.color = SGGrey();
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

UIView *SGSectionHeader(UITableView *table, NSString *title) {
    UILabel *label = [UILabel new];
    label.text = title.uppercaseString;
    label.font = SGSubtitleFont();
    label.textColor = SGGrey();
    label.frame = CGRectMake(16, 20, table.bounds.size.width - 32, 14);
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, table.bounds.size.width, SGSectionHeaderHeight)];
    [header addSubview:label];
    return header;
}

UITableViewCell *SGDequeueCell(UITableView *table, NSString *identifier) {
    return [table dequeueReusableCellWithIdentifier:identifier]
        ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
}

static CGFloat brightness(UIColor *color) {
    CGFloat white = 0;
    [color getWhite:&white alpha:NULL];
    return white;
}

// Spotify's list labels carry its typeface: 13pt titles and 11pt grey subtitles.
void SGAdoptFonts(UIView *list, UIView *row) {
    if (sg_titleFont && sg_subtitleFont) return;
    SGForEachView(list, ^(UIView *v) {
        if (![v isKindOfClass:UILabel.class] || SGIsInside(v, row)) return;
        UILabel *label = (UILabel *)v;
        if (label.text.length < 2) return;
        CGFloat size = label.font.pointSize, white = brightness(label.textColor);
        if (size == 13 && !sg_titleFont) sg_titleFont = label.font;
        if (size == 11 && !sg_subtitleFont && white > 0.3 && white < 0.95) sg_subtitleFont = label.font;
    });
}

void SGOpenURL(NSString *url) {
    NSURL *target = url ? [NSURL URLWithString:url] : nil;
    if (!target) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIApplication.sharedApplication openURL:target options:@{} completionHandler:nil];
    });
}
