//
//  MOClosure.h
//  Mocha
//
//  Created by Logan Collins on 5/19/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOClosure : NSObject

+ (MOClosure *)closureWithBlock:(id)block;

- (id)initWithBlock:(id)block;

@property (copy, readonly) id block;

@property (readonly) void * callAddress;
@property (readonly) const char * typeEncoding;

@end
