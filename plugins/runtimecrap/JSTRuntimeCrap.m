#import "JSTRuntimeCrap.h"
#import <JSTalk/JSTalk.h>

@implementation JSTRuntimeCrap

@end


id jsobjc_msgSendFix(id value) {
    if (value <= (void*)0xa) {
        return nil;
    }
    
    return value;
}

id jsobjc_msgSendV(id self, SEL op, va_list args) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, args));
}

id jsobjc_msgSend(id self, SEL op) {
    return jsobjc_msgSendFix(objc_msgSend(self, op));
}

id jsobjc_msgSend1(id self, SEL op, id arg) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg));
}

id jsobjc_msgSend2(id self, SEL op, id arg1, id arg2) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg1, arg2));
}

id jsobjc_msgSend3(id self, SEL op, id arg1, id arg2, id arg3) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg1, arg2));
}

id jsobjc_msgSend4(id self, SEL op, id arg1, id arg2, id arg3, id arg4) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg1, arg2, arg3, arg4));
}

id jsobjc_msgSend5(id self, SEL op, id arg1, id arg2, id arg3, id arg4, id arg5) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg1, arg2, arg3, arg4, arg5));
}

id jsobjc_msgSend6(id self, SEL op, id arg1, id arg2, id arg3, id arg4, id arg5, id arg6) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg1, arg2, arg3, arg4, arg5, arg6));
}

id jsobjc_msgSend7(id self, SEL op, id arg1, id arg2, id arg3, id arg4, id arg5, id arg6, id arg7) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg1, arg2, arg3, arg4, arg5, arg6, arg7));
}

id jsobjc_msgSend8(id self, SEL op, id arg1, id arg2, id arg3, id arg4, id arg5, id arg6, id arg7, id arg8) {
    return jsobjc_msgSendFix(objc_msgSend(self, op, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8));
}

@interface JSTObjC : NSObject { } @end 

@implementation JSTObjC
+ (void)jsobjc_msgSend1:(id)o sel:(SEL)s arg:(id)arg1 {
    jsobjc_msgSend1(o, s, arg1);
}

@end

@interface JSTestBlocks : NSObject { } @end 

@implementation JSTestBlocks



- (id) init {
	self = [super init];
	if (self != nil) {
		
        
        NSString *customBS = [[NSBundle bundleForClass:[self class]] pathForResource:@"JSTalk" ofType:@"bridgesupport"];
        
        if (customBS && ![[BridgeSupportController sharedController] isBridgeSupportLoaded:customBS]) {
            if (![[BridgeSupportController sharedController] loadBridgeSupport:customBS]) {
                NSLog(@"Could not load JSTalk's bridge support file: %@", customBS);
            }
        }
        
        
	}
	return self;
}



+ (void)testThisFunction:(JSValueRefAndContextRef)callbackFunction {
    id jsc = [JSCocoa controllerFromContext:callbackFunction.ctx];
    [jsc callJSFunction:callbackFunction.value withArguments:[NSArray arrayWithObjects:@"Hai", nil]];
}

+ (id)newErrorBlockForJSFunction:(JSValueRefAndContextRef)callbackFunction {
    
    
    debug(@"callbackFunction: %p", (void*)callbackFunction.ctx);
    
    id jsc = [JSCocoa controllerFromContext:callbackFunction.ctx];
    void (^theBlock)(NSError *) = ^(NSError *err) {
        [jsc callJSFunction:callbackFunction.value withArguments:[NSArray arrayWithObjects:err, nil]];
    };
    
    return [theBlock copy];
}

+ (void)testFunction:(void (^)(NSError *))theBlock {
    theBlock(nil);
}

@end






