#import "Settings/SGModPage.h"
#import "Privacy.h"

UIViewController *SGPrivacySettingsPage(void) {
    NSMutableArray<SGModRow *> *counts = [NSMutableArray array];
    for (NSString *label in SGBlockedLabels()) {
        [counts addObject:SGStatRow(label, ^NSString *{
            return @(SGBlockedCount(label)).stringValue;
        })];
    }
    [counts addObject:SGStatRow(@"Total", ^NSString *{
        return @(SGBlockedCount(nil)).stringValue;
    })];
    return [[SGModPage alloc] initWithTitle:@"Privacy" intro:SGRestartNote sections:@[
        SGSection(@"Telemetry", @[
            SGSwitchRow(@"Block telemetry", @"Answer the analytics endpoints with an empty reply instead of letting the request out", SGKeyBlockTelemetry),
        ]),
        SGSection(@"Blocked so far", counts),
        SGSection(nil, @[
            SGActionRow(@"Reset the counters", @"Start counting from zero", ^{ SGResetBlocked(); }),
        ]),
    ] footer:nil];
}
