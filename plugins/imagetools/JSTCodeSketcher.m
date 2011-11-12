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
@end

@implementation JSTCodeSketcher

@synthesize jstalk = _jstalk;
@synthesize flipped = _flipped;

static NSMutableDictionary *JSTSketchers = 0x00;

+ (id)codeSketcherWithName:(NSString*)name {
    if (!JSTSketchers) {
        JSTSketchers = [[NSMutableDictionary dictionary] retain];
    }
    
    JSTCodeSketcher *cs = [JSTSketchers objectForKey:name];
    
    if (!cs) {
        cs = [[JSTCodeSketcher new] autorelease];
        [JSTSketchers setObject:cs forKey:name];
    }
    
    [cs stop];
    
    [cs setJstalk:[JSTalk currentJSTalk]];
    
    dispatch_async(dispatch_get_main_queue(),^ {
        [cs start];
    });
    
    return cs;
}


- (id)init {
    self = [super init];
    if (self) {
        _flipped = YES;
    }
    return self;
}

- (void)dealloc {
    
    _unretainedSketcherView = 0x00;
    
    [super dealloc];
}

- (void)stop {
    
    [_redrawTimer invalidate];
    [_redrawTimer release];
    _redrawTimer = 0x00;
    
    if (_drawFunction) {
        JSValueUnprotect([[_jstalk jsController] ctx], _drawFunction);
    }
}

- (void)start {
    
    [self setupWindow];
    
    [_unretainedSketcherView setNeedsDisplay:YES];
    
    if (_fps > 0) {
        _redrawTimer = [[NSTimer scheduledTimerWithTimeInterval:(1.0 / _fps) target:self selector:@selector(fpsTimerHit:) userInfo:0x00 repeats:YES] retain];
    }
}

- (void)fpsTimerHit:(NSTimer*)timer {
    [_unretainedSketcherView setNeedsDisplay:YES];
}

- (void)setFramesPerSecond:(CGFloat)f {
    
    if (_fps > 60) {
        _fps = 60;
        NSLog(@"FPS set too high, limiting to 60");
    }
    
    _fps = f;
}

- (void)setDraw:(JSValueRefAndContextRef)ref {
    
    _drawFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _drawFunction);
}

- (void)setMouseMove:(JSValueRefAndContextRef)ref {
    _mouseMovedFunction = ref.value;
    JSValueProtect([[_jstalk jsController] ctx], _mouseMovedFunction);
}

- (NSRect)viewBounds {
    return [_unretainedSketcherView bounds];
}

- (void)callMouseMovedWithEvent:(NSEvent*)event {
    if (_mouseMovedFunction) {
        [[_jstalk jsController] callJSFunction:_mouseMovedFunction withArguments:[NSArray arrayWithObject:event]];
    }
}

- (void)callDrawWithRect:(NSRect)r {
    if (_drawFunction) {
        
        [[NSGraphicsContext currentContext] saveGraphicsState];
        
        [[_jstalk jsController] callJSFunction:_drawFunction withArguments:[NSArray arrayWithObject:[JSTFakeRect rectWithRect:r]]];
        
        [[NSGraphicsContext currentContext] restoreGraphicsState];
    }
}

- (void)setupWindow {
    if (!_window) {
        
        CGFloat bottomBorderHeight = 20;
        
        NSRect winRect = NSMakeRect(0, 0, 800, 400);
        NSRect extent = winRect;
        
        winRect.size.height += bottomBorderHeight;
        
        
        _window = [[NSWindow alloc] initWithContentRect:winRect
                                         styleMask:NSTitledWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask | NSResizableWindowMask
                                           backing:NSBackingStoreBuffered
                                             defer:NO];
        
        [_window center];
        [_window setShowsResizeIndicator:YES];
        [_window makeKeyAndOrderFront:self];
        [_window setReleasedWhenClosed:YES]; // we retain it in the dictionary.
        [_window setContentBorderThickness:bottomBorderHeight forEdge:NSMinYEdge];
        [_window setPreferredBackingLocation:NSWindowBackingLocationMainMemory];
        
        
        [_window setAcceptsMouseMovedEvents:YES];
        
        extent.origin.y += bottomBorderHeight;
        
        JSTCodeSketcherView *iv = [[[JSTCodeSketcherView alloc] initWithFrame:extent] autorelease];
        [iv setAutoresizingMask:NSViewHeightSizable | NSViewWidthSizable];
        [[_window contentView] addSubview:iv];
        [_window setTitle:@"Code Sketcher!"];
        
        [_window makeFirstResponder:iv];
        
        [iv setSketcher:self];
        
        _unretainedSketcherView = iv;
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSWindowWillCloseNotification object:_window queue:nil usingBlock:^(NSNotification *arg1) {
            
            dispatch_async(dispatch_get_main_queue(),^ {
                
                [_unretainedSketcherView setSketcher:0x00];
                
                _unretainedSketcherView = 0x00;
                
                debug(@"Wow, we're just leaking here.");
            });
        }];
    }
}

- (CGFloat)mouseX {
    
    NSPoint p = [NSEvent mouseLocation];
    
    p = [_window convertScreenToBase:p];
    p = [_unretainedSketcherView convertPoint:p fromView:nil];
    
    return p.x;
}

- (CGFloat)mouseY {
    NSPoint p = [NSEvent mouseLocation];
    
    p = [_window convertScreenToBase:p];
    p = [_unretainedSketcherView convertPoint:p fromView:nil];
    
    return p.y;
}

@end


@implementation JSTCodeSketcherView
@synthesize sketcher = _sketcher;

- (void)dealloc {
    [_sketcher release];
    [super dealloc];
}

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
    
    [_sketcher callDrawWithRect:dirtyRect];
}

- (void)mouseMoved:(NSEvent *)event {
    [_sketcher callMouseMovedWithEvent:event];
}

- (BOOL)isFlipped {
    return [_sketcher isFlipped];
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

