//
//  JSTBridge.m
//  jstalk
//
//  Created by August Mueller on 9/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTBridge.h"
#import "JSTFunction.h"
#import "JSTUtils.h"

// JSObjectGetPropertyCallback
JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception);
JSValueRef JSTBridge_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);


void       JSTClass_initialize(JSContextRef ctx, JSObjectRef object); // JSObjectInitializeCallback
void       JSTClass_finalize(JSObjectRef object); // JSObjectFinalizeCallback
JSValueRef JSTClass_convertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception);
JSValueRef JSTClass_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception);

static const char * JSTRuntimeAssociatedInfoKey = "jstri";

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
        bridgedObjectDefinition.className            = "id";
        
        bridgedObjectDefinition.initialize           = JSTClass_initialize;
        bridgedObjectDefinition.finalize             = JSTClass_finalize;
        bridgedObjectDefinition.convertToType        = JSTClass_convertToType;
        bridgedObjectDefinition.getProperty          = JSTClass_getProperty;
        
        
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
        bridgedFunctionDefinition.className            = "JSTFunction";
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

- (JSValueRef)evalJSString:(NSString*)script withPath:(NSString*)path {
    
    debug(@"script: '%@'", script);
    
    JSStringRef scriptJS    = JSStringCreateWithCFString((CFStringRef)script);
    JSValueRef exception    = nil;
    JSStringRef scriptPath  = path ? JSStringCreateWithUTF8CString([path UTF8String]) : nil;
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

- (JSObjectRef)makeJSObjectWithNSObject:(id)obj runtimeInfo:(JSTRuntimeInfo*)info {
    
    if (!obj) {
        return nil;
    }
    
    objc_setAssociatedObject(obj, &JSTRuntimeAssociatedInfoKey, info, OBJC_ASSOCIATION_ASSIGN);
    [obj retain];
    return JSObjectMake(_jsContext, _bridgedObjectClass, obj);
}

/*
- (JSObjectRef)makeJSObjectWithNSObject:(id*)bridgedObject runtimeInfo:(JSTRuntimeInfo*)info {
    objc_setAssociatedObject(*obj, &JSTRuntimeAssociatedInfoKey, info, OBJC_ASSOCIATION_ASSIGN);
    return JSObjectMake(_jsContext, _bridgedObjectClass, *bridgedObject);
}
*/

- (JSObjectRef)makeBridgedFunctionWithRuntimeInfo:(JSTRuntimeInfo*)info name:(NSString*)functionName {
    JSTFunction *function = [[JSTFunction alloc] initWithFunctionName:functionName bridge:self runtimeInfo:info];
    objc_setAssociatedObject(function, &JSTRuntimeAssociatedInfoKey, info, OBJC_ASSOCIATION_ASSIGN);
    return JSObjectMake(_jsContext, _bridgedFunctionClass, function);
}

- (JSTRuntimeInfo*)runtimeInfoForObject:(id)obj {
    return objc_getAssociatedObject(obj, &JSTRuntimeAssociatedInfoKey);
}

- (id)NSObjectForJSObject:(JSObjectRef)jsObj {
    return (id)JSObjectGetPrivate(jsObj);
}


- (JSTFunction*)functionForJSFunction:(JSObjectRef)jsObj {
    return (JSTFunction*)JSObjectGetPrivate(jsObj);
}


- (void)pushObject:(id)obj withName:(NSString*)name  {
    
    JSStringRef propName = JSStringCreateWithUTF8CString([name UTF8String]);
    JSObjectRef jsObject = [self makeJSObjectWithNSObject:obj runtimeInfo:nil];
    JSObjectSetProperty(_jsContext, JSContextGetGlobalObject(_jsContext), propName, jsObject, 0, NULL);
    JSStringRelease(propName);
}

- (JSValueRef)internalFunctionForJSObject:(JSObjectRef)object functionName:(NSString*)functionName outException:(JSValueRef*)exception {
    
    id target = [self NSObjectForJSObject:object];
    
    if (!target) {
        return nil;
    }
    
    JSTFunction *function = 0x00;
    
    if ([@"valueOf" isEqualToString:functionName]) {
        function = [[JSTValueOfFunction alloc] initWithTarget:target bridge:self];
    }
    else if ([@"toString" isEqualToString:functionName]) {
        function = [[JSTToStringFunction alloc] initWithTarget:target bridge:self];
    }
    else {
        NSLog(@"Unknown internal function name '%@'", functionName);
        JSTAssert(false);
    }
    
    return JSObjectMake(_jsContext, _bridgedFunctionClass, function);
}

- (JSValueRef)propertyForObject:(JSObjectRef)object named:(JSStringRef)jsPropertyName outException:(JSValueRef*)exception {
    
    NSString *propertyName      = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, jsPropertyName);
    JSValueRef returnJSObject   = 0x00;
    id returnNSObject           = 0x00;
    JSTRuntimeInfo *info        = [JSTBridgeSupportLoader runtimeInfoForSymbol:propertyName];
    
    
    if ([propertyName isEqualToString:@"valueOf"] || [propertyName isEqualToString:@"toString"]) {
        return [self internalFunctionForJSObject:object functionName:propertyName outException:exception];
    }
    
    
    if (info) {
        
        if ([info jstType] == JSTTypeClass) {
            returnNSObject = NSClassFromString(propertyName);
            returnJSObject = [self makeJSObjectWithNSObject:returnNSObject runtimeInfo:info];
        }
        else if ([info jstType] == JSTTypeFunction) {
            returnJSObject = [self makeBridgedFunctionWithRuntimeInfo:info name:propertyName];
            returnNSObject = [self NSObjectForJSObject:(JSObjectRef)returnJSObject];
        }
        else if ([info jstType] == JSTTypeStruct) {
            
        }
        else if (([info jstType] == JSTTypeConstant)) {
            
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
            
            if ([constInfo jstType] == JSTTypeClass) {
                id obj = *(id*)symbol;
                returnJSObject = [self makeJSObjectWithNSObject:obj runtimeInfo:constInfo];
            }
            else if ([[constInfo typeEncoding] isEqualToString:@"B"]) {
                returnJSObject = JSValueMakeBoolean(_jsContext, *(bool*)symbol);
            }
        }
        else if ([info jstType] == JSTTypeEnum) {
            returnJSObject = JSValueMakeNumber(_jsContext, [info enumValue]);
        }
    }
    else { // info is nil.
        
        
        // well, we can always fall back on NSClassFromString.
        
        Class runtimeClass = NSClassFromString(propertyName);
        if (runtimeClass) {
            returnJSObject = [self makeJSObjectWithNSObject:runtimeClass runtimeInfo:0x00];
        }
        
        if (!returnJSObject) {
            void *symbol = dlsym(RTLD_DEFAULT, [propertyName UTF8String]);
            
            if (symbol) {
                NSLog(@"FOUND THE SYMBOL IN THE RUNTIME, BUT DOING NOTHING WITH IT.");
            }
        }
    }
    
    
    return returnJSObject;
}


- (JSValueRef)callFunction:(JSObjectRef)jsFunction onObject:(JSObjectRef)thisObject argCount:(size_t)argumentCount arguments:(const JSValueRef*)arguments outException:(JSValueRef*)exception {
    
    JSTFunction *function       = [self functionForJSFunction:jsFunction];
    JSTRuntimeInfo *runtimeInfo = [self runtimeInfoForObject:function];
    NSString *functionName      = [function functionName];
    JSTAssert(functionName);
    JSTAssert(function);
    
    //debug(@"functionName: '%@'", functionName);
    
    if (!function) {
        // FIXME: throw a JS exception, saying we couldn't find the function.
        return nil;
    }
    
    if (runtimeInfo) {
        
        assert([runtimeInfo jstType] == JSTTypeFunction);
        
        if (![runtimeInfo isVariadic] && ([[runtimeInfo arguments] count] != argumentCount)) {
            // FIXME: blow up and throw an exception about the wrong number of args.
            NSLog(@"Wrong number of arguments to %@", functionName);
            return nil;
        }
    }
    
    [function setArguments:arguments withCount:argumentCount];
    
    return [function call:exception];
}


- (void)initializeObject:(JSObjectRef)jsObject {
    
}

- (JSValueRef)convertObject:(JSObjectRef)object toType:(JSType)type outException:(JSValueRef*)exception {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return nil;
}

@end



JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    return [(JSTBridge*)JSObjectGetPrivate(object) propertyForObject:object named:propertyName outException:exception];
}

void JSTClass_initialize(JSContextRef ctx, JSObjectRef object) {
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) initializeObject:object];
}

JSValueRef JSTClass_convertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception) {
    assert(false);
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) convertObject:object toType:type outException:exception];
    
}

JSValueRef JSTClass_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) propertyForObject:object named:propertyName outException:exception];
}

// @abstract The callback invoked when an object is finalized (prepared for garbage collection). An object may be finalized on any thread.
// So yea, don't do much here thank you very much.
void JSTClass_finalize(JSObjectRef object) {
    id o = JSObjectGetPrivate(object);
    debug(@"releasing: %@", o);
    [o release];
}

JSValueRef JSTBridge_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) callFunction:function onObject:thisObject argCount:argumentCount arguments:arguments outException:exception];
}





