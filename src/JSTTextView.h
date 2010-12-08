//
//  JSTTextView.h
//  jstalk
//
//  Created by August Mueller on 1/18/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NoodleLineNumberView;

@interface JSTTextView : NSTextView <NSTextStorageDelegate>{
    NoodleLineNumberView	*_lineNumberView;
    NSDictionary            *_keywords;
    
    NSString                *_lastAutoInsert;
}


@property (retain) NSDictionary *keywords;
@property (retain) NSString *lastAutoInsert;

- (void)parseCode:(id)sender;

@end
