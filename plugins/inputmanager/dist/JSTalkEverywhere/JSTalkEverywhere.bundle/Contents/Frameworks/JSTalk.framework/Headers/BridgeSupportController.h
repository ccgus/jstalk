//
//  BridgeSupportController.h
//  JSCocoa
//
//  Created by Patrick Geiller on 08/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif

@class JSBridgeType;

@interface BridgeSupportController : NSObject {

	NSMutableArray*			paths;
	NSMutableArray*			xmlDocuments;

	NSMutableDictionary*	hash;
    
    NSMutableDictionary*    ghash;
    
    JSBridgeType* currentBridgeType;
}

+ (id)sharedController;

- (BOOL)loadBridgeSupport:(NSString*)path;
- (BOOL)isBridgeSupportLoaded:(NSString*)path;
- (NSUInteger)bridgeSupportIndexForString:(NSString*)string;

/*
- (NSString*)query:(NSString*)name withType:(NSString*)type;
- (NSString*)query:(NSString*)name withType:(NSString*)type inBridgeSupportFile:(NSString*)file;
*/
- (NSString*)queryName:(NSString*)name;
- (NSString*)queryName:(NSString*)name type:(NSString*)type;

- (JSBridgeType*) typeForName:(NSString*)name;

@end

extern NSString *JSBridgeTypeConstant;
extern NSString *JSBridgeTypeEnum;
extern NSString *JSBridgeTypeFunction;

@interface JSBridgeType : NSObject {
    NSString *_type;
    NSString *_name;
    NSString *_ctype;
    NSInteger _evalue;
    
    NSArray *_args;
    NSDictionary *_retval;
}

@property (retain) NSString *type;
@property (retain) NSString *name;
@property (retain) NSString *ctype;
@property (assign) NSInteger evalue;
@property (retain) NSArray *args;
@property (retain) NSDictionary *retval;

@end
