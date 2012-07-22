//
//  MOBridgeSupportSymbol.m
//  Mocha
//
//  Created by Logan Collins on 5/11/12.
//  Copyright (c) 2012 Sunflower Softworks. All rights reserved.
//

#import "MOBridgeSupportSymbol.h"


@implementation MOBridgeSupportSymbol

@synthesize name=_name;

- (void)dealloc {
	[_name release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportStruct

@synthesize type=_type;
@synthesize type64=_type64;
@synthesize opaque=_opaque;

- (void)dealloc {
	[_type release];
	[_type64 release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportCFType

@synthesize type=_type;
@synthesize type64=_type64;

@synthesize tollFreeBridgedClassName=_tollFreeBridgedClassName;
@synthesize getTypeIDFunctionName=_getTypeIDFunctionName;

- (void)dealloc {
	[_type release];
	[_type64 release];
	[_tollFreeBridgedClassName release];
	[_getTypeIDFunctionName release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportOpaque

@synthesize type=_type;
@synthesize type64=_type64;

@synthesize hasMagicCookie=_hasMagicCookie;

- (void)dealloc {
	[_type release];
	[_type64 release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportConstant

@synthesize type=_type;
@synthesize type64=_type64;

@synthesize hasMagicCookie=_hasMagicCookie;

- (void)dealloc {
	[_type release];
	[_type64 release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportStringConstant

@synthesize value=_value;
@synthesize hasNSString=_hasNSString;

- (void)dealloc {
	[_value release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportEnum

@synthesize value=_value;
@synthesize value64=_value64;

@synthesize ignored=_ignored;
@synthesize suggestion=_suggestion;

- (void)dealloc {
	[_value release];
	[_value64 release];
	[_suggestion release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportFunction {
    NSMutableArray *_arguments;
}

@synthesize variadic=_variadic;
@synthesize sentinel=_sentinel;
@synthesize inlineFunction=_inlineFunction;

@synthesize returnValue=_returnValue;

- (id)init {
    self = [super init];
    if (self) {
        _arguments = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
	[_sentinel release];
    [_arguments release];
    [_returnValue release];
	[super dealloc];
}


#pragma mark -
#pragma mark Arguments

- (NSArray *)arguments {
	return [[_arguments copy] autorelease];
}

- (void)setArguments:(NSArray *)arguments {
	[_arguments setArray:arguments];
}

- (void)addArgument:(MOBridgeSupportArgument *)argument {
	if (![_arguments containsObject:argument]) {
		[_arguments addObject:argument];
	}
}

- (void)removeArgument:(MOBridgeSupportArgument *)argument {
	if ([_arguments containsObject:argument]) {
		[_arguments removeObject:argument];
	}
}

@end


@implementation MOBridgeSupportFunctionAlias

@synthesize original=_original;

- (void)dealloc {
	[_original release];
	[super dealloc];
}

@end


@implementation MOBridgeSupportClass {
	NSMutableArray *_methods;
}

- (id)init {
	self = [super init];
	if (self) {
		_methods = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_methods release];
	[super dealloc];
}


#pragma mark -
#pragma mark Methods

- (NSArray *)methods {
	return _methods;
}

- (void)setMethods:(NSArray *)methods {
	[_methods setArray:methods];
}

- (void)addMethod:(MOBridgeSupportMethod *)method {
	if (![_methods containsObject:method]) {
		[_methods addObject:method];
	}
}

- (void)removeMethod:(MOBridgeSupportMethod *)method {
	if ([_methods containsObject:method]) {
		[_methods removeObject:method];
	}
}

- (MOBridgeSupportMethod *)methodWithSelector:(SEL)selector {
    NSUInteger index = [_methods indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ([obj selector] == selector);
    }];
    if (index != NSNotFound) {
        return [_methods objectAtIndex:index];
    }
    return nil;
}

@end


@implementation MOBridgeSupportInformalProtocol {
	NSMutableArray *_methods;
}

- (id)init {
	self = [super init];
	if (self) {
		_methods = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_methods release];
	[super dealloc];
}


#pragma mark -
#pragma mark Methods

- (NSArray *)methods {
	return _methods;
}

- (void)setMethods:(NSArray *)methods {
	[_methods setArray:methods];
}

- (void)addMethod:(MOBridgeSupportMethod *)method {
	if (![_methods containsObject:method]) {
		[_methods addObject:method];
	}
}

- (void)removeMethod:(MOBridgeSupportMethod *)method {
	if ([_methods containsObject:method]) {
		[_methods removeObject:method];
	}
}

- (MOBridgeSupportMethod *)methodWithSelector:(SEL)selector {
    NSUInteger index = [_methods indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return ([obj selector] == selector);
    }];
    if (index != NSNotFound) {
        return [_methods objectAtIndex:index];
    }
    return nil;
}

@end


@implementation MOBridgeSupportMethod {
	NSMutableArray *_arguments;
}

@synthesize selector=_selector;

@synthesize type=_type;
@synthesize type64=_type64;

@synthesize returnValue=_returnValue;

@synthesize classMethod=_classMethod;

@synthesize variadic=_variadic;
@synthesize sentinel=_sentinel;

@synthesize ignored=_ignored;
@synthesize suggestion=_suggestion;

- (id)init {
	self = [super init];
	if (self) {
		_arguments = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[_type release];
	[_type64 release];
	[_arguments release];
	[_returnValue release];
	[_sentinel release];
	[_suggestion release];
	[super dealloc];
}


#pragma mark -
#pragma mark Arguments

- (NSArray *)arguments {
	return [[_arguments copy] autorelease];
}

- (void)setArguments:(NSArray *)arguments {
	[_arguments setArray:arguments];
}

- (void)addArgument:(MOBridgeSupportArgument *)argument {
	if (![_arguments containsObject:argument]) {
		[_arguments addObject:argument];
	}
}

- (void)removeArgument:(MOBridgeSupportArgument *)argument {
	if ([_arguments containsObject:argument]) {
		[_arguments removeObject:argument];
	}
}

@end


@implementation MOBridgeSupportArgument {
    NSMutableArray *_arguments;
}

@synthesize type=_type;
@synthesize type64=_type64;

@synthesize typeModifier=_typeModifier;

@synthesize signature=_signature;
@synthesize signature64=_signature64;

@synthesize cArrayLengthInArg=_cArrayLengthInArg;
@synthesize cArrayOfFixedLength=_cArrayOfFixedLength;
@synthesize cArrayDelimitedByNull=_cArrayDelimitedByNull;
@synthesize cArrayOfVariableLength=_cArrayOfVariableLength;
@synthesize cArrayLengthInReturnValue=_cArrayLengthInReturnValue;

@synthesize index=_index;

@synthesize acceptsNull=_acceptsNull;
@synthesize acceptsPrintfFormat=_acceptsPrintfFormat;

@synthesize alreadyRetained=_alreadyRetained;
@synthesize functionPointer=_functionPointer;

@synthesize returnValue=_returnValue;

- (id)init {
    self = [super init];
    if (self) {
        _arguments = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc {
	[_type release];
	[_type64 release];
	[_typeModifier release];
	[_signature release];
	[_signature64 release];
	[_cArrayLengthInArg release];
	[super dealloc];
}


#pragma mark -
#pragma mark Arguments

- (NSArray *)arguments {
	return [[_arguments copy] autorelease];
}

- (void)setArguments:(NSArray *)arguments {
	[_arguments setArray:arguments];
}

- (void)addArgument:(MOBridgeSupportArgument *)argument {
	if (![_arguments containsObject:argument]) {
		[_arguments addObject:argument];
	}
}

- (void)removeArgument:(MOBridgeSupportArgument *)argument {
	if ([_arguments containsObject:argument]) {
		[_arguments removeObject:argument];
	}
}

@end


