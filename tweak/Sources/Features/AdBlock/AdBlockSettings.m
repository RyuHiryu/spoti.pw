#import "Settings/SGModPage.h"
#import "AdBlock.h"

NSString *const SGFakePremiumWarning = @"This is the part of EeveeSpotify Spotify's takedown went after, and it has not been tested here. It can end in a forced logout or worse for the account. A Premium account gains nothing from it.";

NSArray<SGModSection *> *SGAdBlockSections(void) {
    NSMutableArray<SGModRow *> *counts = [NSMutableArray array];
    for (NSString *label in SGAdBlockLabels()) {
        [counts addObject:SGStatRow(label, ^NSString *{
            return @(SGAdBlockCount(label)).stringValue;
        })];
    }
    [counts addObject:SGStatRow(@"Total", ^NSString *{
        return @(SGAdBlockCount(nil)).stringValue;
    })];
    SGModRow *fakePremium = SGOptionRow(@"Spoof Premium", @"Free accounts only. The product state and config the server sends are rewritten to a Premium account's, and the logout it sends back is answered as done", SGKeyFakePremium);
    fakePremium.warning = SGFakePremiumWarning;
    return @[
        SGSection(nil, @[
            fakePremium,
            SGOptionRow(@"Hide ads", @"The ad services never start, ad components leave Home and Search before they render, and the requests behind them are answered empty", SGKeyHideAds),
            SGOptionRow(@"Hide upsells", @"Premium prompts, banners and sheets dropped, and the flags that show them forced off", SGKeyHideUpsells),
        ]),
        SGSection(@"Blocked so far", counts),
        SGSection(nil, @[
            SGActionRow(@"Reset the counters", @"Start counting from zero", ^{ SGResetAdBlock(); }),
        ]),
    ];
}
