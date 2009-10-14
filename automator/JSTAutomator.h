//
//  automator.h
//  automator
//
//  Created by August Mueller on 3/5/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>
#import <JSTalk/JSTTextView.h>
@class JSTTextView;

@interface JSTAutomator : AMBundleAction  {
    IBOutlet JSTTextView *scriptView;
}

- (void) runScript:(id)sender;

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
