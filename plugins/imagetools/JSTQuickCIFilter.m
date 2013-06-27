//
//  JSTQuickCIFilter.m
//  CIOpenCLTools
//
//  Created by August Mueller on 8/4/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTQuickCIFilter.h"

@implementation JSTQuickCIFilter

+ (id)quickFilterWithKernel:(NSString*)kernel {
    
    JSTQuickCIFilter *f = [JSTQuickCIFilter new];
    
    [f setTheKernel:[[CIKernel kernelsWithString:kernel] objectAtIndex:0]];
    [f setKernelArgs:[NSMutableArray array]];
    return f;
}

- (CGRect)xregionOf:(int)sampler destRect:(CGRect)rect userInfo:(id)ui {
    return CGRectInfinite;
}

- (void)addKernelArgument:(id)obj {
    
    // Convenience stuff.
    if ([obj isKindOfClass:[NSColor class]]) {
        obj = [[CIColor alloc] initWithColor:obj];
    }
    else if ([obj isKindOfClass:[CIImage class]]) {
        obj = [CISampler samplerWithImage:obj];
    }
    
    [_kernelArgs addObject:obj];
}

- (CGRect)xxregionOf:(int)sampler destRect:(CGRect)rect userInfo:(id)ui {
    
    NSValue *v = [[JSTalk currentJSTalk] callJSFunction:[_roiMethod JSObject] withArgumentsInArray:nil];
    
    return [v rectValue];
}

- (CIImage*)applyWithArguments:(NSArray *)args options:(NSDictionary *)dict {
    return [self apply:_theKernel arguments:args options:dict];
}

- (CIImage *)outputImage {
    
    if (_roiMethod && [JSTalk currentJSTalk]) {
        [_theKernel setROISelector:@selector(regionOf:destRect:userInfo:)];
    }
    
    if (_outputImageMethod && [JSTalk currentJSTalk]) {
        CIImage *i = [[JSTalk currentJSTalk] callJSFunction:[_outputImageMethod JSObject] withArgumentsInArray:nil];
        return i;
    }
    
	return [self apply:_theKernel arguments:_kernelArgs options:[NSDictionary dictionary]];
}

@end
