//
//  automator.h
//  automator
//
//  Created by August Mueller on 3/5/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Automator/AMBundleAction.h>

@interface JSTAutomator : AMBundleAction  {
    IBOutlet NSTextView *scriptView;
}

- (void) runScript:(id)sender;

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo;

@end
