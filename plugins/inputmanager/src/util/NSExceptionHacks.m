//
//  NSExceptionHacks.m
//  flyopts
//
//  Created by August Mueller on 11/20/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import "NSExceptionHacks.h"
#import "FOUtils.h"

@implementation NSException  (NSExceptionHacks)

+ (void) debugOnRaise; {

    NSException *e = [[NSException alloc] init];
    
    NS_DURING
        [e raise];
    NS_HANDLER
        ;
    NS_ENDHANDLER
    
    MethodSwizzle([NSException class],
                  @selector(raise),
                  @selector(trapOnRaise));
    
    NS_DURING
        [e raise];
    NS_HANDLER
        ;
    NS_ENDHANDLER
    
    [e release];
}

- (void) trapOnRaise; {
    NSLog(@"%@ , %@", [self name], [self reason]);
    //asm { trap };
    
    // This trick won't work for intel, but here's some code that'll lead the way.
    // __asm__ volatile ("trap") == __asm__ volatile ("int3")
}

@end
