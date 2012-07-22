//
//  MOJavaScriptObject.h
//  Mocha
//
//  Created by Logan Collins on 5/28/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>


@interface MOJavaScriptObject : NSObject

+ (MOJavaScriptObject *)objectWithJSObject:(JSObjectRef)jsObject context:(JSContextRef)ctx;

@property JSObjectRef JSObject;
@property JSContextRef JSContext;

@end
