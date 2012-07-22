//
//  MOUndefined.m
//  Mocha
//
//  Created by Logan Collins on 5/15/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import "MOUndefined.h"


@implementation MOUndefined

static MOUndefined *sharedInstance = nil;

+ (MOUndefined *)undefined {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (id)allocWithZone:(NSZone *)zone {
    if (sharedInstance == nil) {
        return [super allocWithZone:zone];
    }
    else {
        return nil;
    }
}

- (id)retain {
    return self;
}

- (oneway void)release {
    // no-op
}

- (id)autorelease {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

@end
