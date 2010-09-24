//
//  JSTBridge.m
//  jstalk
//
//  Created by August Mueller on 9/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTBridge.h"

// JSObjectGetPropertyCallback
JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception);
JSValueRef JSTBridge_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);

void JSTBridge_objectInitialize(JSContextRef ctx, JSObjectRef object); // JSObjectInitializeCallback
void JSTBridge_objectFinalize(JSObjectRef object); // JSObjectFinalizeCallback


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
        
        bridgedObjectDefinition.initialize           = JSTBridge_objectInitialize;
        bridgedObjectDefinition.finalize             = JSTBridge_objectFinalize;
        
        /*
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
        
        
        JSClassDefinition bridgedFunctionDefinition    = kJSClassDefinitionEmpty;
        bridgedFunctionDefinition.className            = "JSCocoa box";
        bridgedFunctionDefinition.parentClass          = _bridgedObjectClass;
        bridgedFunctionDefinition.callAsFunction       = JSTBridge_callAsFunction;
        
        _bridgedFunctionClass = JSClassCreate(&bridgedFunctionDefinition);
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

- (JSObjectRef)makeBridgedObject:(JSTBridgedObject **)bridgedObject runtimeInfo:(JSTRuntimeInfo*)info {
    *bridgedObject = [[JSTBridgedObject alloc] initWithRuntimeInfo:info];
    return JSObjectMake(_jsContext, _bridgedObjectClass, *bridgedObject);
}

- (JSObjectRef)makeBridgedFunction:(JSTBridgedObject **)bridgedObject runtimeInfo:(JSTRuntimeInfo*)info {
    *bridgedObject = [[JSTBridgedObject alloc] initWithRuntimeInfo:info];
    return JSObjectMake(_jsContext, _bridgedFunctionClass, *bridgedObject);
}

- (JSTBridgedObject*)bridgedObjectForJSObject:(JSObjectRef)jsObj {
    return (JSTBridgedObject*)JSObjectGetPrivate(jsObj);
}


- (void)pushObject:(id)obj withName:(NSString*)name  {
    
    JSStringRef propName = JSStringCreateWithUTF8CString([name UTF8String]);
    
    JSTBridgedObject *bridgedObject;
    JSObjectRef jsObject = [self makeBridgedObject:&bridgedObject runtimeInfo:nil];
    [bridgedObject setObject:obj];
    
    JSObjectSetProperty(_jsContext, JSContextGetGlobalObject(_jsContext), propName, jsObject, 0, NULL);
    JSStringRelease(propName);
}

- (JSValueRef)propertyForObject:(JSObjectRef)object named:(JSStringRef)jsPropertyName outException:(JSValueRef*)exception {
    
    NSString *propertyName          = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, jsPropertyName);
    JSValueRef returnJSObject       = 0x00;
    JSTBridgedObject *bridgedObject = 0x00;
    
    JSTRuntimeInfo *info = [JSTBridgeSupportLoader runtimeInfoForSymbol:propertyName];
    
    if (info) {
        
        debug(@"Found bridge info for: '%@'", propertyName);
        
        if ([info objectType] == JSTClass) {
            debug(@"It's a class!");
            returnJSObject = [self makeBridgedObject:&bridgedObject runtimeInfo:info];
            
            
        }
        else if ([info objectType] == JSTFunction) {
            
            returnJSObject = [self makeBridgedFunction:&bridgedObject runtimeInfo:info];
            
            debug(@"it's a function");
            /*
            JSObjectRef jsRef               = [JSCocoaController jsCocoaPrivateFunctionInContext:ctx];
            private.runtimeInfo             = bridgedObjectInfo;
            
            jstrace(@"%@ is a function (jsRef: %p)", propertyName, jsRef);
            
            return jsRef;
            */
        }
        else if ([info objectType] == JSTStruct) {
            debug(@"it's a struct");
            
        }
        else if (([info objectType] == JSTConstant)) {
            
            // in the case of NSBundleDidLoadNotification, it's declaredType is NSString*, so we need to trim it up to find the symbol info
            NSString *fixedDeclaredType = [info declaredType];
            while ([fixedDeclaredType hasSuffix:@"*"]) {
                fixedDeclaredType = [fixedDeclaredType substringToIndex:[fixedDeclaredType length] - 1];
            }
            
            JSTRuntimeInfo *constInfo = [[JSTBridgeSupportLoader sharedController] runtimeInfoForSymbol:fixedDeclaredType];
            if (!constInfo) {
                constInfo = info;
            }
            
            
            void *symbol = dlsym(RTLD_DEFAULT, [propertyName UTF8String]);
            if (!symbol) {
                NSLog(@"%s:%d", __FUNCTION__, __LINE__);
                NSLog(@"symbol %@ not found", propertyName);
                return nil;
            }
            
            if ([constInfo objectType] == JSTClass) {
                returnJSObject = [self makeBridgedObject:&bridgedObject runtimeInfo:constInfo];
                [bridgedObject setObject:*(id*)symbol];
            }
            else if ([[constInfo typeEncoding] isEqualToString:@"B"]) {
                returnJSObject = JSValueMakeBoolean(_jsContext, *(bool*)symbol);
            }
        }
        else if ([info objectType] == JSTEnum) {
            returnJSObject = JSValueMakeNumber(_jsContext, [info enumValue]);
        }
    }
    else { // info is nil.
        
        
        // well, we can always fall back on NSClassFromString.
        
        Class runtimeClass = NSClassFromString(propertyName);
        if (runtimeClass) {
            debug(@"%@ found in runtime", propertyName);
            returnJSObject = [self makeBridgedObject:&bridgedObject runtimeInfo:0x00];
            [bridgedObject setObject:runtimeClass];
        }
        
        // bummer.  Let's see if we can look it up in the runtime
    }
    
    if (!returnJSObject) {
        debug(@"Can't find any info for '%@'", propertyName);
    }
    
    return returnJSObject;
}

- (JSValueRef)callFunction:(JSObjectRef)function onObject:(JSObjectRef)thisObject argCount:(size_t)argumentCount arguments:(const JSValueRef*)arguments outException:(JSValueRef*)exception {
    
    JSTBridgedObject *bridgedFunction       = [self bridgedObjectForJSObject:function];
    JSTBridgedObject *bridgedFunctionCaller = [self bridgedObjectForJSObject:thisObject];
    
    debug(@"bridgedFunctionCaller: '%@'", bridgedFunctionCaller);
    
    bridgedFunctionCaller = ((id)bridgedFunctionCaller == self) ? nil : bridgedFunctionCaller;
    
    
    
    debug(@"function call: %@ %@", bridgedFunction, [[bridgedFunction runtimeInfo] symbolName]);
    
    //debug(@"bridgedFunctionCaller: %@ %@", bridgedFunctionCaller, [[bridgedFunctionCaller runtimeInfo] symbolName]);
    
    
    return nil;
}

- (void)initializeObject:(JSObjectRef)jsObject {
    //JSTBridgedObject *bridgedObject = [self bridgedObjectForJSObject:jsObject];
}

@end



JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    return [(JSTBridge*)JSObjectGetPrivate(object) propertyForObject:object named:propertyName outException:exception];
}

void JSTBridge_objectInitialize(JSContextRef ctx, JSObjectRef object) {
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) initializeObject:object];
}

// @abstract The callback invoked when an object is finalized (prepared for garbage collection). An object may be finalized on any thread.
// So yea, don't do much here thank you very much.
void JSTBridge_objectFinalize(JSObjectRef object) {
    [(JSTBridge*)JSObjectGetPrivate(object) release];
}

JSValueRef JSTBridge_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) callFunction:function onObject:thisObject argCount:argumentCount arguments:arguments outException:exception];
}





