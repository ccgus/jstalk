//
//  JSTalkTask.h
//
//  Created by Casey Fleser on 6/16/06.
//  Copyright 2006 Griffin Technology, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <ProxiLib/ProxiLib.h>

@interface JSTalkTask : NSObject <GTask>
{
	NSString *_scriptSource;
}


@property (retain) NSString	*scriptSource;

@end
