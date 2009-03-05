//
//  JSTPreprocessor.h
//  jstalk
//
//  Created by August Mueller on 2/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JSTPreprocessor : NSObject {

}

+ (NSString*) preprocessCode:(NSString*)sourceString;

@end





@interface JSTPObjcCall : NSObject {
    
    NSMutableArray *_args;
    
    JSTPObjcCall *_parent;
    
    NSString *_target;
    NSString *_lastString;
    NSMutableString *_selector;
    NSMutableString *_currentArgument;
}

@property (retain) NSMutableArray *args;
@property (retain) NSMutableString *selector;
@property (retain) NSString *target;
@property (retain) NSString *lastString;
@property (retain) NSMutableString *currentArgument;
@property (assign) JSTPObjcCall *parent;

- (void) addSymbol:(id)whatever;

@end




