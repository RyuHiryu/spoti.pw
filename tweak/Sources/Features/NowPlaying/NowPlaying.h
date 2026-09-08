// Now Playing: the glass bar (NowPlayingBar.x), the full screen player (Player.x) and the lyrics
// card with the page it expands into (Lyrics.x). The bar, the backdrop and the lyrics card are off
// until asked for, together through Liquid Glass UI in UI Tweaks; the header buttons are on.
#import <UIKit/UIKit.h>

#define SGKeyNowPlayingBar @"spotifyglass.nowPlayingBar"
#define SGKeyPlayer @"spotifyglass.player"
#define SGKeyPlayerBackdrop @"spotifyglass.playerBackdrop"
#define SGKeyLyricsCard @"spotifyglass.lyricsCard"

UIViewController *SGNowPlayingSettingsPage(void);
