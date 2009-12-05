#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>



@interface JavaScriptPluginEnabler :  VPPlugin <VPEventRunner,VPURLHandler>  {
    NSTextView *_nonRetainedCurrentTextView;
}

- (NSString*) scriptsDir;
- (void) registerScript:(NSString*)scriptPath;

- (void) handleRunAsJavaScript:(id<VPPluginWindowController>)windowController;
- (void) runScript:(NSString*)script withWindowController:(id<VPPluginWindowController>)windowController;

@end

extern JavaScriptPluginEnabler *JavaScriptPluginEnablerGlobalHACKHACKHACK;
