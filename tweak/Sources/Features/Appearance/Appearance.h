// Appearance: the AMOLED background (Amoled.x), the glass search field (SearchField.x) and
// Repaint.x, which keeps what the other features stripped transparent when Spotify repaints it.
#import <UIKit/UIKit.h>

#define SGKeyAmoled @"spotifyglass.amoled"
#define SGKeySearchField @"spotifyglass.searchField"

UIViewController *SGAppearanceSettingsPage(void);
