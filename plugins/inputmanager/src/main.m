#import <Cocoa/Cocoa.h>
#import <JSTalk/JSTalk.h>

@interface JSTalkEverywhere : NSObject {
    
}

@end

@implementation JSTalkEverywhere

+ (void)load {
    
    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    
    if (![bundleIdentifier isEqualToString:@"com.flyingmeat.JSTalkEditor"]) {
        [JSTalk listen];
    }
    
    [self performSelector:@selector(install:) withObject:nil afterDelay:0.0];
}

+ (void)install:(id)sender {
    
    NSMenu *mainMenu = [NSApp mainMenu];
    
    if (!mainMenu) {
        NSLog(@"crap.");
        return;
    }
    
    // install a separatorItem because it looks prettier that way.
    NSMenuItem *editMenu = [mainMenu itemWithTitle:@"Edit"];
    [[editMenu submenu] addItem:[NSMenuItem separatorItem]];
    
    
    // install our expansion stuff.
    NSMenuItem *jstalkItem = [[editMenu submenu] addItemWithTitle:@"Run as JSTalk" action:@selector(jstalkRun:) keyEquivalent:@"J"];
    [jstalkItem  setKeyEquivalentModifierMask: NSCommandKeyMask | NSShiftKeyMask];
    
    NSLog(@"jstalkItem: %@", jstalkItem);
    
}
    
    
@end
