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
    return YES;
}

- (BOOL)testClassBoolValue {
    // this should never be called.
    assert(false);
}

+ (BOOL)testClassBoolValue {
    return YES;
}

- (NSString*)testStringValue {
    return @"String from testStringValue";
}

+ (NSString*)testClassStringValue {
    return @"String from testClassStringValue";
}

- (NSString*)testAppendString:(NSString*)string {
    return [NSString stringWithFormat:@"String from testAppendString: %@", string];
}

- (NSString*)testClassAppendString:(NSString*)string {
    return [NSString stringWithFormat:@"String from testClassAppendString: %@", string];
}

+ (NSString*)nonBridgedClassMethodReturnString {
    return @"String from nonBridgedClassMethodReturnString";
}

- (NSString*)nonBridgedInstanceMethodReturnString {
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

- (float)nonBridgedInstanceMethodReturnFloat {
    return 4.5f;
}


- (float)nonBridgedInstanceMethodReturnAddAndReturnFloat:(float)val {
    return val + 4.5f;
}

- (double)nonBridgedInstanceMethodReturnDouble {
    return 14.5;
}


- (double)nonBridgedInstanceMethodReturnAddAndReturnDouble:(double)val {
    return val + 14.5f;
}

- (long double)nonBridgedInstanceMethodReturnAddAndReturnLongDouble:(long double)val {
    debug(@"val: %Lf", val);
    return val + 50.f;
}

+ (JSTTestStruct)classTestStruct {
    JSTTestStruct foo;
   
    foo.b = 1;
   
    return foo; 
}

+ (NSRect)classTestNSRect {
    return NSMakeRect(1,2,3,4);
}

@end
