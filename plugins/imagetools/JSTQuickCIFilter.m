//
//  JSTQuickCIFilter.m
//  CIOpenCLTools
//
//  Created by August Mueller on 8/4/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTQuickCIFilter.h"


@implementation JSTQuickCIFilter
@synthesize theKernel=_theKernel;
@synthesize kernelArgs=_kernelArgs;

+ (id)quickFilterWithKernel:(NSString*)kernel {
    
    JSTQuickCIFilter *f = [[[JSTQuickCIFilter alloc] init] autorelease];
    
    [f setTheKernel:[[[CIKernel kernelsWithString:kernel] objectAtIndex:0] retain]];
    [f setKernelArgs:[NSMutableArray array]];
    return f;
}

- (void)dealloc {
    [_theKernel release];
    [_kernelArgs release];
    [super dealloc];
}

- (void)addKernelArgument:(id)obj {
    
    // Convenience stuff.
    if ([obj isKindOfClass:[NSColor class]]) {
        obj = [[[CIColor alloc] initWithColor:obj] autorelease];
    }
    else if ([obj isKindOfClass:[CIImage class]]) {
        obj = [CISampler samplerWithImage:obj];
    }
    
    [_kernelArgs addObject:obj];
}

- (CIImage *)outputImage {
	return [self apply:_theKernel arguments:_kernelArgs options:[NSDictionary dictionary]];
}

@end