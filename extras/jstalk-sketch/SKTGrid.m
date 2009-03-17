/*
	SKTGrid.m
	Part of the Sketch Sample Code
*/


#import "SKTGrid.h"


// A string constant declared in the header. We haven't bother declaring string constants for the other keys mentioned in the header yet because no one would be using them. Those keys are all typed directly into Interface Builder's bindings inspector.
NSString *SKTGridAnyKey = @"any";


// The number of seconds that we wait after temporarily showing the grid before we hide it again. This number has never been reviewed by an actual user interface designer, but it seems nice to at least one engineer at Apple. 
static NSTimeInterval SKTGridTemporaryShowingTime = 1.0;


@implementation SKTGrid


+ (void)initialize {

    // Specify that a KVO-compliant change for any of this class' non-derived properties should result in a KVO change notification for the "any" virtual property. Views that want to use this grid can observe "any" for notification of the need to redraw the grid.
    [self setKeys:[NSArray arrayWithObjects:@"color", @"spacing", @"alwaysShown", @"constraining", nil] triggerChangeNotificationsForDependentKey:SKTGridAnyKey];

    // Declare the dependencies between this class' other properties. In general, dependency declarations like these should pretty closely match instance variable usage in -<dependentKey>: methods.
    [self setKeys:[NSArray arrayWithObjects:@"spacing", nil] triggerChangeNotificationsForDependentKey:@"usable"];
    [self setKeys:[NSArray arrayWithObjects:@"alwaysShown", nil] triggerChangeNotificationsForDependentKey:@"canSetColor"];
    [self setKeys:[NSArray arrayWithObjects:@"alwaysShown", @"constraining", nil] triggerChangeNotificationsForDependentKey:@"canSetSpacing"];

}


// An override of the superclass' designated initializer.
- (id)init {
    
    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {

	// Establish reasonable defaults. 9 points is an eighth of an inch, which is a reasonable default.
	_color = [[NSColor lightGrayColor] retain];
	_spacing = 9.0f;
	
    }
    return self;
    
}


- (void)dealloc {

    // If we've set a timer to hide the grid invalidate it so it doesn't send a message to this object's zombie.
    [_hidingTimer invalidate];

    // Do the regular Cocoa thing.
    [_color release];
    [super dealloc];

}


#pragma mark *** Private KVC-Compliance for Public Properties ***


- (void)stopShowingGridForTimer:(NSTimer *)timer {
    
    // The timer is now invalid and will be releasing itself.
    _hidingTimer = nil;
    
    // Tell observing views to redraw. By the way, it is virtually always a mistake to put willChange/didChange invocations together with nothing in between. Doing so can result in bugs that are hard to track down. You should always invoke -willChangeValueForKey:theKey before the result of -valueForKey:theKey would change, and then invoke -didChangeValueForKey:theKey after the result of -valueForKey:theKey would have changed. We can get away with this here because there is no value for the "any" key.
    [self willChangeValueForKey:SKTGridAnyKey];
    [self didChangeValueForKey:SKTGridAnyKey];

}


- (void)setSpacing:(CGFloat)spacing {
    
    // Weed out redundant invocations.
    if (spacing!=_spacing) {
        _spacing = spacing;

	// If the grid is drawable, make sure the user gets visual feedback of the change. We don't have to do anything special if the grid is being shown right now.  Observers of "any" will get notified of this change because of what we did in +initialize. They're expected to invoke -drawRect:inView:. 
	if (_spacing>0 && !_isAlwaysShown) {

	    // Are we already showing the grid temporarily?
	    if (_hidingTimer) {
		
		// Yes, and now the user's changed the grid spacing again, so put off the hiding of the grid.
		[_hidingTimer setFireDate:[NSDate dateWithTimeIntervalSinceNow:SKTGridTemporaryShowingTime]];
		
	    } else {
		
		// No, so show it the next time -drawRect:inView: is invoked, and then hide it again in one second.
		_hidingTimer = [NSTimer scheduledTimerWithTimeInterval:SKTGridTemporaryShowingTime target:self selector:@selector(stopShowingGridForTimer:) userInfo:nil repeats:NO];
		
		// Don't bother with a separate _showsGridTemporarily instance variable. -drawRect: can just check to see if _hidingTimer is non-nil.
		
	    }
	    
	}
	
    }
    
}


- (BOOL)canSetColor {
    
    // Don't let the user change the color of the grid when that would be useless.
    return _isAlwaysShown && [self isUsable];
    
}


- (BOOL)canSetSpacing {
    
    // Don't let the user change the spacing of the grid when that would be useless.
    return _isAlwaysShown || _isConstraining;
    
}


#pragma mark *** Public Methods ***


// Boilerplate.
- (BOOL)isAlwaysShown {
    return _isAlwaysShown;
}
- (BOOL)isConstraining {
    return _isConstraining;
}
- (void)setConstraining:(BOOL)isConstraining {
    _isConstraining = isConstraining;
}


- (BOOL)isUsable {

    // The grid isn't usable if the spacing is set to zero. The header comments explain why we don't validate away zero spacing.
    return _spacing>0;

}


- (void)setAlwaysShown:(BOOL)isAlwaysShown {

    // Weed out redundant invocations.
    if (isAlwaysShown!=_isAlwaysShown) {
	_isAlwaysShown = isAlwaysShown;

	// If we're temporarily showing the grid then there's a timer that's going to hide it. If we're supposed to show the grid right now then we don't want the timer to undo that. If we're supposed to hide the grid right now then the hiding that the timer would do is redundant.
	if (_hidingTimer) {
	    [_hidingTimer invalidate];
	    [_hidingTimer release];
	    _hidingTimer = nil;
	}

    }

}


- (NSPoint)constrainedPoint:(NSPoint)point {
    
    // The grid might not be usable right now, or constraining might be turned off.
    if ([self isUsable] && _isConstraining) {
	point.x = floor((point.x / _spacing) + 0.5) * _spacing;
	point.y = floor((point.y / _spacing) + 0.5) * _spacing;
    }
    return point;
    
}


- (BOOL)canAlign {
    
    // You can invoke alignedRect: any time the spacing is valid.
    return [self isUsable];

}


- (NSRect)alignedRect:(NSRect)rect {
    
    // Aligning is done even when constraining is not.
    NSPoint upperRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
    rect.origin.x = floor((rect.origin.x / _spacing) + 0.5) * _spacing;
    rect.origin.y = floor((rect.origin.y / _spacing) + 0.5) * _spacing;
    upperRight.x = floor((upperRight.x / _spacing) + 0.5) * _spacing;
    upperRight.y = floor((upperRight.y / _spacing) + 0.5) * _spacing;
    rect.size.width = upperRight.x - rect.origin.x;
    rect.size.height = upperRight.y - rect.origin.y;
    return rect;

}


- (void)drawRect:(NSRect)rect inView:(NSView *)view {
    
    // The grid might not be usable right now. It might be shown, but only temporarily.
    if ([self isUsable] && (_isAlwaysShown || _hidingTimer)) {
	
	// Figure out a big bezier path that corresponds to the entire grid. It will consist of the vertical lines and then the horizontal lines.
	NSBezierPath *gridPath = [NSBezierPath bezierPath];
	NSInteger lastVerticalLineNumber = floor(NSMaxX(rect) / _spacing);
	for (NSInteger lineNumber = ceil(NSMinX(rect) / _spacing); lineNumber<=lastVerticalLineNumber; lineNumber++) {
	    [gridPath moveToPoint:NSMakePoint((lineNumber * _spacing), NSMinY(rect))];
	    [gridPath lineToPoint:NSMakePoint((lineNumber * _spacing), NSMaxY(rect))];
	}
	NSInteger lastHorizontalLineNumber = floor(NSMaxY(rect) / _spacing);
	for (NSInteger lineNumber = ceil(NSMinY(rect) / _spacing); lineNumber<=lastHorizontalLineNumber; lineNumber++) {
	    [gridPath moveToPoint:NSMakePoint(NSMinX(rect), (lineNumber * _spacing))];
	    [gridPath lineToPoint:NSMakePoint(NSMaxX(rect), (lineNumber * _spacing))];
	}
	
	// Draw the grid as one-pixel-wide lines of a specific color.
	[_color set];
	[gridPath setLineWidth:0.0];
	[gridPath stroke];
	
    }
	
}


@end


/*
IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc. ("Apple") in
consideration of your agreement to the following terms, and your use, installation,
modification or redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject to these
terms, Apple grants you a personal, non-exclusive license, under Apple's copyrights in
this original Apple software (the "Apple Software"), to use, reproduce, modify and
redistribute the Apple Software, with or without modifications, in source and/or binary
forms; provided that if you redistribute the Apple Software in its entirety and without
modifications, you must retain this notice and the following text and disclaimers in all
such redistributions of the Apple Software.  Neither the name, trademarks, service marks
or logos of Apple Computer, Inc. may be used to endorse or promote products derived from
the Apple Software without specific prior written permission from Apple. Except as expressly
stated in this notice, no other rights or licenses, express or implied, are granted by Apple
herein, including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO WARRANTIES,
EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED WARRANTIES OF NON-INFRINGEMENT,
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS
USE AND OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE,
REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND
WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR
OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
