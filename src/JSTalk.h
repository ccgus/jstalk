//
//  JSTalk.h
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSTBridge.h"

@interface JSTalk : NSObject {
    id _printController;
    id _errorController;
    JSTBridge *_bridge;
    NSMutableDictionary *_env;
    BOOL _shouldPreprocess;
}

@property (assign) id printController;
@property (assign) id errorController;
@property (retain) JSTBridge *bridge;
@property (retain) NSMutableDictionary *env;
@property (assign) BOOL shouldPreprocess;

- (id)executeString:(NSString*)str;
//- (void)pushObject:(id)obj withName:(NSString*)name;
- (void)deleteObjectWithName:(NSString*)name;

- (id)callFunctionNamed:(NSString*)name withArguments:(NSArray*)args;

+ (void)listen;
+ (void)resetPlugins;
+ (void)setShouldLoadJSTPlugins:(BOOL)b;
+ (id)application:(NSString*)app;
+ (id)app:(NSString*)app;

@end

// this is used by the preprocessor, to return strings back for cases of @"foo".
// so, [@"foo" uppercaseString] will be turned into objc_msgSend(JSTNSString("foo"), "uppercaseString");
// and it just does the right thing.  It'll return itself, but it forces the conversion of the js string into a cocoa string
NSString *JSTNSString(NSString *s);
