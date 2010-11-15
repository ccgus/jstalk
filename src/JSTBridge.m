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
#import "JSTStructure.h"

// JSObjectGetPropertyCallback
JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception);
JSValueRef JSTBridge_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception);


void       JSTClass_initialize(JSContextRef ctx, JSObjectRef object); // JSObjectInitializeCallback
void       JSTClass_finalize(JSObjectRef object); // JSObjectFinalizeCallback
JSValueRef JSTClass_convertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception);
void       JSTClass_getPropertyNames(JSContextRef ctx, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames);
JSValueRef JSTClass_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyNameJS, JSValueRef* exception);
bool       JSTClass_setProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef* exception);

static const char * JSTRuntimeAssociatedInfoKey = "jstri";

@implementation JSTBridge
@synthesize jsContext=_jsContext;
@synthesize delegate=_delegate;

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
        bridgedObjectDefinition.setProperty          = JSTClass_setProperty;
        bridgedObjectDefinition.getPropertyNames     = JSTClass_getPropertyNames;
        
        /*
        //jsCocoaObjectDefinition.hasProperty            = jsCocoaObject_hasProperty;
        jsCocoaObjectDefinition.getProperty            = jsCocoaObject_getProperty;
        jsCocoaObjectDefinition.setProperty            = jsCocoaObject_setProperty;
        jsCocoaObjectDefinition.deleteProperty        = jsCocoaObject_deleteProperty;
        jsCocoaObjectDefinition.getPropertyNames    = jsCocoaObject_getPropertyNames;
        //jsCocoaObjectDefinition.callAsFunction        = jsCocoaObject_callAsFunction;
        jsCocoaObjectDefinition.callAsConstructor    = jsCocoaObject_callAsConstructor;
        //jsCocoaObjectDefinition.hasInstance            = jsCocoaObject_hasInstance;
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

- (JSClassRef)bridgedObjectClass {
    return _bridgedObjectClass;
}

- (void)callDelegateErrorWithException:(JSValueRef)exception {
    
    JSStringRef exceptionString = JSValueToStringCopy(_jsContext, exception, nil);
    NSString *nsExceptionString = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, exceptionString);
    JSStringRelease(exceptionString);
    
    if (![_delegate respondsToSelector:@selector(bridge:hadError:onLineNumber:atSourcePath:)]) {
        
        
#ifdef debug
        NSBeep();
#endif
        
        debug(@"Exception: '%@'", nsExceptionString);
        
        [nsExceptionString release];
        
        return;
    }
    
    if (JSValueGetType(_jsContext, exception) != kJSTypeObject) {
        [_delegate bridge:self hadError:nsExceptionString onLineNumber:0 atSourcePath:nil];
    }
    
    // Iterate over all properties of the exception
    JSObjectRef jsObject            = JSValueToObject(_jsContext, exception, nil);
    JSPropertyNameArrayRef jsNames  = JSObjectCopyPropertyNames(_jsContext, jsObject);
    size_t i, nameCount             = JSPropertyNameArrayGetCount(jsNames);
    NSString *line                  = 0x00;
    NSString *sourcePath            = 0x00;
    
    for (i = 0; i < nameCount; i++) {
        JSStringRef jsName      = JSPropertyNameArrayGetNameAtIndex(jsNames, i);
        NSString *name          = [(id)JSStringCopyCFString(kCFAllocatorDefault, jsName) autorelease];
        
        JSValueRef jsValueRef   = JSObjectGetProperty(_jsContext, jsObject, jsName, nil);
        JSStringRef valueJS     = JSValueToStringCopy(_jsContext, jsValueRef, nil);
        NSString *value         = [(NSString*)JSStringCopyCFString(kCFAllocatorDefault, valueJS) autorelease];
        JSStringRelease(valueJS);
        
        if ([name isEqualToString:@"line"]) {
            line = value;
        }
        else if ([name isEqualToString:@"sourceURL"]) {
            sourcePath = value;
        }
    }
    
    JSPropertyNameArrayRelease(jsNames);
    [_delegate bridge:self hadError:nsExceptionString onLineNumber:[line intValue] atSourcePath:sourcePath];
}

- (JSValueRef)evalJSString:(NSString*)script withPath:(NSString*)path {
    
    JSStringRef scriptJS    = JSStringCreateWithCFString((CFStringRef)script);
    JSValueRef exception    = nil;
    JSStringRef scriptPath  = path ? JSStringCreateWithUTF8CString([path UTF8String]) : nil;
    JSValueRef result       = JSEvaluateScript(_jsContext, scriptJS, nil, scriptPath, 1, &exception);
    JSStringRelease(scriptJS);
    
    if (scriptPath) {
        JSStringRelease(scriptPath);
    }
    
    if (exception) {
        [self callDelegateErrorWithException:exception];
    }
    
    return result;
}

- (JSObjectRef)makeJSObjectWithNSObject:(id)obj runtimeInfo:(JSTRuntimeInfo*)info {
    
    if (!obj) {
        return (JSObjectRef)JSValueMakeNull(_jsContext);
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


- (JSObjectRef)makeJSStyleBridgedFunction:(NSString*)functionName onObject:(id)target {
    
    // Change the _'s into :'s, and verify that the object responds to it.
    
    functionName = [functionName stringByReplacingOccurrencesOfString:@"_" withString:@":"];
    if (![target respondsToSelector:NSSelectorFromString(functionName)]) {
        functionName = [functionName stringByAppendingString:@":"];
    }
    
    if (![target respondsToSelector:NSSelectorFromString(functionName)]) {
        NSLog(@"Can't find the method named '%@'", functionName);
        return (JSObjectRef)JSValueMakeNull(_jsContext);
    }
    
    JSTRuntimeInfo *info  = [self runtimeInfoForObject:target];
    JSTFunction *function = [[JSTFunction alloc] initWithFunctionName:@"objc_msgSend" bridge:self runtimeInfo:info];
    
    [function setForcedObjcTarget:target];
    [function setForcedObjcSelector:functionName];
    
    return JSObjectMake(_jsContext, _bridgedFunctionClass, function);
}

- (JSTRuntimeInfo*)runtimeInfoForObject:(id)obj {
    JSTRuntimeInfo *info = objc_getAssociatedObject(obj, &JSTRuntimeAssociatedInfoKey);
    
    if (!info) {
        info = [JSTBridgeSupportLoader runtimeInfoForSymbol:NSStringFromClass([obj class])];
    }
    
    return info;
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

- (void)propertyNamesForObject:(JSObjectRef)jsObject propertyNameAccumulator:(JSPropertyNameAccumulatorRef)propertyNames {
    
    id object = [self NSObjectForJSObject:jsObject];
    
    if ([object isKindOfClass:[NSArray class]]) {
#warning add this to the tests:
        /*
         for (idx in args) {
         print("argument " + [args objectAtIndex:idx]);
         }
         
         */
        NSArray *ar = (id)object;
        for (int i = 0; i < [ar count]; i++) {
            
            
            JSStringRef jsString = JSStringCreateWithUTF8CString([[NSString stringWithFormat:@"%d", i] UTF8String]);
            JSPropertyNameAccumulatorAddName(propertyNames, jsString);
            JSStringRelease(jsString);  
        }
    }
    
    if ([object isKindOfClass:[NSDictionary class]]) {

#warning add a test for this:
/*
var d = [NSMutableDictionary dictionary];

d['a'] = 'eh';
d['b'] = 'beee';

for (var key in d) {
    print(key + ": " + [d valueForKey:key]);
}
*/

        NSDictionary *d = (id)object;
        for (id key in [d allKeys]) {
            JSStringRef jsString = JSStringCreateWithUTF8CString([[key description] UTF8String]);
            JSPropertyNameAccumulatorAddName(propertyNames, jsString);
            JSStringRelease(jsString);  
        }
        
    }
    
}

- (JSValueRef)propertyForObject:(JSObjectRef)jsObject named:(JSStringRef)jsPropertyName outException:(JSValueRef*)exception {
    
    NSString *propertyName      = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, jsPropertyName);
    JSValueRef returnJSObject   = 0x00;
    JSTRuntimeInfo *info        = [JSTBridgeSupportLoader runtimeInfoForSymbol:propertyName];
    
    if ([propertyName isEqualToString:@"valueOf"] || [propertyName isEqualToString:@"toString"]) {
        return [self internalFunctionForJSObject:jsObject functionName:propertyName outException:exception];
    }
    
    id caller = [self NSObjectForJSObject:jsObject];
    
    if ([caller isKindOfClass:[JSTStructure class]]) {
        return [(JSTStructure*)caller cantThinkOfAGoodNameForThisYet:propertyName outException:exception];
    }
    
    if ([caller isKindOfClass:[NSDictionary class]]) {
        id value = [caller objectForKey:propertyName];
        return [self makeJSObjectWithNSObject:value runtimeInfo:[self runtimeInfoForObject:value]];
    }
    
    if ([caller isKindOfClass:[NSArray class]]) {
        NSInteger idx  = [propertyName integerValue];
        
        if (idx < 0 || idx > [caller count] - 1) {
            JSTAssignException(self, exception, [NSString stringWithFormat:@"index (%d) out of range for array %@", idx, caller]);
            return nil;
        }
        
        id value        = [caller objectAtIndex:idx];
        return [self makeJSObjectWithNSObject:value runtimeInfo:[self runtimeInfoForObject:value]];
    }
    
    
    
    if (caller != self) {
        // looks like it's a foo.some_objc_method(call, wow, neat);
        return [self makeJSStyleBridgedFunction:propertyName onObject:caller];
    }
    
    
    if (info) {
        if ([info jstType] == JSTTypeClass) {
            returnJSObject = [self makeJSObjectWithNSObject:NSClassFromString(propertyName) runtimeInfo:info];
        }
        else if ([info jstType] == JSTTypeFunction) {
            returnJSObject = [self makeBridgedFunctionWithRuntimeInfo:info name:propertyName];
        }
        else if ([info jstType] == JSTTypeStruct) {
            assert(false);
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


- (BOOL)setPropertyForObject:(JSObjectRef)jsObject named:(JSStringRef)jsPropertyName value:(JSValueRef)value outException:(JSValueRef*)exception {
    
    /*
    JSType type = JSValueGetType(_jsContext, value);
    if (type == kJSTypeNumber) {
        debug(@"JSValueToNumber(ctx, value, nil): %f", JSValueToNumber(_jsContext, value, nil));
    }
    */
    
    NSString *propertyName  = (NSString*)JSStringCopyCFString(kCFAllocatorDefault, jsPropertyName);
    id objectToSet          = [self NSObjectForJSObject:jsObject];
    
    if ([objectToSet isKindOfClass:[JSTStructure class]]) {
        return [(JSTStructure*)objectToSet setValue:value forFieldNamed:propertyName outException:exception];
    }
    
    if ([objectToSet isKindOfClass:[NSDictionary class]]) {
        [objectToSet setValue:JSTNSObjectFromValue(self, value) forKey:propertyName];
        return YES;
    }
    
    return NO;
}


- (JSValueRef)callFunction:(JSObjectRef)jsFunction onObject:(JSObjectRef)thisObject argCount:(size_t)argumentCount arguments:(const JSValueRef*)arguments outException:(JSValueRef*)exception {
    
    JSTFunction *function       = [self functionForJSFunction:jsFunction];
    JSTRuntimeInfo *runtimeInfo = [self runtimeInfoForObject:function];
    NSString *functionName      = [function functionName];
    JSTAssert(functionName);
    JSTAssert(function);
    
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


//#define jsfdebug NSLog
#define jsfdebug(...)

JSValueRef JSTBridge_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    jsfdebug(@"%s:%d", __FUNCTION__, __LINE__);
    return [(JSTBridge*)JSObjectGetPrivate(object) propertyForObject:object named:propertyName outException:exception];
}

void JSTClass_initialize(JSContextRef ctx, JSObjectRef object) {
    jsfdebug(@"%s:%d", __FUNCTION__, __LINE__);
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) initializeObject:object];
}

JSValueRef JSTClass_convertToType(JSContextRef ctx, JSObjectRef object, JSType type, JSValueRef* exception) {
    jsfdebug(@"%s:%d", __FUNCTION__, __LINE__);
    assert(false);
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) convertObject:object toType:type outException:exception];
    
}

void JSTClass_getPropertyNames(JSContextRef ctx, JSObjectRef object, JSPropertyNameAccumulatorRef propertyNames) {
    NSLog(@"%s:%d", __FUNCTION__, __LINE__);
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) propertyNamesForObject:object propertyNameAccumulator:propertyNames];
}


JSValueRef JSTClass_getProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef* exception) {
    jsfdebug(@"%s:%d", __FUNCTION__, __LINE__);
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) propertyForObject:object named:propertyName outException:exception];
}

bool JSTClass_setProperty(JSContextRef ctx, JSObjectRef object, JSStringRef propertyName, JSValueRef value, JSValueRef* exception) {
    jsfdebug(@"%s:%d", __FUNCTION__, __LINE__);
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) setPropertyForObject:object named:propertyName value:value outException:exception];
}

// @abstract The callback invoked when an object is finalized (prepared for garbage collection). An object may be finalized on any thread.
// So yea, don't do much here thank you very much.
void JSTClass_finalize(JSObjectRef object) {
    id o = JSObjectGetPrivate(object);
    debug(@"releasing: %@", o);
    [o release];
}

JSValueRef JSTBridge_callAsFunction(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
    jsfdebug(@"%s:%d", __FUNCTION__, __LINE__);
    return [(JSTBridge*)JSObjectGetPrivate(JSContextGetGlobalObject(ctx)) callFunction:function onObject:thisObject argCount:argumentCount arguments:arguments outException:exception];
}





