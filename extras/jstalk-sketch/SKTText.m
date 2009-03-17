/*
	SKTText.m
	Part of the Sketch Sample Code
*/


#import "SKTText.h"


// String constants declared in the header. They may not be used by any other class in the project, but it's a good idea to provide and use them, if only to help prevent typos in source code.
NSString *SKTTextScriptingContentsKey = @"scriptingContents";
NSString *SKTTextUndoContentsKey = @"undoContents";

// A key that's used in Sketch's property-list-based file and pasteboard formats.
NSString *SKTTextContentsKey = @"contents";


@implementation SKTText


- (NSTextStorage *)contents {

    // Never return nil.
    if (!_contents) {
	_contents = [[NSTextStorage alloc] init];

	// We need to be notified whenever the text storage changes.
	[_contents setDelegate:self];

    }
    return _contents;

}


- (id)copyWithZone:(NSZone *)zone {

    // Sending -copy or -mutableCopy to an NSTextStorage results in an NSAttributedString or NSMutableAttributedString, so we have to do something a little different. We go through [copy contents] to make sure delegation gets set up properly, and [self contents] to easily ensure we're not passing nil to -setAttributedString:.
    SKTText *copy = [super copyWithZone:zone];
    [[copy contents] setAttributedString:[self contents]];
    return copy;

}


- (void)dealloc {

    // Do the regular Cocoa thing.
    [_contents setDelegate:nil];
    [_contents release];
    [super dealloc];

}


#pragma mark *** Text Layout ***


// This is a class method to ensure that it doesn't need to access the state of any particular SKTText.
+ (NSLayoutManager *)sharedLayoutManager {

    // Return a layout manager that can be used for any drawing.
    static NSLayoutManager *layoutManager = nil;
    if (!layoutManager) {
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1.0e7f, 1.0e7f)];
	layoutManager = [[NSLayoutManager alloc] init];
	[textContainer setWidthTracksTextView:NO];
        [textContainer setHeightTracksTextView:NO];
        [layoutManager addTextContainer:textContainer];
        [textContainer release];
    }
    return layoutManager;

}


- (NSSize)naturalSize {

    // Figure out how big this graphic would have to be to show all of its contents. -glyphRangeForTextContainer: forces layout.
    NSRect bounds = [self bounds];
    NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
    NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
    [textContainer setContainerSize:NSMakeSize(bounds.size.width, 1.0e7f)];
    NSTextStorage *contents = [self contents]; 
    [contents addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];
    NSSize naturalSize = [layoutManager usedRectForTextContainer:textContainer].size;
    [contents removeLayoutManager:layoutManager];
    return naturalSize;

}


- (void)setHeightToMatchContents {

    // Update the bounds of this graphic to match the height of the text. Make sure that doesn't result in the registration of a spurious undo action.
    // There might be a noticeable performance win to be had during editing by making this object a delegate of the text views it creates, implementing -[NSObject(NSTextDelegate) textDidChange:], and using information that's already calculated by the editing text view instead of invoking -makeNaturalSize like this.
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _boundsBeingChangedToMatchContents = YES;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    NSRect bounds = [self bounds];
    NSSize naturalSize = [self naturalSize];
    [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, bounds.size.width, naturalSize.height)];
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _boundsBeingChangedToMatchContents = NO;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];

}


// Conformance to the NSObject(NSTextStorageDelegate) informal protocol.
- (void)textStorageDidProcessEditing:(NSNotification *)notification {

    // The work we're going to do here involves sending -glyphRangeForTextContainer: to a layout manager, but you can't send that message to a layout manager attached to a text storage that's still responding to -endEditing, so defer the work to a point where -endEditing has returned.
    [self performSelector:@selector(setHeightToMatchContents) withObject:nil afterDelay:0.0];

}


#pragma mark *** Private KVC-Compliance for Public Properties ***


- (void)willChangeScriptingContents {

    // Tell any object that would observe this one to record undo operations to start observing. In Sketch, each SKTDocument is observing all of its graphics' "keysForValuesToObserveForUndo" values.
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _contentsBeingChangedByScripting = YES;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];

    // Do the first part of notifying observers. It's OK if no changes are actually done by scripting before the matching invocation of -didChangeValueForKey:. Key-value observers aren't allowed to assume that every observer notification is about a real change (that's why the KVO notification method's name starts with -observeValueForKeyPath:, not -observeChangeOfValueForKeyPath:).
    [self willChangeValueForKey:SKTTextUndoContentsKey];

}


- (void)didChangeScriptingContents {

    // Any changes that might have been done by the scripting command are done.
    [self didChangeValueForKey:SKTTextUndoContentsKey];

    // Tell observers to stop observing to record undo operations.
    // This isn't strictly necessary in Sketch: we could just let the SKTDocument keep observing, because we know that no other objects are observing "undoContents." Partial KVO-compliance like this that only works some of the time is a dangerous game though, and it's a good idea to be very explicit about it. This class is very explictily only KVO-compliant for "undoContents" while -keysForValuesToObserveForUndo is returning a set that contains "undoContents."
    [self willChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];
    _contentsBeingChangedByScripting = NO;
    [self didChangeValueForKey:SKTGraphicKeysForValuesToObserveForUndoKey];

}


- (NSTextStorage *)scriptingContents {

    // Before returning an NSTextStorage that Cocoa's scripting support can work with, do the first part of notifying observers, and then schedule the second part of notifying observers for after all potential scripted changes caused by the current scripting command have been done.
    // An alternative to the way we notify key-value observers here would be to return an NSTextStorage that's a proxy to the one held by this object, and make it send this object the -willChangeValueForKey:/-didChangeValueForKey: messages around forwarding of mutation messages (sort of like what the collection proxy objects returned by KVC for sets and arrays do), but that wouldn't gain us anything as far as we know right now, and might even lead to performance problems (because one scripting command could result in potentially many KVO notifications).
    [self willChangeScriptingContents];
    [self performSelector:@selector(didChangeScriptingContents) withObject:nil afterDelay:0.0];
    return [self contents];

}


- (id)coerceValueForScriptingContents:(id)contents {

    // Make sure that NSStrings aren't coerced to NSAttributedStrings by Cocoa's coercion machinery. -setScriptingContents: will do something special with them.
    id coercedContents;
    if ([contents isKindOfClass:[NSString class]]) {
        coercedContents = contents;
    } else {
        coercedContents = [[NSScriptCoercionHandler sharedCoercionHandler] coerceValue:contents toClass:[NSTextStorage class]];
    }
    return coercedContents;

}


- (void)setScriptingContents:(id)newContents {

    // If an attributed string is passed then then do a simple replacement. If a string is passed in then reuse the character style that's already there. Either way, we must notify observers of "undoContents" that its value is changing here.
    // By the way, if this method actually changed the value of _contents we would have to move any layout managers attached to the old value of _contents to the new value, so as not to break editing if it's being done at this moment.
    [self willChangeScriptingContents];
    NSMutableAttributedString *contents = [self contents];
    NSRange allContentsRange = NSMakeRange(0, [contents length]);
    if ([newContents isKindOfClass:[NSAttributedString class]]) {
	[contents replaceCharactersInRange:allContentsRange withAttributedString:newContents];
    } else {
	[contents replaceCharactersInRange:allContentsRange withString:newContents];
    }
    [self didChangeScriptingContents];

}


- (NSAttributedString *)undoContents {

    // Never return an object whose value will change after it's been returned. This is generally good behavior for any getter method that returns the value of an attribute or a to-many relationship. (For to-one relationships just returning the related object is the right thing to do, as in this class' -contents method.) However, this particular implementation of this good behavior might not be fast enough for all situations. If the copying here causes a performance problem, an alternative might be to return [[contents retain] autorelease], set a bit that indicates that the contents should be lazily replaced with a copy before any mutation, and then heed that bit in other methods of this class.
    return [[[self contents] copy] autorelease];

}


- (void)setUndoContents:(NSAttributedString *)newContents {

    // When undoing a change that could have only been done by scripting, behave exactly if scripting is doing another change, for the benefit of redo.
    [self setScriptingContents:newContents];

}


#pragma mark *** Overrides of SKTGraphic Methods ***


- (id)initWithProperties:(NSDictionary *)properties {

    // Let SKTGraphic do its job and then handle the one additional property defined by this subclass.
    self = [super initWithProperties:properties];
    if (self) {

	// The dictionary entries are all instances of the classes that can be written in property lists. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources. We don't have to worry about KVO-compliance in initializers like this by the way; no one should be observing an unitialized object.
	NSData *contentsData = [properties objectForKey:SKTTextContentsKey];
	if ([contentsData isKindOfClass:[NSData class]]) {
	    NSTextStorage *contents = [NSUnarchiver unarchiveObjectWithData:contentsData];
	    if ([contents isKindOfClass:[NSTextStorage class]]) {
		_contents = [contents retain];

		// We need to be notified whenever the text storage changes.
		[_contents setDelegate:self];

	    }
	}

    }
    return self;

}


- (NSMutableDictionary *)properties {

    // Let SKTGraphic do its job and then handle the one additional property defined by this subclass. The dictionary must contain nothing but values that can be written in old-style property lists.
    NSMutableDictionary *properties = [super properties];
    [properties setObject:[NSArchiver archivedDataWithRootObject:[self contents]] forKey:SKTTextContentsKey];
    return properties;

}


- (BOOL)isDrawingStroke {

    // We never draw a stroke on this kind of graphic.
    return NO;

}


- (NSRect)drawingBounds {

    // The drawing bounds must take into account the focus ring that might be drawn by this class' override of -drawContentsInView:isBeingCreatedOrEdited:. It can't forget to take into account drawing done by -drawHandleInView:atPoint: though. Because this class doesn't override -drawHandleInView:atPoint:, it should invoke super to let SKTGraphic take care of that, and then alter the results.
    return NSUnionRect([super drawingBounds], NSInsetRect([self bounds], -1.0f, -1.0f));

}


- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing {

    // Draw the fill color if appropriate.
    NSRect bounds = [self bounds];
    if ([self isDrawingFill]) {
        [[self fillColor] set];
        NSRectFill(bounds);
    }

    // If this graphic is being created it has no text. If it is being edited then the editor returned by -newEditingViewWithSuperviewBounds: will draw the text.
    if (isBeingCreatedOrEditing) {

	// Just draw a focus ring.
	[[NSColor knobColor] set];
	NSFrameRect(NSInsetRect(bounds, -1.0, -1.0));

    } else {

	// Don't bother doing anything if there isn't actually any text.
	NSTextStorage *contents = [self contents]; 
	if ([contents length]>0) {

	    // Get a layout manager, size its text container, and use it to draw text. -glyphRangeForTextContainer: forces layout and tells us how much of text fits in the container.
	    NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
	    NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
	    [textContainer setContainerSize:bounds.size];
	    [contents addLayoutManager:layoutManager];
	    NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
	    if (glyphRange.length>0) {
		[layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:bounds.origin];
		[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:bounds.origin];
	    }
	    [contents removeLayoutManager:layoutManager];

        }

    }

}


- (BOOL)canSetDrawingStroke {

    // Don't let the user think we would even try to draw a stroke on this kind of graphic.
    return NO;

}


- (void)makeNaturalSize {

    // The real work is done in code shared with -setHeightToMatchContents:.
    NSRect bounds = [self bounds];
    NSSize naturalSize = [self naturalSize];
    [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, naturalSize.width, naturalSize.height)];

}


- (void)setBounds:(NSRect)bounds {

    // In Sketch the user can change the bounds of a text area while it's being edited using the graphics inspector, scripting, or undo. When that happens we have to update the editing views (there might be more than one, in different windows) to keep things consistent. We don't need to do this when the bounds is being changed to keep up with changes to the contents, because the text views we set up take care of that themselves.
    [super setBounds:bounds];
    if (!_boundsBeingChangedToMatchContents) {
	NSArray *layoutManagers = [[self contents] layoutManagers];
	NSUInteger layoutManagerCount = [layoutManagers count];
	for (NSUInteger index = 0; index<layoutManagerCount; index++) {
	    NSLayoutManager *layoutManager = [layoutManagers objectAtIndex:index];

	    // We didn't set up any multiple-text-view layout managers in -newEditingViewWithSuperviewBounds:, so we're not expecting to have to deal with any here.
	    [[layoutManager firstTextView] setFrame:bounds];

	}
    }

}



- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds {

    // Create a text view that has the same frame as this graphic. We use -[NSTextView initWithFrame:textContainer:] instead of -[NSTextView initWithFrame:] because the latter method creates the entire collection of objects associated with an NSTextView - its NSTextContainer, NSLayoutManager, and NSTextStorage - and we already have an NSTextStorage. The text container should be the width of this graphic but very high to accomodate whatever text is typed into it.
    NSRect bounds = [self bounds];
    NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(bounds.size.width, 1.0e7f)];
    NSTextView *textView = [[NSTextView alloc] initWithFrame:bounds textContainer:textContainer];

    // Create a layout manager that will manage the communication between our text storage and the text container, and hook it up.
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    [layoutManager addTextContainer:textContainer];
    [textContainer release];
    NSTextStorage *contents = [self contents]; 
    [contents addLayoutManager:layoutManager];
    [layoutManager release];

    // Of course text editing should be as undoable as anything else.
    [textView setAllowsUndo:YES];

    // This kind of graphic shouldn't appear opaque just because it's being edited.
    [textView setDrawsBackground:NO];

/*
    // This is has been handy for debugging text editing view size problems though.
    [textView setBackgroundColor:[NSColor greenColor]];
    [textView setDrawsBackground:YES];
*/

    // Start off with the all of the text selected.
    [textView setSelectedRange:NSMakeRange(0, [contents length])];

    // Specify that the text view should grow and shrink to fit the text as text is added and removed, but only in the vertical direction. With these settings the NSTextView will always be large enough to show an extra line fragment but never so large that the user won't be able to see just-typed text on the screen. Sending -setVerticallyResizable:YES to the text view without also sending -setMinSize: or -setMaxSize: would be useless by the way; the default minimum and maximum sizes of a text view are the size of the frame that is specified at initialization time.
    [textView setMinSize:NSMakeSize(bounds.size.width, 0.0)];
    [textView setMaxSize:NSMakeSize(bounds.size.width, superviewBounds.size.height - bounds.origin.y)];
    [textView setVerticallyResizable:YES];

    // The invoker doesn't have to release this object.
    return [textView autorelease];

}


- (void)finalizeEditingView:(NSView *)editingView {

    // Tell our text storage that it doesn't have to talk to the editing view's layout manager anymore.
    [[self contents] removeLayoutManager:[(NSTextView *)editingView layoutManager]];

}


- (NSSet *)keysForValuesToObserveForUndo {

    // Observation of "undoContents," and the observer's resulting registration of changes with the undo manager, is only valid when changes are made to text contents via scripting. When changes are made directly by the user in a text view the text view will register better, more specific, undo actions. Also, we don't want some changes of bounds to result in undo actions.
    NSSet *keysToReturn = [super keysForValuesToObserveForUndo];
    if (_contentsBeingChangedByScripting || _boundsBeingChangedToMatchContents) {
	NSMutableSet *keys = [keysToReturn mutableCopy];
	if (_contentsBeingChangedByScripting) {
	    [keys addObject:SKTTextUndoContentsKey];
	}
	if (_boundsBeingChangedToMatchContents) {
	    [keys removeObject:SKTGraphicBoundsKey];
	}
	keysToReturn = [keys autorelease];
    }
    return keysToReturn;

}


+ (NSString *)presentablePropertyNameForKey:(NSString *)key {

    // Pretty simple. As is usually the case when a key is passed into a method like this, we have to invoke super if we don't recognize the key.
    static NSDictionary *presentablePropertyNamesByKey = nil;
    if (!presentablePropertyNamesByKey) {
	presentablePropertyNamesByKey = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
	    NSLocalizedStringFromTable(@"Text", @"UndoStrings", @"Action name part for SKTTextUndoContentsKey."), SKTTextUndoContentsKey,
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
