//
//  JSTTests.h
//  jstalk
//
//  Created by August Mueller on 9/26/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

/*
 This file is used by gen_bridge_metadata, and for some of our unit tests.
 
 http://www.mail-archive.com/macruby-devel@lists.macosforge.org/msg01492.html
 
 cd /builds/Debug/JSTalk.framework/Headers/
 gen_bridge_metadata -F exceptions-template -c '-I.' JSTTests.h > exception.xml
 gen_bridge_metadata  -e ./exception.xml -f /builds/Debug/JSTalk.framework -o JSTalk.bridgesupport
*/

#import <Cocoa/Cocoa.h>

struct JSTTestStruct {
    BOOL        b;
    /*
    float       f;
    double      d;
    int8_t      i8;
    uint8_t     ui8;
    int16_t     i16;
    uint16_t    ui16;
    int32_t     i32;
    uint32_t    ui32;
    int64_t     i64;
    uint64_t    ui64;
    
    struct JSTTestStruct *next;
    */
};
typedef struct JSTTestStruct JSTTestStruct;

@interface JSTTests : NSObject {

}

+ (JSTTestStruct)classTestStruct;
+ (NSRect)classTestNSRect;

/*
+ (BOOL)testClassBoolValue;

- (NSString*)testStringValue;
+ (NSString*)testClassStringValue;

- (NSString*)testAppendString:(NSString*)string;
- (NSString*)testClassAppendString:(NSString*)string;
*/

@end
