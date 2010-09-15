//
//  JSTBridgeType.m
//  jstalk
//
//  Created by August Mueller on 9/15/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTBridgedObject.h"


@implementation JSTBridgedObject

@synthesize objectType=_objectType;
@synthesize name=_name;
@synthesize type=_type;
@synthesize declaredType=_declaredType;
@synthesize enumValue=_enumValue;
@synthesize returnValue=_returnValue;
@synthesize methodSelector=_methodSelector;


- (void)dealloc {
    [_name release];
    [_type release];
    [_structFields release];
    [_declaredType release];
    [_arguments release];
    [_returnValue release];
    [_methodSelector release];
    [_instanceMethods release];

    [super dealloc];
}

- (NSArray *)structFields {
    return _structFields;
}

- (void)addStructField:(NSString*)s {
    if (!_structFields) {
        _structFields = [[NSMutableArray alloc] init];
    }
    
    [_structFields addObject:s];
}

- (NSArray *)arguments {
    return _arguments;
}
- (void)addArgument:(JSTBridgedObject*)arg {
    if (!_arguments) {
        _arguments = [[NSMutableArray alloc] init];
    }
    
    [_arguments addObject:arg];
}



- (NSDictionary *)instanceMethods {
    return _instanceMethods;
}

- (void)addInstanceMethod:(JSTBridgedObject*)arg {
    if (!_instanceMethods) {
        _instanceMethods = [[NSMutableDictionary alloc] init];
    }
    
    [_instanceMethods setObject:arg forKey:[arg methodSelector]];
}


- (NSDictionary *)classMethods {
    return _instanceMethods;
}

- (void)addClassMethod:(JSTBridgedObject*)arg {
    if (!_classMethods) {
        _classMethods = [[NSMutableDictionary alloc] init];
    }
    
    [_classMethods setObject:arg forKey:[arg methodSelector]];
}

- (void)grabTypeFromAttributes:(NSDictionary*)atts {
    
#if defined(__x86_64__)
    if ([atts objectForKey:@"type64"]) {
        [self setType:[atts objectForKey:@"type64"]];
    }
    else
#endif
    {
        [self setType:[atts objectForKey:@"type"]];
    }
}

@end
