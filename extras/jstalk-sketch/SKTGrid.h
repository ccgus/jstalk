/*
	SKTGrid.h
	Part of the Sketch Sample Code
*/

#import <Cocoa/Cocoa.h>

// The "any" key described down below.
extern NSString *SKTGridAnyKey;

@interface SKTGrid : NSObject {
    @private

    // The values underlying the key-value coding (KVC) and observing (KVO) compliance described below. There isn't a full complement of corresponding getter or setter methods. KVC's direct instance variable access, KVO's autonotifying, and KVO's property dependency mechanism make them unnecessary. If in the future we decide that we need to do more complicated things when these values are gotten or set we can add getter and setter methods then, and no bound object will know the difference (so don't let me hear any more guff about direct ivar access "breaking encapsulation").
    NSColor *_color;
    CGFloat _spacing;
    BOOL _isAlwaysShown;
    BOOL _isConstraining;

    // Sometimes we temporarily show the grid to provide feedback for user changes to the grid spacing. When we do that we use a timer to turn it off again.
    NSTimer *_hidingTimer;
    
}

/* This class is KVC and KVO compliant for these keys:

"color" (an NSColor; read-write) - The color that will be used when the grid is shown.
    
"spacing" (a floating point NSNumber; read-write) - The distance (in user space units) between the grid lines used when showing the grid or constraining points to it.

"alwaysShown" (a boolean NSNumber; read-write) - Whether or not the user wants the grid to always be visible. -drawRect:inView: may draw a visible grid even when the value of this property is NO, if it's animating itself to provide good user feedback about a change to one of its properties.

"constraining" (a boolean NSNumber; read-write) - Whether or not the user wants graphics to be constrained to this grid. Graphic views should not need to access this property. They should invoke -constrainedPoint: instead.

"usable" (a boolean NSNumber; read-only) - Whether or not grid parameters are currently set to values that are valid enough that grid showing and constraining of graphics to the grid can be done. This wouldn't be necessary if we didn't allow zero to be a valid value for grid spacing, but we do, even though we don't want to draw zero-space grids, because there's no other reasonable number to use as the miminum value for the grid spacing slider in the grid panel. Why not use "one-point-oh" you ask? What's so special about that value I ask back. Grid spacing isn't in terms of pixel widths. It's in terms of user space units. Why not implement a validation method for the "gridSpacing" property to catch the user trying to set it to zero? Because the best thing that could come of that would be an alert that's presented to the user whenever they drag the spacing slider all the way to the left, or maybe just a beep, and either would be obnoxious. [User interface advice given in the comments of Sketch sample code is strictly the opinion of the engineer who's rewriting Sketch, and hasn't been reviewed by Apple's actual user interface designers, but, really.] By the way, an alternative to binding to this property would be binding directly to the "spacing" property using a very simple SKTIsGreaterThanZero value transformer of our own making. That would be putting a little to much logic into the nibs though, and a couple of nibs would require updating if we someday had to change the rules about when the grid is useful. This way we would just have to update this class' -isUsable method.

"canSetColor" (a boolean NSNumber; read-only) - Whether or not grid parameters are currently set to values that are valid enough that setting the grid color would do something useful, from the user's point of view.

"canSetSpacing" (a boolean NSNumber; read-only) - Whether or not grid parameters are currently set to values that are valid enough that setting grid spacing would do something useful, from the user's point of view. This wouldn't be necessary if we just forbade the user from changing the grid spacing when the grid wasn't shown, because then we could just bind the "editable" property of controls that set the grid spacing to to "alwaysShown" instead, but that would be a little weak. The grid spacing is useful for constraining graphics to the grid even when the grid isn't shown. Now, whenever we let the user change the grid spacing we have to provide good immediate feedback to the user about it, and Sketch does. See -setSpacing for our solution to that problem.

"any" (no value; not readable or writable) - A virtual property for which KVO change notifications are sent whenever any of the properties that affect the drawing of the grid have changed. We use KVO for this instead of more traditional methods so that we don't have to write any code other than an invocation of KVO's +setKeys:triggerChangeNotificationsForDependentKey:. (To use NSNotificationCenter for instance we would have to write -set...: methods for all of this object's settable properties. That's pretty easy, but it's nice to avoid such boilerplate when possible.) There is no value for this property, because it would not be useful, and this class isn't KVC-compliant for "any." This property is not called "needsDrawing" or some such thing because instances of this class do not know how many views are using it, and potentially there will be moments when it "needs drawing" in some views but not others.

In Sketch various properties of the controls of the grid inspector are bound to the properties (all except for the "any" property) of the grid belonging to the window controller of the main window. Each SKTGraphicView observes the "any" property of the grid to which its bound so it knows when the grid needs drawing.

*/

// Simple accessors.
- (BOOL)isAlwaysShown;
- (BOOL)isConstraining;
- (BOOL)isUsable;
- (void)setAlwaysShown:(BOOL)isAlwaysShown;
- (void)setConstraining:(BOOL)isConstraining;

// Given a point, return a point that is constrained to the grid, if constraining is being done. Otherwise just return the passed-in point.
- (NSPoint)constrainedPoint:(NSPoint)point;

// Return YES if this grid can be used to align right now, NO otherwise. The difference between "align" and "constrain" in this class' naming scheme is that constraining is controlled by the user's setting of the value of "constraining," while aligning is not.
- (BOOL)canAlign;

// Given a rectangle, return a rectangle the four corners of which are aligned to the grid, regardless of whether this grid is constraining right now. It's a programming error invoke this when -canAlign would return NO though.
- (NSRect)alignedRect:(NSRect)rect;

// Given the bounds of a rectangular area in the coordinate space establish by a view's bounds, draw in that view the part of the grid showing in that rectangular area.
- (void)drawRect:(NSRect)rect inView:(NSView *)view;

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
