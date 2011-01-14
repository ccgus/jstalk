//
//  JSTAppDelegate.m
//  jstalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTAppDelegate.h"
#import "JSTalk.h"

@interface JSTAppDelegate (PrivateStuff)
- (void)restoreWorkspace;
- (void)saveWorkspace;
- (void)loadExternalEditorPrefs;
- (void)updatePrefsFontField;
@end

void JSTUncaughtExceptionHandler(NSException *exception) {
    NSLog(@"Uncaught exception: %@", exception);
}

@implementation JSTAppDelegate

+ (void)initialize {
    
	NSMutableDictionary *defaultValues 	= [NSMutableDictionary dictionary];
    NSUserDefaults      *defaults 	 	= [NSUserDefaults standardUserDefaults];
    
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"rememberWorkspace"];
    [defaultValues setObject:[NSNumber numberWithBool:YES] forKey:@"clearConsoleOnRun"];
    [defaultValues setObject:@"com.apple.xcode"            forKey:@"externalEditor"];
    
    [defaults registerDefaults: defaultValues];
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    // Let's preload some bridge files.
    
    NSString *bridgeSupport = [[NSBundle bundleForClass:[JSTalk class]] pathForResource:@"JSTalk" ofType:@"bridgesupport"];
    
    if (bridgeSupport && ![[JSTBridgeSupportLoader sharedController] isBridgeSupportLoaded:bridgeSupport]) {
        if (![[JSTBridgeSupportLoader sharedController] loadBridgeSupportAtPath:bridgeSupport]) {
            NSLog(@"Could not load JSTalk's bridge support file: %@", bridgeSupport);
        }
    }
            
    
    /*
    [[JSTBridgeSupportLoader sharedController] loadFrameworkAtPath:@"/System/Library/Frameworks/Foundation.framework"];
    [[JSTBridgeSupportLoader sharedController] loadFrameworkAtPath:@"/System/Library/Frameworks/CoreFoundation.framework"];
    [[JSTBridgeSupportLoader sharedController] loadFrameworkAtPath:@"/System/Library/Frameworks/AppKit.framework"];
    [[JSTBridgeSupportLoader sharedController] loadFrameworkAtPath:@"/System/Library/Frameworks/ApplicationServices.framework"];
    [[JSTBridgeSupportLoader sharedController] loadFrameworkAtPath:@"/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/CoreGraphics.framework"];
    */
}

- (void)awakeFromNib {
    
    if ([JSTPrefs boolForKey:@"rememberWorkspace"]) {
        [self restoreWorkspace];
    }
    
    [JSTalk setShouldLoadJSTPlugins:YES];
    [JSTalk listen];
    
    NSSetUncaughtExceptionHandler(JSTUncaughtExceptionHandler);
    
    // register this object to handle the services stuff.
    [NSApp setServicesProvider:self];
    
    // have all the services menus get updated.
    NSUpdateDynamicServices();
}

- (IBAction)showPrefs:(id)sender {
    
    [self loadExternalEditorPrefs];
    [self updatePrefsFontField];
    
    if (![prefsWindow isVisible]) {
        [prefsWindow center];
    }
    
    [prefsWindow makeKeyAndOrderFront:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self saveWorkspace];
}

- (void)restoreWorkspace {
    
    NSArray *ar = [[NSUserDefaults standardUserDefaults] objectForKey:@"workspaceOpenDocuments"];
    
    for (NSString *path in ar) {
        
        if ([path hasSuffix:@".jstplugin"]) {
            debug(@"Skipping %@", path);
            continue;
        }
        
        [[NSDocumentController sharedDocumentController] openDocumentWithContentsOfURL:[NSURL fileURLWithPath:path] display:YES error:nil];
    }
}

- (void)saveWorkspace {
    
    NSMutableArray *openDocs = [NSMutableArray array];
    
    for (NSDocument *doc in [[NSDocumentController sharedDocumentController] documents]) {
        
        if ([doc fileURL]) {
            // saving the file alias would be better.
            [openDocs addObject:[[doc fileURL] path]];
        }
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:openDocs forKey:@"workspaceOpenDocuments"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)loadExternalEditorPrefs {
    
    NSString *editorId = [[NSUserDefaults standardUserDefaults] objectForKey:@"externalEditor"];
    
    NSWorkspace *ws     = [NSWorkspace sharedWorkspace];
    NSString *appPath   = [ws absolutePathForAppBundleWithIdentifier:editorId];
    NSString *appName   = nil;
    
    if (appPath) {
        
        NSBundle *appBundle  = [NSBundle bundleWithPath:appPath];
        NSString *bundleName = [appBundle objectForInfoDictionaryKey:@"CFBundleName"];
        
        if (bundleName) {
            appName = bundleName;
        }
    }
    
    if (!appName) {
        appName = @"Unknown";
    }
    
    [externalEditorField setStringValue:appName];
}

- (void)openPanelDidEndForExternalEditor:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode) {
        
        NSString *path = [sheet filename];
        
        NSBundle *appBundle = [NSBundle bundleWithPath:path];
        NSString *bundleId  = [appBundle bundleIdentifier];
        
        if (!bundleId) {
            NSBeep();
            NSLog(@"Could not load the bundle info for %@", bundleId);
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setObject:bundleId forKey:@"externalEditor"];
        
        [self loadExternalEditorPrefs];
        
    }
}

- (void)chooseExternalEditor:(id)sender {
    
    NSOpenPanel *p = [NSOpenPanel openPanel];
    
    [p setCanChooseFiles:YES];
    [p setCanChooseDirectories:NO];
    [p setAllowsMultipleSelection:NO];
    
    [p beginSheetForDirectory:@"/Applications"
                         file:nil
                        types:[NSArray arrayWithObjects:@"app", @"APPL", nil]
               modalForWindow:prefsWindow
                modalDelegate:self
               didEndSelector:@selector(openPanelDidEndForExternalEditor:returnCode:contextInfo:)
                  contextInfo:nil];
}

- (void)prefsChoosefont:(id)sender {
    
    [[NSFontManager sharedFontManager] setTarget:self];
    
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
    
}

- (void)changeFont:(id)sender {
    
    NSFont *f = [[sender fontPanel:NO] panelConvertFont:[self defaultEditorFont]];
    
    [self setDefaultEditorFont:f];
    
    [self updatePrefsFontField];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JSTFontChangeNotification" object:self];
    
}

- (void)updatePrefsFontField {
    NSFont *f = [self defaultEditorFont];
    [prefsFontField setStringValue:[NSString stringWithFormat:@"%@ %dfp", [f fontName],(int)[f pointSize]]];
}

- (void)setDefaultEditorFont:(NSFont*)f {
    NSData *fontAsData = [NSArchiver archivedDataWithRootObject:f];
    [[NSUserDefaults standardUserDefaults] setObject:fontAsData forKey: @"defaultFont"];
}

- (NSFont*)defaultEditorFont {
    
    NSFont *defaultFont = 0x00;
    
    NSData *d = [[NSUserDefaults standardUserDefaults] objectForKey:@"defaultFont"];
    if (d) {
        defaultFont = [NSUnarchiver unarchiveObjectWithData:d];
    }
    
    if (!defaultFont) {
        defaultFont = [NSFont fontWithName:@"Monaco" size:10];
    }
    
    if (!defaultFont) {
        defaultFont = [NSFont systemFontOfSize:12];
    }
    
    return defaultFont;
}


- (void)runAsJSTalkScript:(NSPasteboard *)pb userData:(NSDictionary *)userData error:(NSString **)error {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    // Test for strings on the pasteboard.
    NSArray *classes = [NSArray arrayWithObject:[NSString class]];
    NSDictionary *options = [NSDictionary dictionary];
    if (![pb canReadObjectForClasses:classes options:options])  {
        *error = NSLocalizedString(@"Error: couldn't read the text.", @"pboard couldn't give string.");
        return;
    }
    
    NSString *result = 0x00;
    NSString *script = [pb stringForType:NSPasteboardTypeString];
    
    debug(@"script: '%@'", script);
    
    @try {
        
        JSTalk *jstalk = [[JSTalk alloc] init];
        
        [[[NSThread currentThread] threadDictionary] setObject:jstalk forKey:@"org.jstalk.currentJSTalkContext"];
        
        result = [[jstalk executeString:script] description];
        
        //
        result = @"This doesn't work in the jstalk branch currently!";
        
        
        [[[NSThread currentThread] threadDictionary] removeObjectForKey:@"org.jstalk.currentJSTalkContext"];
        
        [jstalk release];
        
    }
    @catch (NSException *e) {
        
        *error = [e reason];
        return;
    }
    @finally {
        // um.?
    }
    
    // 4+4
    
    [pb clearContents];
    
    if (result) {
        [pb writeObjects:[NSArray arrayWithObject:result]];
    }
}

@end
