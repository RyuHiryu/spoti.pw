// Flags: Spotify's remote-config flags. Flags.x forces an override into the configuration
// provider; SGFlagList.m is the table of every flag, generated from the IPA by
// scripts/extract-flags.py; FlagsPage.m is the searchable All flags page and FlagPages.m the pages
// that list flags by topic (Playback, Ads & nags, Lock screen widget, Unreleased, Experimental).
#import <UIKit/UIKit.h>

// Spotify ships its newer design behind several flags at once, so this switch owns them all:
// Flags.x forces each one while it is on and the settings rows show them locked at the forced
// value, which is what keeps the switch and the rows from contradicting each other.
#define SGKeySpotifyGlass @"spotifyglass.spotifyGlass"
BOOL SGGlassOwnsFlag(NSString *key);

typedef NS_ENUM(NSInteger, SGFlagType) { SGFlagUnknown, SGFlagBool, SGFlagInt, SGFlagEnum };
typedef struct { const char *key; SGFlagType type; long value, lower, upper; } SGFlagDef;
extern const SGFlagDef SGFlagTable[];
extern const NSUInteger SGFlagCount;

UIViewController *SGAllFlagsPage(void);
UIViewController *SGPlaybackSettingsPage(void);
UIViewController *SGAdsSettingsPage(void);
UIViewController *SGLockScreenSettingsPage(void);
UIViewController *SGUnreleasedSettingsPage(void);
UIViewController *SGExperimentalSettingsPage(void);
