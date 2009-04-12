/*
	SKTRenderingView.m
	Part of the Sketch Sample Code
*/


#import "SKTRenderingView.h"
#import "SKTError.h"
#import "SKTGraphic.h"


@implementation SKTRenderingView


+ (NSData *)pdfDataWithGraphics:(NSArray *)graphics {

    // Create a view that will be used just for making PDF.
    NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];
    SKTRenderingView *view = [[SKTRenderingView alloc] initWithFrame:bounds graphics:graphics printJobTitle:nil];
    NSData *pdfData = [view dataWithPDFInsideRect:bounds];
    [view release];
    return pdfData;

}


+ (NSData *)tiffDataWithGraphics:(NSArray *)graphics error:(NSError **)outError {

    // How big a of a TIFF are we going to make? Regardless of what NSImage supports, Sketch doesn't support the creation of TIFFs that are 0 by 0 pixels. (We have to demonstrate a custom saving error somewhere, and this is an easy place to do it...)
    NSData *tiffData = nil;
    NSRect bounds = [SKTGraphic drawingBoundsOfGraphics:graphics];
    if (!NSIsEmptyRect(bounds)) {
	
	// Create a new image and prepare to draw in it. Get the graphics context for it after we lock focus, not before.
	NSImage *image = [[NSImage alloc] initWithSize:bounds.size];
	[image setFlipped:YES];
	[image lockFocus];
	NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
	
	// We're not drawing a page image here, just the rectangle that contains the graphics being drawn, so make sure they get drawn in the right place.
	NSAffineTransform *transform = [NSAffineTransform transform];
	[transform translateXBy:(0.0f - bounds.origin.x) yBy:(0.0f - bounds.origin.y)];
	[transform concat];
	
	// Draw the graphics back to front.
	NSUInteger graphicIndex = [graphics count];
	while (graphicIndex-->0) {
	    SKTGraphic *graphic = [graphics objectAtIndex:graphicIndex];
	    [currentContext saveGraphicsState];
	    [NSBezierPath clipRect:[graphic drawingBounds]];
	    [graphic drawContentsInView:nil isBeingCreateOrEdited:NO];
	    [currentContext restoreGraphicsState];
	}
	
	// We're done drawing.
	[image unlockFocus];
	tiffData = [image TIFFRepresentation];
	[image release];
	
    } else if (outError) {
	
	// In Sketch there are lots of places to catch this situation earlier. For example, we could have overridden -writableTypesForSaveOperation: and made it not return NSTIFFPboardType, but then the user would have no idea why TIFF isn't showing up in the save panel's File Format popup. This way we can present a nice descriptive errror message.
	*outError = SKTErrorWithCode(SKTWriteCouldntMakeTIFFError);
	
    }
    return tiffData;
    
}


- (id)initWithFrame:(NSRect)frame graphics:(NSArray *)graphics printJobTitle:(NSString *)printJobTitle {

    // Do the regular Cocoa thing.
    self = [super initWithFrame:frame];
    if (self) {
	_graphics = [graphics copy];
	_printJobTitle = [printJobTitle copy];
    }
    return self;

}


- (void)dealloc {

    // Do the regular Cocoa thing.
    [_printJobTitle release];
    [_graphics release];
    [super dealloc];

}


// An override of the NSView method.
- (void)drawRect:(NSRect)rect {

    // Draw the background background.
    [[NSColor whiteColor] set];
    NSRectFill(rect);
    
    // Draw every graphic that intersects the rectangle to be drawn. In Sketch the frontmost graphics have the lowest indexes.
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    NSInteger graphicCount = [_graphics count];
    for (NSInteger index = graphicCount - 1; index>=0; index--) {
        SKTGraphic *graphic = [_graphics objectAtIndex:index];
        NSRect graphicDrawingBounds = [graphic drawingBounds];
        if (NSIntersectsRect(rect, graphicDrawingBounds)) {

	    // Draw the graphic.
            [currentContext saveGraphicsState];
            [NSBezierPath clipRect:graphicDrawingBounds];
            [graphic drawContentsInView:self isBeingCreateOrEdited:NO];
            [currentContext restoreGraphicsState];
	    
        }
    }
    
}


// An override of the NSView method.
- (BOOL)isFlipped {

    // Put (0, 0) at the top-left of the view.
    return YES;

}


// An override of the NSView method.
- (BOOL)isOpaque {

    // Our override of -drawRect: always draws a background.
    return YES;

}


// An override of the NSView method.
- (NSString *)printJobTitle {
    
    // Do the regular Cocoa thing.
    return [[_printJobTitle retain] autorelease];

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
