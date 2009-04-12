//
//  NSExceptionHacks.h
//  flyopts
//
//  Created by August Mueller on 11/20/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSException (NSExceptionHacks)

+ (void) debugOnRaise;

@end
