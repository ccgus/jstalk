//
//  MOMethod_Private.h
//  Mocha
//
//  Created by Logan Collins on 5/12/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import "MOMethod.h"


@interface MOMethod ()

@property (unsafe_unretained, readwrite) id target;
@property (readwrite) SEL selector;

@property (copy, readwrite) id block;

@end
