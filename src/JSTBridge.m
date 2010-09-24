//
//  JSTBridge.m
//  jstalk
//
//  Created by August Mueller on 9/23/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTBridge.h"
#import "JSTClosure.h"
#import "MABlockClosure.h"
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
        
        if ([info objectType] == JSTClass) {
            returnJSObject = [self makeBridgedObject:&bridgedObject runtimeInfo:info];
        }
        else if ([info objectType] == JSTFunction) {
            returnJSObject = [self makeBridgedFunction:&bridgedObject runtimeInfo:info];
        }
        else if ([info objectType] == JSTStruct) {
            
            
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
            returnJSObject = [self makeBridgedObject:&bridgedObject runtimeInfo:0x00];
            [bridgedObject setObject:runtimeClass];
        }
        
        // bummer.  Let's see if we can look it up in the runtime
    }
    
    if (!returnJSObject) {
        //debug(@"Can't find any info for '%@'", propertyName);
    }
    
    return returnJSObject;
}

- (JSValueRef)callMsgSendWithArgCount:(size_t)argumentCount arguments:(const JSValueRef*)arguments outException:(JSValueRef*)exception {
    /*
    Let's say I've got x number of arguments to objc_msgSend in an array- what's the best way to set everything up to call it, libffi?
    
    */
    
    return nil;
}

- (JSValueRef)callFunction:(JSObjectRef)function onObject:(JSObjectRef)thisObject argCount:(size_t)argumentCount arguments:(const JSValueRef*)arguments outException:(JSValueRef*)exception {
    
    JSTBridgedObject *bridgedFunction       = [self bridgedObjectForJSObject:function];
    JSTBridgedObject *bridgedFunctionCaller = [self bridgedObjectForJSObject:thisObject];
    NSString *functionName                  = [[bridgedFunction runtimeInfo] symbolName];
    JSTAssert(functionName);
    
    bridgedFunctionCaller = ((id)bridgedFunctionCaller == self) ? nil : bridgedFunctionCaller;
    
    JSTRuntimeInfo *runtimeInfo = [bridgedFunction runtimeInfo];
    
    /*
[3:36pm] mikeash: first, you need to construct an array of ffi_type* that describes all the argument types
[3:36pm] mikeash: also one for the return type if you have one
[3:36pm] mikeash: this is easy for primitives and pointers, can get hairy for pass-by-value structs
[3:36pm] ccgus: k
[3:37pm] mikeash: next, you need a pointer to each argument and put it all into an array of pointers
[3:37pm] mikeash: so you end up with a void ** for the arguments
[3:37pm] mikeash: finally, ffi_prep_cif to get the type info properly packed, and then ffi_call to actually make the call
[3:37pm] ccgus: danke
[3:37pm] mikeash: all of these pieces can be seen in MABlockClosure.m
[3:37pm] ccgus: _ffiArgForEncode looks like it'll be helpful
[3:38pm] mikeash: they are somewhat scattered though
[3:38pm] mikeash: and if you have float/struct returns, don't forget that you'll need to conditionally invoke objc_msgSend_fpret or _strect
[3:38pm] ccgus: yea- I'll let my preprocessor deal with that bit :)
[3:39pm] ccgus: luckily, the bridge info stuff will help me out there.
[3:40pm] mikeash: oh yeah
[3:40pm] mikeash: _ffiArgForEncode: is probably a big help, should take care of every single primitive that @encode can represent
[3:40pm] mikeash: and pointer
*/
    //ffi_type **argTypes = malloc(sizeof(ffi_type*) * argumentCount);
    
    //debug(@"function call: %@ %@", bridgedFunction, functionName);
    
    /*
    JSTClosure *closure = [[[JSTClosure alloc] initWithFunctionName:functionName] autorelease];
    
    if (!closure) {
        // FIXME: throw a JS exception, saying we couldn't find the function.
        return nil;
    }
    */
    
    if (runtimeInfo) {
        
        assert([runtimeInfo objectType] == JSTFunction);
        
        debug(@"typeEncoding: '%@'", [runtimeInfo typeEncoding]);
        debug(@"typeEncoding: '%@'", [runtimeInfo arguments]);
        
        if (![runtimeInfo isVariadic] && ([[runtimeInfo arguments] count] != argumentCount)) {
            // FIXME: blow up and throw an exception about the wrong number of args.
            NSLog(@"Wrong number of arguments to %@", functionName);
            return nil;
        }
        
        for (int j = 0; j < argumentCount; j++) {
            JSValueRef argument = arguments[j];
            
            JSType type = JSValueGetType(_jsContext, argument);
            JSTRuntimeInfo *argRuntimeInfo = [[runtimeInfo arguments] objectAtIndex:j];
            
            debug(@"[argRuntimeInfo typeEncoding]: '%@'", [argRuntimeInfo typeEncoding]);
            
            
            
            
        }
        
        
    }
    
    
    
    
    
    id block = ^(id fff, SEL cmd, NSString *arg) { NSLog(@"arg is %@", arg); };
    BlockFptrAuto(block);
    
    //debug(@"closure: '%@'", closure);
    
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





