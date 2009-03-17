/*
	SKTWindowController.m
	Part of the Sketch Sample Code
*/


#import "SKTWindowController.h"
#import "SKTDocument.h"
#import "SKTGraphic.h"
#import "SKTGraphicView.h"
#import "SKTGrid.h"
#import "SKTToolPaletteController.h"
#import "SKTZoomingScrollView.h"


// A value that's used as a context by this class' invocation of a KVO observer registration method. See the comment near the top of SKTGraphicView.m for a discussion of this.
static NSString *SKTWindowControllerCanvasSizeObservationContext = @"com.apple.SKTWindowController.canvasSize";


@implementation SKTWindowController


- (id)init {

    // Do the regular Cocoa thing, specifying a particular nib.
    self = [super initWithWindowNibName:@"DrawWindow"];
    if (self) {

	// Create a grid for use by graphic views whose "grid" property is bound to this object's "grid" property.
	_grid = [[SKTGrid alloc] init];

	// Set the zoom factor to a reasonable default (100%).
	_zoomFactor = 1.0f;

    }
    return self;

}


- (void)dealloc {

    // Stop observing the tool palette.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SKTSelectedToolDidChangeNotification object:[SKTToolPaletteController sharedToolPaletteController]];
    
    // Stop observing the document's canvas size.
    [[self document] removeObserver:self forKeyPath:SKTDocumentCanvasSizeKey];

    // Do the regular Cocoa thing.
    [_grid release];
    [super dealloc];

}


#pragma mark *** Observing ***


- (void)observeDocumentCanvasSize:(NSSize)documentCanvasSize {
    
    // The document's canvas size changed. Invoking -setNeedsDisplay: twice like this makes sure everything gets redrawn if the view gets smaller in one direction or the other.
    [_graphicView setNeedsDisplay:YES];
    [_graphicView setFrameSize:documentCanvasSize];
    [_graphicView setNeedsDisplay:YES];

}


// An override of the NSObject(NSKeyValueObserving) method.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context {

    // Make sure we don't intercept an observer notification that's meant for NSWindowController. In Tiger NSWindowControllers don't observe anything, but that could change in the future. We can do a simple pointer comparison because KVO doesn't do anything at all with the context value, not even retain or copy it.
    if (context==SKTWindowControllerCanvasSizeObservationContext) {

	// The "new value" in the change dictionary will be NSNull, instead of just not existing, if the value for some key in the key path is nil. In this case there are times in an NSWindowController's life cycle when its document is nil. Don't update the graphic view's size when we get notifications about that.
	NSValue *documentCanvasSizeValue = [change objectForKey:NSKeyValueChangeNewKey];
	if (![documentCanvasSizeValue isEqual:[NSNull null]]) {
	    [self observeDocumentCanvasSize:[documentCanvasSizeValue sizeValue]];
	}

    } else {
	
	// In overrides of -observeValueForKeyPath:ofObject:change:context: always invoke super when the observer notification isn't recognized. Code in the superclass is apparently doing observation of its own. NSObject's implementation of this method throws an exception. Such an exception would be indicating a programming error that should be fixed.
	[super observeValueForKeyPath:keyPath ofObject:observedObject change:change context:context];

    }

}


- (void)selectedToolDidChange:(NSNotification *)notification {
    // Just set the correct cursor
    Class theClass = [[SKTToolPaletteController sharedToolPaletteController] currentGraphicClass];
    NSCursor *theCursor = nil;
    if (theClass) {
        theCursor = [theClass creationCursor];
    }
    if (!theCursor) {
        theCursor = [NSCursor arrowCursor];
    }
    [[_graphicView enclosingScrollView] setDocumentCursor:theCursor];
}


#pragma mark *** Overrides of NSWindowController Methods ***


- (void)setDocument:(NSDocument *)document {

    // Cocoa Bindings makes many things easier. Unfortunately, one of the things it makes easier is creation of reference counting cycles. In Tiger NSWindowController has a feature that keeps bindings to File's Owner, when File's Owner is a window controller, from retaining the window controller in a way that would prevent its deallocation. We're setting up bindings programmatically in -windowDidLoad though, so that feature doesn't kick in, and we have to explicitly unbind to make sure this window controller and everything in the nib it owns get deallocated. We do this here instead of in an override of -[NSWindowController close] because window controllers aren't sent -close messages for every kind of window closing. Fortunately, window controllers are sent -setDocument:nil messages during window closing.
    if (!document) {
	[_zoomingScrollView unbind:SKTZoomingScrollViewFactor];
	[_graphicView unbind:SKTGraphicViewGridBindingName];
	[_graphicView unbind:SKTGraphicViewGraphicsBindingName];
    }
    
    // Redo the observing of the document's canvas size when the document changes. You would think we would just be able to observe self's "document.canvasSize" in -windowDidLoad or maybe even -init, but KVO wasn't really designed with observing of self in mind so things get a little squirrelly.
    [[self document] removeObserver:self forKeyPath:SKTDocumentCanvasSizeKey];
    [super setDocument:document];
    [[self document] addObserver:self forKeyPath:SKTDocumentCanvasSizeKey options:NSKeyValueObservingOptionNew context:SKTWindowControllerCanvasSizeObservationContext];

}


- (void)windowDidLoad {

    // Do the regular Cocoa thing.
    [super windowDidLoad];

    // Set up the graphic view and its enclosing scroll view.
    NSScrollView *enclosingScrollView = [_graphicView enclosingScrollView];
    [enclosingScrollView setHasHorizontalRuler:YES];
    [enclosingScrollView setHasVerticalRuler:YES];

    // We're already observing the document's canvas size in case it changes, but we haven't been able to size the graphic view to match until now.
    [self observeDocumentCanvasSize:[(SKTDocument *)[self document] canvasSize]];

    // Bind the graphic view's selection indexes to the controller's selection indexes. The graphics controller's content array is bound to the document's graphics in the nib, so it knows when graphics are added and remove, so it can keep the selection indexes consistent.
    [_graphicView bind:SKTGraphicViewSelectionIndexesBindingName toObject:_graphicsController withKeyPath:@"selectionIndexes" options:nil];

    // Bind the graphic view's graphics to the document's graphics. We do this instead of binding to the graphics controller because NSArrayController is not KVC-compliant enough for "arrangedObjects" to work properly when the graphic view sends its bound-to object a -mutableArrayValueForKeyPath: message. The binding to self's "document.graphics" is 1) easy and 2) appropriate for a window controller that may someday be able to show one of several documents in its window. If we instead bound the graphic view to [self document] then we would have to redo the binding in -setDocument:.
    [_graphicView bind:SKTGraphicViewGraphicsBindingName toObject:self withKeyPath:[NSString stringWithFormat:@"%@.%@", @"document", SKTDocumentGraphicsKey] options:nil];

    // Bind the graphic view's grid to this window controller's grid.
    [_graphicView bind:SKTGraphicViewGridBindingName toObject:self withKeyPath:@"grid" options:nil];

    // Bind the zooming scroll view's factor to this window's controller's zoom factor.
    [_zoomingScrollView bind:SKTZoomingScrollViewFactor toObject:self withKeyPath:@"zoomFactor" options:nil];
    
    // Start observing the tool palette.
    [self selectedToolDidChange:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedToolDidChange:) name:SKTSelectedToolDidChangeNotification object:[SKTToolPaletteController sharedToolPaletteController]];

}


#pragma mark *** Actions ***


// Conformance to the NSObject(NSMenuValidation) informal protocol.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    // Which menu item?
    BOOL enabled;
    SEL action = [menuItem action];
    if (action==@selector(newDocumentWindow:)) {

	// Give the menu item that creates new sibling windows for this document a reasonably descriptive title. It's important to use the document's "display name" in places like this; it takes things like file name extension hiding into account. We could do a better job with the punctuation!
	[menuItem setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"New window for '%@'", @"MenuItems", @"Formatter string for the new document window menu item. Argument is a the display name of the document."), [[self document] displayName]]];
	enabled = YES;

    } else if (action==@selector(toggleGridConstraining:) || action==@selector(toggleGridShowing:)) {

	// The grid can be in an unusable state, in which case the menu items that control it are disabled.
	enabled = [_grid isUsable];

	// The Snap to Grid and Show Grid menu items are toggles.
	BOOL menuItemIsOn = action==@selector(toggleGridConstraining:) ? [_grid isConstraining] : [_grid isAlwaysShown];
	[menuItem setState:(menuItemIsOn ? NSOnState : NSOffState)];

    } else {
	enabled = [super validateMenuItem:menuItem];
    }
    return enabled;

}


- (IBAction)newDocumentWindow:(id)sender {

    // Do the same thing that a typical override of -[NSDocument makeWindowControllers] would do, but then also show the window. This is here instead of in SKTDocument, though it would work there too, with one small alteration, because it's really view-layer code.
    SKTWindowController *windowController = [[SKTWindowController alloc] init];
    [[self document] addWindowController:windowController];
    [windowController showWindow:self];
    [windowController release];

}


- (IBAction)toggleGridConstraining:(id)sender {

    // Simple.
    [_grid setConstraining:![_grid isConstraining]];

}


- (IBAction)toggleGridShowing:(id)sender{

    // Simple.
    [_grid setAlwaysShown:![_grid isAlwaysShown]];

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
