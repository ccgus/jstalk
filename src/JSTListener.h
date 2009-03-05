//
//  JSTListener.h
//  jstalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JSTListener : NSObject {
    
    CFMessagePortRef messagePort;
    
    NSConnection *_conn;
    
    id _rootObject;
    
}

@property (assign) id rootObject;


+ (void) listen;

@end
