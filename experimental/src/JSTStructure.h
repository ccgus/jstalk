//
//  JSTStructure.h
//  jstalk
//
//  Created by August Mueller on 10/13/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JSTRuntimeInfo.h"
#import "JSTBridge.h"

@interface JSTStructure : NSObject {
    NSMutableData *_bytes;
    JSTRuntimeInfo *_runtimeInfo;
    JSTBridge *_bridge;
}

@property (retain) NSMutableData *bytes;
@property (assign) JSTRuntimeInfo *runtimeInfo;
@property (assign) JSTBridge *bridge;

+ (id)structureWithData:(NSMutableData*)data bridge:(JSTBridge*)bridge;
- (JSValueRef)cantThinkOfAGoodNameForThisYet:(NSString*)prop outException:(JSValueRef*)exception;

- (BOOL)setValue:(JSValueRef)value forFieldNamed:(NSString*)field outException:(JSValueRef*)exception;

@end
