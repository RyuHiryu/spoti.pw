// Appearance: the AMOLED background (Amoled.x), the glass search field (SearchField.x) and
// Repaint.x, which keeps what the other features stripped transparent when Spotify repaints it.
// Both switches are off until asked for, as are the tab bar's and Spotify's own glass.
#import <UIKit/UIKit.h>

#define SGKeyAmoled @"spotifyglass.amoled"
#define SGKeySearchField @"spotifyglass.searchField"

// Liquid Glass UI, the one switch of UI Tweaks that sets others: Spotify's own glass and, with
// it, the search field, the now playing bar, the artwork background and the lyrics card. Each
// stays a switch of its own afterwards.
void SGSetLiquidGlassUI(BOOL on);

UIViewController *SGAppearanceSettingsPage(void);
