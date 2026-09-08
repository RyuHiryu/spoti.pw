// Declarations the SDK Theos builds against does not have: iOS 26 API and private UIKit.
// Everything here is resolved at runtime; a call site checks respondsToSelector: first.
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIGlassEffect : UIVisualEffect
+ (instancetype)effectWithStyle:(NSInteger)style;
@property (nonatomic, copy) UIColor *tintColor;
@property (nonatomic, getter=isInteractive) BOOL interactive;
@end

@interface NSObject (SGiOS26)
+ (id)capsuleConfiguration;
+ (id)configurationWithUniformRadius:(id)radius;
+ (id)fixedRadius:(CGFloat)radius;
- (void)setCornerConfiguration:(id)configuration;
@end

@interface UIView (SGPrivate)
- (NSString *)recursiveDescription;
@end

@interface UIViewController (SGPrivate)
- (NSString *)_printHierarchy;
@end

@interface UIButtonConfiguration (SGiOS26)
+ (instancetype)glassButtonConfiguration;
+ (instancetype)prominentGlassButtonConfiguration;
@end

@interface UIImageView (SGiOS17)
- (void)addSymbolEffect:(id)effect;
@end

@interface NSObject (SGiOS17)
+ (id)effect;   // NSSymbolBounceEffect and the other symbol effects
@end
