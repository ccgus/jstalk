//
//  JSTTextView.m
//  jstalk
//
//  Created by August Mueller on 1/18/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTTextView.h"


@implementation JSTTextView

- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textViewDidChangeSelection:) name:NSTextViewDidChangeSelectionNotification object:self];
}

- (void) insertTab:(id)sender {
    [self insertText:@"    "];
}


- (void) insertNewline:(id)sender {
    
    [super insertNewline:sender];
    
    NSRange r = [self selectedRange];
    if (r.location > 0) {
        r.location --;
    }
    
    r = [self selectionRangeForProposedRange:r granularity:NSSelectByParagraph];
    
    NSString *previousLine = [[[self textStorage] mutableString] substringWithRange:r];
    
    int j = 0;
    
    while (j < [previousLine length] && ([previousLine characterAtIndex:j] == ' ' || [previousLine characterAtIndex:j] == '\t')) {
        j++;
    }
    
    if (j > 0) {
        NSString *foo = [[[self textStorage] mutableString] substringWithRange:NSMakeRange(r.location, j)];
        [self insertText:foo];
    }
}







enum {
    OpeningLatinQuoteCharacter = 0x00AB,
    ClosingLatinQuoteCharacter = 0x00BB,
};

static NSString *defaultOpeningBraces = @"{[(";
static NSString *defaultClosingBraces = @"}])";

static NSString *openingBraces = nil;
static NSString *closingBraces = nil;

#define NUM_BRACE_PAIRS ([openingBraces length])

static void initBraces() {
    if (!openingBraces) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *defStr;
        
        defStr = [defaults objectForKey:@"TEOpeningBracesCharacters"];
        if (defStr) {
            openingBraces = [defStr retain];
            defStr = [defaults objectForKey:@"TEClosingBracesCharacters"];
            closingBraces = [defStr retain];
            if (!closingBraces || ([openingBraces length] != [closingBraces length])) {
                NSLog(@"TextExtras: Values for user defaults keys TEOpeningBracesCharacters and TEClosingBracesCharacters must both be present and the same length if either one is set.");
                [openingBraces release];
                openingBraces = nil;
                [closingBraces release];
                closingBraces = nil;
            }
        }
        
        if (!openingBraces) {
            unichar charBuf[100];
            unsigned defLen;
            
            defLen = [defaultOpeningBraces length];
            [defaultOpeningBraces getCharacters:charBuf];
            charBuf[defLen++] = OpeningLatinQuoteCharacter;
            openingBraces = [[NSMutableString allocWithZone:NULL] initWithCharacters:charBuf length:defLen];
            
            defLen = [defaultClosingBraces length];
            [defaultClosingBraces getCharacters:charBuf];
            charBuf[defLen++] = ClosingLatinQuoteCharacter;
            closingBraces = [[NSMutableString allocWithZone:NULL] initWithCharacters:charBuf length:defLen];
        }
    }
}

unichar TE_matchingDelimiter(unichar delimiter) {
    // This is not very efficient or anything, but the list of delimiters is expected to be quite short.
    unsigned i, c;
    
    initBraces();
    
    c = NUM_BRACE_PAIRS;
    for (i=0; i<c; i++) {
        if (delimiter == [openingBraces characterAtIndex:i]) {
            return [closingBraces characterAtIndex:i];
        }
        if (delimiter == [closingBraces characterAtIndex:i]) {
            return [openingBraces characterAtIndex:i];
        }
    }
    return (unichar)0;
}

BOOL TE_isOpeningBrace(unichar delimiter) {
    // This is not very efficient or anything, but the list of delimiters is expected to be quite short.
    unsigned i, c = NUM_BRACE_PAIRS;
    
    initBraces();
    
    for (i=0; i<c; i++) {
        if (delimiter == [openingBraces characterAtIndex:i]) {
            return YES;
        }
    }
    return NO;
}

BOOL TE_isClosingBrace(unichar delimiter) {
    // This is not very efficient or anything, but the list of delimiters is expected to be quite short.
    unsigned i, c = NUM_BRACE_PAIRS;
    
    initBraces();
    
    for (i=0; i<c; i++) {
        if (delimiter == [closingBraces characterAtIndex:i]) {
            return YES;
        }
    }
    return NO;
}

#define STACK_DEPTH 100
#define BUFF_SIZE 512

NSRange TE_findMatchingBraceForRangeInString(NSRange origRange, NSString *string) {
    // Note that this delimiter matching does not treat delimiters inside comments and quoted delimiters specially at all.
    NSRange matchRange = NSMakeRange(NSNotFound, 0);
    unichar selChar = [string characterAtIndex:origRange.location];
    BOOL backwards;
    
    // Figure out if we're doing anything and which direction to do it in...
    if (TE_isOpeningBrace(selChar)) {
        backwards = NO;
    } else if (TE_isClosingBrace(selChar)) {
        backwards = YES;
    } else {
        return matchRange;
    }
    
    {
        unichar delimiterStack[STACK_DEPTH];
        unsigned stackCount = 0;
        NSRange searchRange, buffRange;
        unichar buff[BUFF_SIZE];
        int i;
        BOOL done = NO;
        BOOL push = NO, pop = NO;
        
        delimiterStack[stackCount++] = selChar;
        
        if (backwards) {
            searchRange = NSMakeRange(0, origRange.location);
        } else {
            searchRange = NSMakeRange(NSMaxRange(origRange), [string length] - NSMaxRange(origRange));
        }
        // This loops over all the characters in searchRange, going either backwards or forwards.
        while ((searchRange.length > 0) && !done) {
            // Fill the buffer with a chunk of the searchRange
            if (searchRange.length <= BUFF_SIZE) {
                buffRange = searchRange;
            } else {
                if (backwards) {
                    buffRange = NSMakeRange(NSMaxRange(searchRange) - BUFF_SIZE, BUFF_SIZE);
                } else {
                    buffRange = NSMakeRange(searchRange.location, BUFF_SIZE);
                }
            }
            [string getCharacters:buff range:buffRange];
            
            // This loops over all the characters in buffRange, going either backwards or forwards.
            for (i = (backwards ? (buffRange.length - 1) : 0); (!done && (backwards ? (i >= 0) : (i < buffRange.length))); (backwards ? i-- : i++)) {
                // Figure out if we need to push or pop the stack.
                if (backwards) {
                    push = TE_isClosingBrace(buff[i]);
                    pop = TE_isOpeningBrace(buff[i]);
                } else {
                    push = TE_isOpeningBrace(buff[i]);
                    pop = TE_isClosingBrace(buff[i]);
                }
                
                // Now do the push or pop, if any
                if (pop) {
                    if (delimiterStack[--stackCount] != TE_matchingDelimiter(buff[i])) {
                        // Might want to beep here?
                        done = YES;
                    } else if (stackCount == 0) {
                        matchRange = NSMakeRange(buffRange.location + i, 1);
                        done = YES;
                    }
                } else if (push) {
                    if (stackCount < STACK_DEPTH) {
                        delimiterStack[stackCount++] = buff[i];
                    } else {
                        NSLog(@"TextExtras: Exhausted stack depth for delimiter matching.  Giving up.");
                        done = YES;
                    }
                }
            }
            
            // Remove the buffRange from the searchRange.
            if (!backwards) {
                searchRange.location += buffRange.length;
            }
            searchRange.length -= buffRange.length;
        }
    }
    
    return matchRange;
}



- (void)textViewDidChangeSelection:(NSNotification *)notification {
    NSTextView *textView = [notification object];
    NSRange selRange = [textView selectedRange];
    //TEPreferencesController *prefs = [TEPreferencesController sharedPreferencesController];
    
    //if ([prefs selectToMatchingBrace]) {
    if (YES) {
        // The NSTextViewDidChangeSelectionNotification is sent before the selection granularity is set.  Therefore we can't tell a double-click by examining the granularity.  Fortunately there's another way.  The mouse-up event that ended the selection is still the current event for the app.  We'll check that instead.  Perhaps, in an ideal world, after checking the length we'd do this instead: ([textView selectionGranularity] == NSSelectByWord).
        if ((selRange.length == 1) && ([[NSApp currentEvent] type] == NSLeftMouseUp) && ([[NSApp currentEvent] clickCount] == 2)) {
            NSRange matchRange = TE_findMatchingBraceForRangeInString(selRange, [textView string]);
            
            if (matchRange.location != NSNotFound) {
                selRange = NSUnionRange(selRange, matchRange);
                [textView setSelectedRange:selRange];
                [textView scrollRangeToVisible:matchRange];
            }
        }
    }
    
    //if ([prefs showMatchingBrace]) {
    if (YES) {
        NSRange oldSelRangePtr;
        
        [[[notification userInfo] objectForKey:@"NSOldSelectedCharacterRange"] getValue:&oldSelRangePtr];
        
        // This test will catch typing sel changes, also it will catch right arrow sel changes, which I guess we can live with.  MF:??? Maybe we should catch left arrow changes too for consistency...
        if ((selRange.length == 0) && (selRange.location > 0) && ([[NSApp currentEvent] type] == NSKeyDown) && (oldSelRangePtr.location == selRange.location - 1)) {
            NSRange origRange = NSMakeRange(selRange.location - 1, 1);
            unichar origChar = [[textView string] characterAtIndex:origRange.location];
            
            if (TE_isClosingBrace(origChar)) {
                NSRange matchRange = TE_findMatchingBraceForRangeInString(origRange, [textView string]);
                if (matchRange.location != NSNotFound) {
                    [self showFindIndicatorForRange:matchRange];
                }
            }
        }
    }
}





@end

// stolen from NSTextStorage_TETextExtras.m
@implementation NSTextStorage (TETextExtras)

- (BOOL)_usesProgrammingLanguageBreaks {
    return YES;
}
@end
