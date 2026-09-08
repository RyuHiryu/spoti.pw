// About: where the build points its user, and whether the site has a newer one (Update.m). The
// status is a string for the Updates row; the page's ticker reads it, so the check needs no
// callback. SGCheckForUpdate(NO) respects a six hour cache, SGCheckForUpdate(YES) always asks.
#import <UIKit/UIKit.h>
#import "Settings/SGModPage.h"

extern NSString *const SGSiteURL;
extern NSString *const SGRepoURL;
extern NSString *const SGUpdateURL;
NSString *SGUpdateVersion(void);  // nil unless the site has one newer than this build
NSString *SGUpdateNotes(void);
NSString *SGUpdateStatus(void);
void SGCheckForUpdate(BOOL force);

SGModSection *SGAboutSection(void);
