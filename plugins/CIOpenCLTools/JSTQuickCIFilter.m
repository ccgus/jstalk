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


static NSMutableDictionary *JSTCIWindows = 0x00;

- (void)viewImageInWindowNamed:(NSString*)winName extent:(CGRect)extent {
    
    if (!JSTCIWindows) {
        JSTCIWindows = [[NSMutableDictionary dictionary] retain];
    }
    
    NSWindow *w = [JSTCIWindows objectForKey:winName];
    
    if (!w) {
        
        CGFloat bottomBorderHeight = 20;
        
        NSRect winRect = extent;
        winRect.size.height += bottomBorderHeight;
        
        
        w = [[[NSWindow alloc] initWithContentRect:winRect
                                         styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:NO] autorelease];
        
        [w center];
        [w setShowsResizeIndicator:YES];
        [w makeKeyAndOrderFront:self];
        [w setReleasedWhenClosed:NO]; // we retain it in the dictionary.
        [w setContentBorderThickness:bottomBorderHeight forEdge:NSMinYEdge];
        //[w setPreferredBackingLocation:NSWindowBackingLocationMainMemory];
        
        extent.origin.y += bottomBorderHeight;
        
        JSTSimpleCIView *iv = [[[JSTSimpleCIView alloc] initWithFrame:extent] autorelease];
        [iv setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [[w contentView] addSubview:iv];
        [w setTitle:winName];
        
        [JSTCIWindows setObject:w forKey:winName];
        
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:w queue:nil usingBlock:^(NSNotification *arg1) {
            
            NSWindow *win = [arg1 object];
            
            dispatch_async(dispatch_get_main_queue(),^ {
                // remove our ref to it in a sec.  Otherwise, it'll be released early and then boom!
                [JSTCIWindows removeObjectForKey:[win title]];
            });
        }];
        
    }
    
    JSTSimpleCIView *imageView = [[[w contentView] subviews] lastObject];
    
    [imageView setTheImage:[self outputImage]];
    [imageView setNeedsDisplay:YES];
}


@end

@implementation JSTSimpleCIView
@synthesize theImage=_theImage;

- (void)dealloc {
    [_theImage release];
    [super dealloc];
}

- (void)drawRect:(NSRect)r {
    
    static CIFilter *kCheckerFilter = 0x00;
    
    if (!kCheckerFilter) {
        kCheckerFilter = [[CIFilter filterWithName:@"CICheckerboardGenerator"] retain];
        [kCheckerFilter setDefaults];
        
        [kCheckerFilter setValue:[CIColor colorWithRed:0.9f green:0.9f blue:0.9f] forKey:@"inputColor1"];
        [kCheckerFilter setValue:[NSNumber numberWithFloat:10.0f] forKey:@"inputWidth"];
    }
    
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    NSMutableDictionary *contextOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           (id)cs, kCIContextWorkingColorSpace,
                                           [NSNumber numberWithBool:YES], kCIContextUseSoftwareRenderer,
                                           nil];
    
    CGColorSpaceRelease(cs);
    
    CIContext *cictx = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:contextOptions];
    
    [cictx drawImage:[kCheckerFilter valueForKey:@"outputImage"]
              inRect:[self bounds]
            fromRect:[self bounds]];
    
    [cictx drawImage:_theImage inRect:r fromRect:r];
    
}



@end
