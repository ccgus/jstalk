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
    
    NSURL *url = [[NSBundle bundleForClass:[JSTImageTools class]] URLForImageResource:imageName];
    
    
    if (!url) {
       url = [[NSBundle mainBundle] URLForImageResource:imageName];
    }
    
    if (!url) {
        return 0x00;
    }
    
    return [CIImage imageWithContentsOfURL:url];
    
}

@end
