//
//  JSTalk.m
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTalk.h"
#import "JSTListener.h"
#import "JSTPreprocessor.h"
#import <ScriptingBridge/ScriptingBridge.h>
#import "MochaRuntime.h"
#import "MOMethod.h"
#import "MOUndefined.h"
#import "MOBridgeSupportController.h"

extern int *_NSGetArgc(void);
extern char ***_NSGetArgv(void);

static BOOL JSTalkShouldLoadJSTPlugins = YES;
static NSMutableArray *JSTalkPluginList;

@interface Mocha (Private)
- (JSValueRef)setObject:(id)object withName:(NSString *)name;
- (BOOL)removeObjectWithName:(NSString *)name;
- (JSValueRef)callJSFunction:(JSObjectRef)jsFunction withArgumentsInArray:(NSArray *)arguments;

@end

@interface JSTalk (Private)
- (void) print:(NSString*)s;
@end


@implementation JSTalk
@synthesize printController=_printController;
@synthesize errorController=_errorController;
@synthesize env=_env;
@synthesize shouldPreprocess=_shouldPreprocess;

+ (void)listen {
    [JSTListener listen];
}

+ (void)setShouldLoadExtras:(BOOL)b {
    JSTalkShouldLoadJSTPlugins = b;
}

+ (void)setShouldLoadJSTPlugins:(BOOL)b {
    JSTalkShouldLoadJSTPlugins = b;
}

- (id)init {
	self = [super init];
	if ((self != nil)) {
        _mochaRuntime = [[Mocha alloc] init];
        
        self.env = [NSMutableDictionary dictionary];
        _shouldPreprocess = YES;
        
        [self addExtrasToRuntime];
	}
    
	return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (JSGlobalContextRef)context {
    return [_mochaRuntime context];
}

- (void)addExtrasToRuntime {
    
    [self pushObject:self withName:@"jstalk"];
    [_mochaRuntime evalString:@"var nil=null;\n"];
    [_mochaRuntime setValue:[MOMethod methodWithTarget:self selector:@selector(print:)] forKey:@"print"];
    
    [_mochaRuntime loadFrameworkWithName:@"AppKit"];
    [_mochaRuntime loadFrameworkWithName:@"Foundation"];
}

+ (void)loadExtraAtPath:(NSString*)fullPath {
    
    Class pluginClass;
    
    @try {
        
        NSBundle *pluginBundle = [NSBundle bundleWithPath:fullPath];
        if (!pluginBundle) {
            return;
        }
        
        NSString *principalClassName = [[pluginBundle infoDictionary] objectForKey:@"NSPrincipalClass"];
        
        if (principalClassName && NSClassFromString(principalClassName)) {
            NSLog(@"The class %@ is already loaded, skipping the load of %@", principalClassName, fullPath);
            return;
        }
        
        [principalClassName class]; // force loading of it.
        
        NSError *err = nil;
        [pluginBundle loadAndReturnError:&err];
        
        if (err) {
            NSLog(@"Error loading plugin at %@", fullPath);
            NSLog(@"%@", err);
        }
        else if ((pluginClass = [pluginBundle principalClass])) {
            
            // do we want to actually do anything with em' at this point?
            
            NSString *bridgeSupportName = [[pluginBundle infoDictionary] objectForKey:@"BridgeSuportFileName"];
            
            if (bridgeSupportName) {
                NSString *bridgeSupportPath = [pluginBundle pathForResource:bridgeSupportName ofType:nil];
                
                NSError *outErr = nil;
                if (![[MOBridgeSupportController sharedController] loadBridgeSupportAtURL:[NSURL fileURLWithPath:bridgeSupportPath] error:&outErr]) {
                    NSLog(@"Could not load bridge support file at %@", bridgeSupportPath);
                }
            }
        }
        else {
            //debug(@"Could not load the principal class of %@", fullPath);
            //debug(@"infoDictionary: %@", [pluginBundle infoDictionary]);
        }
        
    }
    @catch (NSException * e) {
        NSLog(@"EXCEPTION: %@: %@", [e name], e);
    }
    
}

+ (void)resetPlugins {
    JSTalkPluginList = nil;
}

+ (void)loadPlugins {
    
    // install plugins that were passed via the command line
    int i = 0;
    char **argv = *_NSGetArgv();
    for (i = 0; argv[i] != NULL; ++i) {
        
        NSString *a = [NSString stringWithUTF8String:argv[i]];
        
        if ([@"-jstplugin" isEqualToString:a]) {
            i++;
            NSLog(@"Loading plugin at: [%@]", [NSString stringWithUTF8String:argv[i]]);
            [self loadExtraAtPath:[NSString stringWithUTF8String:argv[i]]];
        }
    }
    
    JSTalkPluginList = [NSMutableArray array];
    
    NSString *appSupport = @"Library/Application Support/JSTalk/Plug-ins";
    NSString *appPath    = [[NSBundle mainBundle] builtInPlugInsPath];
    NSString *sysPath    = [@"/" stringByAppendingPathComponent:appSupport];
    NSString *userPath   = [NSHomeDirectory() stringByAppendingPathComponent:appSupport];
    
    
    // only make the JSTalk dir if we're JSTalkEditor.
    // or don't ever make it, since you'll get rejected from the App Store. *sigh*
    /*
    if (![[NSFileManager defaultManager] fileExistsAtPath:userPath]) {
        
        NSString *mainBundleId = [[NSBundle mainBundle] bundleIdentifier];
        
        if ([@"org.jstalk.JSTalkEditor" isEqualToString:mainBundleId]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:userPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
    }
    */
    
    for (NSString *folder in [NSArray arrayWithObjects:appPath, sysPath, userPath, nil]) {
        
        for (NSString *bundle in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil]) {
            
            if (!([bundle hasSuffix:@".jstplugin"])) {
                continue;
            }
            
            [self loadExtraAtPath:[folder stringByAppendingPathComponent:bundle]];
        }
    }
    
    if (![[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"org.jstalk.JSTalkEditor"]) {
        
        NSURL *jst = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:@"org.jstalk.JSTalkEditor"];
        
        if (jst) {
            
            NSURL *folder = [[jst URLByAppendingPathComponent:@"Contents"] URLByAppendingPathComponent:@"PlugIns"];
            
            for (NSString *bundle in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[folder path] error:nil]) {
                
                if (!([bundle hasSuffix:@".jstplugin"])) {
                    continue;
                }
                
                [self loadExtraAtPath:[[folder path] stringByAppendingPathComponent:bundle]];
            }
        }
    }
}

+ (void)loadBridgeSupportFileAtURL:(NSURL*)url {
    NSError *outErr = nil;
    if (![[MOBridgeSupportController sharedController] loadBridgeSupportAtURL:url error:&outErr]) {
        NSLog(@"Could not load bridge support file at %@", url);
    }
}

NSString *currentJSTalkThreadIdentifier = @"org.jstalk.currentJSTalkHack";

+ (JSTalk*)currentJSTalk {
    return [[[NSThread currentThread] threadDictionary] objectForKey:currentJSTalkThreadIdentifier];
}

- (void)pushAsCurrentJSTalk {
    [[[NSThread currentThread] threadDictionary] setObject:self forKey:currentJSTalkThreadIdentifier];
}

- (void)popAsCurrentJSTalk {
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:currentJSTalkThreadIdentifier];
}

- (void)pushObject:(id)obj withName:(NSString*)name  {
    [_mochaRuntime setObject:obj withName:name];
}

- (void)deleteObjectWithName:(NSString*)name {
    [_mochaRuntime removeObjectWithName:name];
}


- (id)executeString:(NSString*)str {
    
    if (!JSTalkPluginList && JSTalkShouldLoadJSTPlugins) {
        [JSTalk loadPlugins];
    }
    
    if (_shouldPreprocess) {
        str = [JSTPreprocessor preprocessCode:str];
    }
    
    [self pushAsCurrentJSTalk];
    
    id resultObj = nil;
    
    @try {
        
        resultObj = [_mochaRuntime evalString:str];
        
        if (resultObj == [MOUndefined undefined]) {
            resultObj = nil;
        }
    }
    @catch (NSException *e) {
        
        NSDictionary *d = [e userInfo];
        if ([d objectForKey:@"line"]) {
            if ([_errorController respondsToSelector:@selector(JSTalk:hadError:onLineNumber:atSourceURL:)]) {
                [_errorController JSTalk:self hadError:[e reason] onLineNumber:[[d objectForKey:@"line"] integerValue] atSourceURL:nil];
            }
        }
        
        NSLog(@"Exception: %@", [e userInfo]);
        [self print:[e description]];
    }
    @finally {
        //
    }
    
    [self popAsCurrentJSTalk];
    
    return resultObj;
}

- (BOOL)hasFunctionNamed:(NSString*)name {
    
    JSValueRef exception = nil;
    JSStringRef jsFunctionName = JSStringCreateWithUTF8CString([name UTF8String]);
    JSValueRef jsFunctionValue = JSObjectGetProperty([_mochaRuntime context], JSContextGetGlobalObject([_mochaRuntime context]), jsFunctionName, &exception);
    JSStringRelease(jsFunctionName);
    
    
    return jsFunctionValue && (JSValueGetType([_mochaRuntime context], jsFunctionValue) == kJSTypeObject);
}

- (id)callFunctionNamed:(NSString*)name withArguments:(NSArray*)args {
    
    id returnValue = nil;
    
    @try {
        
        [self pushAsCurrentJSTalk];
        
        returnValue = [_mochaRuntime callFunctionWithName:name withArgumentsInArray:args];
        
        if (returnValue == [MOUndefined undefined]) {
            returnValue = nil;
        }
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
        [self print:[e description]];
    }
    
    [self popAsCurrentJSTalk];
    
    return returnValue;
}


- (JSValueRef)callJSFunction:(JSObjectRef)jsFunction withArgumentsInArray:(NSArray *)arguments {
    [self pushAsCurrentJSTalk];
    JSValueRef r = [_mochaRuntime callJSFunction:jsFunction withArgumentsInArray:arguments];
    [self popAsCurrentJSTalk];
    return r;
}

// JavaScriptCore isn't safe for recursion.  So calling this function from
// within a script is a really bad idea.  Of couse, that's what it was written
// for, so it really needs to be taken out.

- (void)include:(NSString*)fileName {
    
    if (![fileName hasPrefix:@"/"] && [_env objectForKey:@"scriptURL"]) {
        NSString *parentDir = [[[_env objectForKey:@"scriptURL"] path] stringByDeletingLastPathComponent];
        fileName = [parentDir stringByAppendingPathComponent:fileName];
    }
    
    NSURL *scriptURL = [NSURL fileURLWithPath:fileName];
    NSError *err = nil;
    NSString *str = [NSString stringWithContentsOfURL:scriptURL encoding:NSUTF8StringEncoding error:&err];
    
    if (!str) {
        NSLog(@"Could not open file '%@'", scriptURL);
        NSLog(@"Error: %@", err);
        return;
    }
    
    if (_shouldPreprocess) {
        str = [JSTPreprocessor preprocessCode:str];
    }
    
    [_mochaRuntime evalString:str];
}

- (void)print:(NSString*)s {
    
    if (_printController && [_printController respondsToSelector:@selector(print:)]) {
        [_printController print:s];
    }
    else {
        if (![s isKindOfClass:[NSString class]]) {
            s = [s description];
        }
        
        printf("%s\n", [s UTF8String]);
    }
}


+ (id)applicationOnPort:(NSString*)port {
    
    NSConnection *conn  = nil;
    NSUInteger tries    = 0;
    
    while (!conn && tries < 10) {
        
        conn = [NSConnection connectionWithRegisteredName:port host:nil];
        tries++;
        if (!conn) {
            debug(@"Sleeping, waiting for %@ to open", port);
            sleep(1);
        }
    }
    
    if (!conn) {
        NSBeep();
        NSLog(@"Could not find a JSTalk connection to %@", port);
    }
    
    return [conn rootProxy];
}

+ (id)application:(NSString*)app {
    
    NSString *appPath = [[NSWorkspace sharedWorkspace] fullPathForApplication:app];
    
    if (!appPath) {
        NSLog(@"Could not find application '%@'", app);
        // fixme: why are we returning a bool?
        return [NSNumber numberWithBool:NO];
    }
    
    NSBundle *appBundle = [NSBundle bundleWithPath:appPath];
    NSString *bundleId  = [appBundle bundleIdentifier];
    
    // make sure it's running
	NSArray *runningApps = [[[NSWorkspace sharedWorkspace] launchedApplications] valueForKey:@"NSApplicationBundleIdentifier"];
    
	if (![runningApps containsObject:bundleId]) {
        BOOL launched = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bundleId
                                                                             options:NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync
                                                      additionalEventParamDescriptor:nil
                                                                    launchIdentifier:nil];
        if (!launched) {
            NSLog(@"Could not open up %@", appPath);
            return nil;
        }
    }
    
    
    return [self applicationOnPort:[NSString stringWithFormat:@"%@.JSTalk", bundleId]];
}

+ (id)app:(NSString*)app {
    return [self application:app];
}

+ (id)proxyForApp:(NSString*)app {
    return [self application:app];
}


@end



