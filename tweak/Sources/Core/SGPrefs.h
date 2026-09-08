// The mod's own settings, in Spotify's NSUserDefaults. Every key is declared by the feature that
// owns it, in that feature's header; the accessors here are what the hooks and the pages share.
#import <Foundation/Foundation.h>

BOOL SGFlag(NSString *key, BOOL fallback);
BOOL SGEnabled(NSString *key);   // an unset switch is on
BOOL SGHidden(NSString *key);    // an unset switch is off
void SGSetEnabled(NSString *key, BOOL on);

// Overrides of Spotify's remote-config flags, stored under SGFlagOverridePrefix + flag key;
// nil keeps Spotify's value. Features/Flags reads them, the All flags page and flag rows write them.
extern NSString *const SGFlagOverridePrefix;
id SGFlagOverride(NSString *key);
void SGSetFlagOverride(NSString *key, id value);
