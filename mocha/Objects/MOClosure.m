//
//  MOClosure.m
//  Mocha
//
//  Created by Logan Collins on 5/19/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import "MOClosure.h"
#import "MOClosure_Private.h"

#import "MOUtilities.h"


@implementation MOClosure

@synthesize block=_block;

//
// The following two structs are taken from clang's source.
//

struct Block_descriptor {
    unsigned long reserved;
    unsigned long size;
    void *rest[1];
};

struct Block_literal {
    void *isa;
    int flags;
    int reserved;
    void *invoke;
    struct Block_descriptor *descriptor;
};

+ (MOClosure *)closureWithBlock:(id)block {
    return [[[self alloc] initWithBlock:block] autorelease];
}

- (id)initWithBlock:(id)block {
    self = [super init];
    if (self) {
        _block = [block copy];
    }
    return self;
}

- (void)dealloc {
    [_block release];
    [super dealloc];
}

- (void *)callAddress {
    return ((struct Block_literal *)_block)->invoke;
}

- (const char *)typeEncoding {
    struct Block_literal *block = (struct Block_literal *)_block;
    struct Block_descriptor *descriptor = block->descriptor;
    
    int copyDisposeFlag = 1 << 25;
    int signatureFlag = 1 << 30;
    
    assert(block->flags & signatureFlag);
    
    int index = 0;
    if (block->flags & copyDisposeFlag) {
        index += 2;
    }
    
    return descriptor->rest[index];
}

@end
