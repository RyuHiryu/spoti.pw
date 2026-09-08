#import "Settings/SGModPage.h"
#import "Home.h"
#import "Features/Declutter/Declutter.h"

UIViewController *SGHomeSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"Home & Library" intro:SGRestartNote sections:@[
        SGSection(@"Background", @[
            SGOptionRow(@"Gradient", @"A green wash behind the top of the page, fading into the background", SGKeyHomeGradient),
        ]),
        SGSection(@"Hide", @[
            SGHideRow(@"Filter pills", @"Music and Podcasts next to your avatar", SGHideHomePills),
            SGHideRow(@"Shortcuts grid", @"The tiles at the top", SGHideHomeShortcuts),
            SGHideRow(@"Promo cards", @"Single cards such as the next episode of a podcast", SGHideHomePromo),
            SGHideRow(@"Preview cards", @"Album, playlist and video previews with a play button", SGHideHomePreviews),
            SGHideRow(@"DJ card", @"Your own personal DJ", SGHideHomeDJ),
        ]),
        SGSection(@"Spotify's flags", @[
            SGFlagRow(@"Pull to refresh", @"ios-home-evopage-impl.pull_to_refresh_enabled"),
            SGFlagRow(@"Hide items from Recents", @"ios-system-home-hidefromhome.is_hide_from_recents_enabled"),
            SGFlagRow(@"Hide items from Shortcuts", @"ios-system-home-hidefromhome.is_hide_from_shortcuts_enabled"),
        ]),
        SGSection(@"Library", @[
            SGFlagRow(@"Denser rows", @"ios-feature-yourlibaryx.denser_rows_enabled"),
            SGFlagRow(@"Recents", @"ios-feature-yourlibaryx.recents_enabled"),
            SGFlagRow(@"Recents sort order", @"ios-feature-yourlibaryx.recents_sort_order_enabled"),
            SGFlagRow(@"Sort playlists by recently updated", @"ios-feature-yourlibaryx.recently_updated_playlists_sort_enabled"),
            SGFlagRow(@"Sort artists by recently updated", @"ios-feature-yourlibaryx.recently_updated_artists_sort_enabled"),
            SGFlagRow(@"Library settings", @"ios-feature-yourlibaryx.library_settings_enabled"),
            SGFlagRow(@"Library Pro", @"ios-feature-yourlibaryx.your_library_pro_enabled"),
        ]),
    ] footer:nil];
}
