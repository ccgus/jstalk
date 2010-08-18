//
//  JSTNSStringExtras.m
//  samplejstalkextra
//
//  Created by August Mueller on 3/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTImageTools.h"
#import "JSTOpenCLProgram.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSImage (JSTExtras)
+ (id)imageWithSize:(NSSize)s {
    return [[[self alloc] initWithSize:s] autorelease];
}

@end


@implementation JSTImageTools

+ (CGImageRef)createImageRefFromBuffer:(JSTOpenCLImageBuffer*)imgBuffer {
    
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    
    CGContextRef context = CGBitmapContextCreate([imgBuffer bitmapData],
                                                 [imgBuffer width],
                                                 [imgBuffer height],
                                                 32,
                                                 [imgBuffer bytesPerRow],
                                                 cs, kCGBitmapFloatComponents | kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Host);
    
    CGImageRef img = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    
    return img;
    
    CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:@"/tmp/bob.tiff"], kUTTypeTIFF, 1, NULL);
    CGImageDestinationAddImage(imageDestination, img, (CFDictionaryRef)[NSDictionary dictionary]);
    CGImageDestinationFinalize(imageDestination);
    CFRelease(imageDestination);
    
    CGImageRelease(img);
    
}

+ (NSData*)tiffDataFromImageBuffer:(JSTOpenCLImageBuffer*)imgBuffer {
    
    CGImageRef img = [self createImageRefFromBuffer:imgBuffer];
    
    if (img) {
        
        NSMutableData *data = [NSMutableData data];
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithData((CFMutableDataRef)data, kUTTypeTIFF, 1, nil);
        CGImageDestinationAddImage(imageDestination, img, (CFDictionaryRef)[NSDictionary dictionary]);
        CGImageDestinationFinalize(imageDestination);
        CFRelease(imageDestination);
        CGImageRelease(img);
        
        return data;
    }
    
    NSLog(@"Could not create image");
    
    
    return 0x00;
}

static NSMutableDictionary *JSTImageViewWindows = 0x00;

+ (NSWindow*)getImageViewWindowNamed:(NSString*)winName defaultSize:(NSSize)s {
    
    if (!JSTImageViewWindows) {
        JSTImageViewWindows = [[NSMutableDictionary dictionary] retain];
    }
    
    NSWindow *w = [JSTImageViewWindows objectForKey:winName];
    
    if (!w) {
        NSRect r = NSMakeRect(0, 0, s.width, s.height);
        
        w = [[[NSWindow alloc] initWithContentRect:r styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
        
        [w center];
        [w setShowsResizeIndicator:YES];
        [w makeKeyAndOrderFront:self];
        [w setReleasedWhenClosed:NO]; // we retain it in the dictionary.
        
        NSImageView *iv = [[[NSImageView alloc] initWithFrame:r] autorelease];
        [iv setImageAlignment:NSImageAlignCenter];
        [iv setImageScaling:NSImageScaleProportionallyDown];
        [iv setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [iv setEditable:YES];
        [[w contentView] addSubview:iv];
        [w setTitle:winName];
        
        [JSTImageViewWindows setObject:w forKey:winName];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:w queue:nil usingBlock:^(NSNotification *arg1) {
            
            NSWindow *win = [arg1 object];
            
            dispatch_async(dispatch_get_main_queue(),^ {
                // remove our ref to it in a sec.  Otherwise, it'll be released early and then boom
                [JSTImageViewWindows removeObjectForKey:[win title]];
            });
        }];
        
    }
    
    return w;
}

+ (void)viewImageBuffer:(JSTOpenCLImageBuffer*)imgBuffer inWindowNamed:(NSString*)winName {
    
    CGImageRef img = [self createImageRefFromBuffer:imgBuffer];
    
    NSWindow *w = [self getImageViewWindowNamed:winName defaultSize:NSMakeSize(CGImageGetWidth(img), CGImageGetHeight(img))];
    
    NSImageView *imageView = [[[w contentView] subviews] lastObject];
    
    NSImage *i = [[[NSImage alloc] initWithCGImage:img size:NSMakeSize(CGImageGetWidth(img), CGImageGetHeight(img))] autorelease];
    
    [imageView setImage:i];
    
    CGImageRelease(img);
}

+ (void)viewNSImage:(NSImage*)img inWindowNamed:(NSString*)winName {
    
    NSWindow *w = [self getImageViewWindowNamed:winName defaultSize:[img size]];
    
    NSImageView *imageView = [[[w contentView] subviews] lastObject];
    
    [imageView setImage:img];
}


+ (void)dumpPixelsInBuffer:(JSTOpenCLImageBuffer*)imgBuffer {
    
    size_t bpr                  = [imgBuffer bytesPerRow];
    size_t x = 0, y = 0;
    size_t height               = [imgBuffer height];
    size_t width                = [imgBuffer width];
    size_t rwidth               = bpr / 4;
    JSTOCLFloatPixel *basePtr   = (JSTOCLFloatPixel*)[imgBuffer bitmapData];
    
    while (y < height) {
        
        while (x < width) {
            
            size_t pt = x + ((rwidth * y));
            
            JSTOCLFloatPixel p1 = basePtr[pt];
            
            printf("%ld,%ld r:%f g:%f b:%f a:%f\n", x, y, p1.r, p1.g, p1.b, p1.a);
            
            x++;
        }
        
        x = 0;
        y++;
        
        printf("\n");
    }
}


static NSMutableDictionary *JSTCIWindows = 0x00;

+ (void)viewCIImage:(CIImage*)img inWindowNamed:(NSString*)winName extent:(CGRect)extent {
    
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
        [w setPreferredBackingLocation:NSWindowBackingLocationMainMemory];
        //[w setColorSpace:[NSColorSpace genericRGBColorSpace]];
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
    
    [imageView setTheImage:img];
    [imageView setNeedsDisplay:YES];
    
}

static BOOL JSTImageToolsCISWRender = NO;
+ (void)setShouldUseCISofwareRenderer:(BOOL)b {
    JSTImageToolsCISWRender = b;
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
                                           [NSNumber numberWithBool:JSTImageToolsCISWRender], kCIContextUseSoftwareRenderer,
                                           nil];
    
    CGColorSpaceRelease(cs);
    
    CIContext *cictx = [CIContext contextWithCGContext:[[NSGraphicsContext currentContext] graphicsPort] options:contextOptions];
    
    [cictx drawImage:[kCheckerFilter valueForKey:@"outputImage"]
              inRect:[self bounds]
            fromRect:[self bounds]];
    
    [cictx drawImage:_theImage inRect:r fromRect:r];
    
}

@end
