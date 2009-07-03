//
//  JSTExtras.h
//  jsenabler
//
//  Created by August Mueller on 1/15/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSApplication (JSTExtras)
- (id)open:(NSString*)pathToFile;
@end
