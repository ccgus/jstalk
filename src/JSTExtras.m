//
//  JSTExtras.m
//  jsenabler
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTExtras.h"
#import <ScriptingBridge/ScriptingBridge.h>

@implementation NSApplication (JSTExtras)

- (id)open:(NSString*)pathToFile {
    
    NSError *err = 0x00;
    
    NSURL *url = [NSURL fileURLWithPath:pathToFile];
    
    id doc = [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:url
                                                                                    display:YES
                                                                                      error:&err];
    
    if (err) {
        NSLog(@"Error: %@", err);
        return nil;
    }
    
    return doc;
}

- (void) activate {
    ProcessSerialNumber xpsn = { 0, kCurrentProcess };
    SetFrontProcess( &xpsn );
}

- (NSInteger) displayDialog:(NSString*)msg withTitle:(NSString*) title {
    
    NSAlert *alert = [NSAlert alertWithMessageText:title defaultButton:nil alternateButton:nil otherButton:nil informativeTextWithFormat:msg];
    
    NSInteger button = [alert runModal];
    
    return button;
}

- (NSInteger) displayDialog:(NSString*)msg {
    
    NSString *title = [[[NSBundle mainBundle] infoDictionary] objectForKey:(id)kCFBundleNameKey];
    
    if (!title) {
        title = @"Unknown Application";
    }
    
    return [self displayDialog:msg withTitle:title];
}

- (id) sharedDocumentController {
    return [NSDocumentController sharedDocumentController];
}

- (id) standardUserDefaults {
    return [NSUserDefaults standardUserDefaults];
}

@end


@implementation NSDocument (JSTExtras)

- (id) dataOfType:(NSString*)type {
    
    NSError *err = 0x00;
    
    NSData *data = [self dataOfType:type error:&err];
    
    
    return data;
    
}

@end


@implementation NSData (JSTExtras)

- (BOOL) writeToFile:(NSString*)path {
    
    return [self writeToURL:[NSURL fileURLWithPath:path] atomically:YES];
}

@end

@implementation NSObject (JSTExtras)

- (Class) ojbcClass {
    return [self class];
}

@end


@implementation SBApplication (JSTExtras)

+ (id) application:(NSString*)appName {
    
    NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:appName];
    
    if (!appPath) {
        NSLog(@"Could not find application '%@'", appName);
        return nil;
    }
    
    NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
    NSString *bundleId  = [appBundle bundleIdentifier];
    
    return [SBApplication applicationWithBundleIdentifier:bundleId];
}


@end



@implementation NSString (JSTExtras)

- (NSURL*) fileURL {
    return [NSURL fileURLWithPath:self];
}

@end





