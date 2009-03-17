/*
	SKTAppDelegate.m
	Part of the Sketch Sample Code
*/


#import "SKTAppDelegate.h"
#import "SKTToolPaletteController.h"
#import <JSTalk/JSTalk.h>

// Keys that are used in Sketch's user defaults.
static NSString *SKTAppAutosavesPreferenceKey = @"autosaves";
static NSString *SKTAppAutosavingDelayPreferenceKey = @"autosavingDelay";


#pragma mark *** NSWindowController Conveniences ***


@interface NSWindowController(SKTConvenience)
- (BOOL)isWindowShown;
- (void)showOrHideWindow;
@end
@implementation NSWindowController(SKTConvenience)


- (BOOL)isWindowShown {

    // Simple.
    return [[self window] isVisible];

}


- (void)showOrHideWindow {

    // Simple.
    NSWindow *window = [self window];
    if ([window isVisible]) {
	[window orderOut:self];
    } else {
	[self showWindow:self];
    }

}


@end


@implementation SKTAppDelegate


#pragma mark *** Launching ***


// Conformance to the NSObject(NSApplicationNotifications) informal protocol.
- (void)applicationDidFinishLaunching:(NSNotification *)notification {

    // The tool palette should always show up right away.
    [self showOrHideToolPalette:self];
    
    [JSTalk listen];
    
}


#pragma mark *** Preferences ***


// Conformance to the NSObject(NSApplicationNotifications) informal protocol.
- (void)applicationWillFinishLaunching:(NSNotification *)notification {

    // Set up the default values of our autosaving preferences very early, before there's any chance of a binding using them. The default is for autosaving to be off, but 60 seconds if the user turns it on.
    NSUserDefaultsController *userDefaultsController = [NSUserDefaultsController sharedUserDefaultsController];
    [userDefaultsController setInitialValues:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:NO], SKTAppAutosavesPreferenceKey, [NSNumber numberWithDouble:60.0], SKTAppAutosavingDelayPreferenceKey, nil]];

    // Bind this object's "autosaves" and "autosavingDelay" properties to the user defaults of the same name. We don't bother with ivars for these values. This is just the quick way to get our -setAutosaves: and -setAutosavingDelay: methods invoked.
    [self bind:SKTAppAutosavesPreferenceKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:SKTAppAutosavesPreferenceKey] options:nil];
    [self bind:SKTAppAutosavingDelayPreferenceKey toObject:userDefaultsController withKeyPath:[@"values." stringByAppendingString:SKTAppAutosavingDelayPreferenceKey] options:nil];
    
}


- (void)setAutosaves:(BOOL)autosaves {
    
    // The user has toggled the "autosave documents" checkbox in the preferences panel.
    if (autosaves) {

	// Get the autosaving delay and set it in the NSDocumentController.
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:_autosavingDelay];

    } else {

	// Set a zero autosaving delay in the NSDocumentController. This tells it to turn off autosaving.
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:0.0];

    }
    _autosaves = autosaves;

}


- (void)setAutosavingDelay:(NSTimeInterval)autosaveDelay {

    // Is autosaving even turned on right now?
    if (_autosaves) {

	// Set the new autosaving delay in the document controller, but only if autosaving is being done right now.
	[[NSDocumentController sharedDocumentController] setAutosavingDelay:autosaveDelay];

    }
    _autosavingDelay = autosaveDelay;

}


- (IBAction)showPreferencesPanel:(id)sender {
    
    // We always show the same preferences panel. Its controller doesn't get deallocated when the user closes it.
    if (!_preferencesPanelController) {
        _preferencesPanelController = [[NSWindowController alloc] initWithWindowNibName:@"Preferences"];
	
    	// Make the panel appear in the same place when the user quits and relaunches the application.
        [_preferencesPanelController setWindowFrameAutosaveName:@"Preferences"];
	
    }
    [_preferencesPanelController showWindow:sender];
    
}


#pragma mark *** Other Actions ***


- (IBAction)showOrHideGraphicsInspector:(id)sender {

    // We always show the same inspector panel. Its controller doesn't get deallocated when the user closes it.
    if (!_graphicsInspectorController) {
	_graphicsInspectorController = [[NSWindowController alloc] initWithWindowNibName:@"Inspector"];

    	// Make the panel appear in the same place when the user quits and relaunches the application.
	[_graphicsInspectorController setWindowFrameAutosaveName:@"Inspector"];

    }
    [_graphicsInspectorController showOrHideWindow];

}


- (IBAction)showOrHideGridInspector:(id)sender {

    // We always show the same grid inspector panel. Its controller doesn't get deallocated when the user closes it.
    if (!_gridInspectorController) {
	_gridInspectorController = [[NSWindowController alloc] initWithWindowNibName:@"GridPanel"];

	// Make the panel appear in the same place when the user quits and relaunches the application.
	[_gridInspectorController setWindowFrameAutosaveName:@"Grid"];

    }
    [_gridInspectorController showOrHideWindow];

}


- (IBAction)showOrHideToolPalette:(id)sender {

    // We always show the same tool palette panel. Its controller doesn't get deallocated when the user closes it.
    [[SKTToolPaletteController sharedToolPaletteController] showOrHideWindow];

}


- (IBAction)chooseSelectionTool:(id)sender {

    // Simple.
    [[SKTToolPaletteController sharedToolPaletteController] selectArrowTool];

}


// Conformance to the NSObject(NSMenuValidation) informal protocol.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    // A few menu item's names change between starting with "Show" and "Hide."
    SEL action = [menuItem action];
    if (action==@selector(showOrHideGraphicsInspector:)) {
	[menuItem setTitle:([_graphicsInspectorController isWindowShown] ? NSLocalizedStringFromTable(@"Hide Inspector", @"SKTAppDelegate", @"A main menu item title.") : NSLocalizedStringFromTable(@"Show Inspector", @"SKTAppDelegate", @"A main menu item title."))];
    } else if (action==@selector(showOrHideGridInspector:)) {
	[menuItem setTitle:([_gridInspectorController isWindowShown] ? NSLocalizedStringFromTable(@"Hide Grid Options", @"SKTAppDelegate", @"A main menu item title.") : NSLocalizedStringFromTable(@"Show Grid Options", @"SKTAppDelegate", @"A main menu item title."))];
    } else if (action==@selector(showOrHideToolPalette:)) {
	[menuItem setTitle:([[SKTToolPaletteController sharedToolPaletteController] isWindowShown] ? NSLocalizedStringFromTable(@"Hide Tools", @"SKTAppDelegate", @"A main menu item title.") : NSLocalizedStringFromTable(@"Show Tools", @"SKTAppDelegate", @"A main menu item title."))];
    }
    return YES;

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
