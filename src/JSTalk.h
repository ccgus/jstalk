//
//  JSTalk.h
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JSCocoaController;

@interface JSTalk : NSObject {
    id _printController;
    id _errorController;
    JSCocoaController *_jsController;
    NSMutableDictionary *_env;
    BOOL _shouldPreprocess;
}

@property (assign) id printController;
@property (assign) id errorController;
@property (retain) JSCocoaController *jsController;
@property (retain) NSMutableDictionary *env;
@property (assign) BOOL shouldPreprocess;

- (id)executeString:(NSString*) str;
- (void)pushObject:(id)obj withName:(NSString*)name;
- (void)deleteObjectWithName:(NSString*)name;

- (JSCocoaController*)jsController;
- (id)callFunctionNamed:(NSString*)name withArguments:(NSArray*)args;
- (BOOL)hasFunctionNamed:(NSString*)name;

+ (void)loadBridgeSupportFileAtURL:(NSURL*)url;
+ (void)listen;
+ (void)resetPlugins;
+ (void)loadPlugins;
+ (void)setShouldLoadJSTPlugins:(BOOL)b;
+ (id)application:(NSString*)app;
+ (id)app:(NSString*)app;
+ (JSTalk*)currentJSTalk;

@end

@interface NSObject (JSTalkDelegate)
- (void)JSTalk:(JSTalk*)jstalk hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url;
@end
