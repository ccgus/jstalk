//
//  MOPreprocessor.h
//  jstalk
//
//  Created by August Mueller on 2/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MOPreprocessor : NSObject {

}

+ (NSString*)preprocessCode:(NSString*)sourceString;

@end



@interface MOPSymbolGroup : NSObject {
    
    unichar _openSymbol;
    NSMutableArray *_args;
    MOPSymbolGroup *_parent;
}

@property (retain) NSMutableArray *args;
@property (retain) MOPSymbolGroup *parent;

- (void)addSymbol:(id)aSymbol;

@end


