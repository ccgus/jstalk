//
//  JSTBridgeType.h
//  jstalk
//
//  Created by August Mueller on 9/15/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    JSTUnknown,
    JSTStruct,
    JSTConstant,
    JSTEnum,
    JSTFunction,
    JSTMethod,
    JSTClass,
};

@interface JSTRuntimeInfo : NSObject {
    int                 _objectType;
    NSString            *_symbolName;
    NSString            *_typeEncoding;
    
    NSMutableArray      *_structFields;
    
    NSString            *_declaredType;
    
    int                 _enumValue;
    
    NSMutableArray      *_arguments;
    JSTRuntimeInfo      *_returnValue;
    
    NSMutableDictionary *_instanceMethods;
    NSMutableDictionary *_classMethods;
    
    NSString            *_methodSelector;
}

@property (assign) int objectType;
@property (retain) NSString *symbolName;
@property (retain) NSString *typeEncoding;
@property (retain) NSString *declaredType;
@property (assign) int enumValue;
@property (retain) JSTRuntimeInfo *returnValue;
@property (retain) NSString *methodSelector;

- (NSArray *)structFields;
- (void)addStructField:(NSString*)s;

- (NSArray *)arguments;
- (void)addArgument:(JSTRuntimeInfo*)arg;

- (NSDictionary *)instanceMethods;
- (void)addInstanceMethod:(JSTRuntimeInfo*)arg;

- (NSDictionary *)classMethods;
- (void)addClassMethod:(JSTRuntimeInfo*)arg;

// This is a convenience function, so we don't have to have multiple ifdef's 
// in our parser code.
- (void)grabTypeFromAttributes:(NSDictionary*)atts;

- (JSTRuntimeInfo*)runtimeInfoForClassMethodName:(NSString*)name;
- (JSTRuntimeInfo*)runtimeInfoForInstanceMethodName:(NSString*)name;

- (NSMutableArray*)functionEncodings;

@end
