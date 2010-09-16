//
//  JSCocoa.h
//  JSCocoa
//
//  Created by Patrick Geiller on 09/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//
#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#define MACOSX
#import <ffi/ffi.h>
#endif
#import "JSTBridgeSupportLoader.h"
#import "JSTBridgedObject.h"
#import "JSCocoaFFIArgument.h"
#import "JSCocoaFFIClosure.h"


// JS value container, used by methods wanting a straight JSValue and not a converted JS->ObjC value.
struct JSValueRefAndContextRef {
    JSValueRef    value;
    JSContextRef  ctx;
};
typedef struct JSValueRefAndContextRef JSValueRefAndContextRef;

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import "iPhone/libffi/ffi.h"
#import "iPhone/BurksPool.h"
#endif


//
// JSCocoaController
//
@interface JSCocoaController : NSObject {

    JSGlobalContextRef  _ctx;
    BOOL                _ownsContext;
    id                  _delegate;

    //
    // Safe dealloc
    //    - (void)dealloc cannot be overloaded as it is called during JS GC, which forbids new JS code execution.
    //    As the js dealloc method cannot be called, safe dealloc allows it to be executed during the next run loop cycle
    //    NOTE : upon destroying a JSCocoaController, safe dealloc is disabled
    //
    BOOL                useSafeDealloc;
    BOOL                useJSLint; // JSLint : used for ObjJ syntax, class syntax, return if
    BOOL                useAutoCall;
    BOOL                canSetOnBoxedObjects;
    
}

@property (assign) id delegate;
@property (assign) BOOL useSafeDealloc;
@property (assign) BOOL useJSLint;
@property (assign) BOOL canSetOnBoxedObjects;
@property (assign) BOOL useAutoCall;


- (id)init;
- (id)initWithGlobalContext:(JSGlobalContextRef)ctx;

+ (id)controllerFromContext:(JSContextRef)ctx;
- (JSGlobalContextRef)ctx;
+ (void)hazardReport;
+ (NSString*)runningArchitecture;
+ (void)updateCustomCallPaths;
- (void)accomodateWebKitInspector;

//
// Evaluation
//
- (id)eval:(NSString*)script;
- (id)callFunction:(NSString*)name;
- (id)callFunction:(NSString*)name withArguments:(NSArray*)arguments;
- (BOOL)hasFunction:(NSString*)name;
- (BOOL)isSyntaxValid:(NSString*)script;

- (BOOL)evalJSFile:(NSString*)path;
- (BOOL)evalJSFile:(NSString*)path toJSValueRef:(JSValueRef*)returnValue;
- (JSValueRef)evalJSString:(NSString*)script;
- (JSValueRef)evalJSString:(NSString*)script withScriptPath:(NSString*)path;
- (JSValueRef)callJSFunction:(JSValueRef)function withArguments:(NSArray*)arguments;
- (JSValueRef)callJSFunctionNamed:(NSString*)functionName withArguments:arguments, ... NS_REQUIRES_NIL_TERMINATION;
- (JSValueRef)callJSFunctionNamed:(NSString*)functionName withArgumentsArray:(NSArray*)arguments;
- (JSObjectRef)JSFunctionNamed:(NSString*)functionName;
- (BOOL)hasJSFunctionNamed:(NSString*)functionName;
- (NSString*)expandJSMacros:(NSString*)script path:(NSString*)path;
- (NSString*)expandJSMacros:(NSString*)script path:(NSString*)path errors:(NSMutableArray*)array;
- (BOOL)isSyntaxValid:(NSString*)script error:(NSString**)error;
- (BOOL)setObject:(id)object withName:(id)name;
- (BOOL)setObject:(id)object withName:(id)name attributes:(JSPropertyAttributes)attributes;
- (BOOL)removeObjectWithName:(id)name;
// Get ObjC and raw values from Javascript
- (id)unboxJSValueRef:(JSValueRef)jsValue;
- (BOOL)toBool:(JSValueRef)value;
- (double)toDouble:(JSValueRef)value;
- (int)toInt:(JSValueRef)value;
- (NSString*)toString:(JSValueRef)value;
// Wrapper for unboxJSValueRef
- (id)toObject:(JSValueRef)value;


//
// Framework
//
- (BOOL)loadFrameworkWithName:(NSString*)name;
- (BOOL)loadFrameworkWithName:(NSString*)frameworkName inPath:(NSString*)path;

//
// Garbage collection
//
+ (void)garbageCollect;
- (void)garbageCollect;
- (void)unlinkAllReferences;
+ (void)upJSTBridgedObjectCount;
+ (void)downJSTBridgedObjectCount;
+ (int)JSTBridgedObjectCount;

+ (void)upJSValueProtectCount;
+ (void)downJSValueProtectCount;
+ (int)JSValueProtectCount;

+ (void)logInstanceStats;
- (id)instanceStats;
+ (void)logBoxedObjects;

//
// Class inspection (shortcuts to JSCocoaLib)
//
+ (id)rootclasses;
+ (id)classes;
+ (id)protocols;
+ (id)imageNames;
+ (id)methods;
+ (id)runtimeReport;
+ (id)explainMethodEncoding:(id)encoding;

//
// Class handling
//
+ (BOOL)overloadInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;
+ (BOOL)overloadClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext;

+ (BOOL)addClassMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;
+ (BOOL)addInstanceMethod:(NSString*)methodName class:(Class)class jsFunction:(JSValueRefAndContextRef)valueAndContext encoding:(char*)encoding;

// Tests
- (int)runTests:(NSString*)path;
- (int)runTests:(NSString*)path withSelector:(SEL)sel;

//
// Autorelease pool
//
+ (void)allocAutoreleasePool;
+ (void)deallocAutoreleasePool;

//
// Global boxer : only one JSValueRef for multiple box requests of one pointer
//
+ (JSObjectRef)boxedJSObject:(id)o inContext:(JSContextRef)ctx;
+ (void)downBoxedJSObjectCount:(id)o;


//
// Various internals
//
+ (JSObjectRef)jsCocoaPrivateObjectInContext:(JSContextRef)ctx;
+ (NSMutableArray*)parseObjCMethodEncoding:(const char*)typeEncoding;
//+ (NSMutableArray*)cFunctionEncodingsForBridgedObject:(JSTBridgedObject*)bridgedObject;

+ (void)ensureJSValueIsObjectAfterInstanceAutocall:(JSValueRef)value inContext:(JSContextRef)ctx;
- (NSString*)formatJSException:(JSValueRef)exception;
- (id)selectorForJSFunction:(JSObjectRef)function;


- (const char*)typeEncodingOfMethod:(NSString*)methodName class:(NSString*)className;
+ (const char*)typeEncodingOfMethod:(NSString*)methodName class:(NSString*)className;



@end


//
// JSCocoa delegate methods
//

//
// Error reporting
//
@interface NSObject (JSCocoaControllerDelegateMethods)
- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url;
- (void) safeDealloc;

//
// Getting
//
// Check if getting property is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canGetProperty:(NSString*)propertyName ofObject:(id)object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Custom handler for getting properties
//    Return a custom JSValueRef to bypass JSCocoa
//    Return NULL to let JSCocoa handle getProperty
//    Return JSValueMakeNull() to return a Javascript null
- (JSValueRef) JSCocoa:(JSCocoaController*)controller getProperty:(NSString*)propertyName ofObject:(id)object inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Setting
//
// Check if setting property is allowed
- (BOOL)JSCocoa:(JSCocoaController*)controller canSetProperty:(NSString*)propertyName ofObject:(id)object toValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Custom handler for setting properties
//    Return YES to indicate you handled setting
//    Return NO to let JSCocoa handle setProperty
- (BOOL)JSCocoa:(JSCocoaController*)controller setProperty:(NSString*)propertyName ofObject:(id)object toValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Calling
//
// Check if calling a C function is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canCallFunction:(NSString*)functionName argumentCount:(size_t)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Check if calling an ObjC method is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canCallMethod:(NSString*)methodName ofObject:(id)object argumentCount:(size_t)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Custom handler for calling
//    Return YES to indicate you handled calling
//    Return NO to let JSCocoa handle calling
- (JSValueRef) JSCocoa:(JSCocoaController*)controller callMethod:(NSString*)methodName ofObject:(id)callee privateObject:(JSTBridgedObject*)thisPrivateObject argumentCount:(size_t)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)localCtx exception:(JSValueRef*)exception;

//
// Getting global properties (classes, structures, C function names, enums via OSXObject_getProperty)
//
// Check if getting property is allowed
- (BOOL) JSCocoa:(JSCocoaController*)controller canGetGlobalProperty:(NSString*)propertyName inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
// Custom handler for getting properties
//    Return a custom JSValueRef to bypass JSCocoa
//    Return NULL to let JSCocoa handle getProperty
//    Return JSValueMakeNull() to return a Javascript null
- (JSValueRef) JSCocoa:(JSCocoaController*)controller getGlobalProperty:(NSString*)propertyName inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Returning values to Javascript
//
// Called before returning any value to Javascript : return a new value or the original one
//- (JSValueRef) JSCocoa:(JSCocoaController*)controller willReturnValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;

//
// Evaling
//
// Check if file can be loaded
- (BOOL)JSCocoa:(JSCocoaController*)controller canLoadJSFile:(NSString*)path;
// Check if script can be evaluated
- (BOOL)JSCocoa:(JSCocoaController*)controller canEvaluateScript:(NSString*)script;
// Called before evalJSString, used to modify script about to be evaluated
//    Return a custom NSString (eg a macro expanded version of the source)
//    Return NULL to let JSCocoa handle evaluation
- (NSString*)JSCocoa:(JSCocoaController*)controller willEvaluateScript:(NSString*)script;

@end


//
// Boxed object cache : holds one JSObjectRef for each reference to a pointer to an ObjC object
//
@interface BoxedJSObject : NSObject {
    JSObjectRef _jsObject;
}

- (id)initWithJSObject:(JSObjectRef)ref;
@property (assign) JSObjectRef jsObject;

@end

//
// Helpers
//
NSString *NSStringFromJSValue(JSValueRef value, JSContextRef ctx);
NSString *JSTCreateStringFromJSValue(JSContextRef ctx, JSValueRef value);

// Convert values between contexts (eg user context and webkit page context)
JSValueRef valueToExternalContext(JSContextRef ctx, JSValueRef value, JSContextRef externalCtx);

// valueOf() is called by Javascript on objects, eg someObject + ' someString'
JSValueRef valueOfCallback(JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject, size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception);

//
// From PyObjC : when to call objc_msgSend_stret, for structure return
//        Depending on structure size & architecture, structures are returned as function first argument (done transparently by ffi) or via registers
//

#if defined(__ppc__)
#   define SMALL_STRUCT_LIMIT    4
#elif defined(__ppc64__)
#   define SMALL_STRUCT_LIMIT    8
#elif defined(__i386__) 
#   define SMALL_STRUCT_LIMIT     8
#elif defined(__x86_64__) 
#   define SMALL_STRUCT_LIMIT    16
#elif TARGET_OS_IPHONE
// TOCHECK
#   define SMALL_STRUCT_LIMIT    4
#else
#   error "Unsupported MACOSX platform"
#endif

// Stored in boxedobjects to access a list of methods, properties, ...
#define RuntimeInformationPropertyName "info"


