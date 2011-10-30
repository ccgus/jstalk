#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSTRuntimeInfo.h"
#import "JSTUtils.h"

@class JSTBridge;
@interface JSTFunction : NSObject
{
    NSMutableArray *_allocations;
    ffi_cif         _closureCIF;
    ffi_cif         _innerCIF; // we're not touching this guy.  // FIXME: delete
    int             _closureArgCount;
    void            *_closure;
    id              _block;
    
    BOOL            _isJSTMsgSend;
    
    NSString        *_functionName;
    void            *_callAddress;
    JSTRuntimeInfo  *_runtimeInfo;
    
    JSTRuntimeInfo  *_msgSendMethodRuntimeInfo;
    size_t          _argumentCount;
    JSValueRef      *_jsArguments;
    JSTBridge       *_bridge;
    Method          _objcMethod;
    BOOL            _askedForFFIArgsForEncoding;
    
    ffi_type        **_encodedArgsForUnbridgedMsgSend;
}

@property (retain) NSString *functionName;
@property (retain) id forcedObjcTarget;
@property (assign) NSString *forcedObjcSelector;
@property (assign) BOOL isJSTMsgSend;

- (id)initForJSTMsgSendWithBridge:(JSTBridge*)bridge;
- (id)initWithFunctionName:(NSString*)name bridge:(JSTBridge*)bridge runtimeInfo:(JSTRuntimeInfo*)runtimeInfo;

- (void *)fptr;

- (void)setArguments:(const JSValueRef *)args withCount:(size_t)count;

- (JSValueRef)call:(JSValueRef*)exception;


@end

@interface JSTValueOfFunction : JSTFunction {
    id _target;
}

@property (retain) id target;
- (id)initWithTarget:(id)target bridge:(JSTBridge*)bridge;

@end

@interface JSTToStringFunction : JSTFunction {
    id _target;
}
@property (retain) id target;
- (id)initWithTarget:(id)target bridge:(JSTBridge*)bridge;

@end