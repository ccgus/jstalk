
#import <ffi/ffi.h>
#import <Foundation/Foundation.h>


@interface MABlockClosure : NSObject
{
    NSMutableArray *_allocations;
    ffi_cif _closureCIF;
    ffi_cif _innerCIF;
    int _closureArgCount;
    void *_closure;
    id _block;
}

- (id)initWithBlock: (id)block;

- (void *)fptr;

@end

// convenience function, returns a function pointer
// whose lifetime is tied to 'block'
// block MUST BE a heap block (pre-copied)
// or a global block
void *BlockFptr(id block);

// copies/autoreleases the block, then returns
// function pointer associated to it
void *BlockFptrAuto(id block);
