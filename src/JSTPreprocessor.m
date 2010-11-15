//
//  JSTPreprocessor.m
//  jstalk
//
//  Created by August Mueller on 2/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTPreprocessor.h"
#import "TDTokenizer.h"
#import "TDToken.h"
#import "TDWhitespaceState.h"
#import "TDCommentState.h"

@implementation JSTPreprocessor

+ (NSString*)processMultilineStrings:(NSString*)sourceString {
    
    NSString *tok = @"\"\"\"";
    
    NSScanner *scanner = [NSScanner scannerWithString:sourceString];
    NSMutableString *ret = [NSMutableString string];
    
    while (![scanner isAtEnd]) {
        
        NSString *into;
        NSString *quot;
        
        if ([scanner scanUpToString:tok intoString:&into]) {
            [ret appendString:into];
        }
        
        
        if ([scanner scanString:tok intoString:nil]) {
            if ([scanner scanString:tok intoString: nil]) {
                continue;
            }
            else if ([scanner scanUpToString:tok intoString:&quot] && [scanner scanString:tok intoString: nil]) {
                
                quot = [quot stringByReplacingOccurrencesOfString:@"\r\n" withString:@"\n"];
                quot = [quot stringByReplacingOccurrencesOfString:@"\r" withString:@"\n"];
                
                [ret appendString:@"\""];
                
                NSArray *lines = [quot componentsSeparatedByString:@"\n"];
                int i = 0;
                while (i < [lines count] - 1) {
                    NSString *line = [lines objectAtIndex:i];
                    line = [line stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                    [ret appendFormat:@"%@\\n", line];
                    i++;
                }
                
                NSString *line = [lines objectAtIndex:i];
                line = [line stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
                [ret appendFormat:@"%@\"", line];
            }
        }
    }
    
    return ret;
}

+ (NSString*)preprocessForObjCStrings:(NSString*)sourceString {
    
    NSMutableString *buffer = [NSMutableString string];
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    tokenizer.commentState.reportsCommentTokens = YES;
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = 0x00;
    TDToken *nextToken              = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        if (tok.isSymbol && [[tok stringValue] isEqualToString:@"@"]) {
            
            // woo, it's special objc stuff.
            
            nextToken = [tokenizer nextToken];
            if (nextToken.quotedString) {
                //[buffer appendFormat:@"[NSString stringWithString:%@]", [nextToken stringValue]];
                [buffer appendFormat:@"JSTNSString(%@)", [nextToken stringValue]];
            }
            else {
                [buffer appendString:[tok stringValue]];
                [buffer appendString:[nextToken stringValue]];
            }
        }
        else {
            [buffer appendString:[tok stringValue]];
        }
    }
    
    return buffer;
}

+ (BOOL)isOpenGroupSymbol:(NSString*)tag {
    return [tag isEqualToString:@"["] || [tag isEqualToString:@"("] || [tag isEqualToString:@"{"];
}

+ (BOOL)isCloseGroupSymbol:(NSString*)tag {
    return [tag isEqualToString:@"]"] || [tag isEqualToString:@")"] || [tag isEqualToString:@"}"];
}

+ (NSString*)preprocessForObjCMessagesToJS:(NSString*)sourceString {
    
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    [[tokenizer whitespaceState] setReportsWhitespaceTokens:YES];
    [[tokenizer commentState] setReportsCommentTokens:YES];
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = 0x00;
    JSTPSymbolGroup *baseGroup      = [[JSTPSymbolGroup alloc] init];
    JSTPSymbolGroup *currentGroup   = baseGroup;
    [baseGroup setIsBaseGroup:YES];
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        
        if ([tok isSymbol] && [self isOpenGroupSymbol:[tok stringValue]]) {
            
            JSTPSymbolGroup *nextGroup  = [[[JSTPSymbolGroup alloc] init] autorelease];
            
            nextGroup.parent            = currentGroup;
            currentGroup                = nextGroup;
        }
        else if ([tok isSymbol] && [self isCloseGroupSymbol:[tok stringValue]]) {
            
            [currentGroup addSymbol:tok];
            
            [[currentGroup parent] addSymbol:currentGroup];
            
            currentGroup = [currentGroup parent];
            
            continue;
        }
        
        NSString *v = [tok stringValue];
        
        if ([@"nil" isEqualToString:v]) {
            [currentGroup addSymbol:@"null"];
        }
        else {
            [currentGroup addSymbol:tok];
        }
    }
    
    return [baseGroup description];
}

+ (NSString*)preprocessCode:(NSString*)sourceString {
    
    sourceString = [self processMultilineStrings:sourceString];
    sourceString = [self preprocessForObjCStrings:sourceString];
    sourceString = [self preprocessForObjCMessagesToJS:sourceString];
    
    return sourceString;
}

@end



@implementation JSTPSymbolGroup
@synthesize args=_args;
@synthesize parent=_parent;
@synthesize isBaseGroup=_isBaseGroup;

- (id)init {
	self = [super init];
	if (self != nil) {
		_args = [[NSMutableArray array] retain];
	}
    
	return self;
}


- (void)dealloc {
    [_args release];
    [_parent release];

    [super dealloc];
}


- (id)lastNonWhitespaceOrCommentSymbol {
    
    NSUInteger i = [_args count];
    
    while (i) {
        i--;
        id sym = [_args objectAtIndex:i];
        
        if ([sym isKindOfClass:[TDToken class]] && ([sym isWhitespace] || [sym isComment])) {
            continue;
        }
        
        return sym;
    }
    
    return 0x00;
}

- (void)removeUpToToken:(id)tok {
    
    NSUInteger i = [_args count];
    
    while (i) {
        i--;
        id sym = [_args objectAtIndex:i];
        [_args removeObjectAtIndex:i];
        
        if (sym == tok) {
            break;
        }
    }
}

- (void)addSymbol:(id)aSymbol {
    
    if (!_isBaseGroup && !_openSymbol && [aSymbol isKindOfClass:[TDToken class]]) {
        _openSymbol = [[aSymbol stringValue] characterAtIndex:0];
        
        if (_openSymbol == '(') {
            id foo = [[self parent] lastNonWhitespaceOrCommentSymbol];
            [_args addObject:foo];
            [[self parent] removeUpToToken:foo];
        }
        else if (_openSymbol == '[') {
            // whoa- are we array access, or something else?
            
            id foo = [[self parent] lastNonWhitespaceOrCommentSymbol];
            
            if (!foo || [foo isKindOfClass:[TDToken class]] && [foo isSymbol]) {
                _msgSend = YES;
            }
        }
        else if (_openSymbol == '{') {
            
            id foo = [[self parent] lastNonWhitespaceOrCommentSymbol];
            
            if ([[foo description] hasSuffix:@")"]) {
                // looks to be a function() { return 1; } kind of thing.
                [_args addObject:foo];
                [[self parent] removeUpToToken:foo];
            }
        }
        
        [_args addObject:aSymbol];
    }
    else {
        [_args addObject:aSymbol];
    }
}

- (int)nonWhitespaceCountInArray:(NSArray*)ar {
    
    int count = 0;
    
    for (id f in ar) {
        
        f = [[f description] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([f length]) {
            count++;
        }
    } 
    
    return count;
}

- (id)firstNonWhitespaceObjectInArray:(NSArray*)ar startIndex:(NSUInteger)idx {
    
    for (; idx < [ar count]; idx++) {
        
        id f = [ar objectAtIndex:idx];
        
        if ([f isKindOfClass:[TDToken class]] && !([f isWhitespace] || [f isComment])) {
            return f;
        }
    }
    
    return 0x00;
    
}

- (NSString*)description {
    
    if (_openSymbol != '[') {
        
        NSMutableString *ret = [NSMutableString string];
        
        for (id arg in _args) {
            [ret appendString:[arg description]];
        }
        
        return ret;
        
    }
    
    if (!_msgSend || ![[[_args lastObject] description] isEqualToString:@"]"] || ([_args count] < 4)) {
        return [_args componentsJoinedByString:@""];
    }
    
    NSMutableArray *argsCopy = [[_args mutableCopy] autorelease];
    
    [argsCopy removeObjectAtIndex:0];
    [argsCopy removeObjectAtIndex:[argsCopy count] - 1];
    
    
    // let's make our selector.
    
    NSString *selectorWasHere   = @"THIS DOESN'T REALLY MATTER WHAT THE TEXT SAYS (chocklock) WE'RE JUST COMPARING POINTERS ANYWAY";
    NSMutableString *selector   = [NSMutableString string];
    NSMutableArray *msgSendArgs = [NSMutableArray array];
    
    for (id arg in argsCopy) {
        
        if ([arg isKindOfClass:[TDToken class]] && [arg isSymbol] && [[arg stringValue] isEqualToString:@":"]) {
            [selector appendFormat:@"%@:", [msgSendArgs objectAtIndex:[msgSendArgs count] -1]];
            [msgSendArgs replaceObjectAtIndex:[msgSendArgs count] - 1 withObject:selectorWasHere];
        }
        else {
            [msgSendArgs addObject:arg];
        }
    }
    
    id target = [[[msgSendArgs objectAtIndex:0] retain] autorelease];
    
    if (![selector length] && [self nonWhitespaceCountInArray:argsCopy] == 2) {
        selector = [self firstNonWhitespaceObjectInArray:msgSendArgs startIndex:1];
        [msgSendArgs removeAllObjects];
    }
    
    NSMutableString *buf = [NSMutableString stringWithString:@"objc_msgSend("];
    
    [buf appendFormat:@"%@, \"%@\"", target, selector];
    
    for (int i = 1; i < [msgSendArgs count]; i++) {
        
        id arg = [msgSendArgs objectAtIndex:i];
        
        if ([arg isKindOfClass:[TDToken class]] && ([arg isComment] || [arg isWhitespace])) {
            /*
            if ([arg isComment]) {
                [buf appendString:[arg stringValue]];
            }
            */
        }
        else {
            
            if ([arg isKindOfClass:[TDToken class]] && [[arg stringValue] isEqualToString:@","]) {
                
                if (![selector length]) { // looks like it's an array: print([3+4, 5]);
                    return [NSString stringWithFormat:@"[%@]", [argsCopy componentsJoinedByString:@""]];
                }
            }
            
            if (arg == selectorWasHere) {
                [buf appendString:@", "];
            }
            else {
                [buf appendString:[arg description]];
            }
        }
    }
    
    [buf appendString:@")"];
    
    return buf;
}


@end

