//
//  JSTStructure.m
//  jstalk
//
//  Created by August Mueller on 10/13/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import "JSTStructure.h"
#import "TDTokenizer.h"
#import "TDToken.h"
#import "TDWhitespaceState.h"
#import "TDCommentState.h"
#import "JSTUtils.h"

@implementation JSTStructure
@synthesize bytes=_bytes;
@synthesize runtimeInfo=_runtimeInfo;
@synthesize bridge=_bridge;

- (id)initWithData:(NSMutableData*)data bridge:(JSTBridge*)bridge {
	self = [super init];
	if (self != nil) {
		[self setBytes:data];
        _bridge = bridge;
	}
	return self;
}

+ (id)structureWithData:(NSMutableData*)data bridge:(JSTBridge*)bridge {
    return [[[self alloc] initWithData:data bridge:bridge] autorelease];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_bytes release];
    [super dealloc];
}

- (JSTRuntimeInfo*)runtimeInfoForFieldAtIndex:(NSUInteger)idx getOffset:(int*)offset {
    
    NSString *info = [_runtimeInfo typeEncoding];
    // {CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}
    
    int fieldIndex              = 0;
    int bracketDepth            = 0;
    TDTokenizer *tokenizer      = [TDTokenizer tokenizerWithString:info];
    TDToken *eof                = [TDToken EOFToken];
    TDToken *tok                = nil;
    NSString *lastVal           = 0x00;
    JSTRuntimeInfo *returnInfo  = 0x00;
    
    while ((tok = [tokenizer nextToken]) != eof && !returnInfo) {
        NSString *val = [tok stringValue];
        
        if ([tok isWord] && [lastVal hasPrefix:@"\""]) {
            *offset += JSTSizeOfTypeEncoding(val);
        }
        else if ([tok isSymbol]) {
        
            if ([@"{" isEqualToString:val]) {
                bracketDepth++;
            }
            else if ([@"}" isEqualToString:val]) {
                bracketDepth--;
                
                if (bracketDepth == 1) {
                    fieldIndex++;
                }
            }
            else if ([@"=" isEqualToString:val] && (bracketDepth == 2) && idx == fieldIndex) {
                returnInfo = [JSTBridgeSupportLoader runtimeInfoForSymbol:lastVal];
            }
        }
        
        [lastVal release];
        lastVal = [val retain];
    }
    
    [lastVal release];
    
    return returnInfo;
}

- (NSString*)typeForFieldAtIndex:(NSUInteger)idx getOffset:(int*)offset {
    NSString *info = [_runtimeInfo typeEncoding];
    // '{CGSize="width"d"height"d}'
    
    TDTokenizer *tokenizer      = [TDTokenizer tokenizerWithString:info];
    TDToken *eof                = [TDToken EOFToken];
    TDToken *tok                = nil;
    NSString *lastVal           = 0x00;
    NSString *lookingFor        = [NSString stringWithFormat:@"\"%@\"", [[_runtimeInfo structFields] objectAtIndex:idx]];
    NSString *found             = 0x00;
    BOOL grabNextType           = NO;
    
    while ((tok = [tokenizer nextToken]) != eof) {
        NSString *val = [tok stringValue];
        
        if ([val isEqualToString:lookingFor]) {
            found = [[tokenizer nextToken] stringValue];
            break;
        }
        
        if ([tok isWord] && [lastVal hasPrefix:@"\""]) {
            *offset += JSTSizeOfTypeEncoding(val);
            
            if (grabNextType) {
                found = [val retain];
            }
        }
        
        [lastVal release];
        lastVal = [val retain];
    }
    
    [lastVal release];
    
    return found;
}



- (void*)bytesForFieldAtIndex:(NSUInteger)idx getTypeInfo:(NSString**)typeInfo {
    
    int offset = 0;
    
    *typeInfo = [self typeForFieldAtIndex:idx getOffset:&offset];
    
    void *foo = (void*)[_bytes bytes];
    foo += offset;
    
    return foo;
}

- (BOOL)setValue:(JSValueRef)value forFieldNamed:(NSString*)prop outException:(JSValueRef*)exception {
    
    if (!_runtimeInfo || ![[_runtimeInfo structFields] containsObject:prop]) {
        JSTAssignException(_bridge, exception, [NSString stringWithFormat:@"No field with name '%@'", prop]);
        return 0x00;
    }
    
    NSUInteger fieldIndex = [[_runtimeInfo structFields] indexOfObject:prop];
    
    NSString *typeInfo;
    void *foo = [self bytesForFieldAtIndex:fieldIndex getTypeInfo:&typeInfo];
    
    #warning move this stuff out to a general function
    
    if ([typeInfo isEqualToString:@"d"]) {
        
        *(double*)foo = JSValueToNumber([_bridge jsContext], value, nil);
        return YES;
    }
    else if ([typeInfo isEqualToString:@"Q"]) {
        *(unsigned long*)foo = (unsigned long)JSValueToNumber([_bridge jsContext], value, nil);
        return YES;
    }
    
    return NO;
}

- (JSValueRef)cantThinkOfAGoodNameForThisYet:(NSString*)prop outException:(JSValueRef*)exception {
    
    if (!_runtimeInfo || ![[_runtimeInfo structFields] containsObject:prop]) {
        JSTAssignException(_bridge, exception, [NSString stringWithFormat:@"No field with name '%@'", prop]);
        return 0x00;
    }
    
    NSUInteger fieldIndex = [[_runtimeInfo structFields] indexOfObject:prop];
    
    int offset = 0;
    JSTRuntimeInfo *fieldInfo = [self runtimeInfoForFieldAtIndex:fieldIndex getOffset:&offset];
    
    if (!fieldInfo) {
        // oh, it's a value I guess?
        NSString *typeInfo;
        NSInteger *foo2 = (NSInteger*)[self bytesForFieldAtIndex:fieldIndex getTypeInfo:&typeInfo];
        
        return JSTMakeJSValueWithFFITypeAndValue(JSTFFITypeForTypeEncoding(typeInfo), (void*)*foo2, _bridge);
    }
    
    NSData *newData = [NSData dataWithBytesNoCopy:((void*)[_bytes bytes] + offset)
                                           length:[_bytes length] - offset
                                     freeWhenDone:NO];
    
    JSTStructure *structure = [JSTStructure structureWithData:(id)newData bridge:_bridge];
    [structure setRuntimeInfo:fieldInfo];
    
    JSObjectRef retJS = [_bridge makeJSObjectWithNSObject:structure runtimeInfo:nil];
    
    return retJS;
}

@end
