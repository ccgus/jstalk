//
//  JSTCodeSketcher.m
//  ImageTools
//
//  Created by August Mueller on 11/11/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "JSTCodeSketcher.h"

@interface JSTCodeSketcher()
- (void)setupWindow;
- (void)resizeContext;
@end

@implementation JSTCodeSketcher

@synthesize jstalk = _jstalk;
@synthesize mouseLocation = _mouseLocation;
@synthesize pmouseLocation = _pmouseLocation;
@synthesize mousePressed = _mousePressed;
@synthesize lookupName = _lookupName;
@synthesize frameRate = _frameRate;
@synthesize nsContext = _nsContext;
@synthesize size = _size;

+ (id)codeSketcherWithName:(NSString*)name {
    
    static NSMutableDictionary *JSTSketchers = 0x00;
    
    if (!JSTSketchers) {
        JSTSketchers = [[NSMutableDictionary dictionary] retain];
    }
    
    JSTCodeSketcher *cs = [JSTSketchers objectForKey:name];
    
    if (!cs) {
        cs = [[[JSTCodeSketcher alloc] initWithFrame:NSMakeRect(0, 0, 10, 10)] autorelease];
        [cs setLookupName:name];
        [JSTSketchers setObject:cs forKey:name];
    }
    
    [cs stop];
    
    [cs setJstalk:[JSTalk currentJSTalk]];
    
    dispatch_async(dispatch_get_main_queue(),^ {
        [cs start];
    });
    
    return cs;
}


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _flipped = YES;
        _size = NSMakeSize(400, 800);
    }
    return self;
}


- (void)dealloc {
    debug(@"%s:%d", __FUNCTION__, __LINE__);
    
    [_lookupName release];
    
    if (_context) {
        CGContextRelease(_context);
    }
    [_nsContext release];
    
    [super dealloc];
}

- (void)resizeContext {
    
    NSSize mySize = [self bounds].size;
    
    if (_context) {
        
        if (CGBitmapContextGetWidth(_context) == mySize.width && CGBitmapContextGetHeight(_context) == mySize.height) {
            return;
        }
        
        CGContextRelease(_context);
    }
    
    CGColorSpaceRef cs = [[[NSScreen mainScreen] colorSpace] CGColorSpace];
    _context = CGBitmapContextCreate(0x00, mySize.width, mySize.height, 8, 0, cs, kCGImageAlphaPremultipliedLast);
    
    [self setNsContext:[NSGraphicsContext graphicsContextWithGraphicsPort:_context flipped:_flipped]];
    
}

- (void)stop {
    
    [_redrawTimer invalidate];
    [_redrawTimer release];
    _redrawTimer = 0x00;
    
    if (_setupFunction) {
        JSValueUnprotect([[_jstalk jsController] ctx], _drawFunction);
    }
    
    if (_drawFunction) {
        JSValueUnprotect([[_jstalk jsController] ctx], _drawFunction);
    }
    
    if (_mouseUpFunction) {
        JSValueUnprotect([[_jstalk jsController] ctx], _mouseUpFunction);
    }
    
    if (_mouseDownFunction) {
        JSValueUnprotect([[_jstalk jsController] ctx], _mouseDownFunction);
    }
    
    if (_mouseMoveFunction) {
        JSValueUnprotect([[_jstalk jsController] ctx], _mouseMoveFunction);
    }
    
    if (_mouseDragFunction) {
        JSValueUnprotect([[_jstalk jsController] ctx], _mouseDragFunction);
    }
}

- (void)start {
    
    if (_setupFunction) {
        [[_jstalk jsController] callJSFunction:_setupFunction withArguments:0x00];
    }
    
    [self setupWindow];
    
    NSSize newSize = [_mwindow frameRectForContentRect:NSMakeRect(0, 0, _size.width, _size.height)].size;
    
    NSRect newFrame = [_mwindow frame];
    newFrame.size = newSize;
    
    [_mwindow setFrame:newFrame display:YES];
    
    [self resizeContext];
    
    [self setNeedsDisplay:YES];
    
    if (_frameRate > 60) {
        _frameRate = 60;
        NSLog(@"FPS set too high, limiting to 60");
    }
    
    if (_frameRate > 0) {
        _redrawTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / _frameRate) target:self selector:@selector(fpsTimerHit:) userInfo:0x00 repeats:YES] retain];
    }
}

- (void)fpsTimerHit:(NSTimer*)timer {
    [self setNeedsDisplay:YES];
}

- (void)setupWindow {
    if (!_mwindow) {
        
        CGFloat bottomBorderHeight = 20;
        
        NSRect winRect = NSMakeRect(0, 0, _size.width, _size.height);
        NSRect extent = winRect;
        
        winRect.size.height += bottomBorderHeight;
        
        
        _mwindow = [[NSWindow alloc] initWithContentRect:winRect
                                         styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
        
        [_mwindow center];
        [_mwindow setShowsResizeIndicator:YES];
        [_mwindow makeKeyAndOrderFront:self];
        [_mwindow setReleasedWhenClosed:YES]; // we retain it in the dictionary.
        [_mwindow setContentBorderThickness:bottomBorderHeight forEdge:NSMinYEdge];
        [_mwindow setPreferredBackingLocation:NSWindowBackingLocationMainMemory];
        
        
        [_mwindow setAcceptsMouseMovedEvents:YES];
        
        extent.origin.y += bottomBorderHeight;
        [self setFrame:extent];
        
        [self setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [[_mwindow contentView] addSubview:self];
        [_mwindow setTitle:_lookupName];
        
        [_mwindow makeFirstResponder:self];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:_mwindow queue:nil usingBlock:^(NSNotification *arg1) {
            
            dispatch_async(dispatch_get_main_queue(),^ {
                
                debug(@"Wow, we're just leaking here.");
            });
        }];
        
        NSPoint p = [NSEvent mouseLocation];
        
        p = [_mwindow convertScreenToBase:p];
        _mouseLocation = [self convertPoint:p fromView:nil];
    }
}


- (void)pushContext {
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:_nsContext];
    CGContextSaveGState(_context);
}

- (void)popContext {
    CGContextRestoreGState(_context);
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    if (!_context) {
        [self resizeContext];
    }
    
    if (_drawFunction) {
        [self pushContext];
        [[_jstalk jsController] callJSFunction:_drawFunction withArguments:0x00];
        [self popContext];
    }
    
    CGContextRef screenContext = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGImageRef img = CGBitmapContextCreateImage(_context);
    CGContextDrawImage(screenContext, [self bounds], img);
    CGImageRelease(img);
}

- (void)viewDidEndLiveResize {
    [self resizeContext];
}

- (void)setSetup:(JSValueRefAndContextRef)ref {
    _setupFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _setupFunction);
}

- (void)setDraw:(JSValueRefAndContextRef)ref {
    _drawFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _drawFunction);
}

- (void)setMouseMove:(JSValueRefAndContextRef)ref {
    _mouseMoveFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _mouseMoveFunction);
}

- (void)setMouseUp:(JSValueRefAndContextRef)ref {
    _mouseUpFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _mouseUpFunction);
}

- (void)setMouseDown:(JSValueRefAndContextRef)ref {
    _mouseDownFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _mouseDownFunction);
}

- (void)setMouseDrag:(JSValueRefAndContextRef)ref {
    _mouseDragFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _mouseDragFunction);
}

- (void)mouseDown:(NSEvent *)event {
    _mousePressed = YES;
    
    _pmouseLocation = _mouseLocation;
    _mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];;
    
    if (_mouseDownFunction) {
        [self pushContext];
        [[_jstalk jsController] callJSFunction:_mouseDownFunction withArguments:[NSArray arrayWithObject:event]];
        [self popContext];
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseUp:(NSEvent *)event {
    _mousePressed = NO;
    _pmouseLocation = _mouseLocation;
    _mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    
    if (_mouseUpFunction) {
        [self pushContext];
        [[_jstalk jsController] callJSFunction:_mouseUpFunction withArguments:[NSArray arrayWithObject:event]];
        [self popContext];
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseDragged:(NSEvent *)event {
    
    _pmouseLocation = _mouseLocation;
    _mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    
    if (_mouseDragFunction) {
        [self pushContext];
        [[_jstalk jsController] callJSFunction:_mouseDragFunction withArguments:[NSArray arrayWithObject:event]];
        [self popContext];
        [self setNeedsDisplay:YES];
    }
}

- (void)mouseMoved:(NSEvent *)event {
    
    _pmouseLocation = _mouseLocation;
    _mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    
    if (_mouseMoveFunction) {
        [self pushContext];
        [[_jstalk jsController] callJSFunction:_mouseMoveFunction withArguments:[NSArray arrayWithObject:event]];
        [self popContext];
        [self setNeedsDisplay:YES];
    }
    
}

- (BOOL)isFlipped {
    return _flipped;
}

- (void)setFlipped:(BOOL)flag {
    _flipped = flag;
}

- (void)translateX:(CGFloat)x Y:(CGFloat)y {
    
    CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextTranslateCTM(ctx, x, y);
}


- (void)copy:(id)sender {
    
    NSImage *img = [[NSImage alloc] initWithSize:[self bounds].size];
    [img lockFocus];
    
    [self drawRect:[self bounds]];
    
    [img unlockFocus];
    
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    [pboard declareTypes:[NSArray arrayWithObjects:(id)kUTTypeTIFF, nil] owner:nil];
    
    [pboard setData:[img TIFFRepresentation] forType:(id)kUTTypeTIFF];
}

- (CGContextRef)context {
    if (!_context) {
        [self resizeContext];
    }
    
    return _context;
}

- (void)fillWithColor:(NSColor*)color {
    
    /*
    CGContextSaveGState([self context]);
    
    CGColorRef c = JSTCGColorCreateFromNSColor(color);
    
    CGContextSetFillColorWithColor([self context], c);
    
    CGColorRelease(c);
    
    CGContextFillRect([self context], [self bounds]);
    
    CGContextRestoreGState([self context]);
    */
}

- (void)clear {
    CGContextClearRect([self context], [self bounds]);
}

- (void)update {
    [self setNeedsDisplay:YES];
}



@end





@implementation JSTFakePoint

@synthesize x = _x;
@synthesize y = _y;

@end

@implementation JSTFakeSize

@synthesize width = _width;
@synthesize height = _height;

@end

@implementation JSTFakeRect

@synthesize origin = _origin;
@synthesize size = _size;

+ (id)rectWithRect:(NSRect)rect {
    
    JSTFakeRect *r = [[[JSTFakeRect alloc] init] autorelease];
    
    r.origin.x      = rect.origin.x;
    r.origin.y      = rect.origin.y;
    r.size.width    = rect.size.width;
    r.size.height   = rect.size.height;
    
    return r;
}

@end



CGColorRef JSTCGColorCreateFromNSColor(NSColor *c) {
    CGColorSpaceRef colorSpace = [[c colorSpace] CGColorSpace];
    NSInteger componentCount = [c numberOfComponents];
    CGFloat *components = (CGFloat *)calloc(componentCount, sizeof(CGFloat));
    [c getComponents:components];
    CGColorRef color = CGColorCreate(colorSpace, components);
    free((void*)components);
    return color;
}
