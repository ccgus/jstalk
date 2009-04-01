#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>

@interface JavaScriptPluginEnabler :  VPPlugin <VPEventRunner>  {
    NSTextView *_nonRetainedCurrentTextView;
}

- (NSString*) scriptsDir;
- (void) registerScript:(NSString*)scriptPath;

@end
