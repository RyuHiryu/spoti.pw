#import "Settings/SGModPage.h"
#import "Appearance.h"
#import "Features/Navbar/Navbar.h"
#import "Features/Flags/Flags.h"

UIViewController *SGAppearanceSettingsPage(void) {
    return [[SGModPage alloc] initWithTitle:@"UI Tweaks" intro:SGRestartNote sections:@[
        SGSection(@"Liquid Glass", @[
            SGUnstableRow(@"Tab bar", @"[WIP] Unstable", SGKeyTabBar,
                        @"The glass capsule does not render the way iOS draws its own, and there is no selection indicator behind the active tab. Switching this on will look wrong.\n\nIf you want to take it further, pull requests are very welcome."),
            SGSwitchRow(@"Search field", @"Glass capsule instead of the white field", SGKeySearchField),
            SGSwitchRow(@"Spotify's own Liquid Glass", @"The glass navigation bar, the new player slider and the new sheets, all shipped switched off", SGKeySpotifyGlass),
        ]),
        SGSection(@"Theme", @[
            SGSwitchRow(@"AMOLED background", @"Pure black instead of Spotify's dark grey", SGKeyAmoled),
        ]),
    ] footer:nil];
}
