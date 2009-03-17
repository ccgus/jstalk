/*
	SKTLine.h
	Part of the Sketch Sample Code
*/

#import "SKTGraphic.h"

// The keys described down below.
extern NSString *SKTLineBeginPointKey;
extern NSString *SKTLineEndPointKey;

@interface SKTLine : SKTGraphic {
    @private

    // YES if the line's ending is to the right or below, respectively, it's beginning, NO otherwise. Because we reuse SKTGraphic's "bounds" property, we have to keep track of the corners of the bounds at which the line begins and ends. A more natural thing to do would be to just record two points, but then we'd be wasting an NSRect's worth of ivar space per instance, and have to override more SKTGraphic methods to boot. This of course raises the question of why SKTGraphic has a bounds property when it's not readily applicable to every conceivable subclass. Perhaps in the future it won't, but right now in Sketch it's the handy thing to do for four out of five subclasses.
    BOOL _pointsRight;
    BOOL _pointsDown;

}

/* This class is KVC and KVO compliant for these keys:

"beginPoint" and "endPoint" (NSPoint-containing NSValues; read-only) - The two points that define the line segment.

In Sketch "beginPoint" and "endPoint" are two more of the properties that SKTDocument observes so it can register undo actions when they change.

Notice that we don't guarantee KVC or KVO compliance for "pointsRight" and "pointsDown." Those aren't just private instance variables, they're private properties, concepts that no code outside of SKTLine should care about.

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
