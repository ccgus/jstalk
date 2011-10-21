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

+ (NSString*)preprocessCode:(NSString*)sourceString;

@end



@interface JSTPSymbolGroup : NSObject {
    
    unichar _openSymbol;
    NSMutableArray *_args;
    JSTPSymbolGroup *_parent;
    BOOL _isBaseGroup;
}

@property (retain) NSMutableArray *args;
@property (retain) JSTPSymbolGroup *parent;
@property (assign) BOOL isBaseGroup;
@property (retain) id functionHead;

- (void)addSymbol:(id)aSymbol;

- (void)printTree:(int)depth;
@end


