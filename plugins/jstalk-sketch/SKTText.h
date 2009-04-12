/*
	SKTText.h
	Part of the Sketch Sample Code
*/

#import "SKTGraphic.h"

// The keys described down below.
extern NSString *SKTTextScriptingContentsKey;
extern NSString *SKTTextUndoContentsKey;

@interface SKTText : SKTGraphic {
    @private

    // The value underlying the key-value coding (KVC) and observing (KVO) compliance described below.
    NSTextStorage *_contents;

    // Whether or not this graphic's contents might be being changed by scripting, so the changes will be made undable.
    BOOL _contentsBeingChangedByScripting;

    // Whether or not this graphic is automatically changing its own bounds to maintain consistency with its contents, so the changing will not be made undable (because that would be a spurious undo action, and actually defeat the undo action coalescing that NSTextView's undo support does).
    BOOL _boundsBeingChangedToMatchContents;

}

/* This class is KVC but not KVO compliant for this key:

"scriptingContents" (an NSTextStorage; read-write; coercible from NSString) -  The text being presented by this object. This is a to-one relationship, so it's meaningful to get an SKTText's "scriptingContents" and mutate it, which is exactly what Cocoa's built-in support for text scripting does.

This class is KVC and KVO (kind of) compliant for this key:

"undoContents" (an NSAttributedString; read-write) - Also the text being presented by this object. This is an attribute, and no one should be surprised if each invocation of -valueForKey:@"undoContents" returns a different object. One _should_ be surprised if the object returned by an invocation of -valueForKey:@"undoContents" changes after it's returned. (In an ideal world, this is true of pretty much all getting of attribute values and to-many relationships, regardless of whether the getting is done via KVC or via a directly-invoked accessor method). This class is only KVO-compliant for this key while -keysForValuesToObserveForUndo would return a set containing the key. That (and, in Sketch, SKTDocument's observing of "keysForValuesToObserveForUndo") are all the KVO-compliance that's necessary to make scripted changes of the contents undoable. More complete KVO-compliance is very difficult to implement because NSTextView's undo mechanism changes NSTextStorages directly, and listening in on that conversation is a lot of work.

In Sketch, "scriptingContents" is scriptable. "undoContents" is another of the properties that SKTDocument observes so it can register undo actions when the value changes. Why are there two properties to represent the same thing? Why can't there just be one "contents" property that SKTDocument observes? Because SKTDocument implements undo by observing properties of SKTGraphics and registering undo actions using their old values when they change. Scripting operations don't actually change the value of the contents property, they just mutate the object that is the value.

*/

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
