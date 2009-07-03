//
//  JSTalkTask.m
//
//  Created by Casey Fleser on 6/16/06.
//  Copyright 2006 Griffin Technology, Inc. All rights reserved.
//  Modified by Mr. Gus Mueller, 2009 or something.

#import "JSTalkTask.h"
#import <JSTalk/JSTalk.h>

static NSNib				*sTaskNib = nil;
static NSView				*sView = nil;
static NSObjectController	*sController = nil;

@implementation JSTalkTask

@synthesize scriptSource=_scriptSource;


+ (void) load
{
	NSBundle		*ourBundle = [NSBundle bundleForClass: [JSTalkTask class]];
	NSArray			*nibObjects;
	
	sTaskNib = [[NSNib alloc] initWithNibNamed: @"JSTalk" bundle: ourBundle];

	if ([sTaskNib instantiateNibWithOwner: NSApp topLevelObjects: &nibObjects]) {
		NSEnumerator	*objEnumerator = [nibObjects objectEnumerator];
		id				anObj;
		
		[nibObjects retain];	// around for the life of the app
		while (anObj = [objEnumerator nextObject]) {
			if ([anObj isKindOfClass: [NSView class]]) {
				sView = anObj;
			}
			if ([anObj isKindOfClass: [NSObjectController class]]) {
				sController = anObj;
			}
		}
	}
}

+ (GComponentDescription *) componentDescription
{
	static GComponentDescription		*sComponentDesc = nil;

	if (sComponentDesc == nil) {
		NSBundle	*ourBundle = [NSBundle bundleForClass: [JSTalkTask class]];
		NSString	*imagePath;
		
		sComponentDesc = [[GComponentDescription alloc] init];
		[sComponentDesc setComponentClass: @"JSTalkTask"];
		[sComponentDesc setCopyright: @"Flying Meat Inc, 2009"];
		[sComponentDesc setName: @"JSTalk"];
		[sComponentDesc setOwner: @"Flying Meat"];
		[sComponentDesc setSummary: @"Execute a JavaScript task"];
		if (imagePath = [ourBundle pathForResource: @"jstalk" ofType: @"tiff"]) {
			[sComponentDesc setImage: [[NSImage alloc] initWithContentsOfFile: imagePath]];
		}
	}
	
	return sComponentDesc;
}

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) inKey
{
	static NSArray		*sManualKeys = nil;

	if (sManualKeys == nil)
		sManualKeys = [[NSArray arrayWithObjects: @"scriptSource", nil] retain];
	
	return [sManualKeys containsObject: inKey] ? NO : [NSObject automaticallyNotifiesObserversForKey: inKey];
}

- (id) init
{
	[self setScriptSource: @""];

	return self;
}

- (void) encodeWithCoder: (NSCoder *) inCoder
{
	if ([inCoder allowsKeyedCoding]) {
		[inCoder encodeObject: [self scriptSource] forKey: @"scriptSource"];
	}
}

- (id) initWithCoder: (NSCoder *) inCoder
{
    self = [self init];
	
	if ([inCoder allowsKeyedCoding]) {
		[self setScriptSource: [inCoder decodeObjectForKey: @"scriptSource"]];
    }
	
    return self;
}

- (void) dealloc
{
	[_scriptSource release];

	[super dealloc];
}

- (NSView *) settingsView
{
	return sView;
}

- (NSImage *) image
{
	return [[JSTalkTask componentDescription] image]; 
}

- (void) setImage: (NSImage *) inImage
{
}

- (void) willBeShown
{
	[sController setContent: self];
}

- (void) willBeHidden
{
	[sController setContent: nil];
}

- (BOOL) processNotification: (NSDictionary *) inValues
{
	NSString *script = [ProxiUtils substituteTokensInString: [self scriptSource] usingValues: inValues];
	
    JSTalk *jstalk = [[[JSTalk alloc] init] autorelease];
    
    id result = [jstalk executeString:script];
    
    if (result) {
        NSLog(@"%@", [result description]);
    }
    
    return YES;
}

/*
- (NSString *) scriptSource
{
	return _scriptSource;
}

- (void) setScriptSource: (NSString *) inSubjectField
{
	if (inSubjectField != nil && (_subjectField == nil || [_subjectField compare: inSubjectField] != NSOrderedSame)) {
		[self willChangeValueForKey: @"subjectField"];
		[_subjectField autorelease];
		_subjectField = [inSubjectField retain];
		[self didChangeValueForKey: @"subjectField"];
	}
}
*/

@end
