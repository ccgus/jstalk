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

+ (BOOL)isOpenSymbol:(NSString*)tag {
    return [tag isEqualToString:@"["] || [tag isEqualToString:@"("];
}

+ (BOOL)isCloseSymbol:(NSString*)tag {
    return [tag isEqualToString:@"]"] || [tag isEqualToString:@")"];
}

+ (NSString*)preprocessForObjCMessagesToJS:(NSString*)sourceString {
    
    NSMutableString *buffer = [NSMutableString string];
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    [[tokenizer whitespaceState] setReportsWhitespaceTokens:YES];
    [[tokenizer commentState] setReportsCommentTokens:YES];
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = 0x00;
    NSString *desc                  = 0x00;
    JSTPSymbolGroup *currentGroup   = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        if ([tok isSymbol] && [self isOpenSymbol:[tok stringValue]]) {
            
            JSTPSymbolGroup *nextGroup  = [[[JSTPSymbolGroup alloc] init] autorelease];
            
            nextGroup.parent            = currentGroup;
            currentGroup                = nextGroup;

        }
        else if ([tok isSymbol] && [self isCloseSymbol:[tok stringValue]]) {
            
            if ([currentGroup parent]) {
                [[currentGroup parent] addSymbol:currentGroup];
            }
            else if ((desc = [currentGroup description])) {
                [buffer appendString:desc];
            }
            
            currentGroup = currentGroup.parent;
            
            continue;
        }
        
        if (currentGroup) {
            [currentGroup addSymbol:tok];
        }
        else {
            NSString *v = [tok stringValue];
            
            if ([@"nil" isEqualToString:v]) {
                v = @"null";
            }
            
            [buffer appendString:v];
        }
    }
    
    return buffer;
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

- (void)addSymbol:(id)aSymbol {
    
    if (!_openSymbol && [aSymbol isKindOfClass:[TDToken class]]) {
        _openSymbol = [[aSymbol stringValue] characterAtIndex:0];
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

- (NSString*)descriptionThatSortOfWorks {
    
    NSUInteger argsCount = [_args count];
    
    if (_openSymbol == '(') {
        return [NSString stringWithFormat:@"(%@)", [_args componentsJoinedByString:@""]];
    }
    
    if (_openSymbol != '[') {
        return [NSString stringWithFormat:@"Bad JSTPSymbolGroup! %@", _args];
    }
    
    BOOL firstArgIsWord         = [_args count] && ([[_args objectAtIndex:0] isKindOfClass:[TDToken class]] && [[_args objectAtIndex:0] isWord]);
    BOOL firstArgIsSymbolGroup  = [_args count] && [[_args objectAtIndex:0] isKindOfClass:[JSTPSymbolGroup class]];
    
    // objc messages start with a word.  So, if it isn't- then let's just fling things back the way they were.
    if (!firstArgIsWord && !firstArgIsSymbolGroup) {
        return [NSString stringWithFormat:@"[%@]", [_args componentsJoinedByString:@""]];
    }
    
    
    NSMutableString *selector   = [NSMutableString string];
    NSMutableArray *currentArgs = [NSMutableArray array];
    NSMutableArray *methodArgs  = [NSMutableArray array];
    NSString *target            = [_args objectAtIndex:0];
    NSString *lastWord          = 0x00;
    BOOL hadSymbolAsArg         = NO;
    NSUInteger idx = 1;
    
    while (idx < argsCount) {
        
        id currentPassedArg = [_args objectAtIndex:idx++];
        
        TDToken *currentToken = [currentPassedArg isKindOfClass:[TDToken class]] ? currentPassedArg : 0x00;
        
        NSString *value = currentToken ? [currentToken stringValue] : [currentPassedArg description];
        
        if ([currentToken isWhitespace]) {
            //[currentArgs addObject:value];
            continue;
        }
        
        if (!hadSymbolAsArg && [currentToken isSymbol]) {
            hadSymbolAsArg = YES;
        }
        
        
        if ([@":" isEqualToString:value]) {
            
            [currentArgs removeLastObject];
            
            if ([currentArgs count]) {
                [methodArgs addObject:[currentArgs componentsJoinedByString:@" "]];
                [currentArgs removeAllObjects];
            }
            
            [selector appendString:lastWord];
            [selector appendString:value];
        }
        else {
            [currentArgs addObject:[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        
        lastWord = value;
    }
    
    
    if ([currentArgs count]) {
        [methodArgs addObject:[currentArgs componentsJoinedByString:@""]];
    }
    
    
    if (![selector length] && !hadSymbolAsArg && ([methodArgs count] == 1)) {
        [selector appendString:[methodArgs lastObject]];
        [methodArgs removeAllObjects];
    }
    
    if (![selector length] && [methodArgs count] == 1) {
        return [NSString stringWithFormat:@"[%@%@]", target, [methodArgs lastObject]];
    }
    
    if (![methodArgs count] && ![selector length]) {
        return [NSString stringWithFormat:@"[%@]", target];
    }
    
    if (![selector length] && lastWord) {
        [selector appendString:lastWord];
        [methodArgs removeLastObject];
    }
    
    
    BOOL useMsgSend = YES;
    
    if (useMsgSend) {
        NSMutableString *ret = [NSMutableString stringWithString:@"objc_msgSend"];
        
        [ret appendFormat:@"(%@, \"%@\"", target, selector];
        
        for (NSString *arg in methodArgs) {
            [ret appendFormat:@", %@", arg];
        }
        
        [ret appendString:@")"];
        
        return ret;
    }
    
    [selector replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [selector length])];
    
    NSMutableString *ret = [NSMutableString stringWithFormat:@"%@.%@(", target, selector];
    
    if ([self nonWhitespaceCountInArray:methodArgs]) {
        
        for (int i = 0; i < [methodArgs count]; i++) {
            
            NSString *arg = [methodArgs objectAtIndex:i];
            NSString *s = [arg description];
            NSString *t = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [ret appendString:s];
            
            if ([t length] && i < [methodArgs count] - 1) {
                [ret appendString:@","];
            }
        }
    }
    
    [ret appendString:@")"];
    
    return ret;
    
}

- (NSString*)description {
    
    NSUInteger argsCount = [_args count];
    
    if (_openSymbol == '(') {
        return [NSString stringWithFormat:@"(%@)", [_args componentsJoinedByString:@""]];
    }
    
    if (_openSymbol != '[') {
        return [NSString stringWithFormat:@"Bad JSTPSymbolGroup! %@", _args];
    }
    
    BOOL firstArgIsWord         = [_args count] && ([[_args objectAtIndex:0] isKindOfClass:[TDToken class]] && [[_args objectAtIndex:0] isWord]);
    BOOL firstArgIsSymbolGroup  = [_args count] && [[_args objectAtIndex:0] isKindOfClass:[JSTPSymbolGroup class]];
    
    // objc messages start with a word.  So, if it isn't- then let's just fling things back the way they were.
    if (!firstArgIsWord && !firstArgIsSymbolGroup) {
        return [NSString stringWithFormat:@"[%@]", [_args componentsJoinedByString:@""]];
    }
    
    if ([_args count] == 1) {
        return [NSString stringWithFormat:@"[%@]", [_args objectAtIndex:0]];
    }
    
    
    BOOL startedSelector      = NO;
    NSString *lastArg         = 0x00;
    NSMutableArray *fixedArgs = [NSMutableArray array];
    NSMutableString *selector = [NSMutableString string];
    NSString *preSelArg       = 0x00;
    
    id targetObj              = [_args objectAtIndex:0];
    NSString *target          = [targetObj isKindOfClass:[TDToken class]] ? [targetObj stringValue] : [targetObj description];
    
    NSUInteger idx            = 1;
    while (idx < argsCount) {
        id arg                  = [_args objectAtIndex:idx];
        TDToken *currentToken   = [arg isKindOfClass:[TDToken class]] ? arg : 0x00;
        
        NSString *s = currentToken ? [currentToken stringValue] : [arg description];
        s = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([s isEqualToString:@":"]) {
            [selector appendString:lastArg];
            [selector appendString:s];
            
            if (startedSelector) {
                [fixedArgs removeLastObject];
            }
            
            if (preSelArg == lastArg) {
                preSelArg = 0x00;
            }
            
            startedSelector = YES;
        }
        else if ([s length]) {
            
            if (startedSelector) {
                [fixedArgs addObject:s];
            }
            else if (!preSelArg) {
                preSelArg = s;
            }
        }
        
        lastArg = s;
        idx++;
    }
    
    if (!startedSelector) {
        
        for (id arg in _args) {
            
            TDToken *tok = [arg isKindOfClass:[TDToken class]] ? arg : 0x00;
            
            if ([tok isSymbol]) {
                // looks like an array of some sort then.
                return [NSString stringWithFormat:@"[%@]", [_args componentsJoinedByString:@""]];
            }
        }
        
        
    }
    
    
    
    if (!startedSelector) {
        selector = (id)lastArg;
        if (selector == preSelArg) {
            preSelArg = 0x00;
        }
    }
    
    debug(@"selector: '%@'", selector);
    debug(@"_args: '%@'", _args);
    
    /*
    if (![selector length] && [methodArgs count] == 1) {
        return [NSString stringWithFormat:@"[%@%@]", target, [methodArgs lastObject]];
    }
    */
    
    
    
    
    
    debug(@"selector: '%@'", selector);
    
    NSMutableString *ret = [NSMutableString stringWithString:@"objc_msgSend"];
    
    [ret appendFormat:@"(%@%@, \"%@\"", target, preSelArg ? preSelArg : @"", selector];
    
    for (NSString *arg in fixedArgs) {
        
        NSString *f = [arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([f length]) {
            [ret appendFormat:@", %@", arg];
        }
    }
    
    [ret appendString:@")"];
    
    debug(@"ret: '%@'", ret);
    
    return ret;
    
    #warning this is completely fucked:
    /*
[NSApp a:1 fake:function() {
    [someClass runBlock:[NSApp blockForJSFunction:function(err) {
        var foo = Foo();
    }]];
}];
*/

}

- (NSString*)descriptionOld {
    
    NSUInteger argsCount = [_args count];
    
    if (_openSymbol == '(') {
        return [NSString stringWithFormat:@"(%@)", [_args componentsJoinedByString:@""]];
    }
    
    if (_openSymbol != '[') {
        return [NSString stringWithFormat:@"Bad JSTPSymbolGroup! %@", _args];
    }
    
    BOOL firstArgIsWord         = [_args count] && ([[_args objectAtIndex:0] isKindOfClass:[TDToken class]] && [[_args objectAtIndex:0] isWord]);
    BOOL firstArgIsSymbolGroup  = [_args count] && [[_args objectAtIndex:0] isKindOfClass:[JSTPSymbolGroup class]];
    
    // objc messages start with a word.  So, if it isn't- then let's just fling things back the way they were.
    if (!firstArgIsWord && !firstArgIsSymbolGroup) {
        return [NSString stringWithFormat:@"[%@]", [_args componentsJoinedByString:@""]];
    }
    
    NSMutableString *selector   = [NSMutableString string];
    NSMutableArray *currentArgs = [NSMutableArray array];
    NSMutableArray *methodArgs  = [NSMutableArray array];
    NSString *target            = [_args objectAtIndex:0];
    NSString *lastWord          = 0x00;
    BOOL hadSymbolAsArg         = NO;
    NSUInteger idx = 1;
    
    while (idx < argsCount) {
        
        id currentPassedArg = [_args objectAtIndex:idx++];
        
        TDToken *currentToken = [currentPassedArg isKindOfClass:[TDToken class]] ? currentPassedArg : 0x00;
        
        NSString *value = currentToken ? [currentToken stringValue] : [currentPassedArg description];
        
        if ([currentToken isWhitespace]) {
            [currentArgs addObject:value];
            continue;
        }
        
        if (!hadSymbolAsArg && [currentToken isSymbol]) {
            hadSymbolAsArg = YES;
        }
        
        if ([@":" isEqualToString:value]) {
            
            [currentArgs removeLastObject];
            
            if ([currentArgs count]) {
                [methodArgs addObject:[currentArgs componentsJoinedByString:@" "]];
                [currentArgs removeAllObjects];
            }
            
            [selector appendString:lastWord];
            [selector appendString:value];
        }
        else {
            [currentArgs addObject:[value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
        }
        
        lastWord = value;
    }
    
    if ([currentArgs count]) {
        [methodArgs addObject:[currentArgs componentsJoinedByString:@""]];
    }
    
    if (![selector length] && !hadSymbolAsArg && ([methodArgs count] == 1)) {
        [selector appendString:[methodArgs lastObject]];
        [methodArgs removeAllObjects];
    }
    
    if (![selector length] && [methodArgs count] == 1) {
        return [NSString stringWithFormat:@"[%@%@]", target, [methodArgs lastObject]];
    }
    
    if (![methodArgs count] && ![selector length]) {
        return [NSString stringWithFormat:@"[%@]", target];
    }
    
    if (![selector length] && lastWord) {
        [selector appendString:lastWord];
        [methodArgs removeLastObject];
    }
    
    
    [selector replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [selector length])];
    
    NSMutableString *ret = [NSMutableString stringWithFormat:@"%@.%@(", target, selector];
    
    if ([self nonWhitespaceCountInArray:methodArgs]) {
        
        for (int i = 0; i < [methodArgs count]; i++) {
            
            NSString *arg = [methodArgs objectAtIndex:i];
            NSString *s = [arg description];
            NSString *t = [s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            [ret appendString:s];
            
            if ([t length] && i < [methodArgs count] - 1) {
                [ret appendString:@","];
            }
        }
    }
    
    [ret appendString:@")"];
    
    return ret;
    
}

@end

