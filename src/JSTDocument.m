//
//  JSTDocument.m
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//

#import "JSTDocument.h"
#import "JSTListener.h"
#import "JSTalk.h"
#import "JSCocoaController.h"
#import "JSTPreprocessor.h"

@implementation JSTDocument
@synthesize tokenizer=_tokenizer;
@synthesize keywords=_keywords;
@synthesize externalEditorFileWatcher=_externalEditorFileWatcher;

- (id)init {
    self = [super init];
    if (self) {
        self.tokenizer = [[[TDTokenizer alloc] init] autorelease];
        /*
var s = "break case catch continue default delete do else finally for function if in instanceof new return switch this throw try typeof var void while with abstract boolean byte char class const debugger double enum export extends final float goto implements import int interface long native package private protected public short static super synchronized throws transient volatile null true false nil"

words = s.split(" ")
var i = 0;
list = ""
while (i < words.length) {
    list = list + '@"' + words[i] + '", ';
    i++
}

print("NSArray *blueWords = [NSArray arrayWithObjects:" + list + " nil];")
        */
        
        NSArray *blueWords = [NSArray arrayWithObjects:@"break", @"case", @"catch", @"continue", @"default", @"delete", @"do", @"else", @"finally", @"for", @"function", @"if", @"in", @"instanceof", @"new", @"return", @"switch", @"this", @"throw", @"try", @"typeof", @"var", @"void", @"while", @"with", @"abstract", @"boolean", @"byte", @"char", @"class", @"const", @"debugger", @"double", @"enum", @"export", @"extends", @"final", @"float", @"goto", @"implements", @"import", @"int", @"interface", @"long", @"native", @"package", @"private", @"protected", @"public", @"short", @"static", @"super", @"synchronized", @"throws", @"transient", @"volatile", @"null", @"true", @"false", @"nil",  nil];
        
        NSMutableDictionary *keywords = [NSMutableDictionary dictionary];
        
        for (NSString *word in blueWords) {
            [keywords setObject:[NSColor blueColor] forKey:word];
        }
        
        self.keywords = keywords;
        
    }
    
    NSString *someContent = @"Hello World!";
    NSString *path = @"/tmp/foo.txt";
    [[someContent dataUsingEncoding:NSUTF8StringEncoding] writeToFile:path atomically:YES];
    
    
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tokenizer release];
    _tokenizer = 0x00;
    
    [_keywords release];
    _keywords = 0x00;
    
    [_externalEditorFileWatcher release];
    _externalEditorFileWatcher = 0x00;
    
    [super dealloc];
}


- (NSString *)windowNibName {
    return @"JSTDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
    [super windowControllerDidLoadNib:aController];
    
    if ([self fileURL]) {
        
        NSError *err = 0x00;
        NSString *src = [NSString stringWithContentsOfURL:[self fileURL] encoding:NSUTF8StringEncoding error:&err];
        
        if (err) {
            NSBeep();
            NSLog(@"err: %@", err);
        }
        
        if (src) {
            [[[jsTextView textStorage] mutableString] setString:src];
        }
        
        [[aController window] setFrameAutosaveName:[self fileName]];
        [splitView setAutosaveName:[self fileName]];
    }
    
    // FIXME: make this a pref
    [[jsTextView textStorage] setAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Monaco" size:10] forKey:NSFontAttributeName] range:NSMakeRange(0, [[jsTextView textStorage] length]) ];
    
    lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:[jsTextView enclosingScrollView]];
    [[jsTextView enclosingScrollView] setVerticalRulerView:lineNumberView];
    [[jsTextView enclosingScrollView] setHasHorizontalRuler:NO];
    [[jsTextView enclosingScrollView] setHasVerticalRuler:YES];
    [[jsTextView enclosingScrollView] setRulersVisible:YES];
    
    [outputTextView setTypingAttributes:[jsTextView typingAttributes]];
    
    [[jsTextView textStorage] setDelegate:self];
    [self parseCode:nil];
    
    NSToolbar *toolbar  = [[[NSToolbar alloc] initWithIdentifier:@"JSTalkDocument"] autorelease];
    _toolbarItems       = [[NSMutableDictionary dictionary] retain];
    
    JSTAddToolbarItem(_toolbarItems, @"Run", @"Run", @"Run", @"Run the script", nil, @selector(setImage:), [NSImage imageNamed:@"Play.tiff"], @selector(executeScript:), nil);
    JSTAddToolbarItem(_toolbarItems, @"Clear", @"Clear", @"Clear", @"Clear the console", nil, @selector(setImage:), [NSImage imageNamed:@"Clear.tiff"], @selector(clearConsole:), nil);
    
    [toolbar setDelegate:self];
    [toolbar setAllowsUserCustomization:YES];
    [toolbar setAutosavesConfiguration:YES];
    
    [[splitView window] setToolbar:toolbar];
    
    [[splitView window] setContentBorderThickness:NSMinY([splitView frame]) forEdge:NSMinYEdge];
    
    [errorLabel setStringValue:@""];
    
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    
    NSData *d = [[[jsTextView textStorage] string] dataUsingEncoding:NSUTF8StringEncoding];
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
	return d;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    
    return YES;
}

- (void) print:(NSString*)s {
    [[[outputTextView textStorage] mutableString] appendFormat:@"%@\n", s];
}

- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url {
    
    lineNumber -= 1;
    
    if (!error) {
        return;
    }
    
    if (lineNumber < 0) {
        [errorLabel setStringValue:error];
    }
    else {
        [errorLabel setStringValue:[NSString stringWithFormat:@"Line %d, %@", lineNumber, error]];
        
        NSUInteger lineIdx = 0;
        NSRange lineRange  = NSMakeRange(0, 0);
        
        while (lineIdx < lineNumber) {
            
            lineRange = [[[jsTextView textStorage] string] lineRangeForRange:NSMakeRange(NSMaxRange(lineRange), 0)];
            lineIdx++;
        }
        
        if (lineRange.length) {
            [jsTextView showFindIndicatorForRange:lineRange];
        }
    }
}



//
// JSCocoa : handle setting with callMethod
//	object.width = 100
//	-> 
//	[object setWidth:100]
//
- (BOOL) JSCocoa:(JSCocoaController*)controller setProperty:(NSString*)propertyName ofObject:(id)object toValue:(JSValueRef)value inContext:(JSContextRef)ctx exception:(JSValueRef*)exception;
{
    // FIXME: this doesn't actually work with objc properties, and we can't always rely that this method will exist either...
    // it should probably be moved up into the JSCocoa layer.
    
	NSString*	setterName = [NSString stringWithFormat:@"set%@%@:", 
										[[propertyName substringWithRange:NSMakeRange(0,1)] capitalizedString], 
										[propertyName substringWithRange:NSMakeRange(1, [propertyName length]-1)]];
	
    if ([self JSCocoa:controller callMethod:setterName ofObject:object argumentCount:1 arguments:&value inContext:ctx exception:exception]) {
        return YES;
    }
	
    return	NO;
}

//
// NSDistantObject call using NSInvocation
//
- (JSValueRef) JSCocoa:(JSCocoaController*)controller callMethod:(NSString*)methodName ofObject:(id)callee argumentCount:(int)argumentCount arguments:(JSValueRef*)arguments inContext:(JSContextRef)ctx exception:(JSValueRef*)exception
{
    SEL selector = NSSelectorFromString(methodName);
	if (class_getInstanceMethod([callee class], selector) || class_getClassMethod([callee class], selector)) {
        return nil;
    }
    
    NSMethodSignature *signature = [callee methodSignatureForSelector:selector];
    
    if (!signature) {
        return nil;
    }
    
    // we need to do all this for NSDistantObject , since JSCocoa doesn't handle it natively.
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];

    NSUInteger argIndex = 0;
    while (argIndex < argumentCount) {
        
        id arg = 0x00;
        
        [JSCocoaFFIArgument unboxJSValueRef:arguments[argIndex] toObject:&arg inContext:ctx];
        
        if ([arg isKindOfClass:[NSNumber class]]) {
            
            const char *type = [signature getArgumentTypeAtIndex:argIndex + 2];
            
            if (strcmp(type, @encode(BOOL)) == 0) {
                BOOL b = [arg boolValue];
                [invocation setArgument:&b atIndex:argIndex + 2];
            }
            else if (strcmp(type, @encode(unsigned int)) == 0) {
                unsigned int i = [arg unsignedIntValue];
                [invocation setArgument:&i atIndex:argIndex + 2];
            }
            else if (strcmp(type, @encode(int)) == 0) {
                int i = [arg intValue];
                [invocation setArgument:&i atIndex:argIndex + 2];
            }
            else if (strcmp(type, @encode(unsigned long)) == 0) {
                unsigned long l = [arg unsignedLongValue];
                [invocation setArgument:&l atIndex:argIndex + 2];
            }
            else if (strcmp(type, @encode(long)) == 0) {
                long l = [arg longValue];
                [invocation setArgument:&l atIndex:argIndex + 2];
            }
            else if (strcmp(type, @encode(float)) == 0) {
                float f = [arg floatValue];
                [invocation setArgument:&f atIndex:argIndex + 2];
            }
            else if (strcmp(type, @encode(double)) == 0) {
                double d = [arg doubleValue];
                [invocation setArgument:&d atIndex:argIndex + 2];
            }
            else { // just do int for all else.
                int i = [arg intValue];
                [invocation setArgument:&i atIndex:argIndex + 2];
            }
            
        }
        else {
            [invocation setArgument:&arg atIndex:argIndex + 2];
        }
        
        argIndex++;
    }
    
    
    [invocation invokeWithTarget:callee];
    
    id result = 0x00;
    
    const char *type = [signature methodReturnType];
    
    if (strcmp(type, @encode(id)) == 0) {
        [invocation getReturnValue:&result];
    }
    
    if (!result) {
        return JSValueMakeNull(ctx);
    }
    
    JSValueRef	jsReturnValue = NULL;
    
    [JSCocoaFFIArgument boxObject:result toJSValueRef:&jsReturnValue inContext:ctx];
    
    return	jsReturnValue;
}



- (void) runScript:(NSString*)s {
    
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    JSCocoaController *jsController = [jstalk jsController];
    jsController.delegate = self;
    
    jstalk.printController = self;
    
    [errorLabel setStringValue:@""];
    
    if ([JSTPrefs boolForKey:@"clearConsoleOnRun"]) {
        [self clearConsole:nil];
    }
    
    [jstalk executeString:s];
}

- (void) executeScript:(id)sender { 
    [self runScript:[[jsTextView textStorage] string]];
}

- (void) clearConsole:(id)sender { 
    [[[outputTextView textStorage] mutableString] setString:@""];
}

- (void) executeSelectedScript:(id)sender {
    
    NSRange r = [jsTextView selectedRange];
    
    if (r.length == 0) {
        r = NSMakeRange(0, [[jsTextView textStorage] length]);
    }
    
    NSString *s = [[[jsTextView textStorage] string] substringWithRange:r];
    
    [self runScript:s];
    
}

- (void) textStorageDidProcessEditing:(NSNotification *)note {
    [self parseCode:nil];
}

- (void) preprocessCodeAction:(id)sender {
    
    NSString *code = [JSTPreprocessor preprocessCode:[[jsTextView textStorage] string]];
    
    [[[outputTextView textStorage] mutableString] setString:code];
}


- (void) parseCode:(id)sender {
    
    // we should really do substrings...
    
    NSString *sourceString = [[jsTextView textStorage] string];
    TDTokenizer *tokenizer = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.commentState.reportsCommentTokens = YES;
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    
    TDToken *eof = [TDToken EOFToken];
    TDToken *tok = nil;
    
    [[jsTextView textStorage] beginEditing];
    
    NSUInteger sourceLoc = 0;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        NSColor *fontColor = [NSColor blackColor];
    
        if (tok.quotedString) {
            fontColor = [NSColor darkGrayColor];
        }
        else if (tok.isNumber) {
            fontColor = [NSColor blueColor];
        }
        else if (tok.isComment) {
            fontColor = [NSColor redColor];
        }
        else if (tok.isWord) {
            NSColor *c = [_keywords objectForKey:[tok stringValue]];
            fontColor = c ? c : fontColor;
        }
            
        NSUInteger strLen = [[tok stringValue] length];
        
        if (fontColor) {
            [[jsTextView textStorage] addAttribute:NSForegroundColorAttributeName value:fontColor range:NSMakeRange(sourceLoc, strLen)];
        }
        
        sourceLoc += strLen;
    }
    
    
    [[jsTextView textStorage] endEditing];
    
}

- (void)savePanelDidEndForApplicationSave:(NSSavePanel *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    
    NSString *fileName = [sheet filename];
    if (!fileName) {
        return;
    }
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        if (![[NSFileManager defaultManager] removeFileAtPath:fileName handler:nil]) {
            NSRunAlertPanel(@"Could not remove file", @"Sorry, but I could not remove the old file in order to save your application.", @"OK", nil, nil);
            NSBeep();
            return;
        }
    }
    
    NSString *runnerPath = [[NSBundle mainBundle] pathForResource:@"JSTalkRunner" ofType:@"app"];
    
    if (![[NSFileManager defaultManager] copyPath:runnerPath toPath:fileName handler:nil]) {
        NSRunAlertPanel(@"Could not save", @"Sorry, but I could not save the application to the folder", @"OK", nil, nil);
        return;
    }
    
    NSString *sourcePath = [[[fileName stringByAppendingPathComponent:@"Contents"]
                                      stringByAppendingPathComponent:@"Resources"]
                                      stringByAppendingPathComponent:@"main.jstalk"];
    
    NSURL *sourceURL = [NSURL fileURLWithPath:sourcePath];
    NSError *err = 0x00;
    [[[jsTextView textStorage] string] writeToURL:sourceURL atomically:NO encoding:NSUTF8StringEncoding error:&err];
    
    if (err) {
        NSLog(@"err: %@", err);
    }
}

- (void) saveAsApplication:(id)sender {
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    NSString *appName = @"";
    
    if ([self lastComponentOfFileName]) {
        appName = [NSString stringWithFormat:@"%@.app", [[self lastComponentOfFileName] stringByDeletingPathExtension]];
    }
    
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"app"]];
    
    [savePanel beginSheetForDirectory:nil file:appName modalForWindow:[splitView window] modalDelegate:self didEndSelector:@selector(savePanelDidEndForApplicationSave:returnCode:contextInfo:) contextInfo:nil];
    
}

- (void) externalEditorAction:(id)sender {
    
    if (_externalEditorFileWatcher) {
        /// wait, what?  Should we care?
        [_externalEditorFileWatcher release];
        _externalEditorFileWatcher = 0x00;
    }
    
    if (![self fileURL]) {
        [self saveDocument:self];
        return;
    }
    
    [self saveDocument:self];
    
    /*
    // get a unique name for the file.
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *uuidString = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    [uuidString autorelease];
    
    // write it all out.
    NSString *fileName      = [NSString stringWithFormat:@"%@.jstalk", [uuidString lowercaseString]];
    NSString *fileLocation  = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
    NSURL *fileURL          = [NSURL fileURLWithPath:fileLocation];
    NSError *err            = 0x00;
    
    [[[jsTextView textStorage] string] writeToURL:fileURL atomically:YES encoding:NSUTF8StringEncoding error:&err];
    */
    
    // find our external editor to do some editing.
    NSString *externalEditorBundleId = [[NSUserDefaults standardUserDefaults] objectForKey:@"externalEditor"];
    NSString *appPath   = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:externalEditorBundleId];
    
    if (!appPath) {
        NSLog(@"Could not find the app path for %@", externalEditorBundleId);
        NSBeep();
        return;
    }
    
    // setup our watcher.
    self.externalEditorFileWatcher = [JSTFileWatcher fileWatcherWithPath:[self fileName] delegate:self];
    
    // and away we go.
    [[NSWorkspace sharedWorkspace] openFile:[self fileName] withApplication:appPath];
}

- (void) fileWatcherDidRecieveFSEvent:(JSTFileWatcher*)fw {
    
    NSString *path = [fw path];
    
    NSError *err = 0x00;
    NSString *src = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:&err];
    
    if (err) {
        NSBeep();
        NSLog(@"err: %@", err);
        return;
    }
    
    if (src) {
        [[[jsTextView textStorage] mutableString] setString:src];
    }
}


- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
     itemForItemIdentifier:(NSString *)itemIdentifier 
 willBeInsertedIntoToolbar:(BOOL)flag {
    
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    NSToolbarItem *newItem  = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
    NSToolbarItem *item     = [_toolbarItems objectForKey:itemIdentifier];
    
    [newItem setLabel:[item label]];
    [newItem setPaletteLabel:[item paletteLabel]];
    if ([item view]!=NULL) {
        [newItem setView:[item view]];
    }
    else {
        [newItem setImage:[item image]];
    }
    
    [newItem setToolTip:[item toolTip]];
    [newItem setTarget:[item target]];
    [newItem setAction:[item action]];
    [newItem setMenuFormRepresentation:[item menuFormRepresentation]];
    // If we have a custom view, we *have* to set the min/max size - otherwise, it'll default to 0,0 and the custom
    // view won't show up at all!  This doesn't affect toolbar items with images, however.
    if ([newItem view]!=NULL){
    	[newItem setMinSize:[[item view] bounds].size];
        [newItem setMaxSize:[[item view] bounds].size];
    }
    
    return newItem;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects: @"Run", @"Clear", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects: @"Run", @"Clear", NSToolbarSeparatorItemIdentifier, NSToolbarCustomizeToolbarItemIdentifier, NSToolbarSpaceItemIdentifier,NSToolbarFlexibleSpaceItemIdentifier, NSToolbarPrintItemIdentifier, nil];

}


@end



NSToolbarItem *JSTAddToolbarItem(NSMutableDictionary *theDict,
                              NSString *identifier,
                              NSString *label,
                              NSString *paletteLabel,
                              NSString *toolTip,
                              id target,
                              SEL settingSelector,
                              id itemContent,
                              SEL action, 
                              NSMenu * menu)
{
    NSMenuItem *mItem;
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    // the settingSelector parameter can either be @selector(setView:) or @selector(setImage:).  Pass in the right
    // one depending upon whether your NSToolbarItem will have a custom view or an image, respectively
    // (in the itemContent parameter).  Then this next line will do the right thing automatically.
    [item performSelector:settingSelector withObject:itemContent];
    [item setAction:action];
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it (for text-only mode),
    // we set it up here.  Actually, you have to hand an NSMenuItem (not a complete NSMenu) to the toolbar item,
    // so we create a dummy NSMenuItem that has our real menu as a submenu.
    if (menu!=NULL) {
        // we actually need an NSMenuItem here, so we construct one
        mItem=[[[NSMenuItem alloc] init] autorelease];
        [mItem setSubmenu: menu];
        [mItem setTitle:[menu title]];
        [item setMenuFormRepresentation:mItem];
    }
    // Now that we've setup all the settings for this new toolbar item, we add it to the dictionary.
    // The dictionary retains the toolbar item for us, which is why we could autorelease it when we created
    // it (above).
    [theDict setObject:item forKey:identifier];
    
    return item;
}





