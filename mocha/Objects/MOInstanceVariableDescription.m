//
//  MOInstanceVariableDescription.m
//  Mocha
//
//  Created by Logan Collins on 5/26/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import "MOInstanceVariableDescription.h"
#import "MOInstanceVariableDescription_Private.h"


@implementation MOInstanceVariableDescription

@synthesize name=_name;
@synthesize typeEncoding=_typeEncoding;

+ (MOInstanceVariableDescription *)instanceVariableWithName:(NSString *)name typeEncoding:(NSString *)typeEncoding {
    return [[[self alloc] initWithName:name typeEncoding:typeEncoding] autorelease];
}

- (id)initWithName:(NSString *)name typeEncoding:(NSString *)typeEncoding {
    self = [super init];
    if (self) {
        self.name = name;
        self.typeEncoding = typeEncoding;
    }
    return self;
}

- (void)dealloc {
    [_name release];
    [_typeEncoding release];
    [super dealloc];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p : name=%@, typeEncoding=%@>", [self class], self, self.name, self.typeEncoding];
}

@end
