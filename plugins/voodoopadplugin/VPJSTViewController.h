//
//  VPJSTViewController.h
//  VPJSTalkPlugin
//
//  Created by August Mueller on 10/12/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>
#import "JSTTextView.h"
#import "NoodleLineNumberView.h"
#import "TDParseKit.h"

@interface VPJSTViewController : VPItemController {
    IBOutlet JSTTextView *textView;
    NoodleLineNumberView *lineNumberView;

    TDTokenizer *_tokenizer;
    NSDictionary *_keywords;
}


- (void) executeScript:(id)sender;
- (void) parseCode:(id)sender;

@end
