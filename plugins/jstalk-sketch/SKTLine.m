/*
	SKTLine.m
	Part of the Sketch Sample Code
*/


#import "SKTLine.h"


// String constants declared in the header. They may not be used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
NSString *SKTLineBeginPointKey = @"beginPoint";
NSString *SKTLineEndPointKey = @"endPoint";

// SKTGraphic's default selection handle machinery draws more handles than we need, so this class implements its own.
enum {
    SKTLineBeginHandle = 1,
    SKTLineEndHandle = 2
};


@implementation SKTLine


+ (void)initialize {

    // Specify that invocations of [aLine setBounds:aRect] or [aLine setValue:[NSValue valueWithRect:aRect] forKey:SKTGraphicBoundsKey], or anything else that causes the "bounds" to change in a KVO-compliant way, should automatically notify observers of "beginPoint" and "endPoint" too, because the values of those properties are derived from the value of the bounds.
    NSArray *boundsKeyAsArray = [NSArray arrayWithObject:SKTGraphicBoundsKey];
    [self setKeys:boundsKeyAsArray triggerChangeNotificationsForDependentKey:SKTLineBeginPointKey];
    [self setKeys:boundsKeyAsArray triggerChangeNotificationsForDependentKey:SKTLineEndPointKey];

    // Don't prevent the invocations of -setKeys:triggerChangeNotificationsForDependentKey: that +[SKTGraphic initialize] does.
    [super initialize];

}


- (id)copyWithZone:(NSZone *)zone {

    // Do the regular Cocoa thing.
    SKTLine *copy = [super copyWithZone:zone];
    copy->_pointsRight = _pointsRight;
    copy->_pointsDown = _pointsDown;
    return copy;

}


#pragma mark *** Private KVC-Compliance for Public Properties ***


// The only reason we have to have this many methods for simple KVC and KVO compliance for "beginPoint" and "endPoint" is because reusing SKTGraphic's "bounds" property is so complicated (see the instance variable comments in the header). If we just had _beginPoint and _endPoint we wouldn't need any of these methods because KVC's direct instance variable access and KVO's autonotification would just take care of everything for us (though maybe then we'd have to override -setBounds: and -bounds to fulfill the KVC and KVO compliance obligation for "bounds" that this class inherits from its superclass).


- (NSPoint)beginPoint {
    
    // Convert from our odd storage format to something natural.
    NSPoint beginPoint;
    NSRect bounds = [self bounds];
    beginPoint.x = _pointsRight ? NSMinX(bounds) : NSMaxX(bounds);
    beginPoint.y = _pointsDown ? NSMinY(bounds) : NSMaxY(bounds);
    return beginPoint;
    
}


- (NSPoint)endPoint {
    
    // Convert from our odd storage format to something natural.
    NSPoint endPoint;
    NSRect bounds = [self bounds];
    endPoint.x = _pointsRight ? NSMaxX(bounds) : NSMinX(bounds);
    endPoint.y = _pointsDown ? NSMaxY(bounds) : NSMinY(bounds);
    return endPoint;
    
}


+ (NSRect)boundsWithBeginPoint:(NSPoint)beginPoint endPoint:(NSPoint)endPoint pointsRight:(BOOL *)outPointsRight down:(BOOL *)outPointsDown {

    // Convert the begin and end points of the line to its bounds and flags specifying the direction in which it points.
    BOOL pointsRight = beginPoint.x<endPoint.x;
    BOOL pointsDown = beginPoint.y<endPoint.y;
    CGFloat xPosition = pointsRight ? beginPoint.x : endPoint.x;
    CGFloat yPosition = pointsDown ? beginPoint.y : endPoint.y;
    CGFloat width = fabs(endPoint.x - beginPoint.x);
    CGFloat height = fabs(endPoint.y - beginPoint.y);
    if (outPointsRight) {
	*outPointsRight = pointsRight;
    }
    if (outPointsDown) {
	*outPointsDown = pointsDown;
    }
    return NSMakeRect(xPosition, yPosition, width, height);
    
}


- (void)setBeginPoint:(NSPoint)beginPoint {
    
    // It's easiest to compute the results of setting these points together.
    [self setBounds:[[self class] boundsWithBeginPoint:beginPoint endPoint:[self endPoint] pointsRight:&_pointsRight down:&_pointsDown]];
    
}


- (void)setEndPoint:(NSPoint)endPoint {
    
    // It's easiest to compute the results of setting these points together.
    [self setBounds:[[self class] boundsWithBeginPoint:[self beginPoint] endPoint:endPoint pointsRight:&_pointsRight down:&_pointsDown]];
	
}


#pragma mark *** Overrides of SKTGraphic Methods ***


- (id)initWithProperties:(NSDictionary *)properties {

    // Let SKTGraphic do its job and then handle the additional properties defined by this subclass.
    self = [super initWithProperties:properties];
    if (self) {

	// This object still doesn't have a bounds (because of what we do in our override of -properties), so set one and record the other information we need to place the begin and end points. The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
	Class stringClass = [NSString class];
	NSString *beginPointString = [properties objectForKey:SKTLineBeginPointKey];
	NSPoint beginPoint = [beginPointString isKindOfClass:stringClass] ? NSPointFromString(beginPointString) : NSZeroPoint;
	NSString *endPointString = [properties objectForKey:SKTLineEndPointKey];
	NSPoint endPoint = [endPointString isKindOfClass:stringClass] ? NSPointFromString(endPointString) : NSZeroPoint;
	[self setBounds:[[self class] boundsWithBeginPoint:beginPoint endPoint:endPoint pointsRight:&_pointsRight down:&_pointsDown]];

    }
    return self;

}


- (NSMutableDictionary *)properties {

    // Let SKTGraphic do its job but throw out the bounds entry in the dictionary it returned and add begin and end point entries insteads. We do this instead of simply recording the currnet value of _pointsRight and _pointsDown because bounds+pointsRight+pointsDown is just too unnatural to immortalize in a file format. The dictionary must contain nothing but values that can be written in old-style property lists.
    NSMutableDictionary *properties = [super properties];
    [properties removeObjectForKey:SKTGraphicBoundsKey];
    [properties setObject:NSStringFromPoint([self beginPoint]) forKey:SKTLineBeginPointKey];
    [properties setObject:NSStringFromPoint([self endPoint]) forKey:SKTLineEndPointKey];
    return properties;

}


// We don't bother overriding +keysForValuesAffectingDrawingBounds because we don't need to take advantage of the KVO dependency mechanism enabled by that method. We fulfill our KVO compliance obligations (inherited from SKTGraphic) for SKTGraphicDrawingBoundsKey by just always invoking -setBounds: in -setBeginPoint: and -setEndPoint:. "bounds" is always in the set returned by +[SKTGraphic keysForValuesAffectingDrawingBounds]. Now, there's nothing in SKTGraphic.h that actually guarantees that, so we're taking advantage of "undefined" behavior. If we didn't have the source to SKTGraphic right next to the source for this class it would probably be prudent to override +keysForValuesAffectingDrawingBounds, and make sure.

// We don't bother overriding +keysForValuesAffectingDrawingContents because this class doesn't define any properties that affect drawing without affecting the bounds.


- (BOOL)isDrawingFill {

    // You can't fill a line.
    return NO;

}


- (BOOL)isDrawingStroke {

    // You can't not stroke a line.
    return YES;

}


- (NSBezierPath *)bezierPathForDrawing {

    // Simple.
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:[self beginPoint]];
    [path lineToPoint:[self endPoint]];
    [path setLineWidth:[self strokeWidth]];
    return path;

}


- (void)drawHandlesInView:(NSView *)view {
    
    // A line only has two handles.
    [self drawHandleInView:view atPoint:[self beginPoint]];
    [self drawHandleInView:view atPoint:[self endPoint]];

}


+ (NSInteger)creationSizingHandle {

    // When the user creates a line and is dragging around a handle to size it they're dragging the end of the line.
    return SKTLineEndHandle;

}


- (BOOL)canSetDrawingFill {

    // Don't let the user think we can fill a line.
    return NO;

}


- (BOOL)canSetDrawingStroke {

    // Don't let the user think can ever not stroke a line.
    return NO;

}


- (BOOL)canMakeNaturalSize {

    // What would the "natural size" of a line be?
    return NO;

}


- (BOOL)isContentsUnderPoint:(NSPoint)point {

    // Do a gross check against the bounds.
    BOOL isContentsUnderPoint = NO;
    if (NSPointInRect(point, [self bounds])) {

	// Let the user click within the stroke width plus some slop.
	CGFloat acceptableDistance = ([self strokeWidth] / 2.0f) + 2.0f;

	// Before doing anything avoid a divide by zero error.
	NSPoint beginPoint = [self beginPoint];
	NSPoint endPoint = [self endPoint];
	CGFloat xDelta = endPoint.x - beginPoint.x;
	if (xDelta==0.0f && fabs(point.x - beginPoint.x)<=acceptableDistance) {
	    isContentsUnderPoint = YES;
	} else {

	    // Do a weak approximation of distance to the line segment.
	    CGFloat slope = (endPoint.y - beginPoint.y) / xDelta;
	    if (fabs(((point.x - beginPoint.x) * slope) - (point.y - beginPoint.y))<=acceptableDistance) {
		isContentsUnderPoint = YES;
	    }

	}

    }
    return isContentsUnderPoint;

}


- (NSInteger)handleUnderPoint:(NSPoint)point {

    // A line just has handles at its ends.
    NSInteger handle = SKTGraphicNoHandle;
    if ([self isHandleAtPoint:[self beginPoint] underPoint:point]) {
	handle = SKTLineBeginHandle;
    } else if ([self isHandleAtPoint:[self endPoint] underPoint:point]) {
	handle = SKTLineEndHandle;
    }
    return handle;

}


- (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point {

    // A line just has handles at its ends.
    if (handle==SKTLineBeginHandle) {
	[self setBeginPoint:point];
    } else if (handle==SKTLineEndHandle) {
	[self setEndPoint:point];
    } // else a cataclysm occurred.

    // We don't have to do the kind of handle flipping that SKTGraphic does.
    return handle;

}


- (void)setColor:(NSColor *)color {

    // Because lines aren't filled we'll consider the stroke's color to be the one.
    [self setValue:color forKey:SKTGraphicStrokeColorKey];

}


- (NSSet *)keysForValuesToObserveForUndo {
    
    // When the user drags one of the handles of a line we don't want to just have changes to "bounds" registered in the undo group. That would be:
    // 1) Insufficient. We would also have to register changes of "pointsRight" and "pointsDown," but we already decided to keep those properties private (see the comments in the header).
    // 2) Not very user-friendly. We don't want the user to see an "Undo Change of Bounds" item in the Edit menu. We want them to see "Undo Change of Endpoint."
    // So, tell the observer of undoable properties (SKTDocument, in Sketch) to observe "beginPoint" and "endPoint" instead of "bounds."
    NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
    [keys removeObject:SKTGraphicBoundsKey];
    [keys addObject:SKTLineBeginPointKey];
    [keys addObject:SKTLineEndPointKey];
    return [keys autorelease];
    
}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {
    
    // Pretty simple. As is usually the case when a key is passed into a method like this, we have to invoke super if we don't recognize the key. As far as the user is concerned both points that define a line are "endpoints."
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
	presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Beginpoint", @"UndoStrings", @"Action name part for SKTLineBeginPointKey."), SKTLineBeginPointKey,
	    NSLocalizedStringFromTable(@"Endpoint", @"UndoStrings",@"Action name part for SKTLineEndPointKey."), SKTLineEndPointKey,
	    nil];
    }
    NSString *presentablePropertyName = [presentablePropertyNamesByKey objectForKey:key];
    if (!presentablePropertyName) {
	presentablePropertyName = [super presentablePropertyNameForKey:key];
    }
    return presentablePropertyName;

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
