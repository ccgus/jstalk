//
//  JSTBridgeType.h
//  jstalk
//
//  Created by August Mueller on 9/15/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum {
    JSTTypeUnknown,
    JSTTypeStruct,
    JSTTypeConstant,
    JSTTypeEnum,
    JSTTypeFunction,
    JSTTypeMethod,
    JSTTypeClass,
};

@interface JSTRuntimeInfo : NSObject {
    int                 _jstType;
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
    
    BOOL                _isVariadic;
}


@property (assign, setter=setJSTType:) int jstType;
@property (retain) NSString *symbolName;
@property (retain) NSString *typeEncoding;
@property (retain) NSString *declaredType;
@property (assign) int enumValue;
@property (retain) JSTRuntimeInfo *returnValue;
@property (retain) NSString *methodSelector;
@property (assign) BOOL isVariadic;

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
- (void)grabEnumValueFromAttributes:(NSDictionary*)atts;

- (JSTRuntimeInfo*)runtimeInfoForClassMethodName:(NSString*)name;
- (JSTRuntimeInfo*)runtimeInfoForInstanceMethodName:(NSString*)name;

- (NSMutableArray*)functionEncodings;

@end
