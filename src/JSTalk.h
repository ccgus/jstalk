//
//  JSTalk.h
//  jstalk
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class Mocha;
@interface JSTalk : NSObject {
    id _printController;
    id _errorController;
    NSMutableDictionary *_env;
    BOOL _shouldPreprocess;
    Mocha *_mochaRuntime;
}

@property (assign) id printController;
@property (assign) id errorController;
@property (retain) NSMutableDictionary *env;
@property (assign) BOOL shouldPreprocess;

- (id)executeString:(NSString*) str;
- (void)pushObject:(id)obj withName:(NSString*)name;
- (void)deleteObjectWithName:(NSString*)name;

- (Mocha*)mochaRuntime;
- (id)callFunctionNamed:(NSString*)name withArguments:(NSArray*)args;

+ (void)listen;
+ (void)resetPlugins;
+ (void)loadPlugins;
+ (void)setShouldLoadJSTPlugins:(BOOL)b;
+ (id)application:(NSString*)app;
+ (id)app:(NSString*)app;
+ (JSTalk*)currentJSTalk;

@end

@interface NSObject (JSTalkErrorControllerMethods)
- (void)JSTalk:(JSTalk*)jstalk hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url;
@end
