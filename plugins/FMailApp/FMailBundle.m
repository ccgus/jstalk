//
//  FMailBundle.m
//  FMailApp
//
//  Created by August Mueller on 12/12/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "FMailBundle.h"
#import <objc/objc-runtime.h>
#import <JSTalk/JSTalk.h>


void TSPrintMethodNamesFromClass(Class c) {
    
    if (!c) {
        return;
    }
    
    
    unsigned int outCount;
    Method *methods = class_copyMethodList(c, &outCount);
    
    
    for (int i = 0; i < outCount; i++) {
        Method method = methods[i];
        if (method == NULL) {
            continue;
        }
        
        //NSString *methodName = NSStringFromSelector(method_getName(method));
        
        printf("%s: %s\n", [NSStringFromClass(c) UTF8String], method_getName(method));
        
    }
    
    free(methods);
    
    TSPrintMethodNamesFromClass(class_getSuperclass(c));
    
}

NSString *FRewrapLines(NSString *s, int len) {
    
    NSMutableString *ret = [NSMutableString string];
    
    
    s = [s stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
    
    for (NSString *line in [s componentsSeparatedByString:@"\n"]) {
        
        if (![line length]) {
            [ret appendString:@"\n"];
            continue;
        }
        
        int idx = 0;
        
        while ((idx < [line length]) && ([line characterAtIndex:idx] == '>')) {
            idx++;
        }
        
        NSMutableString *pre = [NSMutableString string];
        
        for (int i = 0; i < idx; i++) {
            [pre appendString:@">"];
        }
        
        NSString *oldLine = [line substringFromIndex:idx];
        
        NSMutableString *newLine = [NSMutableString string];
        
        [newLine appendString:pre];
        
        for (NSString *word in [oldLine componentsSeparatedByString:@" "]) {
            
            if ([newLine length] + [word length] > len) {
                [ret appendString:newLine];
                [ret appendString:@"\n"];
                [newLine setString:pre];
            }
            
            if ([word length] && [newLine length]) {
                [newLine appendString:@" "];
            }
            
            [newLine appendString:word];
            
        }
        
        [ret appendString:newLine];
        [ret appendString:@"\n"];
        
    }
    
    return ret;
    
    
}



#define VPLanguageKey @"VPLanguage"
#define VPScriptMenuTitleKey @"VPScriptMenuTitle"
#define VPScriptSuperMenuTitleKey @"VPScriptSuperMenuTitle"
#define VPShortcutKeyKey @"VPShortcutKey"
#define VPShortcutMaskKey @"VPShortcutMask"
#define VPBackgroundThreadKey @"VPBackgroundThread"

NSDictionary*  FPropertiesFromScriptAtPath(NSString* path) {
    
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


















@implementation FMailBundle

+ (void)load {

    [self performSelector:@selector(install:) withObject:nil afterDelay:0.0];
}

+ (void)install:(id)sender {
    
    NSMenu *mainMenu    = [NSApp mainMenu];
    
    if (!mainMenu) {
        NSLog(@"crap.");
        return;
    }
    
    /*
    if ([[NSBundle bundleWithPath:@"/Volumes/srv/Users/gus/Library/Frameworks/FScript.framework"] load]) {
        [NSClassFromString(@"FScriptMenuItem") performSelector:@selector(insertInMainMenu)];
    }
    */
    
    
    //NSMenuItem *jstalkMenu = [mainMenu addItemWithTitle:@"JSTalk" action:@selector(foob:) keyEquivalent:@""];
    
    NSMenuItem *jstalkMenu = [mainMenu insertItemWithTitle:@"JSTalk" action:nil keyEquivalent:@"" atIndex:8];
    
    NSString *imagePath = [[NSBundle bundleForClass:[self class]] pathForImageResource:@"jstalkstatusicon"];
    
    [jstalkMenu setImage:[[[NSImage alloc] initByReferencingFile:imagePath] autorelease]];
    
    NSMenu *jstalkSubmenu = [[[NSMenu alloc] initWithTitle:@"JSTalk"] autorelease];
    
    [jstalkMenu setSubmenu:jstalkSubmenu];
    
    
    
    NSString *scriptDir = [@"~/Library/Application Support/JSTalk/Mail" stringByExpandingTildeInPath];
    for (NSString *path in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:scriptDir error:0x00]) {
        if (![path hasSuffix:@".jstalk"]) {
            continue;
        }
        
        NSString *scriptPath            = [scriptDir stringByAppendingPathComponent:path];
        NSDictionary *scriptProperties  = FPropertiesFromScriptAtPath(scriptPath);
        NSString *shortcutKey           = [scriptProperties objectForKey:VPShortcutKeyKey];
        shortcutKey                     = shortcutKey ? shortcutKey : @"";
        int shortcutMask                = [[scriptProperties objectForKey:VPShortcutMaskKey] intValue];
        
        NSMenuItem *item = [[jstalkMenu submenu] addItemWithTitle:[path stringByDeletingPathExtension] action:@selector(runJSTalkScriptFromSender:) keyEquivalent:shortcutKey];
        
        [item setKeyEquivalentModifierMask:shortcutMask];
        [item setRepresentedObject:[scriptDir stringByAppendingPathComponent:path]];
    }
}

@end

@interface NSObject (MessageWebHTMLViewStuff)

- (void) selectAll;
- (void) insertText:(NSString*)shudup;
@end



@implementation NSObject (Additions)

/*
- (void) hackattack:(id)Sender {
    
    NSMutableString *rawSource = [self valueForKeyPath:@"window.delegate.backEnd.plainTextMessage.rawSource.mutableCopy.autorelease"];
    
    [rawSource replaceOccurrencesOfString:@"=\n" withString:@"" options:0 range:NSMakeRange(0, [rawSource length])];
    [rawSource replaceOccurrencesOfString:@"=20\n" withString:@"\n" options:0 range:NSMakeRange(0, [rawSource length])];
    
    [self selectAll];
    [self insertText:FRewrapLines(rawSource, 72)];
}
*/

- (void) runJSTalkScriptFromSender:(id)sender {
    
    
    if (![sender respondsToSelector:@selector(representedObject)]) {
        return;
    }
    
    NSString *path = [sender representedObject];
    if (!path || ![path isKindOfClass:[NSString class]]) {
        return;
    }
    
    JSTalk *jst = [[[JSTalk alloc] init] autorelease];
    
    NSString *source = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    if (!source) {
        NSLog(@"Could not read the file at %@", path);
        return;
    }
    
    [jst.env setObject:self forKey:@"caller"];
    
    id result = [jst executeString:source];
    if (result) {
        NSLog(@"%@", [result description]);
    }
}

@end



/*
+ (id)allBundles 
+ (id)composeAccessoryViewOwners;
+ (void)registerBundle;
+ (id)sharedInstance;
+ (BOOL)hasPreferencesPanel;
+ (id)preferencesOwnerClassName;
+ (id)preferencesPanelName;
+ (BOOL)hasComposeAccessoryViewOwner;
+ (id)composeAccessoryViewOwnerClassName;
- (void)dealloc;
- (void)_registerBundleForNotifications;
*/
