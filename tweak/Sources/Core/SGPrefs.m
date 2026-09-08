#import "SGPrefs.h"

BOOL SGFlag(NSString *key, BOOL fallback) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    return value ? [value boolValue] : fallback;
}

BOOL SGEnabled(NSString *key) {
    return SGFlag(key, YES);
}

BOOL SGHidden(NSString *key) {
    return SGFlag(key, NO);
}

void SGSetEnabled(NSString *key, BOOL on) {
    [NSUserDefaults.standardUserDefaults setBool:on forKey:key];
}

NSInteger SGInt(NSString *key, NSInteger fallback) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:key];
    return value ? [value integerValue] : fallback;
}

void SGSetInt(NSString *key, NSInteger value) {
    [NSUserDefaults.standardUserDefaults setInteger:value forKey:key];
}

NSString *const SGFlagOverridePrefix = @"spotifyglass.flag.";

id SGFlagOverride(NSString *key) {
    return [NSUserDefaults.standardUserDefaults objectForKey:[SGFlagOverridePrefix stringByAppendingString:key]];
}

void SGSetFlagOverride(NSString *key, id value) {
    key = [SGFlagOverridePrefix stringByAppendingString:key];
    if (value) [NSUserDefaults.standardUserDefaults setObject:value forKey:key];
    else [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
}
