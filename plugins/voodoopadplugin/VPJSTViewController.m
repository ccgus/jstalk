//
//  VPJSTViewController.m
//  VPJSTalkPlugin
//
//  Created by August Mueller on 10/12/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "VPJSTViewController.h"
#import "JavaScriptPluginEnabler.h"
#import "MarkerLineNumberView.h"
#import <JSTalk/JSTalk.h>

const NSString *kUTTypeJSTalkSource = @"org.jstalk.jstalk-source";

@implementation VPJSTViewController

+ (void) load {
    [VPItemController registerItemControllerClass:self];
}

+ (BOOL) canHandleItemWithUTI:(NSString*)uti {
    
    if (UTTypeConformsTo((CFStringRef)uti, (CFStringRef)kUTTypeJSTalkSource)) {
        return YES;
    }
    
    return NO;
}

+ (VPItemController*) itemController {
    
    VPJSTViewController *newController = [[[VPJSTViewController alloc] initWithNibName:@"JSTalkEditView" bundle:[NSBundle bundleForClass:self]] autorelease];
    [newController loadView];
    
    return newController;
}

+ (NSString*) newItemDescription {
    return NSLocalizedString(@"JSTalk Source",  @"JSTalk Source");
}

+ (NSString*) defaultUTI {
    return (NSString*)kUTTypeJSTalkSource;
}

+ (NSData*) defaultDataForItemWithDisplayName:(NSString*)displayName contextInfo:(NSDictionary*) contextInfo {
    
    NSString *s = [NSString stringWithFormat:@"print(\"Hello %@\");", displayName];
    
    return [s dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_tokenizer autorelease];
    _tokenizer = 0x00;
    
    [super dealloc];
}

- (void)awakeFromNib {
    
}

- (void) close {
    [super close];
}

- (void)setItem:(id<VPData>)newItem {
    
    [super setItem:newItem];
    
    NSData *textData = [[self item] data];
    
    NSString *text = [[NSString alloc] initWithData:textData encoding:NSUTF8StringEncoding];
    
    if (text) {
        [[[textView textStorage] mutableString] setString:text];
    }
    
    // FIXME: make this a pref
    [[textView textStorage] setAttributes:[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Monaco" size:10] forKey:NSFontAttributeName] range:NSMakeRange(0, [[textView textStorage] length]) ];
    
    lineNumberView = [[MarkerLineNumberView alloc] initWithScrollView:[textView enclosingScrollView]];
    [[textView enclosingScrollView] setVerticalRulerView:lineNumberView];
    [[textView enclosingScrollView] setHasHorizontalRuler:NO];
    [[textView enclosingScrollView] setHasVerticalRuler:YES];
    [[textView enclosingScrollView] setRulersVisible:YES];
    
    [[textView textStorage] setDelegate:self];
    [self parseCode:nil];
}

- (NSData*) dataRepresentation {
    
    NSString *text = [[textView textStorage] mutableString];
    
    return [text dataUsingEncoding:NSUTF8StringEncoding];
}

- (JSTTextView*)textView {
    // VPWindowController will call this guy.
    return textView;
}

- (BOOL) isDirty {
    return [[[[[self view] window] windowController] document] isDocumentEdited];
}

- (void) executeScript:(id)sender {
    [JavaScriptPluginEnablerGlobalHACKHACKHACK handleRunAsJavaScript:[[[self view] window] windowController]];
}

- (void) textStorageDidProcessEditing:(NSNotification *)note {
    [self parseCode:nil];
}



- (void) parseCode:(id)sender {
    
    // we should really do substrings...
    
    NSString *sourceString = [[textView textStorage] string];
    TDTokenizer *tokenizer = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.commentState.reportsCommentTokens = YES;
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    
    TDToken *eof = [TDToken EOFToken];
    TDToken *tok = nil;
    
    [[textView textStorage] beginEditing];
    
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
            [[textView textStorage] addAttribute:NSForegroundColorAttributeName value:fontColor range:NSMakeRange(sourceLoc, strLen)];
        }
        
        sourceLoc += strLen;
    }
    
    
    [[textView textStorage] endEditing];
    
}


@end
