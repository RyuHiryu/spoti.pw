#import "Settings/SGModPage.h"
#import "Privacy.h"

NSArray<SGModSection *> *SGPrivacySections(void) {
    NSMutableArray<SGModRow *> *counts = [NSMutableArray array];
    for (NSString *label in SGBlockedLabels()) {
        [counts addObject:SGStatRow(label, ^NSString *{
            return @(SGBlockedCount(label)).stringValue;
        })];
    }
    [counts addObject:SGStatRow(@"Total", ^NSString *{
        return @(SGBlockedCount(nil)).stringValue;
    })];
    return @[
        SGSection(@"Telemetry", @[
            SGSwitchRow(@"Block telemetry", @"Answer the analytics endpoints with an empty reply instead of letting the request out", SGKeyBlockTelemetry),
        ]),
        SGSection(@"Telemetry blocked so far", counts),
        SGSection(nil, @[
            SGActionRow(@"Reset the telemetry counters", @"Start counting from zero", ^{ SGResetBlocked(); }),
        ]),
    ];
}
