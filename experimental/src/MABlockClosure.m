
#import "MABlockClosure.h"

#import <assert.h>
#import <objc/runtime.h>
#import <sys/mman.h>


@implementation MABlockClosure

struct BlockDescriptor
{
    unsigned long reserved;
    unsigned long size;
    void *rest[1];
};

struct Block
{
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct BlockDescriptor *descriptor;
};
    

static void *BlockImpl(id block)
{
    return ((void **)block)[2];
}

static const char *BlockSig(id blockObj)
{
    struct Block *block = (void *)blockObj;
    struct BlockDescriptor *descriptor = block->descriptor;
    
    int copyDisposeFlag = 1 << 25;
    int signatureFlag = 1 << 30;
    
    assert(block->flags & signatureFlag);
    
    int index = 0;
    if(block->flags & copyDisposeFlag)
        index += 2;
    
    return descriptor->rest[index];
}

static void BlockClosure(ffi_cif *cif, void *ret, void **args, void *userdata)
{
    MABlockClosure *self = userdata;
    
    int count = self->_closureArgCount;
    void **innerArgs = malloc((count + 1) * sizeof(*innerArgs));
    innerArgs[0] = &self->_block;
    memcpy(innerArgs + 1, args, count * sizeof(*args));
    ffi_call(&self->_innerCIF, BlockImpl(self->_block), ret, innerArgs);
    free(innerArgs);
}

static void *AllocateClosure(void)
{
    ffi_closure *closure = mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if(closure == (void *)-1)
    {
        perror("mmap");
        return NULL;
    }
    return closure;
}

static void DeallocateClosure(void *closure)
{
    munmap(closure, sizeof(ffi_closure));
}

- (void *)_allocate: (size_t)howmuch
{
    NSMutableData *data = [NSMutableData dataWithLength: howmuch];
    [_allocations addObject: data];
    return [data mutableBytes];
}

static const char *SizeAndAlignment(const char *str, NSUInteger *sizep, NSUInteger *alignp, int *len)
{
    const char *out = NSGetSizeAndAlignment(str, sizep, alignp);
    if(len)
        *len = (int)(out - str);
    while(isdigit(*out))
        out++;
    return out;
}

static int ArgCount(const char *str)
{
    int argcount = -1; // return type is the first one
    while(str && *str)
    {
        str = SizeAndAlignment(str, NULL, NULL, NULL);
        argcount++;
    }
    return argcount;
}

- (ffi_type *)_ffiArgForEncode: (const char *)str
{
    #define SINT(type) do { \
    	if(str[0] == @encode(type)[0]) \
    	{ \
    	   if(sizeof(type) == 1) \
    	       return &ffi_type_sint8; \
    	   else if(sizeof(type) == 2) \
    	       return &ffi_type_sint16; \
    	   else if(sizeof(type) == 4) \
    	       return &ffi_type_sint32; \
    	   else if(sizeof(type) == 8) \
    	       return &ffi_type_sint64; \
    	   else \
    	   { \
    	       NSLog(@"Unknown size for type %s", #type); \
    	       abort(); \
    	   } \
        } \
    } while(0)
    
    #define UINT(type) do { \
    	if(str[0] == @encode(type)[0]) \
    	{ \
    	   if(sizeof(type) == 1) \
    	       return &ffi_type_uint8; \
    	   else if(sizeof(type) == 2) \
    	       return &ffi_type_uint16; \
    	   else if(sizeof(type) == 4) \
    	       return &ffi_type_uint32; \
    	   else if(sizeof(type) == 8) \
    	       return &ffi_type_uint64; \
    	   else \
    	   { \
    	       NSLog(@"Unknown size for type %s", #type); \
    	       abort(); \
    	   } \
        } \
    } while(0)
    
    #define INT(type) do { \
        SINT(type); \
        UINT(unsigned type); \
    } while(0)
    
    #define COND(type, name) do { \
        if(str[0] == @encode(type)[0]) \
            return &ffi_type_ ## name; \
    } while(0)
    
    #define PTR(type) COND(type, pointer)
    
    #define STRUCT(structType, ...) do { \
        if(strncmp(str, @encode(structType), strlen(@encode(structType))) == 0) \
        { \
           ffi_type *elementsLocal[] = { __VA_ARGS__, NULL }; \
           ffi_type **elements = [self _allocate: sizeof(elementsLocal)]; \
           memcpy(elements, elementsLocal, sizeof(elementsLocal)); \
            \
           ffi_type *structType = [self _allocate: sizeof(*structType)]; \
           structType->type = FFI_TYPE_STRUCT; \
           structType->elements = elements; \
           return structType; \
        } \
    } while(0)
    
    SINT(_Bool);
    SINT(signed char);
    UINT(unsigned char);
    INT(short);
    INT(int);
    INT(long);
    INT(long long);
    
    PTR(id);
    PTR(Class);
    PTR(SEL);
    PTR(void *);
    PTR(char *);
    PTR(void (*)(void));
    
    COND(float, float);
    COND(double, double);
    
    COND(void, void);
    
    ffi_type *CGFloatFFI = sizeof(CGFloat) == sizeof(float) ? &ffi_type_float : &ffi_type_double;
    STRUCT(CGRect, CGFloatFFI, CGFloatFFI, CGFloatFFI, CGFloatFFI);
    STRUCT(NSRect, CGFloatFFI, CGFloatFFI, CGFloatFFI, CGFloatFFI);
    STRUCT(CGPoint, CGFloatFFI, CGFloatFFI);
    STRUCT(NSPoint, CGFloatFFI, CGFloatFFI);
    STRUCT(CGSize, CGFloatFFI, CGFloatFFI);
    STRUCT(NSSize, CGFloatFFI, CGFloatFFI);
    
    NSLog(@"Unknown encode string %s", str);
    abort();
}

- (ffi_type **)_argsWithEncodeString: (const char *)str getCount: (int *)outCount
{
    int argCount = ArgCount(str);
    ffi_type **argTypes = [self _allocate: argCount * sizeof(*argTypes)];
    
    int i = -1;
    while(str && *str)
    {
        const char *next = SizeAndAlignment(str, NULL, NULL, NULL);
        if(i >= 0)
            argTypes[i] = [self _ffiArgForEncode: str];
        i++;
        str = next;
    }
    
    *outCount = argCount;
    
    return argTypes;
}

- (int)_prepCIF: (ffi_cif *)cif withEncodeString: (const char *)str skipArg: (BOOL)skip
{
    int argCount;
    ffi_type **argTypes = [self _argsWithEncodeString: str getCount: &argCount];
    
    if(skip)
    {
        argTypes++;
        argCount--;
    }
    
    ffi_status status = ffi_prep_cif(cif, FFI_DEFAULT_ABI, argCount, [self _ffiArgForEncode: str], argTypes);
    if(status != FFI_OK)
    {
        NSLog(@"Got result %ld from ffi_prep_cif", (long)status);
        abort();
    }
    
    return argCount;
}

- (void)_prepClosureCIF
{
    _closureArgCount = [self _prepCIF: &_closureCIF withEncodeString: BlockSig(_block) skipArg: YES];
}

- (void)_prepInnerCIF
{
    [self _prepCIF: &_innerCIF withEncodeString: BlockSig(_block) skipArg: NO];
}

- (void)_prepClosure
{
    ffi_status status = ffi_prep_closure(_closure, &_closureCIF, BlockClosure, self);
    if(status != FFI_OK)
    {
        NSLog(@"ffi_prep_closure returned %d", (int)status);
        abort();
    }
    
    if(mprotect(_closure, sizeof(_closure), PROT_READ | PROT_EXEC) == -1)
    {
        perror("mprotect");
        abort();
    }
}

- (id)initWithBlock: (id)block
{
    if((self = [self init]))
    {
        _allocations = [[NSMutableArray alloc] init];
        _block = block;
        _closure = AllocateClosure();
        [self _prepClosureCIF];
        [self _prepInnerCIF];
        [self _prepClosure];
    }
    return self;
}

- (void)dealloc
{
    if(_closure)
        DeallocateClosure(_closure);
    [_allocations release];
    [super dealloc];
}

- (void *)fptr
{
    return _closure;
}

@end

void *BlockFptr(id block)
{
    @synchronized(block)
    {
        MABlockClosure *closure = objc_getAssociatedObject(block, BlockFptr);
        if(!closure)
        {
            closure = [[MABlockClosure alloc] initWithBlock: block];
            objc_setAssociatedObject(block, BlockFptr, closure, OBJC_ASSOCIATION_RETAIN);
            [closure release]; // retained by the associated object assignment
        }
        return [closure fptr];
    }
}

void *BlockFptrAuto(id block)
{
    return BlockFptr([[block copy] autorelease]);
}
