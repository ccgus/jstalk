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

- (void) setupJSTalkEnv:(JSTalk *)jstalk {
    JSCocoaController *jsController = [jstalk jsController];
    jsController.delegate = self;
    jstalk.printController = self;
    
}

- (void) print:(NSString*)s {
    NSLog(@"%@", s);
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo {
	// Add your code here, returning the data to be passed to the next action.
	
    id result = 0x00;
    
    NSString *script = [[self parameters] objectForKey:@"script"];
    
    NSLog(@"script: %@", script);
    
    if (script) {
        JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
        [self setupJSTalkEnv:jstalk];
        
        [jstalk executeString:script];
        result = [jstalk callFunctionNamed:@"run" withArguments:[NSArray arrayWithObjects:input, [self parameters], nil]];
        
        NSLog(@"result: %@", result);
        
    }
    
    
	return result;
}


- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url {
    
    lineNumber -= 1;
    
    NSLog(@"Error on line %d, %@", lineNumber, error);
    
}


- (void) runScript:(id)sender {
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    [self setupJSTalkEnv:t];
    [t executeString:[[scriptView textStorage] string]];
    id result = [t callFunctionNamed:@"run" withArguments:[NSArray array]];
    (void) result;

}

@end
