#import "Settings/SGPageStyle.h"
#import "About.h"

// Which build this is, whether the site has a newer one, and where to reach the mod: without these
// rows a build that is already installed has no way of telling its user that anything moved on.
SGModSection *SGAboutSection(void) {
    NSString *spotify = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"unknown";
    return SGSection(@"About", @[
        SGStatRow(@"Version", ^NSString *{ return @(SG_VERSION); }),
        SGStatRow(@"Spotify", ^NSString *{ return spotify; }),
        SGStatActionRow(@"Updates", @"Asks the site for the newest build; tap to check now", ^NSString *{
            return SGUpdateStatus();
        }, ^{ SGCheckForUpdate(YES); }),
        SGLinkRow(@"Website", @"Downloads, and the source to add to AltStore or SideStore", SGSiteURL),
        SGLinkRow(@"GitHub", @"Source, releases and issues", SGRepoURL),
    ]);
}
