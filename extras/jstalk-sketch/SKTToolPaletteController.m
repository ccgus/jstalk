// SKTToolPaletteController.m
// Sketch Example
//

#import "SKTToolPaletteController.h"
#import "SKTCircle.h"
#import "SKTLine.h"
#import "SKTRectangle.h"
#import "SKTText.h"

enum {
    SKTArrowToolRow = 0,
    SKTRectToolRow,
    SKTCircleToolRow,
    SKTLineToolRow,
    SKTTextToolRow,
};

NSString *SKTSelectedToolDidChangeNotification = @"SKTSelectedToolDidChange";

@implementation SKTToolPaletteController

+ (id)sharedToolPaletteController {
    static SKTToolPaletteController *sharedToolPaletteController = nil;

    if (!sharedToolPaletteController) {
        sharedToolPaletteController = [[SKTToolPaletteController allocWithZone:NULL] init];
    }

    return sharedToolPaletteController;
}

- (id)init {
    self = [self initWithWindowNibName:@"ToolPalette"];
    if (self) {
        [self setWindowFrameAutosaveName:@"ToolPalette"];
    }
    return self;
}

- (void)windowDidLoad {
    NSArray *cells = [toolButtons cells];
    NSUInteger i, c = [cells count];
    
    [super windowDidLoad];

    for (i=0; i<c; i++) {
        [[cells objectAtIndex:i] setRefusesFirstResponder:YES];
    }
    [(NSPanel *)[self window] setFloatingPanel:YES];
    [(NSPanel *)[self window] setBecomesKeyOnlyIfNeeded:YES];

    [toolButtons setIntercellSpacing:NSMakeSize(0.0, 0.0)];
    [toolButtons sizeToFit];
    [[self window] setContentSize:[toolButtons frame].size];
    [toolButtons setFrameOrigin:NSMakePoint(0.0, 0.0)];
}

- (IBAction)selectToolAction:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:SKTSelectedToolDidChangeNotification object:self];
}

- (Class)currentGraphicClass {
    NSInteger row = [toolButtons selectedRow];
    Class theClass = nil;
    if (row == SKTRectToolRow) {
        theClass = [SKTRectangle class];
    } else if (row == SKTCircleToolRow) {
        theClass = [SKTCircle class];
    } else if (row == SKTLineToolRow) {
        theClass = [SKTLine class];
    } else if (row == SKTTextToolRow) {
        theClass = [SKTText class];
    }
    return theClass;
}

- (void)selectArrowTool {
    [toolButtons selectCellAtRow:SKTArrowToolRow column:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:SKTSelectedToolDidChangeNotification object:self];
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
