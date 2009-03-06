//
//  automator.m
//  automator
//
//  Created by August Mueller on 3/5/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTAutomator.h"
#import <JSTalk/JSTalk.h>


@implementation JSTAutomator


- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo {
	// Add your code here, returning the data to be passed to the next action.
	
    NSLog(@"input: %@", input);
    NSLog(@"anAction: %@", anAction);
    
    id result = 0x00;
    
    NSString *script = [[self parameters] objectForKey:@"script"];
    
    if (script) {
        JSTalk *t = [[[JSTalk alloc] init] autorelease];
        [t executeString:script];
        result = [t callFunctionNamed:@"run" withArguments:[NSArray arrayWithObjects:input, nil]];
    }
    
    
	return input;
}

- (void) runScript:(id)sender {
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    [t executeString:[[scriptView textStorage] string]];
    id result = [t callFunctionNamed:@"run" withArguments:[NSArray array]];
    (void) result;

}

@end
