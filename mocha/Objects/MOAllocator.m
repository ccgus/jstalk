//
//  MOAllocator.m
//  Mocha
//
//  Created by Logan Collins on 7/25/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import "MOAllocator.h"


@implementation MOAllocator {
    id _object;
}

@synthesize objectClass=_objectClass;

+ (MOAllocator *)allocator {
    return [self alloc];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    return [[self objectClass] instanceMethodSignatureForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    if (_object == nil) {
        _object = [[self objectClass] alloc];
    }
    [anInvocation invokeWithTarget:_object];
}

@end
