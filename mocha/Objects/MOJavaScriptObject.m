//
//  MOJavaScriptObject.m
//  Mocha
//
//  Created by Logan Collins on 5/28/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import "MOJavaScriptObject.h"


@implementation MOJavaScriptObject

@synthesize JSObject=_JSObject;
@synthesize JSContext=_JSContext;

+ (MOJavaScriptObject *)objectWithJSObject:(JSObjectRef)jsObject context:(JSContextRef)ctx {
    MOJavaScriptObject *object = [[MOJavaScriptObject alloc] init];
    JSValueProtect(ctx, jsObject);
    object.JSObject = jsObject;
    object.JSContext = ctx;
    return [object autorelease];
}

- (void)dealloc {
    JSValueUnprotect(_JSContext, _JSObject);
    [super dealloc];
}

@end
