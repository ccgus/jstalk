//
//  FOUtils.h
//  flyopts
//
//  Created by August Mueller on 11/20/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel);

NSString * appicationSupportFolder(NSString *appName, NSString *subFolder);
BOOL isTextEdit();
