
#import <ffi/ffi.h>
#import <Foundation/Foundation.h>


@interface JSTClosure : NSObject
{
    NSMutableArray *_allocations;
    ffi_cif _closureCIF;
    ffi_cif _innerCIF;
    int _closureArgCount;
    void *_closure;
    id _block;
    
    NSString *_functionName;
    void *_callAddress;
}

- (id)initWithFunctionName:(NSString*)name;

- (void *)fptr;

@end

// convenience function, returns a function pointer
// whose lifetime is tied to 'block'
// block MUST BE a heap block (pre-copied)
// or a global block
void *JSTBlockFptr(id block);

// copies/autoreleases the block, then returns
// function pointer associated to it
void *JSTBlockFptrAuto(id block);
