//
//  JSTCodeSketcher.h
//  ImageTools
//
//  Created by August Mueller on 11/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JSTalk/JSTalk.h>

@class JSTCodeSketcherView;

@interface JSTCodeSketcher : NSObject {
    
    JSTalk *_jstalk;
    
    JSValueRef _drawFunction;
    JSValueRef _setupFunction;
    JSValueRef _mouseMovedFunction;
    
    CGFloat _fps;
    
    NSWindow *_window;
    
    
    JSTCodeSketcherView *_unretainedSketcherView;
    
    BOOL _flipped;
    
    NSTimer *_redrawTimer;
    
    CGContextRef _context;
}

@property (retain) JSTalk *jstalk;
@property (assign, getter=isFlipped) BOOL flipped;

- (void)stop;
- (void)start;

- (void)setFramesPerSecond:(CGFloat)f;

- (void)setDraw:(JSValueRefAndContextRef)ref;
- (void)setMouseMove:(JSValueRefAndContextRef)ref;
- (void)callDrawWithRect:(NSRect)r;

@end



@interface JSTCodeSketcherView : NSView {
    JSTCodeSketcher *_sketcher;
}

@property (retain) JSTCodeSketcher *sketcher;

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
