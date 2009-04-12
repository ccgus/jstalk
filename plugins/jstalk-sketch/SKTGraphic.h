/*
	SKTGraphic.h
	Part of the Sketch Sample Code
*/

#import <Cocoa/Cocoa.h>

// The keys described down below.
extern NSString *SKTGraphicCanSetDrawingFillKey;
extern NSString *SKTGraphicCanSetDrawingStrokeKey;
extern NSString *SKTGraphicIsDrawingFillKey;
extern NSString *SKTGraphicFillColorKey;
extern NSString *SKTGraphicIsDrawingStrokeKey;
extern NSString *SKTGraphicStrokeColorKey;
extern NSString *SKTGraphicStrokeWidthKey;
extern NSString *SKTGraphicXPositionKey;
extern NSString *SKTGraphicYPositionKey;
extern NSString *SKTGraphicWidthKey;
extern NSString *SKTGraphicHeightKey;
extern NSString *SKTGraphicBoundsKey;
extern NSString *SKTGraphicDrawingBoundsKey;
extern NSString *SKTGraphicDrawingContentsKey;
extern NSString *SKTGraphicKeysForValuesToObserveForUndoKey;

// The value that is returned by -handleUnderPoint: to indicate that no selection handle is under the point.
extern const NSInteger SKTGraphicNoHandle;

@interface SKTGraphic : NSObject<NSCopying> {
    @private

    // The values underlying some of the key-value coding (KVC) and observing (KVO) compliance described below. Any corresponding getter or setter methods are there for invocation by code in subclasses, not for KVC or KVO compliance. KVC's direct instance variable access, KVO's autonotifying, and KVO's property dependency mechanism makes them unnecessary for the latter purpose.
    // If you look closely, you'll notice that SKTGraphic itself never touches these instance variables directly except in initializers, -copyWithZone:, and public accessors. SKTGraphic is following a good rule: if a class publishes getters and setters it should itself invoke them, because people who override methods to customize behavior are right to expect their overrides to actually be invoked.
    NSRect _bounds;
    BOOL _isDrawingFill;
    NSColor *_fillColor;
    BOOL _isDrawingStroke;
    NSColor *_strokeColor;
    CGFloat _strokeWidth;

    // The object that contains the graphic (unretained), from the point of view of scriptability. This is here only for use by this class' override of scripting's -objectSpecifier method. In Sketch this is an SKTDocument.
    NSObject *_scriptingContainer;

}

/* This class is KVC (except for "drawingContents") and KVO (except for the scripting-only properties) compliant for these keys:

"canSetDrawingFill" and "canSetDrawingStroke" (boolean NSNumbers; read-only) - Whether or not it even makes sense to try to change the value of the "drawingFill" or "drawingStroke" property.

"drawingFill" (a boolean NSNumber; read-write) - Whether or not the user wants this graphic to be filled with the "fillColor" when it's drawn.

"fillColor" (an NSColor; read-write) - The color that will be used to fill this graphic when it's drawn. The value of this property is ignored when the value of "drawingFill" is NO.

"drawingStroke" (a boolean NSNumber; read-write) - Whether or not the user wants this graphic to be stroked with a path that is "strokeWidth" units wide, using the "strokeColor," when it's drawn.

"strokeColor" (an NSColor; read-write) - The color that will be used to stroke this graphic when it's drawn. The value of this property is ignored when the value of "drawingStroke" is NO.

"strokeWidth" (a floating point NSNumber; read-write) - The width of the stroke that will be used when this graphic is drawn. The value of this property is ignored when the value of "drawingStroke" is NO.

"xPosition" and "yPosition" (floating point NSNumbers; read-write) - The coordinate of the upper-left corner of the graphic.

"width" and "height" (floating point NSNumbers; read-write) - The size of the graphic.

"bounds" (an NSRect-containing NSValue; read-only) - The basic shape of the graphic. For instance, this doesn't include the width of any strokes that are drawn (so "bounds" is really a bit of a misnomer). Being KVO-compliant for bounds contributes to the automatic KVO compliance for drawingBounds via the use of KVO's dependency mechanism. See +[SKTGraphic keysForValuesAffectingDrawingBounds].

"drawingBounds" (an NSRect-containing NSValue; read-only) - The bounding box of anything the graphic might draw when sent a -drawContentsInView: or -drawHandlesInView: message.

"drawingContents" (no value; not readable or writable) - A virtual property for which KVO change notifications are sent whenever any of the properties that affect the drawing of the graphic without affecting its bounds change. We use KVO for this instead of more traditional methods so that we don't have to write any code other than an invocation of KVO's +setKeys:triggerChangeNotificationsForDependentKey:. (To use NSNotificationCenter for instance we would have to write -set...: methods for all of this object's settable properties. That's pretty easy, but it's nice to avoid such boilerplate when possible.) There is no value for this property, because it would not be useful, so this class isn't actually KVC-compliant for "drawingContents." This property is not called "needsDrawing" or some such thing because instances of this class do not know how many views are using it, and potentially there will moments when it "needs drawing" in some views but not others.

"keysForValuesToObserveForUndo" (an NSSet of NSStrings; read-only) - See the comment for -keysForValuesToObserveForUndo below.

"scriptingFillColor" and "scriptingStrokeColor" (NSColors; read-write) - The colors that will be used to fill or stroke this graphic when it's drawn, or nil if filling or stroking is not being done. These attributes are computed from "drawingFill"/"fillColor" and "drawingStroke"/"strokeColor." They're here because, even though the separate boolean properties are OK for presenting in checkboxes in the UI, we don't want to make scripters deal with them. For scripters a color of nil ("missing value") is what's used to turn off filling or stroking.

"scriptingStrokeWidth" (a floating point NSNumber; read-write) - The width of the stroke that will be used for this graphic when it's drawn, or nil if stroking is not being done. This attribute is derived from "strokeWidth." It's here because we want to accurately report "missing value" when stroking is not being done. Since it's here we might as well let scripters turn off stroking by setting "missing value" too.

In Sketch various properties of the controls of the grid inspector are bound to the properties of the selection of the graphics controller belonging to the window controller of the main window. Each SKTGraphicView observes the "drawingBounds" and "drawingContents" properties of every graphic that it's displaying so it knows when they need redrawing. Each SKTDocument observes many properties of every of one of its graphics so it can register undo actions when they change; for each graphic the exact set of such properties is determined by the current value of the "keysForValuesToObserveForUndo" property. Also, many of these properties are scriptable.

*/

#pragma mark *** Convenience ***

/* You can override these class methods in your subclass of SKTGraphic, but it would be a waste of time, because no one invokes these on any class other than SKTGraphic itself. Really these could just be functions if we didn't have such a syntactic sweet tooth. */

// Move each graphic in the array by the same amount.
+ (void)translateGraphics:(NSArray *)graphics byX:(CGFloat)deltaX y:(CGFloat)deltaY;

// Return the total "bounds" of all of the graphics in the array.
+ (NSRect)boundsOfGraphics:(NSArray *)graphics;

// Return the total drawing bounds of all of the graphics in the array.
+ (NSRect)drawingBoundsOfGraphics:(NSArray *)graphics;

#pragma mark *** Persistence ***

/* You can override these class methods in your subclass of SKTGraphic, but it would be a waste of time, because no one invokes these on any class other than SKTGraphic itself. Really these could just be functions if we didn't have such a syntactic sweet tooth. */

// Return an array of graphics created from flattened data of the sort returned by +pasteboardDataWithGraphics: or, if that's not possible, return nil and set *outError to an NSError that can be presented to the user to explain what went wrong.
+ (NSArray *)graphicsWithPasteboardData:(NSData *)data error:(NSError **)outError;

// Given an array of property list dictionaries whose validity has not been determined, return an array of graphics.
+ (NSArray *)graphicsWithProperties:(NSArray *)propertiesArray;

// Return the array of graphics as flattened data that is appropriate for passing to +graphicsWithPasteboardData:error:.
+ (NSData *)pasteboardDataWithGraphics:(NSArray *)graphics;

// Given an array of graphics, return an array of property list dictionaries.
+ (NSArray *)propertiesWithGraphics:(NSArray *)graphics;

/* Subclasses of SKTGraphic might have reason to override any of the rest of this class' methods, starting here. */

// Given a dictionary having the sort of entries that would be in a dictionary returned by -properties, but whose validity has not been determined, initialize, setting the values of as many properties as possible from it. Ignore unrecognized dictionary entries. Use default values for missing dictionary entries. This is not the designated initializer for this class (-init is).
- (id)initWithProperties:(NSDictionary *)properties;

// Return a dictionary that can be used as property list object and contains enough information to recreate the graphic (except for its class, which is handled by +propertiesWithGraphics:). The returned dictionary must be mutable so that it can be added to efficiently, but the receiver must ignore any mutations made to it after it's been returned.
- (NSMutableDictionary *)properties;

#pragma mark *** Simple Property Getting ***

// Accessors for properties that this class stores as instance variables. These methods provide readable KVC-compliance for several of the keys mentioned in comments above, but that's not why they're here (KVC direct instance variable access makes them unnecessary for that). They're here just for invoking and overriding by subclass code.
- (NSRect)bounds;
- (BOOL)isDrawingFill;
- (NSColor *)fillColor;
- (BOOL)isDrawingStroke;
- (NSColor *)strokeColor;
- (CGFloat)strokeWidth;

#pragma mark *** Drawing ***

// Return the keys of all of the properties whose values affect the appearance of an instance of the receiving subclass of SKTGraphic (even properties declared in a superclass). The first method should return the keys for such properties that affect the drawing bounds of graphics. The second method should return the keys for such properties that do not. Most subclasses of SKTGraphic should override one or both of these, and be KVO-compliant for the properties identified by keys in the returned set. Implementations of these methods don't have to be fast, at least not in the context of Sketch, because their results are cached.
+ (NSSet *)keysForValuesAffectingDrawingBounds;
+ (NSSet *)keysForValuesAffectingDrawingContents;

// Return the bounding box of everything the receiver might draw when sent a -draw...InView: message. The default implementation of this method returns a bounds that assumes the default implementations of -drawContentsInView: and -drawHandlesInView:. Subclasses that override this probably have to override +keysForValuesAffectingDrawingBounds too.
- (NSRect)drawingBounds;

// Draw the contents the receiver in a specific view. Use isBeingCreatedOrEditing if the graphic draws differently during its creation or while it's being edited. The default implementation of this method just draws the result of invoking -bezierPathForDrawing using the current fill and stroke parameters. Subclasses have to override either this method or -bezierPathForDrawing. Subclasses that override this may have to override +keysForValuesAffectingDrawingBounds, +keysForValuesAffectingDrawingContents, and -drawingBounds too.
- (void)drawContentsInView:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing;

// Return a bezier path that can be stroked and filled to draw the graphic, if the graphic can be drawn so simply, nil otherwise. The default implementation of this method returns nil. Subclasses have to override either this method or -drawContentsInView:. Any returned bezier path should already have the graphic's current stroke width set in it.
- (NSBezierPath *)bezierPathForDrawing;

// Draw the handles of the receiver in a specific view. The default implementation of this method just invokes -drawHandleInView:atPoint: for each point at the corners and on the sides of the rectangle returned by -bounds. Subclasses that override this probably have to override -handleUnderPoint: too.
- (void)drawHandlesInView:(NSView *)view;

// Draw handle at a specific point in a specific view. Subclasses that override -drawHandlesInView: can invoke this to easily draw handles whereever they like.
- (void)drawHandleInView:(NSView *)view atPoint:(NSPoint)point;

#pragma mark *** Editing ***

// Return a cursor that can be used when the user has clicked using the creation tool and is dragging the mouse to size a new instance of the receiving class.
+ (NSCursor *)creationCursor;

// Return the number of the handle that the user is dragging when they move the mouse after clicking to create a new instance of the receiving class. The default implementation of this method returns a number that corresponds to one of the corners of the graphic's bounds. Subclasses that override this should probably override -resizeByMovingHandle:toPoint: too.
+ (NSInteger)creationSizingHandle;

// Return YES if it's useful to let the user toggle drawing of the fill or stroke, NO otherwise. The default implementations of these methods return YES.
- (BOOL)canSetDrawingFill;
- (BOOL)canSetDrawingStroke;

// Return YES if sending -makeNaturalSize to the receiver would do something noticable by the user, NO otherwise. The default implementation of this method returns YES if the defaultimplementation of -makeNaturalSize would actually do something, NO otherwise.
- (BOOL)canMakeNaturalSize;

// Return YES if the point is in the contents of the receiver, NO otherwise. The default implementation of this method returns YES if the point is inside [self bounds].
- (BOOL)isContentsUnderPoint:(NSPoint)point;
    
// If the point is in one of the handles of the receiver return its number, SKTGraphicNoHandle otherwise. The default implementation of this method invokes -isHandleAtPoint:underPoint: for the corners and on the sides of the rectangle returned by -bounds. Subclasses that override this probably have to override several other methods too.
- (NSInteger)handleUnderPoint:(NSPoint)point;

// Return YES if the handle at a point is under another point. Subclasses that override -handleUnderPoint: can invoke this to hit-test the sort of handles that would be drawn by -drawHandleInView:atPoint:.
- (BOOL)isHandleAtPoint:(NSPoint)handlePoint underPoint:(NSPoint)point;

// Given that one of the receiver's handles has been dragged by the user, resize to match, and return the handle number that should be passed into subsequent invocations of this same method. The default implementation of this method assumes that the passed-in handle number was returned by a previous invocation of +creationSizingHandle or -handleUnderPoint:, so subclasses that override this should probably override +creationSizingHandle and -handleUnderPoint: too. It also invokes -flipHorizontally and -flipVertically when the user flips the graphic.
- (NSInteger)resizeByMovingHandle:(NSInteger)handle toPoint:(NSPoint)point;

// Given that -resizeByMovingHandle:toPoint: is being invoked and sensed that the user has flipped the graphic one way or the other, change the graphic to accomodate, whatever that means. Subclasses that represent asymmetrical graphics can override these to accomodate the user's dragging of handles without having to override and mostly reimplement -resizeByMovingHandle:toPoint:.
- (void)flipHorizontally;
- (void)flipVertically;

// Given that [[self class] canMakeNaturalSize] would return YES, set the the bounds of the receiver to whatever is "natural" for its particular subclass of SKTGraphic. The default implementation of this method just squares the bounds.
- (void)makeNaturalSize;

// Set the bounds of the graphic, doing whatever scaling and translation is necessary.
- (void)setBounds:(NSRect)bounds;

// Set the color of the graphic, whatever that means. The default implementation of this method just sets isDrawingFill to YES and fillColor to the passed-in color. In Sketch this method is invoked when the user drops a color chip on the graphic or uses the color panel to change the color of all of the selected graphics.
- (void)setColor:(NSColor *)color;

// Given that the receiver has just been created or double-clicked on or something, create and return a view that can present its editing interface to the user, or return nil. The returned view should be suitable for becoming a subview of a view whose bounds is passed in. Its frame should match the bounds of the receiver. The receiver should not assume anything about the lifetime of the returned editing view; it may remain in use even after subsequent invocations of this method, which should, again, create a new editing view each time. In other words, overrides of this method should be prepared for a graphic to have more than editing view outstanding. The default implementation of this method returns nil. In Sketch SKTText overrides it.
- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds;

// Given an editing view that was returned by a previous invocation of -newEditingViewWithSuperviewBounds:, tear down whatever connections exist between it and the receiver.
- (void)finalizeEditingView:(NSView *)editingView;

#pragma mark *** Undo ***

// Return the keys of all of the properties for which value changes are undoable. In Sketch SKTDocument observes the value for each key in the set returned by invoking this method on each graphic in the document, and registers undo operations when the values change. It also observes this "keysForValuesToObserveForUndo" property itself and reacts accordingly, because the value can change dynamically. For example, SKTText overrides this (and KVO-notifies about changes to what the override would return) for a couple of reasons.
- (NSSet *)keysForValuesToObserveForUndo;

// Given a key from the set returned by a previous invocation of -keysForValuesToObserveForUndo, return the human-readable, title-capitalized, localized, name of the property identified by the key, or nil for invalid keys (invokers should throw exceptions if nil is returned, because nil indicates a programming mistake). In Sketch SKTDocument uses this to create an undo action name when the user has changed the value of the property.
+ (NSString *)presentablePropertyNameForKey:(NSString *)key;

#pragma mark *** Scripting ***

// Given that the receiver is now contained by some other object, or is no longer contained by another, take a pointer to its container, but do not retain it.
- (void)setScriptingContainer:(NSObject *)scriptingContainer;

@end

@interface NSObject(SKTGraphicScriptingContainer)

// An informal protocol to which scriptable containers of SKTGraphics must conform. We declare this instead of just making it an SKTDocument method because that would needlessly reduce SKTGraphic's reusability (they would only be containable by SKTDocuments).
- (NSScriptObjectSpecifier *)objectSpecifierForGraphic:(SKTGraphic *)graphic;

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
