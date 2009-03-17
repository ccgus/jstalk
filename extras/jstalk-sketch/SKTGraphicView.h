/*
	SKTGraphicView.h
	Part of the Sketch Sample Code
*/

#import <Cocoa/Cocoa.h>

@class SKTGraphic, SKTGrid;

// The names of the bindings supported by this class, in addition to the ones whose support is inherited from NSView.
extern NSString *SKTGraphicViewGraphicsBindingName;
extern NSString *SKTGraphicViewSelectionIndexesBindingName;
extern NSString *SKTGraphicViewGridBindingName;

@interface SKTGraphicView : NSView {
    @private

    // Information that is recorded when the "graphics" and "selectionIndexes" bindings are established. Notice that we don't keep around copies of the actual graphics array and selection indexes. Those would just be unnecessary (as far as we know, so far, without having ever done any relevant performance measurement) caches of values that really live in the bound-to objects.
    NSObject *_graphicsContainer;
    NSString *_graphicsKeyPath;
    NSObject *_selectionIndexesContainer;
    NSString *_selectionIndexesKeyPath;

    // The grid that is drawn in the view and used to constrain graphics as they're created and moved. In Sketch this is just a cache of a value that canonically lives in the SKTWindowController to which this view's grid property is bound (see SKTWindowController's comments for an explanation of why the grid lives there).
    SKTGrid *_grid;

    // The bounds of moved objects that is echoed in the ruler, if objects are being moved right now.
    NSRect _rulerEchoedBounds;

    // The graphic that is being created right now, if a graphic is being created right now (not explicitly retained, because it's always allocated and forgotten about in the same method).
    SKTGraphic *_creatingGraphic;

    // The graphic that is being edited right now, the view that it gave us to present its editing interface, and the last known frame of that view, if a graphic is being edited right now. We have to record the editing view frame because when it changes we need its old value, and the old value isn't available when this view gets the NSViewFrameDidChangeNotification. Also, the reserved thickness for the horizontal ruler accessory view before editing began, so we can restore it after editing is done. (We could do the same for the vertical ruler, but so far in Sketch there are no vertical ruler accessory views.)
    SKTGraphic *_editingGraphic;
    NSView *_editingView;
    NSRect _editingViewFrame;
    CGFloat _oldReservedThicknessForRulerAccessoryView;

    // The bounds of the marquee selection, if marquee selection is being done right now, NSZeroRect otherwise.
    NSRect _marqueeSelectionBounds;

    // Whether or not selection handles are being hidden while the user moves graphics.
    BOOL _isHidingHandles;

    // Sometimes we temporarily hide the selection handles when the user moves graphics using the keyboard. When we do that this is the timer to start showing them again.
    NSTimer *_handleShowingTimer;

    // The state of the cascading of graphics that we do during repeated pastes.
    NSInteger _pasteboardChangeCount;
    NSInteger _pasteCascadeNumber;
    NSPoint _pasteCascadeDelta;

    // Applications are supposed to update the selection during undo and redo operations. These are the indexes of the graphics that are going to be selected at the end of an undo or redo operation.
    NSMutableIndexSet *_undoSelectionIndexes;

}

// Action methods that are unique to SKTGraphicView, or at least are not declared by NSResponder. SKTGraphicView implements other action methods, but they're all declared by NSResponder and there's not much reason to redeclare them here. We use -showOrHideRulers: instead of -toggleRuler: because we don't want to cause accidental invocation of -[NSTextView toggleRuler:], which doesn't quite work when the text view has been added to a view that already has rulers shown in it, a situation that can arise in Sketch.
- (IBAction)alignBottomEdges:(id)sender;
- (IBAction)alignHorizontalCenters:(id)sender;
- (IBAction)alignLeftEdges:(id)sender;
- (IBAction)alignRightEdges:(id)sender;
- (IBAction)alignTopEdges:(id)sender;
- (IBAction)alignVerticalCenters:(id)sender;
- (IBAction)alignWithGrid:(id)sender;
- (IBAction)bringToFront:(id)sender;
- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)deselectAll:(id)sender;
- (IBAction)makeNaturalSize:(id)sender;
- (IBAction)makeSameHeight:(id)sender;
- (IBAction)makeSameWidth:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)sendToBack:(id)sender;
- (IBAction)showOrHideRulers:(id)sender;

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
