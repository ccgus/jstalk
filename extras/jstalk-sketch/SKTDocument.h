/*
	SKTDocument.h
	Part of the Sketch Sample Code
*/

#import <Cocoa/Cocoa.h>

// The keys described down below.
extern NSString *SKTDocumentCanvasSizeKey;
extern NSString *SKTDocumentGraphicsKey;

@interface SKTDocument : NSDocument {
    @private

    // The value underlying the key-value coding (KVC) and observing (KVO) compliance described below. 
    NSMutableArray *_graphics;

    // State that's used by the undo machinery. It all gets cleared out each time the undo manager sends a checkpoint notification. _undoGroupInsertedGraphics is the set of graphics that have been inserted, if any have been inserted. _undoGroupOldPropertiesPerGraphic is a dictionary whose keys are graphics and whose values are other dictionaries, each of which contains old values of graphic properties, if graphic properties have changed. _undoGroupPresentablePropertyName is the result of invoking +[SKTGraphic presentablePropertyNameForKey:] for changed graphics, if the result of each invocation has been the same so far, nil otherwise. _undoGroupHasChangesToMultipleProperties is YES if changes have been made to more than one property, as determined by comparing the results of invoking +[SKTGraphic presentablePropertyNameForKey:] for changed graphics, NO otherwise.
    NSMutableSet *_undoGroupInsertedGraphics;
    NSMutableDictionary *_undoGroupOldPropertiesPerGraphic;
    NSString *_undoGroupPresentablePropertyName;
    BOOL _undoGroupHasChangesToMultipleProperties;

}

/* This class is KVC and KVO compliant for these keys:

"canvasSize" (an NSSize-containing NSValue; read-only) - The size of the document's canvas. This is derived from the currently selected paper size and document margins.

"graphics" (an NSArray of SKTGraphics; read-write) - the graphics of the document.

In Sketch the graphics property of each SKTGraphicView is bound to the graphics property of the document whose contents its presented. Also, the graphics relationship of an SKTDocument is scriptable.

*/

// Return the current value of the property.
- (NSSize)canvasSize;

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
