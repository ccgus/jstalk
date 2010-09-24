//
//  JSTBridge.m
//  jstalk
//
//  Created by August Mueller on 9/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTBridge.h"

// Global resolver : main class used as 'this' in Javascript's global scope. Name requests go through here.
JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception);


@implementation JSTBridge
@synthesize jsContext=_jsContext;


- (id) init {
	self = [super init];
	
    if (self != nil) {
        JSClassDefinition globalObjectDefinition    = kJSClassDefinitionEmpty;
        globalObjectDefinition.className            = "JSTBridge";
        globalObjectDefinition.getProperty          = JSTBridge_getProperty;
        _jsContext                                  = JSGlobalContextCreate(_globalObjectClass);
        
        //JSObjectMake(_jsContext, _globalObjectClass, self);
        
        //JSObjectSetPrivate(_jsContext, self);
        
	}
    
	return self;
}



- (void)dealloc {
    
    if (_jsContext) {
        JSGarbageCollect(_jsContext);
    }
    
    JSGlobalContextRelease(_jsContext);
    
    [super dealloc];
}

- (JSValueRef)evalJSString:(NSString*)script {
    
    debug(@"script: '%@'", script);
    
    JSStringRef scriptJS    = JSStringCreateWithCFString((CFStringRef)script);
    JSValueRef exception    = nil;
    JSStringRef scriptPath  = nil; //path ? JSStringCreateWithUTF8CString([path UTF8String]) : nil;
    JSValueRef result       = JSEvaluateScript(_jsContext, scriptJS, nil, scriptPath, 1, &exception);
    JSStringRelease(scriptJS);
    
    if (scriptPath) {
        JSStringRelease(scriptPath);
    }
    
    if (exception) {
        
        JSStringRef exceptionString = JSValueToStringCopy(_jsContext, exception, nil);
        NSString *nsExceptionString = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, exceptionString);
        JSStringRelease(exceptionString);
        
        debug(@"nsExceptionString: '%@'", nsExceptionString);
        
        [nsExceptionString release];
    }
    
    return result;
}


@end



JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception) {
    
    JSTBridge *bridge = JSObjectGetPrivate(object);
    
    debug(@"bridge: '%@'", bridge);
    
    NSString* propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, propertyNameJS);
    
    debug(@"propertyName: '%@'", propertyName);
    
    return nil;
}










