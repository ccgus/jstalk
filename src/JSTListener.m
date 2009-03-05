//
//  JSTListener.m
//  jstalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTListener.h"
#import "JSCocoaController.h"
#import "JSTalk.h"

@interface JSTListener (Private)
- (void)setupListener;
@end


@implementation JSTListener

@synthesize rootObject=_rootObject;

+ (id) sharedListener {
    static JSTListener *me = 0x00;
    if (!me) {
        me = [[JSTListener alloc] init];
    }
    
    return me;
}

+ (void) listen {
    [[self sharedListener] setupListener];
}


- (void) setupListener {
    NSString *myBundleId    = [[NSBundle mainBundle] bundleIdentifier];
    NSString *port          = [NSString stringWithFormat:@"%@.JSTalk", myBundleId];
    
    _conn = [[NSConnection alloc] init];
    [_conn setRootObject:_rootObject ? _rootObject : NSApp];
    
    if ([_conn registerName:port]) {
        NSLog(@"JSTalk listening on port %@", port);
    }
    else {
        NSLog(@"Could not listen on port %@", port);
        [_conn release];
        _conn = 0x00;
    }
}

@end
