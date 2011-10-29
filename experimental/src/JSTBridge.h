//
//  JSTBridge.h
//  jstalk
//
//  Created by August Mueller on 9/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSTBridgeSupportLoader.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <sys/mman.h>
#import <assert.h>
#import <dlfcn.h>

@class JSTFunction;

@interface JSTBridge : NSObject {
    JSGlobalContextRef  _jsContext;
    JSClassRef _globalObjectClass;
    JSClassRef _bridgedObjectClass;
    JSClassRef _bridgedFunctionClass;
    
    JSTFunction *_jstMsgSendFunction;
    JSObjectRef _jstMsgSendJSFunctionRef;
    
    id _delegate;
}


@property (assign) id delegate;
@property (assign) JSGlobalContextRef jsContext;

- (void)pushObject:(id)obj withName:(NSString*)name;

- (JSValueRef)evalJSString:(NSString*)script withPath:(NSString*)path;

- (id)NSObjectForJSObject:(JSObjectRef)jsObj;
- (JSTRuntimeInfo*)runtimeInfoForObject:(id)obj;

- (JSObjectRef)makeJSObjectWithNSObject:(id)obj runtimeInfo:(JSTRuntimeInfo*)info;

- (JSClassRef)bridgedObjectClass;

@end

@interface NSObject (JSTDelegate)
- (void)bridge:(JSTBridge*)bridge hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourcePath:(id)url;
@end
