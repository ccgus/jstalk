//
//  JSTQuickCIFilter.h
//  CIOpenCLTools
//
//  Created by August Mueller on 8/4/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import <JSTalk/COScript.h>
#import <JSTalk/MOJavaScriptObject.h>

@interface COSQuickCIFilter : CIFilter {
    CIKernel *_theKernel;
    NSMutableArray *_kernelArgs;
}

@property (retain) CIKernel *theKernel;
@property (retain) NSMutableArray *kernelArgs;

@property (strong) MOJavaScriptObject *roiMethod;
@property (strong) MOJavaScriptObject *outputImageMethod;

@end


