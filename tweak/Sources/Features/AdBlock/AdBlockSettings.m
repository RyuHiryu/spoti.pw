#import "Settings/SGModPage.h"
#import "AdBlock.h"

UIViewController *SGAdBlockSettingsPage(void) {
    NSMutableArray<SGModRow *> *counts = [NSMutableArray array];
    for (NSString *label in SGAdBlockLabels()) {
        [counts addObject:SGStatRow(label, ^NSString *{
            return @(SGAdBlockCount(label)).stringValue;
        })];
    }
    [counts addObject:SGStatRow(@"Total", ^NSString *{
        return @(SGAdBlockCount(nil)).stringValue;
    })];
    SGModRow *fakePremium = SGOptionRow(@"Pretend to be Premium", @"Rewrite the product state and config the server sends to a Premium account's, and answer the logout it sends back as done. Free accounts only", SGKeyFakePremium);
    fakePremium.warning = @"This is the part of EeveeSpotify Spotify's takedown went after, and it has not been tested here. It can end in a forced logout or worse for the account. A Premium account gains nothing from it.";
    return [[SGModPage alloc] initWithTitle:@"Ad blocking" intro:SGRestartNote sections:@[
        SGSection(@"From EeveeSpotify", @[
            SGOptionRow(@"Hide ads", @"The ad services never start, ad components leave Home and Search before they render, and the requests behind them are answered empty", SGKeyHideAds),
            SGOptionRow(@"Hide upsells", @"Premium prompts, banners and sheets dropped, and the flags that show them forced off", SGKeyHideUpsells),
            fakePremium,
        ]),
        SGSection(@"Blocked so far", counts),
        SGSection(nil, @[
            SGActionRow(@"Reset the counters", @"Start counting from zero", ^{ SGResetAdBlock(); }),
        ]),
    ] footer:@"All three are off until switched on, and none is needed on a Premium account, which has no ads to block. Audio ads between songs are the Premium switch's to stop; the other two only reach what is drawn."];
}
