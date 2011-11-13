//
//  JSTCodeSketcher.h
//  ImageTools
//
//  Created by August Mueller on 11/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSTalk/JSTalk.h>

@interface JSTCodeSketcher : NSView {
    
    JSTalk *_jstalk;
    
    JSValueRef _drawFunction;
    JSValueRef _setupFunction;
    JSValueRef _mouseMoveFunction;
    JSValueRef _mouseUpFunction;
    JSValueRef _mouseDownFunction;
    JSValueRef _mouseDragFunction;
    
    CGFloat _frameRate;
    
    NSWindow *_mwindow;
    
    BOOL _flipped;
    
    NSString *_lookupName;
    
    NSTimer *_redrawTimer;
    
    CGContextRef _context;
    NSGraphicsContext *_nsContext;
    
    // Processing type stuff.
    NSPoint _mouseLocation;
    NSPoint _pmouseLocation;
    BOOL _mousePressed;
    NSSize _size;
    
    
}

@property (assign) CGFloat frameRate;
@property (retain) JSTalk *jstalk;
@property (assign) NSPoint mouseLocation;
@property (assign) NSPoint pmouseLocation;
@property (assign, getter=isMousePressed) BOOL mousePressed;
@property (retain) NSString *lookupName;
@property (retain) NSGraphicsContext *nsContext;
@property (assign) NSSize size;
- (void)stop;
- (void)start;

- (void)setDraw:(JSValueRefAndContextRef)ref;
- (void)setMouseMove:(JSValueRefAndContextRef)ref;
- (void)setMouseUp:(JSValueRefAndContextRef)ref;
- (void)setMouseDown:(JSValueRefAndContextRef)ref;
- (void)setMouseDrag:(JSValueRefAndContextRef)ref;


@end


@interface JSTFakePoint : NSObject {
    CGFloat _x;
    CGFloat _y;
}
@property (assign) CGFloat x;
@property (assign) CGFloat y;
@end

@interface JSTFakeSize : NSObject {
    CGFloat _width;
    CGFloat _height;
}
@property (assign) CGFloat width;
@property (assign) CGFloat height;
@end


@interface JSTFakeRect : NSObject {
    JSTFakePoint *_origin;
    JSTFakeSize *_size;
}
@property (retain) JSTFakePoint *origin;
@property (retain) JSTFakeSize *size;
+ (id)rectWithRect:(NSRect)rect;
@end

CGColorRef JSTCGColorCreateFromNSColor(NSColor *c);
