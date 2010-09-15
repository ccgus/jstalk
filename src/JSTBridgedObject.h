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

@interface JSTBridgedObject : NSObject {
    int                 _objectType;
    NSString            *_name;
    NSString            *_type;
    
    NSMutableArray      *_structFields;
    
    NSString            *_declaredType;
    
    int                 _enumValue;
    
    NSMutableArray      *_arguments;
    JSTBridgedObject    *_returnValue;
    
    NSMutableDictionary *_instanceMethods;
    NSMutableDictionary *_classMethods;
    
    NSString            *_methodSelector;
}

@property (assign) int objectType;
@property (retain) NSString *name;
@property (retain) NSString *type;
@property (retain) NSString *declaredType;
@property (assign) int enumValue;
@property (retain) JSTBridgedObject *returnValue;
@property (retain) NSString *methodSelector;

- (NSArray *)structFields;
- (void)addStructField:(NSString*)s;

- (NSArray *)arguments;
- (void)addArgument:(JSTBridgedObject*)arg;

- (NSDictionary *)instanceMethods;
- (void)addInstanceMethod:(JSTBridgedObject*)arg;

- (NSDictionary *)classMethods;
- (void)addClassMethod:(JSTBridgedObject*)arg;

// This is a convenience function, so we don't have to have multiple ifdef's 
// in our parser code.
- (void)grabTypeFromAttributes:(NSDictionary*)atts;

@end
