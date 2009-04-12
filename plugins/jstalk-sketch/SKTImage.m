/*
	SKTImage.m
	Part of the Sketch Sample Code
*/


#import "SKTImage.h"


// String constants declared in the header. They may not be used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
NSString *SKTImageIsFlippedHorizontallyKey = @"flippedHorizontally";
NSString *SKTImageIsFlippedVerticallyKey = @"flippedVertically";
NSString *SKTImageFilePathKey = @"filePath";

// Another key, which is just used in persistent property dictionaries.
static NSString *SKTImageContentsKey = @"contents";

@implementation SKTImage


- (id)copyWithZone:(NSZone *)zone {

    // Do the regular Cocoa thing.
    SKTImage *copy = [super copyWithZone:zone];
    copy->_contents = [_contents copy];
    return copy;

}


- (void)dealloc {

    // Do the regular Cocoa thing.
    [_contents release];
    [super dealloc];

}


#pragma mark *** Private KVC-Compliance for Public Properties ***


- (void)setFlippedHorizontally:(BOOL)isFlippedHorizontally {

    // Record the value and flush the transformed contents cache.
    _isFlippedHorizontally = isFlippedHorizontally;

}


- (void)setFlippedVertically:(BOOL)isFlippedVertically {

    // Record the value and flush the transformed contents cache.
    _isFlippedVertically = isFlippedVertically;
    
}


- (void)setFilePath:(NSString *)filePath {

    // If there's a transformed version of the contents being held as a cache, it's invalid now.
    NSImage *newContents = [[NSImage alloc] initWithContentsOfFile:[filePath stringByStandardizingPath]];
    if (_contents) {
	[_contents release];
    }
    _contents = [newContents retain];
    
}


#pragma mark *** Public Methods ***


- (id)initWithPosition:(NSPoint)position contents:(NSImage *)contents {

    // Do the regular Cocoa thing.
    self = [self init];
    if (self) {
	_contents = [contents retain];

	// Leave the image centered on the mouse pointer.
	NSSize contentsSize = [_contents size];
	[self setBounds:NSMakeRect((position.x - (contentsSize.width / 2.0f)), (position.y - (contentsSize.height / 2.0f)), contentsSize.width, contentsSize.height)];

    }
    return self;

}


#pragma mark *** Overrides of SKTGraphic Methods ***


- (id)initWithProperties:(NSDictionary *)properties {
    
    // Let SKTGraphic do its job and then handle the additional properties defined by this subclass.
    self = [super initWithProperties:properties];
    if (self) {

	// The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
	NSData *contentsData = [properties objectForKey:SKTImageContentsKey];
	if ([contentsData isKindOfClass:[NSData class]]) {
	    NSImage *contents = [NSUnarchiver unarchiveObjectWithData:contentsData];
	    if ([contents isKindOfClass:[NSImage class]]) {
		_contents = [contents retain];
	    }
	}
	NSNumber *isFlippedHorizontallyNumber = [properties objectForKey:SKTImageIsFlippedHorizontallyKey];
	if ([isFlippedHorizontallyNumber isKindOfClass:[NSNumber class]]) {
	    _isFlippedHorizontally = [isFlippedHorizontallyNumber boolValue];
	}
	NSNumber *isFlippedVerticallyNumber = [properties objectForKey:SKTImageIsFlippedVerticallyKey];
	if ([isFlippedVerticallyNumber isKindOfClass:[NSNumber class]]) {
	    _isFlippedVertically = [isFlippedVerticallyNumber boolValue];
	}

    }
    return self;
    
}


- (NSMutableDictionary *)properties {

    // Let SKTGraphic do its job and then handle the one additional property defined by this subclass. The dictionary must contain nothing but values that can be written in old-style property lists.
    NSMutableDictionary *properties = [super properties];
    [properties setObject:[NSArchiver archivedDataWithRootObject:_contents] forKey:SKTImageContentsKey];
    [properties setObject:[NSNumber numberWithBool:_isFlippedHorizontally] forKey:SKTImageIsFlippedHorizontallyKey];
    [properties setObject:[NSNumber numberWithBool:_isFlippedVertically] forKey:SKTImageIsFlippedVerticallyKey];
    return properties;

}


- (BOOL)isDrawingFill {

    // We never fill an image with color.
    return NO;

}


- (BOOL)isDrawingStroke {

    // We never draw a stroke on an image.
    return NO;

}


+ (NSSet *)keysForValuesAffectingDrawingContents {

    // Flipping affects drawing but not the drawing bounds. So of course do the properties managed by the superclass.
    NSMutableSet *keys = [[super keysForValuesAffectingDrawingContents] mutableCopy];
    [keys addObject:SKTImageIsFlippedHorizontallyKey];
    [keys addObject:SKTImageIsFlippedVerticallyKey];
    return [keys autorelease];

}


- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing {

    // Fill the background with the fill color. Maybe it will show, if the image has an alpha channel.
    NSRect bounds = [self bounds];
    if ([self isDrawingFill]) {
        [[self fillColor] set];
        NSRectFill(bounds);
    }

    // Surprisingly, NSImage's -draw... methods don't take into account whether or not the view is flipped. In Sketch, SKTGraphicViews are flipped (and this model class is not supposed to have dependencies on the oddities of any particular view class anyway). So, just do our own transformation matrix manipulation.
    NSAffineTransform *transform = [NSAffineTransform transform];

    // Translating to actually place the image (as opposed to translating as part of flipping).
    [transform translateXBy:bounds.origin.x yBy:bounds.origin.y];

    // Flipping according to the user's wishes.
    [transform translateXBy:(_isFlippedHorizontally ? bounds.size.width : 0.0f) yBy:(_isFlippedVertically ? bounds.size.height : 0.0f)];
    [transform scaleXBy:(_isFlippedHorizontally ? -1.0f : 1.0f) yBy:(_isFlippedVertically ? -1.0f : 1.0f)];

    // Scaling to actually size the image (as opposed to scaling as part of flipping).
    NSSize contentsSize = [_contents size];
    [transform scaleXBy:(bounds.size.width / contentsSize.width) yBy:(bounds.size.height / contentsSize.height)];

    // Flipping to accomodate -[NSImage drawAtPoint:fromRect:operation:fraction:]'s odd behavior.
    if ([view isFlipped]) {
	[transform translateXBy:0.0f yBy:contentsSize.height];
	[transform scaleXBy:1.0f yBy:-1.0f];
    }

    // Do the actual drawing, saving and restoring the graphics state so as not to interfere with the drawing of selection handles or anything else in the same view.
    [[NSGraphicsContext currentContext] saveGraphicsState];
    [transform concat];
    [_contents drawAtPoint:NSZeroPoint fromRect:NSMakeRect(0.0f, 0.0f, contentsSize.width, contentsSize.height) operation:NSCompositeSourceOver fraction:1.0f];
    [[NSGraphicsContext currentContext] restoreGraphicsState];
    
}


- (BOOL)canSetDrawingFill {

    // Don't let the user think we would even try to fill an image with color.
    return NO;

}


- (BOOL)canSetDrawingStroke {

    // Don't let the user think we would even try to draw a stroke on image.
    return NO;

}


- (void)flipHorizontally {

    // Simple.
    [self setFlippedHorizontally:(_isFlippedHorizontally ? NO : YES)];

}

- (void)flipVertically {

    // Simple.
    [self setFlippedVertically:(_isFlippedVertically ? NO : YES)];
    
}


- (void)makeNaturalSize {

    // Return the image to its natural size and stop flipping it.
    NSRect bounds = [self bounds];
    bounds.size = [_contents size];
    [self setBounds:bounds];
    [self setFlippedHorizontally:NO];
    [self setFlippedVertically:NO];

}


- (void)setBounds:(NSRect)bounds {

    // Flush the transformed contents cache and then do the regular SKTGraphic thing.
    [super setBounds:bounds];

}


- (NSSet *)keysForValuesToObserveForUndo {

    // This class defines a few properties for which changes are undoable, in addition to the ones inherited from SKTGraphic.
    NSMutableSet *keys = [[super keysForValuesToObserveForUndo] mutableCopy];
    [keys addObject:SKTImageIsFlippedHorizontallyKey];
    [keys addObject:SKTImageIsFlippedVerticallyKey];
    return [keys autorelease];
    
}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {

    // Pretty simple. As is usually the case when a key is passed into a method like this, we have to invoke super if we don't recognize the key.
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
	presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Horizontal Flipping", @"UndoStrings", @"Action name part for SKTImageIsFlippedHorizontallyKey."), SKTImageIsFlippedHorizontallyKey,
	    NSLocalizedStringFromTable(@"Vertical Flipping", @"UndoStrings",@"Action name part for SKTImageIsFlippedVerticallyKey."), SKTImageIsFlippedVerticallyKey,
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
