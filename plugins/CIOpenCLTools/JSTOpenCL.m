//
//  JSTNSStringExtras.m
//  samplejstalkextra
//
//  Created by August Mueller on 3/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTOpenCL.h"
#import "JSTOpenCLProgram.h"

#define debug NSLog



@implementation JSTOpenCL

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

+ (void)viewImageBuffer:(JSTOpenCLImageBuffer*)imgBuffer {
    
    CGImageRef img = [self createImageRefFromBuffer:imgBuffer];
    
    if (img) {
        
        CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:@"/tmp/bob.tiff"], kUTTypeTIFF, 1, NULL);
        CGImageDestinationAddImage(imageDestination, img, (CFDictionaryRef)[NSDictionary dictionary]);
        CGImageDestinationFinalize(imageDestination);
        CFRelease(imageDestination);
        
        CGImageRelease(img);
        
        system("open /tmp/bob.tiff");
    }
    else {
        NSLog(@"Could not create image");
    }
}

static NSMutableDictionary *JSTOpenCLWindows = 0x00;

+ (void)viewImageBuffer:(JSTOpenCLImageBuffer*)imgBuffer inWindowNamed:(NSString*)winName {
    
    if (!JSTOpenCLWindows) {
        JSTOpenCLWindows = [[NSMutableDictionary dictionary] retain];
    }
    
    CGImageRef img = [self createImageRefFromBuffer:imgBuffer];
    
    NSWindow *w = [JSTOpenCLWindows objectForKey:winName];
    
    if (!w) {
        NSRect r = NSMakeRect(0, 0, CGImageGetWidth(img), CGImageGetHeight(img));;
        
        w = [[[NSWindow alloc] initWithContentRect:r styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO] autorelease];
        
        [w center];
        [w setShowsResizeIndicator:YES];
        [w makeKeyAndOrderFront:self];
        [w setReleasedWhenClosed:NO]; // we retain it in the dictionary.
        
        NSImageView *iv = [[[NSImageView alloc] initWithFrame:r] autorelease];
        [iv setImageAlignment:NSImageAlignCenter];
        [iv setImageScaling:NSImageScaleProportionallyDown];
        [iv setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [[w contentView] addSubview:iv];
        [w setTitle:winName];
        
        [JSTOpenCLWindows setObject:w forKey:winName];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:w queue:nil usingBlock:^(NSNotification *arg1) {
            
            NSWindow *win = [arg1 object];
            
            dispatch_async(dispatch_get_main_queue(),^ {
                // remove our ref to it in a sec.  Otherwise, it'll be released early and then boom
                [JSTOpenCLWindows removeObjectForKey:[win title]];
            });
        }];
        
    }
    
    NSImageView *imageView = [[[w contentView] subviews] lastObject];
    
    NSImage *i = [[[NSImage alloc] initWithCGImage:img size:NSMakeSize(CGImageGetWidth(img), CGImageGetHeight(img))] autorelease];
    
    [imageView setImage:i];
    
    
    CGImageRelease(img);
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

@end
