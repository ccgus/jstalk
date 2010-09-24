//
//  JSTalk.h
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSCocoaController.h"
#import "JSTBridge.h"

@interface JSTalk : NSObject {
    id _printController;
    id _errorController;
    JSCocoaController *_jsController;
    JSTBridge *_bridge;
    NSMutableDictionary *_env;
}

@property (assign) id printController;
@property (assign) id errorController;
@property (retain) JSCocoaController *jsController;
@property (retain) JSTBridge *bridge;
@property (retain) NSMutableDictionary *env;

- (id)executeString:(NSString*) str;
//- (void)pushObject:(id)obj withName:(NSString*)name;
- (void)deleteObjectWithName:(NSString*)name;

- (JSCocoaController*)jsController;
- (id)callFunctionNamed:(NSString*)name withArguments:(NSArray*)args;

+ (void)listen;
+ (void)resetPlugins;
+ (void)setShouldLoadJSTPlugins:(BOOL)b;
+ (id)application:(NSString*)app;

@end
