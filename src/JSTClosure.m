#import "JSTClosure.h"
#import "JSTUtils.h"



@implementation JSTClosure
@synthesize functionName=_functionName;
    
static void BlockClosure(ffi_cif *cif, void *ret, void **args, void *userdata)
{
    JSTClosure *self = userdata;
    
    debug(@"self: '%@'", self);
    /*
    int count = self->_closureArgCount;
    void **innerArgs = malloc((count + 1) * sizeof(*innerArgs));
    innerArgs[0] = &self->_block;
    memcpy(innerArgs + 1, args, count * sizeof(*args));
    ffi_call(&self->_innerCIF, BlockImpl(self->_block), ret, innerArgs);
    free(innerArgs);
    */
}

static void *AllocateClosure(void) {
    
    ffi_closure *closure = mmap(NULL, sizeof(ffi_closure), PROT_READ | PROT_WRITE, MAP_ANON | MAP_PRIVATE, -1, 0);
    if(closure == (void *)-1) {
        perror("mmap");
        return NULL;
    }
    return closure;
}

static void DeallocateClosure(void *closure) {
    munmap(closure, sizeof(ffi_closure));
}

- (void *)_allocate: (size_t)howmuch {
    
    if (!_allocations) {
        _allocations = [[NSMutableArray alloc] init];
    }
    
    NSMutableData *data = [[NSMutableData alloc] initWithLength:howmuch];
    [_allocations addObject:data];
    [data release];
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


- (void)_prepClosure {
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

- (void)setArguments:(const JSValueRef *)args withCount:(size_t)count {
    _jsArguments = (JSValueRef *)args;
    _argumentCount = count;
}

void JSTClosureFunction(ffi_cif* cif, void* resp, void** args, void* userdata) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
	//[(id)userdata calledByClosureWithArgs:args returnValue:resp];
}

- (void)checkForMsgSendMethodRuntimeInfo {
    
    if ((_callAddress != &objc_msgSend) || (_argumentCount < 2)) {
        return;
    }
    
    id target       = JSTNSObjectFromValue(_bridge, _jsArguments[0]);
    NSString *sel   = JSTNSObjectFromValue(_bridge, _jsArguments[1]);
    
    JSTRuntimeInfo *instanceInfo = [_bridge runtimeInfoForObject:target];
    
    BOOL isClassMethod = class_isMetaClass(object_getClass(target));
    
    if (isClassMethod) { // are we dealing with an Class method?
        _msgSendMethodRuntimeInfo = [instanceInfo runtimeInfoForClassMethodName:sel];
    }
    else {
        _msgSendMethodRuntimeInfo = [instanceInfo runtimeInfoForInstanceMethodName:sel];
    }
    
    debug(@"Setup to call: %c[%@ %@]", isClassMethod ? '+' : '-', NSStringFromClass(isClassMethod ? target : [target class]), sel);
    
}



/*
void setterFor4(ffi_type **arg_types, void **arg_values, int index) {
    
    void **foo = allocate(sizeof(void*));
    
    if (index == 0) {
        arg_types[index] = &ffi_type_pointer;
        *foo = [[NSClassFromString(@"TestObject") alloc] init];
    }
    else if (index == 1) {
        arg_types[index] = &ffi_type_pointer;
        *foo = NSSelectorFromString(@"instanceReturnIntAndTakeArg:argTwo:");
    }
    else {
        arg_types[index] = &ffi_type_uint32;
        *foo = (void*)index;
    }
    
    arg_values[index] = foo;    
    
}

*/

-(ffi_type*)setValue:(void**)argVals atIndex:(int)idx {
    
    JSValueRef argument = _jsArguments[idx];
    
    if (_msgSendMethodRuntimeInfo || (_callAddress == &objc_msgSend)) {
        
        if (idx < 0) {
            
            if (!_msgSendMethodRuntimeInfo) {
                // FIXME: look up the return type in the runtime
                return &ffi_type_pointer; // we always assume it's a pointer to id here if we can't find the interface
            }
            
            return JSTFFITypeForTypeEncoding([[_msgSendMethodRuntimeInfo returnValue] typeEncoding]);
        }
        
        void **foo = [self _allocate:(sizeof(void*))];
        
        if (idx == 0) { // this is the target
            *foo = JSTNSObjectFromValue(_bridge, argument);
            argVals[idx] = foo;   
            return &ffi_type_pointer;
        }
        else if (idx == 1) { // arg 2 is always a selector
            *foo = JSTSelectorFromValue(_bridge, argument);
            argVals[idx] = foo;
            return &ffi_type_pointer;
        }
        
        if (!_msgSendMethodRuntimeInfo) {
            // we're going to assume everything is an id right now.
            *foo = JSTNSObjectFromValue(_bridge, argument);
            argVals[idx] = foo;
            
            return &ffi_type_pointer;
        }
        
        *foo                = [_bridge NSObjectForJSObject:(JSObjectRef)argument];
        JSTRuntimeInfo *ri  = [[_msgSendMethodRuntimeInfo arguments] objectAtIndex:idx-2];
        
        return JSTFFITypeForTypeEncoding([ri typeEncoding]);
    }
    else {
        JSTAssert(false);
    }
    
    return 0x00;
}


- (JSValueRef)call {
    
    [self checkForMsgSendMethodRuntimeInfo];
    
    ffi_type **argTypes  = _argumentCount ? malloc(_argumentCount * sizeof(ffi_type*)) : 0x00;
    void     **argVals   = _argumentCount ? malloc(_argumentCount * sizeof(void*)) : 0x00;
    
    for (int j = 0; j < _argumentCount; j++) {
        argTypes[j] = [self setValue:*(void**)&argVals atIndex:j];
    }
    
    ffi_type *returnFIIType = [self setValue:nil atIndex:-1];
    
    ffi_cif cif;
    ffi_status status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (unsigned)_argumentCount, returnFIIType, argTypes);
    if (status != FFI_OK) {
        NSLog(@"Got result %ld from ffi_prep_cif", (long)status);
        abort();
    }
    
    ffi_arg result;
    
    @try {
        ffi_call(&cif, _callAddress, &result, argVals);
    }
    @catch (NSException * e) {
        NSLog(@"Exception: %@", e);
    }
    
    if (argTypes) {
        free(argTypes);
    }
    
    if (argVals) {
        free(argVals);
    }
    
    [_allocations release];
    
    if (returnFIIType == &ffi_type_void) {
        return JSValueMakeNull([_bridge jsContext]);
    }
    else if (returnFIIType == &ffi_type_pointer) {
        return [_bridge makeJSObjectWithNSObject:(id)result runtimeInfo:nil];
    }
    else if (returnFIIType == &ffi_type_sint8) {
        // well, it's a bool or a char or a ... hrm.
        return JSValueMakeBoolean([_bridge jsContext], (bool)result);
    }
    
    JSTAssert(false);
     
    return nil;
}


- (id)initWithFunctionName:(NSString*)name bridge:(JSTBridge*)bridge runtimeInfo:(JSTRuntimeInfo*)runtimeInfo {
    
    if ((self = [self init])) {
        _callAddress = dlsym(RTLD_DEFAULT, [name UTF8String]);
        if (!_callAddress) {
            [self release];
            return nil;
        }
        
        _functionName = [name retain];
        _runtimeInfo  = [runtimeInfo retain];
        _bridge       = [bridge retain];
        
        _closure = AllocateClosure();
    }
    
    return self;
}


- (void)dealloc {
    
    if (_closure) {
        DeallocateClosure(_closure);
    }
        
    [_allocations release];
    [_functionName release];
    [_runtimeInfo release];
    [_bridge release];
    
    [super dealloc];
}

- (void *)fptr {
    return _closure;
}

@end


@implementation JSTClosure (TestExtras)

- (BOOL)testBoolValue {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return YES;
}

- (BOOL)testClassBoolValue {
    assert(false);
}

+ (BOOL)testClassBoolValue {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return YES;
}

- (NSString*)testStringValue {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return @"String from testStringValue";
}

+ (NSString*)testClassStringValue {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return @"String from testClassStringValue";
}

- (NSString*)testAppendString:(NSString*)string {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return [NSString stringWithFormat:@"String from testAppendString: %@", string];
}

- (NSString*)testClassAppendString:(NSString*)string {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return [NSString stringWithFormat:@"String from testClassAppendString: %@", string];
}


@end
















