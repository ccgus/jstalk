#import <Cocoa/Cocoa.h>
#import <JSTalk/JSTalk.h>

@interface JSTalkEverywhere : NSObject {
    
}

@end

@implementation JSTalkEverywhere

+ (void) load {
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    if (![bundleIdentifier isEqualToString:@"com.flyingmeat.JSTalkEditor"]) {
        [JSTalk listen];
    }
}


@end
