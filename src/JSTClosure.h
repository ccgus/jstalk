#import <ffi/ffi.h>
#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSTRuntimeInfo.h"

@class JSTBridge;
@interface JSTClosure : NSObject
{
    NSMutableArray *_allocations;
    ffi_cif _closureCIF;
    ffi_cif _innerCIF; // we're not touching this guy.  // FIXME: delete
    int _closureArgCount;
    void *_closure;
    id _block;
    
    
    NSString            *_functionName;
    void                *_callAddress;
    JSTRuntimeInfo      *_runtimeInfo;
    JSTRuntimeInfo      *_msgSendMethodRuntimeInfo;
    size_t              _argumentCount;
    JSValueRef          *_jsArguments;
    JSTBridge           *_bridge;
    //void                **argValues;
}

- (id)initWithFunctionName:(NSString*)name bridge:(JSTBridge*)bridge runtimeInfo:(JSTRuntimeInfo*)runtimeInfo;

- (void *)fptr;

- (void)setArguments:(const JSValueRef *)args withCount:(size_t)count;

- (JSValueRef)call;

@property (retain) NSString *functionName;

@end
