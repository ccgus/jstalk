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

+ (NSString*) preprocessForObjCStrings:(NSString*)sourceString {
    
    NSMutableString *buffer = [NSMutableString string];
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    tokenizer.commentState.reportsCommentTokens = NO;
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = 0x00;
    TDToken *nextToken              = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        if (tok.isSymbol && [[tok stringValue] isEqualToString:@"@"]) {
            
            // woo, it's special objc stuff.
            
            nextToken = [tokenizer nextToken];
            if (nextToken.quotedString) {
                [buffer appendFormat:@"[NSString stringWithString:%@]", [nextToken stringValue]];
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

+ (BOOL) isOpenSymbol:(NSString*)tag {
    return [tag isEqualToString:@"["] || [tag isEqualToString:@"("];
}

+ (BOOL) isCloseSymbol:(NSString*)tag {
    return [tag isEqualToString:@"]"] || [tag isEqualToString:@")"];
}

+ (NSString*) preprocessForObjCMessagesToJS:(NSString*)sourceString {
    
    NSMutableString *buffer = [NSMutableString string];
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    tokenizer.commentState.reportsCommentTokens = YES;
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = nil;
    
    JSTPSymbolGroup *currentGroup   = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        //debug(@"tok: '%@' %d", [tok description], tok.word);
        
        if ([tok isSymbol] && [self isOpenSymbol:[tok stringValue]]) {
            
            JSTPSymbolGroup *nextGroup  = [[[JSTPSymbolGroup alloc] init] autorelease];
            
            nextGroup.parent            = currentGroup;
            currentGroup                = nextGroup;

        }
        else if (tok.isSymbol && [self isCloseSymbol:tok.stringValue]) {
            
            if (currentGroup.parent) {
                [currentGroup.parent addSymbol:currentGroup];
            }
            else {
                [buffer appendString:[currentGroup description]];
            }
            
            currentGroup = currentGroup.parent;
            
            continue;
        }
        
        if (currentGroup) {
            [currentGroup addSymbol:tok];
        }
        else {
            [buffer appendString:[tok stringValue]];
        }
    }
    
    return buffer;
}

+ (NSString*) preprocessCode:(NSString*)sourceString {
    
    sourceString = [self preprocessForObjCStrings:sourceString];
    sourceString = [self preprocessForObjCMessagesToJS:sourceString];
    
    return sourceString;
}

@end



@implementation JSTPSymbolGroup
@synthesize args=_args;
@synthesize parent=_parent;

- (id) init {
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

- (void) addSymbol:(id)aSymbol {
    
    if (!_openSymbol && [aSymbol isKindOfClass:[TDToken class]]) {
        _openSymbol = [[aSymbol stringValue] characterAtIndex:0];
    }
    else {
        [_args addObject:aSymbol];
    }
}

- (NSString*) description {
    
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
        
        if ([currentToken isWhitespace]) {
            continue;
        }
        
        if (!hadSymbolAsArg && [currentToken isSymbol]) {
            hadSymbolAsArg = YES;
        }
        
        NSString *value = currentToken ? [currentToken stringValue] : [currentPassedArg description];
        
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
    
    
    BOOL useMsgSend = NO;
    
    if (useMsgSend) {
        NSMutableString *ret = [NSMutableString stringWithFormat:@"jstalk_msgsend(%@, '%@'", target, selector];
        
        if ([methodArgs count]) {
            [ret appendString:@", "];
            [ret appendString:[methodArgs componentsJoinedByString:@", "]];
        }
        
        [ret appendString:@")"];
        
        return ret;
    }
    
    [selector replaceOccurrencesOfString:@":" withString:@"_" options:0 range:NSMakeRange(0, [selector length])];
    
    NSMutableString *ret = [NSMutableString stringWithFormat:@"%@.%@(", target, selector];
    
    if ([methodArgs count]) {
        [ret appendString:[methodArgs componentsJoinedByString:@", "]];
    }
    
    [ret appendString:@")"];
    
    return ret;
    
}

@end

