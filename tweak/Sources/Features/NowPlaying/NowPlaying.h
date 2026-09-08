// Now Playing: the glass bar (NowPlayingBar.x), the full screen player (Player.x) and the lyrics
// card with the page it expands into (Lyrics.x). An unset switch is on; the backdrop is off until
// it is asked for.
#import <UIKit/UIKit.h>

#define SGKeyNowPlayingBar @"spotifyglass.nowPlayingBar"
#define SGKeyPlayer @"spotifyglass.player"
#define SGKeyPlayerBackdrop @"spotifyglass.playerBackdrop"
#define SGKeyLyricsCard @"spotifyglass.lyricsCard"

UIViewController *SGNowPlayingSettingsPage(void);
