#import "JSTFunction.h"
#import "JSTStructure.h"

@interface JSTFunction ()
- (Method)objcMethod;
@end

@implementation JSTFunction
@synthesize functionName=_functionName;
@synthesize forcedObjcTarget=_forcedObjcTarget;
@synthesize forcedObjcSelector=_forcedObjcSelector;

static void BlockClosure(ffi_cif *cif, void *ret, void **args, void *userdata)
{
    JSTFunction *self = userdata;
    
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


- (NSMutableData *)_allocateData:(size_t)howmuch {
    if (!_allocations) {
        _allocations = [[NSMutableArray alloc] init];
    }
    
    
    NSMutableData *data = [[NSMutableData alloc] initWithLength:howmuch];
    [_allocations addObject:data];
    [data release];
    
    return data;
}

- (void *)_allocate:(size_t)howmuch {
    
    NSMutableData *data = [self _allocateData:howmuch];
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
    //COND(long double, longdouble);
    
    //printf("%s\n", @encode(float));
    
    //if(str[0] == @encode(long double)[0])
    //    return &ffi_type_longdouble;
    
    
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
    
    if (_forcedObjcTarget) {
        
        JSValueRef *newArgs = malloc(sizeof(JSValueRef *) * (_argumentCount + 2));
        
        newArgs[0] = JSObjectMake([_bridge jsContext], [_bridge bridgedObjectClass], _forcedObjcTarget);
        newArgs[1] = JSObjectMake([_bridge jsContext], [_bridge bridgedObjectClass], _forcedObjcSelector);
        
        for (int j = 0; j < _argumentCount; j++) {
            newArgs[j+2] = args[j];
        }
        
        _jsArguments = newArgs;
        _argumentCount += 2;
    }
    
    
}

void JSTFunctionFunction(ffi_cif* cif, void* resp, void** args, void* userdata) {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
	//[(id)userdata calledByClosureWithArgs:args returnValue:resp];
}

- (void)checkForMsgSendMethodRuntimeInfo {
    
    if ((_callAddress != &objc_msgSend) || (_argumentCount < 2)) {
        //debug(@"%@ Can't possibly be objc_msgSend", _functionName);
        return;
    }
    
    id target           = JSTNSObjectFromValue(_bridge, _jsArguments[0]);
    NSString *sel       = JSTNSObjectFromValue(_bridge, _jsArguments[1]);
    BOOL isClassMethod  = class_isMetaClass(object_getClass(target));
    
    JSTRuntimeInfo *instanceInfo = [_bridge runtimeInfoForObject:target];
    if (!instanceInfo) {
        NSString *classString = NSStringFromClass(isClassMethod ? target :[target class]);
        instanceInfo = [JSTBridgeSupportLoader runtimeInfoForSymbol:classString];
    }
    
    //debug(@"instanceInfo: '%@'", instanceInfo);
    
    if (isClassMethod) { // are we dealing with an Class method?
        _msgSendMethodRuntimeInfo = [instanceInfo runtimeInfoForClassMethodName:sel];
    }
    else {
        _msgSendMethodRuntimeInfo = [instanceInfo runtimeInfoForInstanceMethodName:sel];
    }
    
    
    if (!_msgSendMethodRuntimeInfo) {
        [self objcMethod]; // go ahead and cache that guy.
        
        if (!_objcMethod) {
            debug(@"Can't find runtime info for: %c[%@ %@]", isClassMethod ? '+' : '-', target, sel);
        }
    }
    else {
        //debug(@"Setup to call: %c[%@ %@]", isClassMethod ? '+' : '-', NSStringFromClass(isClassMethod ? target : [target class]), sel);
    }
}


- (Method)objcMethod {
    
    if (_objcMethod) {
        return _objcMethod;
    }
    
    JSTAssert((_callAddress == &objc_msgSend));
    JSTAssert(_argumentCount > 1);
    
    id target = JSTNSObjectFromValue(_bridge, _jsArguments[0]);
    SEL sel   = JSTSelectorFromValue(_bridge, _jsArguments[1]);
    
    if (class_isMetaClass(object_getClass(target))) { // are we dealing with an Class method?
        _objcMethod = class_getClassMethod(target, sel);
    }
    else {
        _objcMethod = class_getInstanceMethod(object_getClass(target), sel);
    }
    
    return _objcMethod;
}

-(ffi_type*)encodingsForStructure:(NSString*)typeEncoding {
    
    debug(@"generating encodings for %@", typeEncoding);
    
    NSArray *encodings       = JSTTypeEncodingsFromStructureTypeEncoding(typeEncoding);
    
    ffi_type *structInfo     = [self _allocate:sizeof(ffi_type)];
    structInfo->alignment    = 0; // wow this is probably wrong.
    structInfo->type         = FFI_TYPE_STRUCT;
    structInfo->elements     = [self _allocate:(sizeof(ffi_type*) * ([encodings count] + 1))];
    
    int idx = 0;
    
    for (NSString *e in encodings) {
        int size = JSTSizeOfTypeEncoding(e);
        
        structInfo->size += size;
        structInfo->elements[idx] = JSTFFITypeForTypeEncoding(e);
        idx++;
    }
    
    structInfo->size = MAX(structInfo->size, sizeof(ffi_arg));
    
    structInfo->elements[idx]   = nil; // this guy is nil terminated
    
    return structInfo;
}

-(ffi_type*)setupReturnType {
    
    if (_msgSendMethodRuntimeInfo || (_callAddress == &objc_msgSend)) {
        
        ffi_type *retType = &ffi_type_pointer;
        
        if (_msgSendMethodRuntimeInfo) {
            retType = JSTFFITypeForTypeEncoding([[_msgSendMethodRuntimeInfo returnValue] typeEncoding]);
            
            if (retType == &ffi_type_jst_structure) {
                debug(@"we need to setup for a struct");
                _callAddress = &objc_msgSend_stret;
                return [self encodingsForStructure:[[_msgSendMethodRuntimeInfo returnValue] typeEncoding]];
            }
        }
        else {
            const char *c = method_getTypeEncoding([self objcMethod]);
            if (c) {
                retType = [self _ffiArgForEncode:c];
            }
            else {
                NSLog(@"Whoa, couldn't find the return type at all for %@", _functionName);
            }
        }
        
        // leme just check something here...
        if (retType == &ffi_type_float || retType == &ffi_type_double || retType == &ffi_type_longdouble) {
            //_returnStorage = [self _allocate:(sizeof(long double*))];
            _callAddress = &objc_msgSend_fpret;
        }
        else {
            //_returnStorage = [self _allocate:(sizeof(void*))];
        }
        
        return retType;
    }
    
    JSTRuntimeInfo *info = [JSTBridgeSupportLoader runtimeInfoForSymbol:_functionName];
    
    if ([info returnValue]) {
        
        if ([[[info returnValue] typeEncoding] hasPrefix:@"{"]) {
           return [self encodingsForStructure:[[info returnValue] typeEncoding]];
        }
        
        
        return JSTFFITypeForTypeEncoding([[info returnValue] typeEncoding]);
    }
    
    return &ffi_type_void;
}

-(ffi_type*)setValue:(void**)argVals atIndex:(int)idx {
    
    JSValueRef argument = _jsArguments[idx];
    
    if (_msgSendMethodRuntimeInfo || (_callAddress == &objc_msgSend)) {
        
        void **foo = [self _allocate:(sizeof(void*))];
        
        if (idx == 0) { // this is the target
            *foo = JSTNSObjectFromValue(_bridge, argument);
            argVals[idx] = foo;   
            return &ffi_type_pointer;
        }
        else if (idx == 1) { // arg 2 is always a selector
            *foo = JSTSelectorFromValue(_bridge, argument);
            
            debug(@"selector: '%@'", NSStringFromSelector(*foo));
            
            argVals[idx] = foo;
            return &ffi_type_pointer;
        }
        
        
        if (_msgSendMethodRuntimeInfo) {
            
            // FIXME: this is lame.
            // FIXME: Why shouldn't we just fall back on the _objcMethod stuff?
            [self objcMethod];
        }
        
        if (!_encodedArgsForUnbridgedMsgSend) {
            
            JSTAssert(_objcMethod);
            const char *c = method_getTypeEncoding(_objcMethod);
            JSTAssert(c);
            
            int argCount;
            _encodedArgsForUnbridgedMsgSend = [self _argsWithEncodeString:c getCount:&argCount];
            
            if (argCount != _argumentCount) {
                NSLog(@"WHOA WHOA WHOA THE ARGUMENT COUNT IS OFF!");
                JSTAssert(false);
            }
        }
        
        assert(_encodedArgsForUnbridgedMsgSend);
        
        ffi_type *retType = _encodedArgsForUnbridgedMsgSend[idx];
        
        if (retType == &ffi_type_pointer) {
            *foo = JSTNSObjectFromValue(_bridge, argument);
            argVals[idx] = foo;
        }
        else if (retType == &ffi_type_sint32) {
            *foo = (void*)((int32_t)JSTLongFromValue(_bridge, argument));
            argVals[idx] = foo;
        }
        else if (retType == &ffi_type_uint32) {
            void **storage = [self _allocate:(sizeof(void*))];
            *storage = (void*)((uint32_t)JSTLongFromValue(_bridge, argument));
            argVals[idx] = storage;
        }
        else if (retType == &ffi_type_uint64) {
            void **storage = [self _allocate:(sizeof(void*))];
            *storage = (void*)((uint64_t)JSTLongFromValue(_bridge, argument));
            argVals[idx] = storage;
        }
        else if (retType == &ffi_type_float) {
            float **floatStorage = [self _allocate:(sizeof(float*))];
            *(float*)floatStorage = (float)JSTDoubleFromValue(_bridge, argument);
            argVals[idx] = floatStorage;
        }
        else if (retType == &ffi_type_double) {
            double **floatStorage = [self _allocate:(sizeof(double*))];
            *(double*)floatStorage = (double)JSTDoubleFromValue(_bridge, argument);
            argVals[idx] = floatStorage;
        }
        else if (retType == &ffi_type_longdouble) {
            long double **floatStorage = [self _allocate:(sizeof(long double*))];
            *(long double*)floatStorage = JSTDoubleFromValue(_bridge, argument);
            debug(@"*(long double*)floatStorage: %Lf", *(long double*)floatStorage);
            argVals[idx] = floatStorage;
        }
        else {
            debug(@"retType: '%@'", JSTStringForFFIType(retType));
            debug(@"not sure what to do with this guy!");
            assert(false);
        }
        
        return retType;
    }
    else {
        
        if (_runtimeInfo) {
            if ([_runtimeInfo isVariadic]) {
                // everything is pointers here...
                void **foo = [self _allocate:(sizeof(void*))];
                
                *foo = JSTNSObjectFromValue(_bridge, argument);
                argVals[idx] = foo;   
                return &ffi_type_pointer;
            }
            else {
                
                #warning refactor this with the crap above.
                
                JSTRuntimeInfo *ri = [[_runtimeInfo arguments] objectAtIndex:idx];
                
                ffi_type *retType = JSTFFITypeForTypeEncoding([ri typeEncoding]);
                
                if (retType == &ffi_type_float) {
                    float **floatStorage = [self _allocate:(sizeof(float*))];
                    *(float*)floatStorage = (float)JSTDoubleFromValue(_bridge, argument);
                    argVals[idx] = floatStorage;
                    return retType;
                }
                else if (retType == &ffi_type_double) {
                    double **floatStorage = [self _allocate:(sizeof(double*))];
                    *(double*)floatStorage = (double)JSTDoubleFromValue(_bridge, argument);
                    argVals[idx] = floatStorage;
                    return retType;
                }
                else if (retType == &ffi_type_uint64) {
                    
                    uint32_t **storage = [self _allocate:(sizeof(uint32_t*))]; 
                    
                    *(uint32_t*)storage = (uint32_t)JSTDoubleFromValue(_bridge, argument);
                    argVals[idx] = storage;
                    return retType;
                }
                if (retType == &ffi_type_pointer) {
                    void **foo = [self _allocate:(sizeof(void*))];
                    
                    *foo = JSTNSObjectFromValue(_bridge, argument);
                    argVals[idx] = foo;   
                    return retType;
                }
                else {
                    
                    assert(false);
                }
                
                
                debug(@"typeEncoding: '%@'", [ri typeEncoding]);
                
                
                //*foo = [_bridge NSObjectForJSObject:(JSObjectRef)argument];
                //return ;
            }
        }
        else {
            JSTAssert(false);
        }
    }
    
    return 0x00;
}


- (JSValueRef)call:(JSValueRef*)exception {
    
    [self checkForMsgSendMethodRuntimeInfo];
    
    debug(@"Calling %@", _functionName);
    
    BOOL success        = YES;
    ffi_type **argTypes = _argumentCount ? malloc(_argumentCount * sizeof(ffi_type*)) : 0x00;
    void **argVals      = _argumentCount ? malloc(_argumentCount * sizeof(void*)) : 0x00;
    
    for (int j = 0; j < _argumentCount; j++) {
        argTypes[j] = [self setValue:*(void**)&argVals atIndex:j];
    }
    
    ffi_type *returnFIIType = [self setupReturnType];
    
    ffi_cif cif;
    ffi_status status = ffi_prep_cif(&cif, FFI_DEFAULT_ABI, (unsigned)_argumentCount, returnFIIType, argTypes);
    if (status != FFI_OK) {
        if (status == FFI_BAD_TYPEDEF) {
            debug(@"FFI_BAD_TYPEDEF");
        }
        else if (status == FFI_BAD_ABI) {
            debug(@"FFI_BAD_ABI");
        }
        else {
            debug(@"unknown ffi status: %d", status);
        }
        
        JSTAssert(NO);
    }
    
    void *returnValue;
    
    @try {
        ffi_call(&cif, _callAddress, &returnValue, argVals);
    }
    @catch (NSException * e) {
        success = NO;
        JSTAssignException(_bridge, exception, [e description]);
    }
    
    if (argTypes) {
        free(argTypes);
    }
    
    if (argVals) {
        free(argVals);
    }
    
    JSValueRef retJS = nil;
    
    if (success) {
        
        //debug(@"success!");
        
        if (returnFIIType->type == FFI_TYPE_STRUCT) {
            // crap must hold on to the memory!
            
            debug(@"returning a struct.");
            
            NSMutableData *data = [self _allocateData:returnFIIType->size];
            void *value = [data mutableBytes];
            memcpy(value, &returnValue, returnFIIType->size);
            
            if ([_functionName isEqualToString:@"NSMakeRect"]) {
                //NSLog(@"the rect: %@", NSStringFromRect(*(NSRect*)value));
            }
            
            JSTStructure *structure = [JSTStructure structureWithData:data bridge:_bridge];
            JSTRuntimeInfo *info    = [JSTBridgeSupportLoader runtimeInfoForSymbol:[[_runtimeInfo returnValue] declaredType]];
            
            if (!info) {
                info = [JSTBridgeSupportLoader runtimeInfoForSymbol:[[_msgSendMethodRuntimeInfo returnValue] declaredType]];
            }
            
            if (!info) {
                info = [[JSTBridgeSupportLoader runtimeInfoForSymbol:_functionName] returnValue];
            }
            
            [structure setRuntimeInfo:info];
            
            debug(@"structure: '%@'", structure);
            
            retJS = [_bridge makeJSObjectWithNSObject:structure runtimeInfo:nil];
            
        }
        else {
            //debug(@"oh?");
            retJS = JSTMakeJSValueWithFFITypeAndValue(returnFIIType, returnValue, _bridge);
        }
        
        JSTAssert(retJS);
    }
    
    [_allocations release];
    
    return retJS;
}

- (id)initWithFunctionName:(NSString*)name bridge:(JSTBridge*)bridge runtimeInfo:(JSTRuntimeInfo*)runtimeInfo {
    
    if ((self = [self init])) {
        _callAddress = dlsym(RTLD_DEFAULT, [name UTF8String]);
        
        if (!_callAddress) {
            debug(@"Can't find the function named '%@', returning nil", name);
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
    
    if (_forcedObjcTarget) {
        free(_jsArguments);
    }
    
    [_forcedObjcTarget release];
    [_forcedObjcSelector release];
    
    [super dealloc];
}

- (void *)fptr {
    return _closure;
}

@end

@implementation JSTValueOfFunction

@synthesize target=_target;

- (id)initWithTarget:(id)target bridge:(JSTBridge*)bridge {
	self = [super init];
	if (self != nil) {
		_target = [target retain];
        _bridge = [bridge retain];
        _functionName = [@"<internal valueOf function>" retain];
	}
	return self;
}

- (void)dealloc {
    [_target release];
    [super dealloc];
}

- (JSValueRef)call:(JSValueRef*)exception {
    
    JSValueRef ret = 0x00;
    
    if ([_target isKindOfClass:[NSString class]]) {
        JSStringRef jsString  = JSStringCreateWithUTF8CString([_target UTF8String]);
        ret = JSValueMakeString([_bridge jsContext], jsString);
        JSStringRelease(jsString);
    }
    else if ([_target isKindOfClass:[NSNull class]]) {
        ret = JSValueMakeNull([_bridge jsContext]);
    }
    else if ([_target isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([_target objCType], @encode(BOOL)) == 0) {
            ret = JSValueMakeBoolean([_bridge jsContext], [_target boolValue]);
        }
        else {
            ret = JSValueMakeNumber([_bridge jsContext], [_target floatValue]);
        }
    }
    else {
        JSStringRef jsString  = JSStringCreateWithUTF8CString([[_target description] UTF8String]);
        ret = JSValueMakeString([_bridge jsContext], jsString);
        JSStringRelease(jsString);
    }
    
    return ret;
}    

@end

@implementation JSTToStringFunction

@synthesize target=_target;

- (id)initWithTarget:(id)target bridge:(JSTBridge*)bridge {
	self = [super init];
	if (self != nil) {
		_target = [target retain];
        _bridge = [bridge retain];
        _functionName = [@"<internal toString function>" retain];
	}
	return self;
}

- (void)dealloc {
    [_target release];
    [super dealloc];
}

- (JSValueRef)call:(JSValueRef*)exception {
    
    NSString *ret = 0x00;
    
    if ([_target isKindOfClass:[NSString class]]) {
        ret = _target;
    }
    else if ([_target isKindOfClass:[NSNull class]]) {
        ret = @"null";
    }
    else if ([_target isKindOfClass:[NSNumber class]]) {
        
        if (strcmp([_target objCType], @encode(BOOL)) == 0) {
            ret = [_target boolValue] ? @"true" : @"false";
        }
        else if (strcmp([_target objCType], @encode(int)) == 0) {
            ret = [NSString stringWithFormat:@"%d", [_target intValue]];
        }
        else {
            ret = [NSString stringWithFormat:@"%f", [_target doubleValue]];
        }
    }
    else {
        ret = [_target description];
    }
    
    if (!ret) {
        return JSValueMakeNull([_bridge jsContext]);
    }
    
    JSStringRef jsString  = JSStringCreateWithUTF8CString([ret UTF8String]);
    JSValueRef jsRet = JSValueMakeString([_bridge jsContext], jsString);
    JSStringRelease(jsString);
    
    return jsRet;
}    

@end

