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


- (id)init {
	self = [super init];
	
    if (self != nil) {
        JSClassDefinition globalObjectDefinition    = kJSClassDefinitionEmpty;
        globalObjectDefinition.className            = "JSTBridge";
        globalObjectDefinition.getProperty          = JSTBridge_getProperty;
        
        _globalObjectClass                          = JSClassCreate(&globalObjectDefinition);
        _jsContext                                  = JSGlobalContextCreate(_globalObjectClass);
                
        JSObjectSetPrivate(JSContextGetGlobalObject(_jsContext), self);
        
        JSClassDefinition bridgedObjectDefinition    = kJSClassDefinitionEmpty;
        bridgedObjectDefinition.className            = "JSTBridgedObject";
        /*
        jsCocoaObjectDefinition.initialize            = jsCocoaObject_initialize;
        jsCocoaObjectDefinition.finalize            = jsCocoaObject_finalize;
        //    jsCocoaObjectDefinition.hasProperty            = jsCocoaObject_hasProperty;
        jsCocoaObjectDefinition.getProperty            = jsCocoaObject_getProperty;
        jsCocoaObjectDefinition.setProperty            = jsCocoaObject_setProperty;
        jsCocoaObjectDefinition.deleteProperty        = jsCocoaObject_deleteProperty;
        jsCocoaObjectDefinition.getPropertyNames    = jsCocoaObject_getPropertyNames;
        //    jsCocoaObjectDefinition.callAsFunction        = jsCocoaObject_callAsFunction;
        jsCocoaObjectDefinition.callAsConstructor    = jsCocoaObject_callAsConstructor;
        //    jsCocoaObjectDefinition.hasInstance            = jsCocoaObject_hasInstance;
        jsCocoaObjectDefinition.convertToType        = jsCocoaObject_convertToType;
        */
        
        _bridgedObjectClass = JSClassCreate(&bridgedObjectDefinition);
        
        
        
        
        
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

- (void)pushObject:(id)obj withName:(NSString*)name  {
    
    
    JSStringRef propName            = JSStringCreateWithUTF8CString([name UTF8String]);
    JSTBridgedObject *bridgedObject = [[JSTBridgedObject alloc] init];
    JSObjectRef jsObject            = JSObjectMake(_jsContext, _bridgedObjectClass, bridgedObject);
    //private.type = @"@";
    [bridgedObject setObject:obj];
    
    JSObjectSetProperty(_jsContext, JSContextGetGlobalObject(_jsContext), propName, jsObject, 0, NULL);
    JSStringRelease(propName);
}

- (JSValueRef)propertyForObject:(JSObjectRef)object named:(JSStringRef)jsPropertyName outException:(JSValueRef*)exception {
    
    NSString* propertyName = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, jsPropertyName);
    debug(@"propertyName: '%@'", propertyName);
    
    return nil;
}


@end



JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    return [(JSTBridge*)JSObjectGetPrivate(object) propertyForObject:object named:propertyName outException:exception];
}








