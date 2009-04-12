/*
	SKTDocument.m
	Part of the Sketch Sample Code
*/


#import "SKTDocument.h"
#import "SKTError.h"
#import "SKTGraphic.h"
#import "SKTRenderingView.h"
#import "SKTCircle.h"
#import "SKTImage.h"
#import "SKTLine.h"
#import "SKTRectangle.h"
#import "SKTText.h"
#import "SKTWindowController.h"


// String constants declared in the header.
NSString *SKTDocumentCanvasSizeKey = @"canvasSize";
NSString *SKTDocumentGraphicsKey = @"graphics";

// Values that are used as contexts by this class' invocation of KVO observer registration methods. See the comment near the top of SKTGraphicView.m for a discussion of this.
static NSString *SKTDocumentUndoKeysObservationContext = @"com.apple.SKTDocument.undoKeys";
static NSString *SKTDocumentUndoObservationContext = @"com.apple.SKTDocument.undo";

// The document type names that must also be used in the application's Info.plist file. We'll take out all uses of SKTDocumentOldTypeName and SKTDocumentOldVersion1TypeName (and NSPDFPboardType and NSTIFFPboardType) someday when we drop 10.4 compatibility and we can just use UTIs everywhere.
static NSString *SKTDocumentOldTypeName = @"Apple Sketch document";
static NSString *SKTDocumentNewTypeName = @"com.apple.sketch2";
static NSString *SKTDocumentOldVersion1TypeName = @"Apple Sketch 1 document";
static NSString *SKTDocumentNewVersion1TypeName = @"com.apple.sketch1";

// More keys, and a version number, which are just used in Sketch's property-list-based file format.
static NSString *SKTDocumentVersionKey = @"version";
static NSString *SKTDocumentPrintInfoKey = @"printInfo";
static NSInteger SKTDocumentCurrentVersion = 2;


// Some methods are invoked by methods above them in this file.
@interface SKTDocument(SKTForwardDeclarations)
- (NSArray *)graphics;
- (void)startObservingGraphics:(NSArray *)graphics;
- (void)stopObservingGraphics:(NSArray *)graphics;
@end


@implementation SKTDocument


// An override of the superclass' designated initializer, which means it should always be invoked.
- (id)init {

    // Do the regular Cocoa thing.
    self = [super init];
    if (self) {

	// Before anything undoable happens, register for a notification we need.
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observeUndoManagerCheckpoint:) name:NSUndoManagerCheckpointNotification object:[self undoManager]];

    }
    return self;

}


- (void)dealloc {

    // Undo some of what we did in -insertGraphics:atIndexes:.
    [self stopObservingGraphics:[self graphics]];

    // Undo what we did in -init.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSUndoManagerCheckpointNotification object:[self undoManager]];

    // Do the regular Cocoa thing.
    [_undoGroupPresentablePropertyName release];
    [_undoGroupOldPropertiesPerGraphic release];
    [_undoGroupInsertedGraphics release];
    [_graphics release];
    [super dealloc];

}


#pragma mark *** Private KVC-Compliance for Public Properties ***


- (NSArray *)graphics {
    
    // Never return nil when the invoker's expecting an empty collection.
    return _graphics ? _graphics : [NSArray array];
    
}


- (void)insertGraphics:(NSArray *)graphics atIndexes:(NSIndexSet *)indexes {

    // Do the actual insertion. Instantiate the graphics array lazily.
    if (!_graphics) {
	_graphics = [[NSMutableArray alloc] init];
    }
    [_graphics insertObjects:graphics atIndexes:indexes];

    // For the purposes of scripting, every graphic has to point back to the document that contains it.
    [graphics makeObjectsPerformSelector:@selector(setScriptingContainer:) withObject:self];

    // Register an action that will undo the insertion.
    NSUndoManager *undoManager = [self undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(removeGraphicsAtIndexes:) object:indexes];

    // Record the inserted graphics so we can filter out observer notifications from them. This way we don't waste memory registering undo operations for changes that wouldn't have any effect because the graphics are going to be removed anyway. In Sketch this makes a difference when you create a graphic and then drag the mouse to set its initial size right away. Why don't we do this if undo registration is disabled? Because we don't want to add to this set during document reading. (See what -readFromData:ofType:error: does with the undo manager.) That would ruin the undoability of the first graphic editing you do after reading a document.
    if ([undoManager isUndoRegistrationEnabled]) {
	if (_undoGroupInsertedGraphics) {
	    [_undoGroupInsertedGraphics addObjectsFromArray:graphics];
	} else {
	    _undoGroupInsertedGraphics = [[NSMutableSet alloc] initWithArray:graphics];
	}
    }

    // Start observing the just-inserted graphics so that, when they're changed, we can record undo operations.
    [self startObservingGraphics:graphics];

}


- (void)removeGraphicsAtIndexes:(NSIndexSet *)indexes {

    // Find out what graphics are being removed. We lazily create the graphics array if necessary even though it should never be necessary, just so a helpful exception will be thrown if this method is being misused.
    if (!_graphics) {
	_graphics = [[NSMutableArray alloc] init];
    }
    NSArray *graphics = [_graphics objectsAtIndexes:indexes];
    
    // Stop observing the just-removed graphics to balance what was done in -insertGraphics:atIndexes:.
    [self stopObservingGraphics:graphics];

    // Register an action that will undo the removal. Do this before the actual removal so we don't have to worry about the releasing of the graphics that will be done.
    [[[self undoManager] prepareWithInvocationTarget:self] insertGraphics:graphics atIndexes:indexes];
    
    // For the purposes of scripting, every graphic had to point back to the document that contains it. Now they should stop that.
    [graphics makeObjectsPerformSelector:@selector(setScriptingContainer:) withObject:nil];

    // Do the actual removal.
    [_graphics removeObjectsAtIndexes:indexes];
    
}


// There's no need for a -setGraphics: method right now, because [thisDocument mutableArrayValueForKey:@"graphics"] will happily return a mutable collection proxy that invokes our insertion and removal methods when necessary. A pitfall to watch out for is that -setValue:forKey: is _not_ bright enough to invoke our insertion and removal methods when you would think it should. If we ever catch anyone sending this object -setValue:forKey: messages for "graphics" then we have to add -setGraphics:. When we do, there's another pitfall to watch out for: if -setGraphics: is implemented in terms of -insertGraphics:atIndexes: and -removeGraphicsAtIndexes:, or vice versa, then KVO autonotification will cause observers to get redundant, incorrect, notifications (because all of the methods involved have KVC-compliant names).


#pragma mark *** Simple Property Getting ***


- (NSSize)canvasSize {
    
    // A Sketch's canvas size is the size of the piece of paper that the user selects in the Page Setup panel for it, minus the document margins that are set.
    NSPrintInfo *printInfo = [self printInfo];
    NSSize canvasSize = [printInfo paperSize];
    canvasSize.width -= ([printInfo leftMargin] + [printInfo rightMargin]);
    canvasSize.height -= ([printInfo topMargin] + [printInfo bottomMargin]);
    return canvasSize;
    
}


#pragma mark *** Overrides of NSDocument Methods ***


// This method will only be invoked on Mac 10.4 and later. If you're writing an application that has to run on 10.3.x and earlier you should override -loadDataRepresentation:ofType: instead.
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {

    // This application's Info.plist only declares two document types, which go by the names SKTDocumentOldTypeName/SKTDocumentOldVersion1TypeName (on Mac OS 10.4) or SKTDocumentNewTypeName/SKTDocumentNewVersion1TypeName (on 10.5), for which it can play the "editor" role, and none for which it can play the "viewer" role, so the type better match one of those. Notice that we don't compare uniform type identifiers (UTIs) with -isEqualToString:. We use -[NSWorkspace type:conformsToType:] (new in 10.5), which is nearly always the correct thing to do with UTIs.
    BOOL readSuccessfully;
    NSArray *graphics = nil;
    NSPrintInfo *printInfo = nil;
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    BOOL useTypeConformance = [workspace respondsToSelector:@selector(type:conformsToType:)];
    if ((useTypeConformance && [workspace type:typeName conformsToType:SKTDocumentNewTypeName]) || [typeName isEqualToString:SKTDocumentOldTypeName]) {

	// The file uses Sketch 2's new format. Read in the property list.
	NSDictionary *properties = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListImmutable format:NULL errorDescription:NULL];
	if (properties) {

	    // Get the graphics. Strictly speaking the property list of an empty document should have an empty graphics array, not no graphics array, but we cope easily with either. Don't trust the type of something you get out of a property list unless you know your process created it or it was read from your application or framework's resources.
	    NSArray *graphicPropertiesArray = [properties objectForKey:SKTDocumentGraphicsKey];
	    graphics = [graphicPropertiesArray isKindOfClass:[NSArray class]] ? [SKTGraphic graphicsWithProperties:graphicPropertiesArray] : [NSArray array];

	    // Get the page setup. There's no point in considering the opening of the document to have failed if we can't get print info. A more finished app might present a panel warning the user that something's fishy though.
	    NSData *printInfoData = [properties objectForKey:SKTDocumentPrintInfoKey];
	    printInfo = [printInfoData isKindOfClass:[NSData class]] ? [NSUnarchiver unarchiveObjectWithData:printInfoData] : [[[NSPrintInfo alloc] init] autorelease];

	} else if (outError) {

	    // If property list parsing fails we have no choice but to admit that we don't know what went wrong. The error description returned by +[NSPropertyListSerialization propertyListFromData:mutabilityOption:format:errorDescription:] would be pretty technical, and not the sort of thing that we should show to a user.
	    *outError = SKTErrorWithCode(SKTUnknownFileReadError);
	
	}
	readSuccessfully = properties ? YES : NO;

    } else {
	NSParameterAssert((useTypeConformance && [workspace type:typeName conformsToType:SKTDocumentNewVersion1TypeName]) || [typeName isEqualToString:SKTDocumentOldVersion1TypeName]);

	// The file uses Sketch's old format. Sketch is still a work in progress.
	graphics = [NSArray array];
	printInfo = [[[NSPrintInfo alloc] init] autorelease];
	readSuccessfully = YES;

    }

    // Did the reading work? In this method we ought to either do nothing and return an error or overwrite every property of the document. Don't leave the document in a half-baked state.
    if (readSuccessfully) {

	// Update the document's list of graphics by going through KVC-compliant mutation methods. KVO notifications will be automatically sent to observers (which does matter, because this might be happening at some time other than document opening; reverting, for instance). Update its page setup the regular way. Don't let undo actions get registered while doing any of this. The fact that we have to explicitly protect against useless undo actions is considered an NSDocument bug nowadays, and will someday be fixed.
	[[self undoManager] disableUndoRegistration];
	[self removeGraphicsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self graphics] count])]];
	[self insertGraphics:graphics atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [graphics count])]];
	[self setPrintInfo:printInfo];
	[[self undoManager] enableUndoRegistration];

    } // else it was the responsibility of something in the previous paragraph to set *outError.
    return readSuccessfully;

}


// This method will only be invoked on Mac OS 10.4 and later. If you're writing an application that has to run on 10.3.x and earlier you should override -dataRepresentationOfType: instead.
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {

    // This method must be prepared for typeName to be any value that might be in the array returned by any invocation of -writableTypesForSaveOperation:. Because this class:
    // doesn't - override -writableTypesForSaveOperation:, and
    // doesn't - override +writableTypes or +isNativeType: (which the default implementation of -writableTypesForSaveOperation: invokes),
    // and because:
    // - Sketch has a "Save a Copy As..." file menu item that results in NSSaveToOperations,
    // we know that that the type names we have to handle here include:
    // - SKTDocumentOldTypeName (on Mac OS 10.4) or SKTDocumentNewTypeName (on 10.5), because this application's Info.plist file declares that instances of this class can play the "editor" role for it, and
    // - NSPDFPboardType (on 10.4) or kUTTypePDF (on 10.5) and NSTIFFPboardType (on 10.4) or kUTTypeTIFF (on 10.5), because according to the Info.plist a Sketch document is exportable as them.
    // We use -[NSWorkspace type:conformsToType:] (new in 10.5), which is nearly always the correct thing to do with UTIs, but the arguments are reversed here compared to what's typical. Think about it: this method doesn't know how to write any particular subtype of the supported types, so it should assert if it's asked to. It does however effectively know how to write all of the supertypes of the supported types (like public.data), and there's no reason for it to refuse to do so. Not particularly useful in the context of an app like Sketch, but correct.
    // If we had reason to believe that +[SKTRenderingView pdfDataWithGraphics:] or +[SKTGraphic propertiesWithGraphics:] could return nil we would have to arrange for *outError to be set to a real value when that happens. If you signal failure in a method that takes an error: parameter and outError!=NULL you must set *outError to something decent.
    NSData *data;
    NSArray *graphics = [self graphics];
    NSPrintInfo *printInfo = [self printInfo];
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    BOOL useTypeConformance = [workspace respondsToSelector:@selector(type:conformsToType:)];
    if ((useTypeConformance && [workspace type:SKTDocumentNewTypeName conformsToType:typeName]) || [typeName isEqualToString:SKTDocumentOldTypeName]) {

	// Convert the contents of the document to a property list and then flatten the property list.
	NSMutableDictionary *properties = [NSMutableDictionary dictionary];
	[properties setObject:[NSNumber numberWithInteger:SKTDocumentCurrentVersion] forKey:SKTDocumentVersionKey];
	[properties setObject:[SKTGraphic propertiesWithGraphics:graphics] forKey:SKTDocumentGraphicsKey];
	[properties setObject:[NSArchiver archivedDataWithRootObject:printInfo] forKey:SKTDocumentPrintInfoKey];
	data = [NSPropertyListSerialization dataFromPropertyList:properties format:NSPropertyListBinaryFormat_v1_0 errorDescription:NULL];

    } else if ((useTypeConformance && [workspace type:(NSString *)kUTTypePDF conformsToType:typeName]) || [typeName isEqualToString:NSPDFPboardType]) {
	data = [SKTRenderingView pdfDataWithGraphics:graphics];
    } else {
	NSParameterAssert((useTypeConformance && [workspace type:(NSString *)kUTTypeTIFF conformsToType:typeName]) || [typeName isEqualToString:NSTIFFPboardType]);
        data = [SKTRenderingView tiffDataWithGraphics:graphics error:outError];
    }
    return data;

}


- (void)setPrintInfo:(NSPrintInfo *)printInfo {
    
    // Do the regular Cocoa thing, but also be KVO-compliant for canvasSize, which is derived from the print info.
    [self willChangeValueForKey:SKTDocumentCanvasSizeKey];
    [super setPrintInfo:printInfo];
    [self didChangeValueForKey:SKTDocumentCanvasSizeKey];
    
}


// This method will only be invoked on Mac 10.4 and later. If you're writing an application that has to run on 10.3.x and earlier you should override -printShowingPrintPanel: instead.
- (NSPrintOperation *)printOperationWithSettings:(NSDictionary *)printSettings error:(NSError **)outError {

    // Figure out a title for the print job. It will be used with the .pdf file name extension in a save panel if the user chooses Save As PDF... in the print panel, or in a similar way if the user hits the Preview button in the print panel, or for any number of other uses the printing system might put it to. We don't want the user to see file names like "My Great Sketch.sketch2.pdf", so we can't just use [self displayName], because the document's file name extension might not be hidden. Instead, because we know that all valid Sketch documents have file name extensions, get the last path component of the file URL and strip off its file name extension, and use what's left.
    NSString *printJobTitle = [[[[self fileURL] path] lastPathComponent] stringByDeletingPathExtension];
    if (!printJobTitle) {

	// Wait, this document doesn't have a file associated with it. Just use -displayName after all. It will be "Untitled" or "Untitled 2" or something, which is fine.
	printJobTitle = [self displayName];

    }

    // Create a view that will be used just for printing.
    NSSize documentSize = [self canvasSize];
    SKTRenderingView *renderingView = [[SKTRenderingView alloc] initWithFrame:NSMakeRect(0.0, 0.0, documentSize.width, documentSize.height) graphics:[self graphics] printJobTitle:printJobTitle];
    
    // Create a print operation.
    NSPrintOperation *printOperation = [NSPrintOperation printOperationWithView:renderingView printInfo:[self printInfo]];
    [renderingView release];
    
    // Specify that the print operation can run in a separate thread. This will cause the print progress panel to appear as a sheet on the document window.
    [printOperation setCanSpawnSeparateThread:YES];
    
    // Set any print settings that might have been specified in a Print Document Apple event. We do it this way because we shouldn't be mutating the result of [self printInfo] here, and using the result of [printOperation printInfo], a copy of the original print info, means we don't have to make yet another temporary copy of [self printInfo].
    [[[printOperation printInfo] dictionary] addEntriesFromDictionary:printSettings];
    
    // We don't have to autorelease the print operation because +[NSPrintOperation printOperationWithView:printInfo:] of course already autoreleased it. Nothing in this method can fail, so we never return nil, so we don't have to worry about setting *outError.
    return printOperation;
    
}


- (void)makeWindowControllers {

    // Start off with one document window.
    SKTWindowController *windowController = [[SKTWindowController alloc] init];
    [self addWindowController:windowController];
    [windowController release];

}


#pragma mark *** Undo ***


- (void)setGraphicProperties:(NSDictionary *)propertiesPerGraphic {

    // The passed-in dictionary is keyed by graphic...
    NSEnumerator *graphicEnumerator = [propertiesPerGraphic keyEnumerator];
    SKTGraphic *graphic;
    while (graphic = [graphicEnumerator nextObject]) {

	// ...with values that are dictionaries of properties, keyed by key-value coding key.
	NSDictionary *graphicProperties = [propertiesPerGraphic objectForKey:graphic];

	// Use a relatively unpopular method. Here we're effectively "casting" a key path to a key (see how these dictionaries get built in -observeValueForKeyPath:ofObject:change:context:). It had better really be a key or things will get confused. For example, this is one of the things that would need updating if -[SKTGraphic keysForValuesToObserveForUndo] someday becomes -[SKTGraphic keyPathsForValuesToObserveForUndo].
	[graphic setValuesForKeysWithDictionary:graphicProperties];

    }

}


- (void)observeUndoManagerCheckpoint:(NSNotification *)notification {

    // Start the coalescing of graphic property changes over.
    _undoGroupHasChangesToMultipleProperties = NO;
    [_undoGroupPresentablePropertyName release];
    _undoGroupPresentablePropertyName = nil;
    [_undoGroupOldPropertiesPerGraphic release];
    _undoGroupOldPropertiesPerGraphic = nil;
    [_undoGroupInsertedGraphics release];
    _undoGroupInsertedGraphics = nil;

}


- (void)startObservingGraphics:(NSArray *)graphics {

    // Each graphic can have a different set of properties that need to be observed.
    NSUInteger graphicCount = [graphics count];
    for (NSUInteger index = 0; index<graphicCount; index++) {
	SKTGraphic *graphic = [graphics objectAtIndex:index];
	NSSet *keys = [graphic keysForValuesToObserveForUndo];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key;
	while (key = [keyEnumerator nextObject]) {

	    // We use NSKeyValueObservingOptionOld because when something changes we want to record the old value, which is what has to be set in the undo operation. We use NSKeyValueObservingOptionNew because we compare the new value against the old value in an attempt to ignore changes that aren't really changes.
	    [graphic addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SKTDocumentUndoObservationContext];

	}

	// The set of properties to be observed can itself change.
	[graphic addObserver:self forKeyPath:SKTGraphicKeysForValuesToObserveForUndoKey options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SKTDocumentUndoKeysObservationContext];

    }

}


- (void)stopObservingGraphics:(NSArray *)graphics {

    // Do the opposite of what's done in -startObservingGraphics:.
    NSUInteger graphicCount = [graphics count];
    for (NSUInteger index = 0; index<graphicCount; index++) {
	SKTGraphic *graphic = [graphics objectAtIndex:index];
	[graphic removeObserver:self forKeyPath:SKTGraphicKeysForValuesToObserveForUndoKey];
	NSSet *keys = [graphic keysForValuesToObserveForUndo];
	NSEnumerator *keyEnumerator = [keys objectEnumerator];
	NSString *key;
	while (key = [keyEnumerator nextObject]) {
	    [graphic removeObserver:self forKeyPath:key];
	}

    }

}


// An override of the NSObject(NSKeyValueObserving) method.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context {

    // Make sure we don't intercept an observer notification that's meant for NSDocument. In Tiger NSDocuments don't observe anything, but that could change in the future. We can do a simple pointer comparison because KVO doesn't do anything at all with the context value, not even retain or copy it.
    if (context==SKTDocumentUndoKeysObservationContext) {

	// The set of properties that we should be observing has changed for some graphic. Stop or start observing.
	NSSet *oldKeys = [change objectForKey:NSKeyValueChangeOldKey];
	NSSet *newKeys = [change objectForKey:NSKeyValueChangeNewKey];
	NSString *key;
	NSEnumerator *oldKeyEnumerator = [oldKeys objectEnumerator];
	while (key = [oldKeyEnumerator nextObject]) {
	    if (![newKeys containsObject:key]) {
		[observedObject removeObserver:self forKeyPath:key];
	    }
	}
	NSEnumerator *newKeyEnumerator = [newKeys objectEnumerator];
	while (key = [newKeyEnumerator nextObject]) {
	    if (![oldKeys containsObject:key]) {
		[observedObject addObserver:self forKeyPath:key options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:SKTDocumentUndoObservationContext];
	    }
	}

    } else if (context==SKTDocumentUndoObservationContext) {

	// The value of some graphic's property has changed. Don't waste memory by recording undo operations affecting graphics that would be removed during undo anyway. In Sketch this check matters when you use a creation tool to create a new graphic and then drag the mouse to resize it; there's no reason to record a change of "bounds" in that situation.
	SKTGraphic *graphic = (SKTGraphic *)observedObject;
	if (![_undoGroupInsertedGraphics containsObject:graphic]) {

	    // Ignore changes that aren't really changes. Now that Sketch's inspector panel allows you to change a property of all selected graphics at once (it didn't always, as recently as the version that appears in Tiger's /Developer/Examples/AppKit), it's easy for the user to cause a big batch of SKTGraphics to be sent -setValue:forKeyPath: messages that don't do anything useful. Try this simple example: create 10 circles, and set all but one to be filled. Select them all. In the inspector panel the Fill checkbox will show the mixed state indicator (a dash). Click on it. Cocoa's bindings machinery sends [theCircle setValue:[NSNumber numberWithBOOL:YES] forKeyPath:SKTGraphicIsDrawingFillKey] to each selected circle. KVO faithfully notifies this SKTDocument, which is observing all of its graphics, for each circle object, even though the old value of the SKTGraphicIsDrawingFillKey property for 9 out of the 10 circles was already YES. If we didn't actively filter out useless notifications like these we would be wasting memory by recording undo operations that don't actually do anything.
	    // How much processor time does this memory optimization cost? We don't know, because we haven't measured it. The use of NSKeyValueObservingOptionNew in -startObservingGraphics:, which makes NSKeyValueChangeNewKey entries appear in change dictionaries, definitely costs something when KVO notifications are sent (it costs virtually nothing at observer registration time). Regardless, it's probably a good idea to do simple memory optimizations like this as they're discovered and debug just enough to confirm that they're saving the expected memory (and not introducing bugs). Later on it will be easier to test for good responsiveness and sample to hunt down processor time problems than it will be to figure out where all the darn memory went when your app turns out to be notably RAM-hungry (and therefore slowing down _other_ apps on your user's computers too, if the problem is bad enough to cause paging).
	    // Is this a premature optimization? No. Leaving out this very simple check, because we're worried about the processor time cost of using NSKeyValueChangeNewKey, would be a premature optimization.
	    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
	    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
	    if (![newValue isEqualTo:oldValue]) {

		// Is this the first observed graphic change in the current undo group?
		NSUndoManager *undoManager = [self undoManager];
		if (!_undoGroupOldPropertiesPerGraphic) {

		    // We haven't recorded changes for any graphics at all since the last undo manager checkpoint. Get ready to start collecting them.
		    _undoGroupOldPropertiesPerGraphic = [[NSMutableDictionary alloc] init];

		    // Register an undo operation for any graphic property changes that are going to be coalesced between now and the next invocation of -observeUndoManagerCheckpoint:.
		    [undoManager registerUndoWithTarget:self selector:@selector(setGraphicProperties:) object:_undoGroupOldPropertiesPerGraphic];

		}

		// Find the dictionary in which we're recording the old values of properties for the changed graphic.
		NSMutableDictionary *oldGraphicProperties = [_undoGroupOldPropertiesPerGraphic objectForKey:graphic];
		if (!oldGraphicProperties) {

		    // We have to create a dictionary to hold old values for the changed graphic. -[NSMutableDictionary setObject:forKey:] always makes a copy of the key object, but we don't want to make copies of SKTGraphics here, so don't use it. Take advantage of toll-free bridging and use CFDictionarySetValue() instead. It will just retain the key object (NSMutableDictionaries casted to CFMutableDictionaryRefs act like CFMutableDictionaryRefs that have been created with kCFTypeDictionaryKeyCallBacks not kCFCopyStringDictionaryKeyCallBacks). In a slightly bigger app we wouldn't use such a subtle trick; the fact that no one should add new code that sends -setObject:forKey: to _undoGroupOldPropertiesPerGraphic is pretty easy to miss!
		    oldGraphicProperties = [[NSMutableDictionary alloc] init];
		    CFDictionarySetValue((CFMutableDictionaryRef)_undoGroupOldPropertiesPerGraphic, graphic, oldGraphicProperties);
		    [oldGraphicProperties release];

		}

		// Record the old value for the changed property, unless an older value has already been recorded for the current undo group. Here we're "casting" a KVC key path to a dictionary key, but that should be OK. -[NSMutableDictionary setObject:forKey:] doesn't know the difference.
		if (![oldGraphicProperties objectForKey:keyPath]) {
		    [oldGraphicProperties setObject:oldValue forKey:keyPath];
		}

		// Don't set the undo action name during undoing and redoing. In Sketch, SKTGraphicView sometimes overwrites whatever action name we set up here with something more specific (as in, "Move" or "Resize" instead of "Change of Bounds"), but only during the building of the original undo action. During undoing and redoing SKTGraphicView doesn't get a chance to do that desirable overwriting again. Just leave the action name alone during undoing and redoing and the action name from the original undo group will continue to be used.
		if (![undoManager isUndoing] && ![undoManager isRedoing]) {

		    // What's the human-readable name of the property that's just been changed? Here we're effectively "casting" a key path to a key. It had better really be a key or things will get confused. For example, this is one of the things that would need updating if -[SKTGraphic keysForValuesToObserveForUndo] someday becomes -[SKTGraphic keyPathsForValuesToObserveForUndo].
		    Class graphicClass = [graphic class];
		    NSString *presentablePropertyName = [graphicClass presentablePropertyNameForKey:keyPath];
		    if (!presentablePropertyName) {

			// Someone overrode -[SKTGraphic keysForValuesToObserveForUndo] but didn't override +[SKTGraphic presentablePropertyNameForKey:] to match. Help debug a little. Hopefully the SKTGraphic public interface makes it so that you only have to test a little bit to find bugs like this.
			NSString *graphicClassName = NSStringFromClass(graphicClass);
			[NSException raise:NSInternalInconsistencyException format:@"[[%@ class] keysForValuesToObserveForUndo] returns a set that includes @\"%@\", but [[%@ class] presentablePropertyNameForKey:@\"%@\"] returns nil.", graphicClassName, keyPath, graphicClassName, keyPath];

		    }

		    // Have we set an action name for the current undo group yet?
		    if (_undoGroupPresentablePropertyName || _undoGroupHasChangesToMultipleProperties) {

			// Yes. Have we already determined that we have to use a generic undo action name, and set it? If so, there's nothing to do.
			if (!_undoGroupHasChangesToMultipleProperties) {

			    // So far we've set an action name for the current undo group that mentions a specific property. Is the property that's just been changed the same one mentioned in that action name (regardless of which graphic has been changed)? If so, there's nothing to do.
			    if (![_undoGroupPresentablePropertyName isEqualToString:presentablePropertyName]) {

				// The undo action is going to restore the old values of different properties. Set a generic undo action name and record the fact that we've done so.
				[undoManager setActionName:NSLocalizedStringFromTable(@"Change of Multiple Graphic Properties", @"UndoStrings", @"Generic action name for complex graphic property changes.")];
				_undoGroupHasChangesToMultipleProperties = YES;

				// This is useless now.
				[_undoGroupPresentablePropertyName release];
				_undoGroupPresentablePropertyName = nil;

			    }

			}

		    } else {

			// So far the action of the current undo group is going to be the restoration of the value of one property. Set a specific undo action name and record the fact that we've done so.
			[undoManager setActionName:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Change of %@", @"UndoStrings", @"Specific action name for simple graphic property changes. The argument is the name of a property."), presentablePropertyName]];
			_undoGroupPresentablePropertyName = [presentablePropertyName copy];

		    }

		}

	    }

	}

    } else {

	// In overrides of -observeValueForKeyPath:ofObject:change:context: always invoke super when the observer notification isn't recognized. Code in the superclass is apparently doing observation of its own. NSObject's implementation of this method throws an exception. Such an exception would be indicating a programming error that should be fixed.
	[super observeValueForKeyPath:keyPath ofObject:observedObject change:change context:context];

    }
    
}


#pragma mark *** Scripting ***


// Conformance to the NSObject(SKTGraphicScriptingContainer) informal protocol.
- (NSScriptObjectSpecifier *)objectSpecifierForGraphic:(SKTGraphic *)graphic {

    // Graphics don't have unique IDs or names, so just return an index specifier.
    NSScriptObjectSpecifier *graphicObjectSpecifier = nil;
    NSUInteger graphicIndex = [[self graphics] indexOfObjectIdenticalTo:graphic];
    if (graphicIndex!=NSNotFound) {
        NSScriptObjectSpecifier *objectSpecifier = [self objectSpecifier];
        graphicObjectSpecifier = [[[NSIndexSpecifier alloc] initWithContainerClassDescription:[objectSpecifier keyClassDescription] containerSpecifier:objectSpecifier key:@"graphics" index:graphicIndex] autorelease];
    }
    return graphicObjectSpecifier;

}


// These are methods that wouldn't be here if this class weren't scriptable for relationships like "circles," "rectangles," etc. The first two methods are redundant with the -insertGraphics:atIndexes: and -removeGraphicsAtIndexes: methods up above, except they're a little more convenient for invoking in all of the code down below. They don't have KVO-compliant names (-insertObject:inGraphicsAtIndex: and -removeObjectFromGraphicsAtIndex:) on purpose. If they did then extra, incorrect, KVO autonotification would be done.


- (void)insertGraphic:(SKTGraphic *)graphic atIndex:(NSUInteger)index {

    // Just invoke the regular method up above.
    NSArray *graphics = [[NSArray alloc] initWithObjects:graphic, nil];
    NSIndexSet *indexes = [[NSIndexSet alloc] initWithIndex:index];
    [self insertGraphics:graphics atIndexes:indexes];
    [indexes release];
    [graphics release];

}


- (void)removeGraphicAtIndex:(NSUInteger)index {

    // Just invoke the regular method up above.
    NSIndexSet *indexes = [[NSIndexSet alloc] initWithIndex:index];
    [self removeGraphicsAtIndexes:indexes];
    [indexes release];

}


- (void)addInGraphics:(SKTGraphic *)graphic {

    // Just a convenience for invoking by some of the methods down below.
    [self insertGraphic:graphic atIndex:[[self graphics] count]];

}


- (NSArray *)graphicsWithClass:(Class)theClass {
    NSArray *graphics = [self graphics];
    NSMutableArray *result = [NSMutableArray array];
    NSUInteger i, c = [graphics count];
    id curGraphic;

    for (i=0; i<c; i++) {
        curGraphic = [graphics objectAtIndex:i];
        if ([curGraphic isKindOfClass:theClass]) {
            [result addObject:curGraphic];
        }
    }
    return result;
}

- (NSArray *)rectangles {
    return [self graphicsWithClass:[SKTRectangle class]];
}

- (NSArray *)circles {
    return [self graphicsWithClass:[SKTCircle class]];
}

- (NSArray *)lines {
    return [self graphicsWithClass:[SKTLine class]];
}

- (NSArray *)textAreas {
    return [self graphicsWithClass:[SKTText class]];
}

- (NSArray *)images {
    return [self graphicsWithClass:[SKTImage class]];
}

- (void)insertObject:(SKTGraphic *)graphic inRectanglesAtIndex:(NSUInteger)index {
    // MF:!!! This is not going to be ideal.  If we are being asked to, say, "make a new rectangle at after rectangle 2", we will be after rectangle 2, but we may be after some other stuff as well since we will be asked to insertInRectangles:atIndex:3...
    NSArray *rects = [self rectangles];
    if (index == [rects count]) {
        [self addInGraphics:graphic];
    } else {
        NSArray *graphics = [self graphics];
        NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[rects objectAtIndex:index]];
        if (newIndex != NSNotFound) {
            [self insertGraphic:graphic atIndex:newIndex];
        } else {
            // Shouldn't happen.
            [NSException raise:NSRangeException format:@"Could not find the given rectangle in the graphics."];
        }
    }
}

- (void)removeObjectFromRectanglesAtIndex:(NSUInteger)index {
    NSArray *rects = [self rectangles];
    NSArray *graphics = [self graphics];
    NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[rects objectAtIndex:index]];
    if (newIndex != NSNotFound) {
        [self removeGraphicAtIndex:newIndex];
    } else {
        // Shouldn't happen.
        [NSException raise:NSRangeException format:@"Could not find the given rectangle in the graphics."];
    }
}

- (void)insertObject:(SKTGraphic *)graphic inCirclesAtIndex:(NSUInteger)index {
    // MF:!!! This is not going to be ideal.  If we are being asked to, say, "make a new rectangle at after rectangle 2", we will be after rectangle 2, but we may be after some other stuff as well since we will be asked to insertInCircles:atIndex:3...
    NSArray *circles = [self circles];
    if (index == [circles count]) {
        [self addInGraphics:graphic];
    } else {
        NSArray *graphics = [self graphics];
        NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[circles objectAtIndex:index]];
        if (newIndex != NSNotFound) {
            [self insertGraphic:graphic atIndex:newIndex];
        } else {
            // Shouldn't happen.
            [NSException raise:NSRangeException format:@"Could not find the given circle in the graphics."];
        }
    }
}

- (void)removeObjectFromCirclesAtIndex:(NSUInteger)index {
    NSArray *circles = [self circles];
    NSArray *graphics = [self graphics];
    NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[circles objectAtIndex:index]];
    if (newIndex != NSNotFound) {
        [self removeGraphicAtIndex:newIndex];
    } else {
        // Shouldn't happen.
        [NSException raise:NSRangeException format:@"Could not find the given circle in the graphics."];
    }
}

- (void)insertObject:(SKTGraphic *)graphic inLinesAtIndex:(NSUInteger)index {
    // MF:!!! This is not going to be ideal.  If we are being asked to, say, "make a new rectangle at after rectangle 2", we will be after rectangle 2, but we may be after some other stuff as well since we will be asked to insertInLines:atIndex:3...
    NSArray *lines = [self lines];
    if (index == [lines count]) {
        [self addInGraphics:graphic];
    } else {
        NSArray *graphics = [self graphics];
        NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[lines objectAtIndex:index]];
        if (newIndex != NSNotFound) {
            [self insertGraphic:graphic atIndex:newIndex];
        } else {
            // Shouldn't happen.
            [NSException raise:NSRangeException format:@"Could not find the given line in the graphics."];
        }
    }
}

- (void)removeObjectFromLinesAtIndex:(NSUInteger)index {
    NSArray *lines = [self lines];
    NSArray *graphics = [self graphics];
    NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[lines objectAtIndex:index]];
    if (newIndex != NSNotFound) {
        [self removeGraphicAtIndex:newIndex];
    } else {
        // Shouldn't happen.
        [NSException raise:NSRangeException format:@"Could not find the given line in the graphics."];
    }
}

- (void)insertObject:(SKTGraphic *)graphic inTextAreasAtIndex:(NSUInteger)index {
    // MF:!!! This is not going to be ideal.  If we are being asked to, say, "make a new rectangle at after rectangle 2", we will be after rectangle 2, but we may be after some other stuff as well since we will be asked to insertInTextAreas:atIndex:3...
    NSArray *textAreas = [self textAreas];
    if (index == [textAreas count]) {
        [self addInGraphics:graphic];
    } else {
        NSArray *graphics = [self graphics];
        NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[textAreas objectAtIndex:index]];
        if (newIndex != NSNotFound) {
            [self insertGraphic:graphic atIndex:newIndex];
        } else {
            // Shouldn't happen.
            [NSException raise:NSRangeException format:@"Could not find the given text area in the graphics."];
        }
    }
}

- (void)removeObjectFromTextAreasAtIndex:(NSUInteger)index {
    NSArray *textAreas = [self textAreas];
    NSArray *graphics = [self graphics];
    NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[textAreas objectAtIndex:index]];
    if (newIndex != NSNotFound) {
        [self removeGraphicAtIndex:newIndex];
    } else {
        // Shouldn't happen.
        [NSException raise:NSRangeException format:@"Could not find the given text area in the graphics."];
    }
}

- (void)insertObject:(SKTGraphic *)graphic inImagesAtIndex:(NSUInteger)index {
    // MF:!!! This is not going to be ideal.  If we are being asked to, say, "make a new rectangle at after rectangle 2", we will be after rectangle 2, but we may be after some other stuff as well since we will be asked to insertInImages:atIndex:3...
    NSArray *images = [self images];
    if (index == [images count]) {
        [self addInGraphics:graphic];
    } else {
        NSArray *graphics = [self graphics];
        NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[images objectAtIndex:index]];
        if (newIndex != NSNotFound) {
            [self insertGraphic:graphic atIndex:newIndex];
        } else {
            // Shouldn't happen.
            [NSException raise:NSRangeException format:@"Could not find the given image in the graphics."];
        }
    }
}

- (void)removeObjectFromImagesAtIndex:(NSUInteger)index {
    NSArray *images = [self images];
    NSArray *graphics = [self graphics];
    NSInteger newIndex = [graphics indexOfObjectIdenticalTo:[images objectAtIndex:index]];
    if (newIndex != NSNotFound) {
        [self removeGraphicAtIndex:newIndex];
    } else {
        // Shouldn't happen.
        [NSException raise:NSRangeException format:@"Could not find the given image in the graphics."];
    }
}

// The following "indicesOf..." methods are in support of scripting.  They allow more flexible range and relative specifiers to be used with the different graphic keys of a SKTDocument.
// The scripting engine does not know about the fact that the "rectangles" key is really just a subset of the "graphics" key, so script code like "rectangles from circle 1 to line 4" don't make sense to it.  But Sketch does know and can answer such questions itself, with a little work.
- (NSArray *)indicesOfObjectsByEvaluatingRangeSpecifier:(NSRangeSpecifier *)rangeSpec {
    NSString *key = [rangeSpec key];

    if ([key isEqual:@"graphics"] || [key isEqual:@"rectangles"] || [key isEqual:@"circles"] || [key isEqual:@"lines"] || [key isEqual:@"textAreas"] || [key isEqual:@"images"]) {
        // This is one of the keys we might want to deal with.
        NSScriptObjectSpecifier *startSpec = [rangeSpec startSpecifier];
        NSScriptObjectSpecifier *endSpec = [rangeSpec endSpecifier];
        NSString *startKey = [startSpec key];
        NSString *endKey = [endSpec key];
        NSArray *graphics = [self graphics];

        if ((startSpec == nil) && (endSpec == nil)) {
            // We need to have at least one of these...
            return nil;
        }
        if ([graphics count] == 0) {
            // If there are no graphics, there can be no match.  Just return now.
            return [NSArray array];
        }

        if ((!startSpec || [startKey isEqual:@"graphics"] || [startKey isEqual:@"rectangles"] || [startKey isEqual:@"circles"] || [startKey isEqual:@"lines"] || [startKey isEqual:@"textAreas"] || [startKey isEqual:@"images"]) && (!endSpec || [endKey isEqual:@"graphics"] || [endKey isEqual:@"rectangles"] || [endKey isEqual:@"circles"] || [endKey isEqual:@"lines"] || [endKey isEqual:@"textAreas"] || [endKey isEqual:@"images"])) {
            NSInteger startIndex;
            NSInteger endIndex;

            // The start and end keys are also ones we want to handle.

            // The strategy here is going to be to find the index of the start and stop object in the full graphics array, regardless of what its key is.  Then we can find what we're looking for in that range of the graphics key (weeding out objects we don't want, if necessary).

            // First find the index of the first start object in the graphics array
            if (startSpec) {
                id startObject = [startSpec objectsByEvaluatingWithContainers:self];
                if ([startObject isKindOfClass:[NSArray class]]) {
                    if ([startObject count] == 0) {
                        startObject = nil;
                    } else {
                        startObject = [startObject objectAtIndex:0];
                    }
                }
                if (!startObject) {
                    // Oops.  We could not find the start object.
                    return nil;
                }
                startIndex = [graphics indexOfObjectIdenticalTo:startObject];
                if (startIndex == NSNotFound) {
                    // Oops.  We couldn't find the start object in the graphics array.  This should not happen.
                    return nil;
                }
            } else {
                startIndex = 0;
            }

            // Now find the index of the last end object in the graphics array
            if (endSpec) {
                id endObject = [endSpec objectsByEvaluatingWithContainers:self];
                if ([endObject isKindOfClass:[NSArray class]]) {
                    NSUInteger endObjectsCount = [endObject count];
                    if (endObjectsCount == 0) {
                        endObject = nil;
                    } else {
                        endObject = [endObject objectAtIndex:(endObjectsCount-1)];
                    }
                }
                if (!endObject) {
                    // Oops.  We could not find the end object.
                    return nil;
                }
                endIndex = [graphics indexOfObjectIdenticalTo:endObject];
                if (endIndex == NSNotFound) {
                    // Oops.  We couldn't find the end object in the graphics array.  This should not happen.
                    return nil;
                }
            } else {
                endIndex = [graphics count] - 1;
            }

            if (endIndex < startIndex) {
                // Accept backwards ranges gracefully
                NSInteger temp = endIndex;
                endIndex = startIndex;
                startIndex = temp;
            }

            {
                // Now startIndex and endIndex specify the end points of the range we want within the graphics array.
                // We will traverse the range and pick the objects we want.
                // We do this by getting each object and seeing if it actually appears in the real key that we are trying to evaluate in.
                NSMutableArray *result = [NSMutableArray array];
                BOOL keyIsGraphics = [key isEqual:@"graphics"];
                NSArray *rangeKeyObjects = (keyIsGraphics ? nil : [self valueForKey:key]);
                id curObj;
                NSUInteger curKeyIndex, i;

                for (i=startIndex; i<=endIndex; i++) {
                    if (keyIsGraphics) {
                        [result addObject:[NSNumber numberWithInteger:i]];
                    } else {
                        curObj = [graphics objectAtIndex:i];
                        curKeyIndex = [rangeKeyObjects indexOfObjectIdenticalTo:curObj];
                        if (curKeyIndex != NSNotFound) {
                            [result addObject:[NSNumber numberWithInteger:curKeyIndex]];
                        }
                    }
                }
                return result;
            }
        }
    }
    return nil;
}

- (NSArray *)indicesOfObjectsByEvaluatingRelativeSpecifier:(NSRelativeSpecifier *)relSpec {
    NSString *key = [relSpec key];

    if ([key isEqual:@"graphics"] || [key isEqual:@"rectangles"] || [key isEqual:@"circles"] || [key isEqual:@"lines"] || [key isEqual:@"textAreas"] || [key isEqual:@"images"]) {
        // This is one of the keys we might want to deal with.
        NSScriptObjectSpecifier *baseSpec = [relSpec baseSpecifier];
        NSString *baseKey = [baseSpec key];
        NSArray *graphics = [self graphics];
        NSRelativePosition relPos = [relSpec relativePosition];

        if (baseSpec == nil) {
            // We need to have one of these...
            return nil;
        }
        if ([graphics count] == 0) {
            // If there are no graphics, there can be no match.  Just return now.
            return [NSArray array];
        }

        if ([baseKey isEqual:@"graphics"] || [baseKey isEqual:@"rectangles"] || [baseKey isEqual:@"circles"] || [baseKey isEqual:@"lines"] || [baseKey isEqual:@"textAreas"] || [baseKey isEqual:@"images"]) {
            NSInteger baseIndex;

            // The base key is also one we want to handle.

            // The strategy here is going to be to find the index of the base object in the full graphics array, regardless of what its key is.  Then we can find what we're looking for before or after it.

            // First find the index of the first or last base object in the graphics array
            // Base specifiers are to be evaluated within the same container as the relative specifier they are the base of.  That's this document.
            id baseObject = [baseSpec objectsByEvaluatingWithContainers:self];
            if ([baseObject isKindOfClass:[NSArray class]]) {
                NSInteger baseCount = [baseObject count];
                if (baseCount == 0) {
                    baseObject = nil;
                } else {
                    if (relPos == NSRelativeBefore) {
                        baseObject = [baseObject objectAtIndex:0];
                    } else {
                        baseObject = [baseObject objectAtIndex:(baseCount-1)];
                    }
                }
            }
            if (!baseObject) {
                // Oops.  We could not find the base object.
                return nil;
            }

            baseIndex = [graphics indexOfObjectIdenticalTo:baseObject];
            if (baseIndex == NSNotFound) {
                // Oops.  We couldn't find the base object in the graphics array.  This should not happen.
                return nil;
            }

            {
                // Now baseIndex specifies the base object for the relative spec in the graphics array.
                // We will start either right before or right after and look for an object that matches the type we want.
                // We do this by getting each object and seeing if it actually appears in the real key that we are trying to evaluate in.
                NSMutableArray *result = [NSMutableArray array];
                BOOL keyIsGraphics = [key isEqual:@"graphics"];
                NSArray *relKeyObjects = (keyIsGraphics ? nil : [self valueForKey:key]);
                id curObj;
                NSUInteger curKeyIndex, graphicCount = [graphics count];

                if (relPos == NSRelativeBefore) {
                    baseIndex--;
                } else {
                    baseIndex++;
                }
                while ((baseIndex >= 0) && (baseIndex < graphicCount)) {
                    if (keyIsGraphics) {
                        [result addObject:[NSNumber numberWithInteger:baseIndex]];
                        break;
                    } else {
                        curObj = [graphics objectAtIndex:baseIndex];
                        curKeyIndex = [relKeyObjects indexOfObjectIdenticalTo:curObj];
                        if (curKeyIndex != NSNotFound) {
                            [result addObject:[NSNumber numberWithInteger:curKeyIndex]];
                            break;
                        }
                    }
                    if (relPos == NSRelativeBefore) {
                        baseIndex--;
                    } else {
                        baseIndex++;
                    }
                }

                return result;
            }
        }
    }
    return nil;
}
    
- (NSArray *)indicesOfObjectsByEvaluatingObjectSpecifier:(NSScriptObjectSpecifier *)specifier {
    // We want to handle some range and relative specifiers ourselves in order to support such things as "graphics from circle 3 to circle 5" or "circles from graphic 1 to graphic 10" or "circle before rectangle 3".
    // Returning nil from this method will cause the specifier to try to evaluate itself using its default evaluation strategy.
	
    if ([specifier isKindOfClass:[NSRangeSpecifier class]]) {
        return [self indicesOfObjectsByEvaluatingRangeSpecifier:(NSRangeSpecifier *)specifier];
    } else if ([specifier isKindOfClass:[NSRelativeSpecifier class]]) {
        return [self indicesOfObjectsByEvaluatingRelativeSpecifier:(NSRelativeSpecifier *)specifier];
    }


    // If we didn't handle it, return nil so that the default object specifier evaluation will do it.
    return nil;
}


// JSTalk Support
- (id) makeNewBox {
    id box = [[SKTRectangle alloc] init];
    [self addInGraphics:box];
    return [box autorelease];
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
