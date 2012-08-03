//
//  MOPointer.h
//  Mocha
//
//  Created by Logan Collins on 7/26/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOPointer : NSObject

- (id)initWithPointerValue:(void *)pointerValue typeEncoding:(NSString *)typeEncoding;

@property (readonly) void * pointerValue;
@property (copy, readonly) NSString *typeEncoding;

@end
