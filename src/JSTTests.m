//
//  JSTTests.m
//  jstalk
//
//  Created by August Mueller on 9/26/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTTests.h"


@implementation JSTTests


- (BOOL)testBoolValue {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return YES;
}

- (BOOL)testClassBoolValue {
    // this should never be called.
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

+ (NSString*)nonBridgedClassMethodReturnString {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return @"String from nonBridgedClassMethodReturnString";
}

- (NSString*)nonBridgedInstanceMethodReturnString {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    return @"String from nonBridgedInstanceMethodReturnString";
}

+ (int)nonBridgedClassMethodReturnInt {
    return 34;
}

- (int)nonBridgedInstanceMethodReturnInt {
    return 36;
}


+ (int)nonBridgedClassMethodAddIntTo34:(int)val {
    return 34 + val;
}

- (int)nonBridgedInstanceMethodAddIntTo34:(int)val {
    return 34 + val;
}

@end
