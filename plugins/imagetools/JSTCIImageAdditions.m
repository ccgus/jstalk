//
//  JSTCIImageAdditions.m
//  ImageTools
//
//  Created by August Mueller on 4/3/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import "JSTCIImageAdditions.h"
#import "JSTImageTools.h"

@implementation CIImage (JSTCIImageAdditions)

+ (id)jstImageNamed:(NSString*)imageName {
    
    debug(@"imageName: '%@'", imageName);
    debug(@"[NSBundle bundleForClass:self]: '%@'", [NSBundle bundleForClass:self]);
    NSURL *url = [[NSBundle bundleForClass:[JSTImageTools class]] URLForImageResource:imageName];
    
    debug(@"url: '%@'", url);
    
    if (!url) {
       url = [[NSBundle mainBundle] URLForImageResource:imageName];
    }
    
    if (!url) {
        return 0x00;
    }
    
    return [CIImage imageWithContentsOfURL:url];
    
}

@end
