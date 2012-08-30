/*
 Not only does this plugin load up the JSTalk Listener, so we can talk to Acorn via JSTalk, it also adds support for JavaScript Plugins, via Acorn's plugin API.
 */


#import "JSEnablerPlugIn.h"
#import "ACPlugin.h"
#import "JSTalk.h"
#import "JSCocoa.h"
#import <JavaScriptCore/JavaScriptCore.h>

#define ACScriptMenuTitleKey @"ACScriptMenuTitle"
#define ACScriptSuperMenuTitleKey @"ACScriptSuperMenuTitle"
#define ACShortcutKeyKey @"ACShortcutKey"
#define ACShortcutMaskKey @"ACShortcutMask"
#define ACIsActionKey @"ACIsAction"

@interface JSEnablerPlugIn (SuperSecret)
- (void)findJSCocoaScriptsForPluginManager:(id<ACPluginManager>)pluginManager;
@end


@implementation JSEnablerPlugIn

+ (id)plugin {
    return [[[self alloc] init] autorelease];
}


- (void)didRegister {
    
    // this guy openes up a Distributed Objects port to listen for outside JSTalk commands commands
    [JSTalk listen];
}

- (void)willRegister:(id<ACPluginManager>)pluginManager {
    [self findJSCocoaScriptsForPluginManager:pluginManager];
}

- (NSDictionary*)propertiesFromScriptAtPath:(NSString*)path {
    
    NSError *err = 0x00;
    NSMutableString *s = [NSMutableString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    if (!s) {
        NSLog(@"Error reading %@: %@", path, err);
        return nil;
    }
    
    // clean up some line endings.
    [s replaceOccurrencesOfString:@"\r\n" withString:@"\n" options:0 range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"\r" withString:@"\n" options:0 range:NSMakeRange(0, [s length])];
    
    NSMutableDictionary *d              = [NSMutableDictionary dictionary];
    NSString *menuTitle                 = nil;
    NSString *shortcutKey               = @"";
    NSString *superMenuTitle            = nil;
    int shortcutMask                    = 0;
    NSEnumerator *enumerator            = [[s componentsSeparatedByString:@"\n"] objectEnumerator];
    NSString *line;
    BOOL isAction                       = NO;
    
    while ((line = [enumerator nextObject])) {
    	
        if ([line hasPrefix:@"VPEndConfig"]) {
            break;
        }
        else if ([line hasPrefix:ACScriptMenuTitleKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                menuTitle = [[line substringFromIndex:eqIdx+1]
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:ACScriptSuperMenuTitleKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                superMenuTitle = [[line substringFromIndex:eqIdx+1]
                                  stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:ACShortcutKeyKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                shortcutKey = [[line substringFromIndex:eqIdx+1]
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            }
        }
        else if ([line hasPrefix:ACIsActionKey]) {
            int eqIdx = [line rangeOfString:@"="].location;
            if (eqIdx != NSNotFound && [line length] > eqIdx + 1) {
                NSString *val = [[line substringFromIndex:eqIdx+1]
                               stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                isAction = [val boolValue];
            }
        }
        else if ([line hasPrefix:ACShortcutMaskKey]) {
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
    
    
    if (menuTitle) {
        [d setObject:menuTitle forKey:ACScriptMenuTitleKey];
    }
    
    if (superMenuTitle) {
        [d setObject:superMenuTitle forKey:ACScriptSuperMenuTitleKey];
    }
    
    if (shortcutKey) {
        [d setObject:shortcutKey forKey:ACShortcutKeyKey];
    }
    
    [d setObject:[NSNumber numberWithInt:shortcutMask] forKey:ACShortcutMaskKey];
    [d setObject:[NSNumber numberWithBool:isAction] forKey:ACIsActionKey];
    
    return d;
}


- (void)findJSCocoaScriptsForPluginManager:(id<ACPluginManager>)pluginManager {
    
    NSString *pluginDir = [@"~/Library/Application Support/Acorn/Plug-Ins/" stringByExpandingTildeInPath];
    NSFileManager *fm   = [NSFileManager defaultManager];
    BOOL isDir          = NO;
    
    if (!([fm fileExistsAtPath:pluginDir isDirectory:&isDir] && isDir)) {
        return;
    }
    
    for (NSString *fileName in [fm contentsOfDirectoryAtPath:pluginDir error:nil]) {
        
        if (!([fileName hasSuffix:@".js"] || [fileName hasSuffix:@".jscocoa"] || [fileName hasSuffix:@".jstalk"])) {
            continue;
        }
        
        NSDictionary *scriptProperties      = [self propertiesFromScriptAtPath:[pluginDir stringByAppendingPathComponent:fileName]];
        
        
        NSString *menuTitle                 = [scriptProperties objectForKey:ACScriptMenuTitleKey];
        menuTitle                           = menuTitle ? menuTitle : [fileName stringByDeletingPathExtension];
        
        NSString *shortcutKey               = [scriptProperties objectForKey:ACShortcutKeyKey];
        shortcutKey                         = shortcutKey ? shortcutKey : @"";
        
        NSString *superMenuTitle            = [scriptProperties objectForKey:ACScriptSuperMenuTitleKey];
        NSUInteger shortcutMask             = [[scriptProperties objectForKey:ACShortcutMaskKey] unsignedIntegerValue];
        
        
        if ([[scriptProperties objectForKey:ACIsActionKey] boolValue]) {
            [pluginManager addActionMenuTitle:menuTitle
                           withSuperMenuTitle:superMenuTitle
                                       target:self
                                       action:@selector(executeScriptForImage:scriptPath:)
                                keyEquivalent:shortcutKey
                    keyEquivalentModifierMask:shortcutMask
                                   userObject:[pluginDir stringByAppendingPathComponent:fileName]];
        }
        else {
            
            [pluginManager addFilterMenuTitle:menuTitle
                           withSuperMenuTitle:superMenuTitle
                                       target:self
                                       action:@selector(executeScriptForImage:scriptPath:)
                                keyEquivalent:shortcutKey
                    keyEquivalentModifierMask:shortcutMask
                                   userObject:[pluginDir stringByAppendingPathComponent:fileName]];
        }
    }
}


- (void)setInt:(int)val withName:(NSString*)name jstalk:(JSTalk*)jstalk {
    [jstalk executeString:[NSString stringWithFormat:@"var %@=%d;", name, val]];
}

- (void)JSTalk:(JSTalk*)jstalk hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url {
    NSLog(@"Error executing script on line %ld", (long)lineNumber);
    NSLog(@"%@", error);
}

- (CIImage*)executeScriptForImage:(id<ACLayer>)currentLayer scriptPath:(NSString*)scriptPath {
    
    NSError *err            = 0x00;
    NSString *theJavaScript = [NSString stringWithContentsOfFile:scriptPath encoding:NSUTF8StringEncoding error:&err];
    
    if (err) {
        NSBeep();
        NSLog(@"%@", err);
        return nil;
    }
    
    CIImage *image = [currentLayer CIImage];
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    [jstalk setErrorController:self];
    
    // gen_bridge_metadata -c '-I.' ACPlugin.h > Acorn.bridgesupport
    /*
    NSURL *acornBridgesupportURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Acorn" withExtension:@"bridgesupport"];
    if (acornBridgesupportURL) {
        [JSTalk loadBridgeSupportFileAtURL:acornBridgesupportURL];
    }
    else {
        NSLog(@"Acorn.bridgesupport is missing");
    }*/
    
    // add some defines that are around in the ACPlugin.h header.  This should really be in a bridge support
    // xml file, but it's grabbing the values as Objects right now.  I'll have to figure out what's going on
    // and bring this back in some day.
    /*
    [self setInt:ACBitmapLayer withName:@"ACBitmapLayer" jstalk:jstalk];
    [self setInt:ACBitmapLayer withName:@"ACShapeLayer"  jstalk:jstalk];
    [self setInt:ACGroupLayer  withName:@"ACGroupLayer"  jstalk:jstalk];
    
    [self setInt:ACRectangleGraphic  withName:@"ACRectangleGraphic" jstalk:jstalk];
    [self setInt:ACOvalGraphic       withName:@"ACOvalGraphic"      jstalk:jstalk];
    [self setInt:ACLineGraphic       withName:@"ACLineGraphic"      jstalk:jstalk];
    [self setInt:ACTextGraphic       withName:@"ACTextGraphic"      jstalk:jstalk];
    [self setInt:ACImageGraphic      withName:@"ACImageGraphic"     jstalk:jstalk];
    [self setInt:ACBezierGraphic     withName:@"ACBezierGraphic"    jstalk:jstalk];
    */
    
    
    [jstalk executeString:theJavaScript];
    
    /*
    Our script should look, at least a little bit like this:
    function main(image, doc, layer) {
        // do fancy image stuff
        return image;
    }
    */
    
    id document = [(id)currentLayer valueForKey:@"document"]; // shh!
    
    JSValueRef returnValue = [[jstalk jsController] callJSFunctionNamed:@"main" withArguments:image, document, currentLayer, nil];
    
    // Hurray?
    // The main() method should be returning a value at this point, so we're going to 
    // put it back into a cocoa object.  If it's not there, then it'll be nil and that's 
    // ok for our purposes.
    CIImage *acornReturnValue = 0x00;
    
    if (![JSCocoaFFIArgument unboxJSValueRef:returnValue toObject:&acornReturnValue inContext:[[jstalk jsController] ctx]]) {
        return nil;
    }
    
    // fin.
    return acornReturnValue;
}

- (NSNumber*)worksOnShapeLayers:(id)userObject {
    return [NSNumber numberWithBool:YES];
}

- (NSNumber*)validateForLayer:(id)userObject {
    return [NSNumber numberWithBool:YES];
}

@end



