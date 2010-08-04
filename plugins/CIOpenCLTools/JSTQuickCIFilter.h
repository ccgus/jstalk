//
//  JSTQuickCIFilter.h
//  CIOpenCLTools
//
//  Created by August Mueller on 8/4/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface JSTQuickCIFilter : CIFilter {
    CIKernel *_theKernel;
    NSMutableArray *_kernelArgs;
}

@property (retain) CIKernel *theKernel;
@property (retain) NSMutableArray *kernelArgs;

@end


@interface JSTSimpleCIView : NSView {
    CIImage *_theImage;
}

@property (retain) CIImage *theImage;

@end
