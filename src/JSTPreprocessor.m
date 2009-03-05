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

#warning var name = [NSFullUserName() lowercaseString]; fails

@implementation JSTPreprocessor

+ (NSString*) preprocessForObjCStrings:(NSString*)sourceString {
    
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

+ (NSString*) preprocessForObjCMessagesToJS:(NSString*)sourceString {
    
    NSMutableString *buffer = [NSMutableString string];
    TDTokenizer *tokenizer  = [TDTokenizer tokenizerWithString:sourceString];
    
    tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
    tokenizer.commentState.reportsCommentTokens = YES;
    
    TDToken *eof                    = [TDToken EOFToken];
    TDToken *tok                    = nil;
    TDToken *lastToken              = nil;
    BOOL lastWasWord                = NO;
    NSUInteger bracketCount         = 0;
    JSTPObjcCall *currentObjcCall   = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        
        if (tok.isSymbol && !lastWasWord && [tok.stringValue isEqualToString:@"["]) {
            
            tokenizer.whitespaceState.reportsWhitespaceTokens = NO;
            
            if (!bracketCount) {
                currentObjcCall = [[[JSTPObjcCall alloc] init] autorelease];
            }
            else {
                JSTPObjcCall *newobjc = [[[JSTPObjcCall alloc] init] autorelease];
                
                newobjc.parent = currentObjcCall;
                
                currentObjcCall = newobjc;
            }
            
            bracketCount++;
        }
        else if (bracketCount && tok.isSymbol && [tok.stringValue isEqualToString:@"]"]) {
            
            bracketCount--;
            
            if (!bracketCount) {
                // we're done!
                
                tokenizer.whitespaceState.reportsWhitespaceTokens = YES;
                
            }
            
            JSTPObjcCall *parent = currentObjcCall.parent;
            
            if (!parent) {
                [buffer appendString:[currentObjcCall description]];
            }
            else {
                [parent addSymbol:currentObjcCall];
            }
            
            currentObjcCall = parent;
            
        }
        else if (bracketCount) {
            [currentObjcCall addSymbol:[tok stringValue]];
        }
        else {
            [buffer appendString:[tok stringValue]];
        }
        
        lastWasWord = tok.isWord;
        
        lastToken = tok;
    }
    
    return buffer;
}


+ (NSString*) preprocessCode:(NSString*)sourceString {
    
    sourceString = [self preprocessForObjCStrings:sourceString];
    sourceString = [self preprocessForObjCMessagesToJS:sourceString];
    
    return sourceString;
}

@end




@implementation JSTPObjcCall
@synthesize args=_args;
@synthesize selector=_selector;
@synthesize target=_target;
@synthesize lastString=_lastString;
@synthesize currentArgument=_currentArgument;
@synthesize parent=_parent;

- (id) init {
	self = [super init];
	if (self != nil) {
		self.currentArgument = [NSMutableString string];
	}
	return self;
}


- (void)dealloc {
    [_args release];
    [_selector release];
    [_target release];
    [_lastString release];
    [_currentArgument release];
    [super dealloc];
}


- (void) addSymbol:(id)aSymbol {
    
    //debug(@"aSymbol: %@ (%@)", aSymbol, NSStringFromClass([aSymbol class]));
    
    // the first bit is always the target.
    if (!_target) {
        self.target = aSymbol;
        return;
    }
    
    // the second bit is the first part of the selector.
    if (!_selector) {
        self.selector = [NSMutableString stringWithString:aSymbol];
        return;
    }
    
    // be lazy about creating this guy
    if (!_args) {
        self.args = [NSMutableArray array];
    }
    
    if ([aSymbol isKindOfClass:[JSTPObjcCall class]]) {
        
        if ([_lastString length]) {
            //debug(@"adding %@ to current args", _lastString);
            [_currentArgument appendString:_lastString];
        }
        
        [_currentArgument appendString:[aSymbol description]];
        
        self.lastString = 0x00;
        
        return;
    }
    
    // sanity check.
    if (![aSymbol isKindOfClass:[NSString class]]) {
        // what in the heck...
        NSBeep();
        return;
    }
    
    // yay, it's part of our selector!  maybe?  what about "foo ? bar : xyz" ?  Yea, gotta fix that.
    if ([aSymbol isEqualToString:@":"]) {
        
        if ([_lastString length]) {
            [self.selector appendString:_lastString];
            self.lastString = 0x00;
        }
        
        [self.selector appendString:aSymbol];
        
        if ([_currentArgument length]) {
            [_args addObject:_currentArgument];
        }
        
        
        self.currentArgument = [NSMutableString string];
        
        return;
    }
    
    if ([aSymbol isEqualToString:@","]) {
        // vargs, meh.
        return;
    }
    
    if (_lastString) {
        [_currentArgument appendString:_lastString];
    }
    
    self.lastString = aSymbol;
}

- (NSString*) description {
    
    if ([_lastString length]) {
        [_currentArgument appendString:_lastString];
    }
    
    if ([_currentArgument length]) {
        [_args addObject:_currentArgument];
    }
    
    
    NSMutableString *ret = [NSMutableString string];
    
    NSString *method = [self.selector stringByReplacingOccurrencesOfString:@":" withString:@"_"];
    
    [ret appendFormat:@"%@.%@(", _target, method];
    
    for (id foo in _args) {
        [ret appendFormat:@"%@, ", [foo description]];
    }
    
    // get rid of the last comma
    if ([_args count]) {
        [ret deleteCharactersInRange:NSMakeRange([ret length] - 2 , 2)];
    }
    
    
    [ret appendString:@")"];
    
    return ret;
}


@end





