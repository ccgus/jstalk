/*
Not only does this plugin load up the JSTalk Listener, so we can talk to VoodooPad via JSTalk, it also adds support for JavaScript Plugins, via VP's plugin API.
*/

#import "JavaScriptPluginEnabler.h"

#import <JSTalk/JSTalk.h>

#define VPLanguageKey @"VPLanguage"
#define VPScriptMenuTitleKey @"VPScriptMenuTitle"
#define VPScriptSuperMenuTitleKey @"VPScriptSuperMenuTitle"
#define VPShortcutKeyKey @"VPShortcutKey"
#define VPShortcutMaskKey @"VPShortcutMask"
#define VPBackgroundThreadKey @"VPBackgroundThread"

JavaScriptPluginEnabler *JavaScriptPluginEnablerGlobalHACKHACKHACK;

@interface NSObject (VPAppDelegateExtrase)
- (void) console:(NSString*)s;
@end


@interface JavaScriptPluginEnabler (Private)
- (NSDictionary*) propertiesFromScriptAtPath:(NSString*)path;
@end

@implementation JavaScriptPluginEnabler


- (void) didRegister {

    JavaScriptPluginEnablerGlobalHACKHACKHACK = self;
    
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
    
    [[self pluginManager] addPluginsMenuTitle:@"Run Page as JSTalk"
                           withSuperMenuTitle:@"JSTalk"
                                       target:self
                                       action:@selector(handleRunAsJavaScript:)
                                keyEquivalent:@";"
                    keyEquivalentModifierMask:NSCommandKeyMask | NSControlKeyMask];
    
    [[self pluginManager] addPluginsMenuTitle:[NSString stringWithFormat:@"Save Page as JSTalk Plugin%C", 0x2026]
                           withSuperMenuTitle:@"JSTalk"
                                       target:self
                                       action:@selector(handleSaveAsJavaScript:)
                                keyEquivalent:@""
                    keyEquivalentModifierMask:0];
    
    [[self pluginManager] addPluginsMenuTitle:[NSString stringWithFormat:@"Copy as JSTalk Bookmarklet"]
                           withSuperMenuTitle:@"JSTalk"
                                       target:self
                                       action:@selector(copyBookmarkletToPasteboard:)
                                keyEquivalent:@""
                    keyEquivalentModifierMask:0];
                    
    [[self pluginManager] registerPluginAppleScriptName:@"JSTalk Script"
                                                 target:self
                                                 action:@selector(runScriptAction:)];
    
    [[self pluginManager] registerEventRunner:self forLanguage:@"JSTalk"];
    
    [[self pluginManager] registerURLHandler:self];
    
    // this guy openes up a port to listen for outside JSTalk commands commands
    [JSTalk listen];
}

- (BOOL) runScript:(NSString *)script forEvent:(NSString*)eventName withEventDictionary:(NSMutableDictionary*)eventDictionary {
    // todo
    return NO;
}

- (BOOL) canHandleURL:(NSString*)theUrl {
    return [theUrl hasPrefix:@"jstalk:"] || [theUrl hasPrefix:@"javascript:"];
}


- (BOOL) handleURL:(NSString*)theURL {
    
    if ([theURL hasPrefix:@"jstalk:"]) {
        theURL = [theURL substringWithRange:NSMakeRange(7, [theURL length] - 7)];
    }
    else if ([theURL hasPrefix:@"javascript:"]) {
        theURL = [theURL substringWithRange:NSMakeRange(11, [theURL length] - 11)];
    }
    else {
        // ...?
        return NO;
    }
    
    NSWindowController *wc = 0x00;
    NSDocument *currentDoc = [[NSDocumentController sharedDocumentController] currentDocument];
    
    // let's see if we can figure out what the current window controller is.
    if (currentDoc && [[currentDoc windowControllers] count]) {
        NSWindowController *currentWindowController = [[currentDoc windowControllers] objectAtIndex:0];
        
        // we're really just making an educated guess as to this being the right window controller.  I'm assuming someone's clicking on 
        // a link.
        if ([[currentWindowController window] isMainWindow]) {
            wc = currentWindowController;
        }
    }
    
    NSString *theSource = [theURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    [self runScript:theSource withWindowController:(id)wc];
    
    return YES;
}


- (void) copyBookmarkletToPasteboard:(id<VPPluginWindowController>)windowController {
    
    
    NSRange r = [[windowController textView] selectedRange];
    
    NSString *selectedText = 0x00;
    
    if (r.length == 0) {
        selectedText = [[[windowController textView] textStorage] string];
    }
    else {
        selectedText = [[[[windowController textView] textStorage] string] substringWithRange:r];
    }
    
    NSString *bookmarklet = [NSString stringWithFormat:@"javascript:%@", [selectedText stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSDictionary *atts = [NSDictionary dictionaryWithObject:bookmarklet forKey:NSLinkAttributeName];
    
    NSAttributedString *ats = [[[NSMutableAttributedString alloc] initWithString:@"JSTalk Bookmarklet" attributes:atts] autorelease];
    
    NSData *atsData = [ats RTFFromRange:NSMakeRange(0, [ats length]) documentAttributes:nil];
    
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    
    [pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, NSRTFPboardType, nil] owner:nil];
    [pb setString:bookmarklet forType:NSStringPboardType];
    [pb setData:atsData forType:NSRTFPboardType];
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
    
    NSString *name = [NSString stringWithFormat:@"%@.jstalk", displayName];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    [savePanel setPrompt:NSLocalizedString(@"Save", @"Save")];
    [savePanel setTitle:NSLocalizedString(@"Save as JSTalk Plugin", @"Save as JSTalk Plugin")];
    
    [savePanel beginSheetForDirectory:[self scriptsDir] 
                                 file:name
                       modalForWindow:[windowController window]
                        modalDelegate:self
                       didEndSelector:@selector(savePanelDidEndForSaveAsJavaScript:returnCode:contextInfo:)
                          contextInfo:windowController];
}

- (void) runScript:(NSString*)script withWindowController:(id<VPPluginWindowController>)windowController {
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    [jstalk pushObject:windowController withName:@"windowController"];
    [jstalk pushObject:[windowController document] withName:@"document"];
    
    JSCocoaController *jsController = [jstalk jsController];
    
    jsController.delegate = self;
    
    jstalk.printController = self;
    
    [jstalk executeString:script];
    
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
    
    [self runScript:buffer withWindowController:windowController];
    
    _nonRetainedCurrentTextView = 0x00;
    
}



- (void) handleRunScript:(id<VPPluginWindowController>)windowController userObject:(id)userObject {
    // todo
    
    NSError *err = 0x00;
    NSString *script = [NSString stringWithContentsOfFile:userObject encoding:NSUTF8StringEncoding error:&err];
    
    if (!script) {
        NSLog(@"Could not read script: %@", err);
        return;
    }
    
    [self runScript:script withWindowController:windowController];
}



- (NSDictionary*) propertiesFromScriptAtPath:(NSString*)path {
    
    NSMutableString *s = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
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
            NSInteger eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                lang = [[line substringFromIndex:eqIdx+1]
                        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPScriptMenuTitleKey]) {
            NSInteger eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                menuTitle = [[line substringFromIndex:eqIdx+1]
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPScriptSuperMenuTitleKey]) {
            NSInteger eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                superMenuTitle = [[line substringFromIndex:eqIdx+1]
                                  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPBackgroundThreadKey]) {
            NSInteger eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                
                NSString *junk = [[line substringFromIndex:eqIdx+1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                backgroundThread = [@"true" isEqualToString:junk];
            }
        }
        else if ([line hasPrefix:VPShortcutKeyKey]) {
            NSInteger eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                shortcutKey = [[line substringFromIndex:eqIdx+1]
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:VPShortcutMaskKey]) {
            NSInteger eqIdx = [line rangeOfString:@"="].location;
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
    
    NSMutableString *s = [NSMutableString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:nil];
    if (!s) {
        return;
    }
    
    id <VPPluginManager> pluginManager  = [self pluginManager];
    NSDictionary *scriptProperties      = [self propertiesFromScriptAtPath:scriptPath];
    
    if (!([scriptPath hasSuffix:@".jstalk"] || [scriptPath hasSuffix:@".jscocoa"] || [scriptPath hasSuffix:@".javascript"] || [scriptPath hasSuffix:@".js"])){
        return;
    }
    
    NSString *menuTitle                 = [scriptProperties objectForKey:VPScriptMenuTitleKey];
    menuTitle                           = menuTitle ? menuTitle : [[scriptPath lastPathComponent] stringByDeletingPathExtension];
    NSString *shortcutKey               = [scriptProperties objectForKey:VPShortcutKeyKey];
    shortcutKey                         = shortcutKey ? shortcutKey : @"";
    NSString *superMenuTitle            = [scriptProperties objectForKey:VPScriptSuperMenuTitleKey];
    int shortcutMask                    = [[scriptProperties objectForKey:VPShortcutMaskKey] intValue];
    
    superMenuTitle = superMenuTitle ? superMenuTitle : @"JSTalk";
    
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

- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url {
    
    lineNumber -= 1;
    
    if (!error) {
        return;
    }
    
    if (lineNumber < 0) {
        [self print:error];
    }
    else {
        [self print:[NSString stringWithFormat:@"Line %d, %@", lineNumber, error]];
        
        if (_nonRetainedCurrentTextView) {
            
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
}

- (BOOL) validateAction:(SEL)anAction forPageType:(NSString*)pageType userObject:(id)userObject {
    return YES;
}

@end
