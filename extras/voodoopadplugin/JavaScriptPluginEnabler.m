//
//  SketchPageController.m
//  SketchPage
//
//  Created by August Mueller on 4/21/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import "JavaScriptPluginEnabler.h"

#import <JSTalk/JSTalk.h>

#define VPLanguageKey @"VPLanguage"
#define VPScriptMenuTitleKey @"VPScriptMenuTitle"
#define VPScriptSuperMenuTitleKey @"VPScriptSuperMenuTitle"
#define VPShortcutKeyKey @"VPShortcutKey"
#define VPShortcutMaskKey @"VPShortcutMask"
#define VPBackgroundThreadKey @"VPBackgroundThread"

@interface NSObject (VPAppDelegateExtrase)
- (void) console:(NSString*)s;
@end


@interface JavaScriptPluginEnabler (Private)
- (NSDictionary*) propertiesFromScriptAtPath:(NSString*)path;
- (void) runPluginViaAppleScript:(id)windowController userObject:(id)userObject properties:(NSDictionary*)asProperties;
@end

@implementation JavaScriptPluginEnabler

@synthesize scriptsData=_scriptsData;

- (void)dealloc {
	[_scriptsData release];
	[super dealloc];
}


- (id)init {
	self = [super init];
    if (self) {
        [self setScriptsData:[NSMutableDictionary dictionary]];
    }
    
	return self;
}

- (void) didRegister {
    
    NSString *scriptsDir = [self scriptsDir];
    if (!scriptsDir) {
        NSLog(@"Could not find Script PlugIns directory");
        return;
    }
    
    NSArray *scriptsFolder      = [[NSFileManager defaultManager] directoryContentsAtPath:scriptsDir];
    NSEnumerator *enumerator    = [scriptsFolder objectEnumerator];
    NSString *fileName;
    NSString *filePath;
    while ((fileName = [enumerator nextObject])) {
    	filePath = [scriptsDir stringByAppendingPathComponent:fileName];
        [self registerScript:filePath];
    }
    
    [[self pluginManager] addPluginsMenuTitle:@"Run Page as JavaScript"
                           withSuperMenuTitle:@"JavaScript"
                                       target:self
                                       action:@selector(handleRunAsJavaScript:)
                                keyEquivalent:@";"
                    keyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
    
    [[self pluginManager] addPluginsMenuTitle:[NSString stringWithFormat:@"Save Page as JavaScript Plugin%C", 0x2026]
                           withSuperMenuTitle:@"JavaScript"
                                       target:self
                                       action:@selector(handleSaveAsJavaScript:)
                                keyEquivalent:@""
                    keyEquivalentModifierMask:0];
    
    [[self pluginManager] registerPluginAppleScriptName:@"JavaScript Script"
                                                 target:self
                                                 action:@selector(runScriptAction:)];
    
    [[self pluginManager] registerEventRunner:self forLanguage:@"JavaScript"];
    
    
    // this guy openes up a port to listen for outside JSTalk commands commands
    [JSTalk listen];
}

- (BOOL) runScript:(NSString *)script forEvent:(NSString*)eventName withEventDictionary:(NSMutableDictionary*)eventDictionary {
    // todo
    return NO;
}


- (void)savePanelDidEndForSaveAsJavaScript:(NSSavePanel *)savePanel
                         returnCode:(int)returnCode
                        contextInfo:(id<VPPluginWindowController>)windowController
{
    if (returnCode == NSOKButton) {
        NSString *s = [[windowController textView] string];
        
        [[s dataUsingEncoding:NSUTF8StringEncoding] writeToFile:[savePanel filename] atomically:YES];
        
        [self registerScript:[savePanel filename]];
        
        // privateness, please ignore.
        [[self pluginManager] performSelector:@selector(sortMenu)];
    }
}

- (void) handleSaveAsJavaScript:(id<VPPluginWindowController>)windowController {
    
    NSString *key = [windowController key];
    
    NSString *displayName = [[[windowController document] vpDataForKey:key] displayName];
    
    if (!displayName) {
        NSLog(@"I could not figure out the name of this page!");
        NSBeep();
        return;
    }
    
    NSString *name = [NSString stringWithFormat:@"%@.js", displayName];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    [savePanel setPrompt:NSLocalizedString(@"Save", @"Save")];
    [savePanel setTitle:NSLocalizedString(@"Save as JavaScript Plugin", @"Save as JavaScript Plugin")];
    
    [savePanel beginSheetForDirectory:[self scriptsDir] 
                                 file:name
                       modalForWindow:[windowController window]
                        modalDelegate:self
                       didEndSelector:@selector(savePanelDidEndForSaveAsJavaScript:returnCode:contextInfo:)
                          contextInfo:windowController];
}

- (void) handleRunAsJavaScript:(id<VPPluginWindowController>)windowController {
    
    _nonRetainedCurrentTextView = [windowController textView];
    
    NSString *buffer = [[[windowController textView] textStorage] mutableString];
    
    NSRange r = [[windowController textView] selectedRange];
    if (r.length > 0) {
        buffer = [buffer substringWithRange:r];
        
        // now put the insertion point at the end of the selection.
        r.location += r.length;
        r.length = 0;
        [[windowController textView] setSelectedRange:r];
    }
    
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    JSCocoaController *jsController = [jstalk jsController];
    
    jsController.exceptionHandler = self;
    
    jstalk.printController = self;
    
    [jstalk executeString:buffer];
    
    _nonRetainedCurrentTextView = 0x00;
    
}



- (void) handleRunScript:(id<VPPluginWindowController>)windowController userObject:(id)userObject {
    // todo
}



- (NSDictionary*) propertiesFromScriptAtPath:(NSString*)path {
    
    NSMutableString *s = [NSMutableString stringWithContentsOfFile:path];
    if (!s) {
        return nil;
    }
    
    // clean up some line endings.
    [s replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, [s length])];
    
    NSMutableDictionary *d              = [NSMutableDictionary dictionary];
    NSString *lang                      = 0x00;
    NSString *menuTitle                 = 0x00;
    NSString *shortcutKey               = @"";
    NSString *superMenuTitle            = nil;
    int shortcutMask                    = 0x00;
    BOOL backgroundThread               = 0x00;
    NSEnumerator *enumerator            = [[s componentsSeparatedByString:@"\n"] objectEnumerator];
    NSString *line;
    
    while ((line = [enumerator nextObject])) {
    	
        if ([line hasPrefix:@"VPEndConfig"]) {
            break;
        }
        else if ([line hasPrefix:VPLanguageKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                lang = [[line substringFromIndex:eqIdx+1]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPScriptMenuTitleKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                menuTitle = [[line substringFromIndex:eqIdx+1]
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPScriptSuperMenuTitleKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                superMenuTitle = [[line substringFromIndex:eqIdx+1]
                                  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPBackgroundThreadKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                
                NSString *junk = [[line substringFromIndex:eqIdx+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                backgroundThread = [@"true" isEqualToString:junk];
            }
        }
        else if ([line hasPrefix:VPShortcutKeyKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                shortcutKey = [[line substringFromIndex:eqIdx+1]
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPShortcutMaskKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                NSString *junk = [[line substringFromIndex:eqIdx+1]
                                  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                
                junk = [junk lowercaseString];
                
                if ([junk rangeOfString:@"command"].location != NSNotFound) {
                    shortcutMask = shortcutMask | NSCommandKeyMask;
                }
                if ([junk rangeOfString:@"option"].location != NSNotFound) {
                    shortcutMask = shortcutMask | NSAlternateKeyMask;
                }
                if ([junk rangeOfString:@"shift"].location != NSNotFound) {
                    shortcutMask = shortcutMask | NSShiftKeyMask;
                }
                if ([junk rangeOfString:@"control"].location != NSNotFound) {
                    shortcutMask = shortcutMask | NSControlKeyMask;
                }
            }
        }
    }
    
    if (lang) {
        [d setObject:lang forKey:VPLanguageKey];
    }
    else if ([[path lowercaseString] hasSuffix:@".js"]) {
        [d setObject:@"javascript" forKey:VPLanguageKey];
        [d setObject:@"JavaScript" forKey:VPScriptSuperMenuTitleKey];
        [d setObject:[[path lastPathComponent] stringByDeletingPathExtension] forKey:VPScriptMenuTitleKey];
    }
    if (menuTitle) {
        [d setObject:menuTitle forKey:VPScriptMenuTitleKey];
    }
    if (superMenuTitle) {
        [d setObject:superMenuTitle forKey:VPScriptSuperMenuTitleKey];
    }
    if (shortcutKey) {
        [d setObject:shortcutKey forKey:VPShortcutKeyKey];
    }
    
    [d setObject:[NSNumber numberWithBool:backgroundThread] forKey:VPBackgroundThreadKey];
    [d setObject:[NSNumber numberWithInt:shortcutMask] forKey:VPShortcutMaskKey];
    
    return d;
}

- (void) registerScript:(NSString*)scriptPath {
    
    NSMutableString *s = [NSMutableString stringWithContentsOfFile:scriptPath];
    if (!s) {
        return;
    }
    
    id <VPPluginManager> pluginManager  = [self pluginManager];
    NSDictionary *scriptProperties      = [self propertiesFromScriptAtPath:scriptPath];
    
    if (![scriptProperties objectForKey:VPLanguageKey] || ![@"javascript" isEqualToString:[scriptProperties objectForKey:VPLanguageKey]]) {
        // we dont' handle anything but javascript right now.
        return;
    }
    
    NSString *menuTitle                 = [scriptProperties objectForKey:VPScriptMenuTitleKey];
    menuTitle                           = menuTitle ? menuTitle : [scriptPath lastPathComponent];
    NSString *shortcutKey               = [scriptProperties objectForKey:VPShortcutKeyKey];
    shortcutKey                         = shortcutKey ? shortcutKey : @"";
    NSString *superMenuTitle            = [scriptProperties objectForKey:VPScriptSuperMenuTitleKey];
    int shortcutMask                    = [[scriptProperties objectForKey:VPShortcutMaskKey] intValue];
    
    [pluginManager addPluginsMenuTitle:menuTitle
                    withSuperMenuTitle:superMenuTitle
                                target:self
                                action:@selector(handleRunScript:userObject:)
                         keyEquivalent:shortcutKey
             keyEquivalentModifierMask:shortcutMask
                            userObject:[scriptPath retain]];
    
}

- (NSString*) scriptsDir {
    
    NSString *scriptPluginDir = [@"~/Library/Application Support/VoodooPad/Script PlugIns" stringByExpandingTildeInPath];
    BOOL isDir;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:scriptPluginDir isDirectory:&isDir] &&  isDir) {
        return scriptPluginDir;
    }
    
    if ([fm createDirectoryAtPath:scriptPluginDir attributes:nil]) {
        return scriptPluginDir;
    }
    
    return nil;
}



- (void) print:(NSString*)s {
    [[NSApp delegate] console:s];
}

- (void) jscontroller:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber {
    
    lineNumber -= 2;
    
    if (!error) {
        return;
    }
    
    if (lineNumber < 0) {
        [self print:error];
    }
    else {
        [self print:[NSString stringWithFormat:@"Line %d, %@", lineNumber, error]];
        
        NSUInteger lineIdx = 0;
        NSRange lineRange  = NSMakeRange(0, 0);
        
        while (lineIdx < lineNumber) {
            
            lineRange = [[[_nonRetainedCurrentTextView textStorage] string] lineRangeForRange:NSMakeRange(NSMaxRange(lineRange), 0)];
            lineIdx++;
        }
        
        if (lineRange.length) {
            [_nonRetainedCurrentTextView showFindIndicatorForRange:lineRange];
        }
    }
}






@end
