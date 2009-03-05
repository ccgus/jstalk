//
//  BridgeSupportController.m
//  JSCocoa
//
//  Created by Patrick Geiller on 08/07/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "BridgeSupportController.h"
#include "expat.h"

static void startElementHandler(void *userData, const char *name, const char **atts);
static void endElementHandler(void *userData, const char *name);
static void characterDataHandler(void *userData, const char *s, int len);

@interface BridgeSupportController (Private)
- (void)parseFile:(const char *)xmlFile;
@end

@implementation BridgeSupportController


+ (id)sharedController
{
	static id singleton;
	@synchronized(self)
	{
		if (!singleton)
			singleton = [[BridgeSupportController alloc] init];
		return singleton;
	}
	return singleton;
}

- (id)init
{
	self = [super init];
	
	paths			= [[NSMutableArray alloc] init];
	xmlDocuments	= [[NSMutableArray alloc] init];
	hash			= [[NSMutableDictionary alloc] init];
	ghash			= [[NSMutableDictionary alloc] init];
	
	return	self;
}

- (void)dealloc
{
	[hash release];
	[ghash release];
	[paths release];
	[xmlDocuments release];

	[super dealloc];
}

//
// Load a bridgeSupport file into a hash as { name : xmlTagString } 
//
- (BOOL)loadBridgeSupport:(NSString*)path
{
    
    debug(@"parsing %@", path);
    
	NSError*	error = nil;
	/*
		Adhoc parser
			NSXMLDocument is too slow
			loading xml document as string then querying on-demand is too slow
			can't get CFXMLParserRef to work
			don't wan't to delve into expat
			-> ad hoc : load file, build a hash of { name : xmlTagString }
	*/
	NSString* xmlDocument = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (error)	return	NSLog(@"loadBridgeSupport : %@", error), NO;
    
	char* c = (char*)[xmlDocument UTF8String];
#ifdef __OBJC_GC__
	char* originalC = c;
	[[NSGarbageCollector defaultCollector] disableCollectorForPointer:originalC];
#endif
	// Start parsing
	for (; *c; c++)
	{
		if (*c == '<')
		{
			char startTagChar = c[1];
			if (startTagChar == 0)	return	NO;

			// 'co'	constant
			// 'cl'	class
			// 'e'	enum
			// 'fu'	function
			// 'st'	struct
			if ((c[1] == 'c' && (c[2] == 'o' || c[2] == 'l')) || c[1] == 'e' || (c[1] == 'f' && c[2] == 'u') || (c[1] == 's' && c[2] == 't'))
			{
				// Extract name
				char* tagStart = c;
				for (; *c && *c != '\''; c++);
				c++;
				char* c0 = c;
				for (; *c && *c != '\''; c++);
				
				id name = [[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding];
				
				// Move to tag end
				BOOL foundEndTag = NO;
				BOOL foundOpenTag = NO;
				c++;
				for (; *c && !foundEndTag; c++)
				{
					if (*c == '<')					foundOpenTag = YES;
					else	
					if (*c == '/')
					{
						if (!foundOpenTag)
						{
							if(c[1] == '>')	foundEndTag = YES, c++;
						}
						else
						{
							if (startTagChar == c[1])	
							{
								foundEndTag = YES;
								// Skip to end of tag
								for (; *c && *c != '>'; c++);
							}
						}
					}
				}
				
				c0 = tagStart;
				id value = [[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding];
				
                
                //debug(@"value: %@=%@", value, name); 
				[hash setValue:value forKey:name];
				[value release];
				[name release];
			}
		}
	}
#ifdef __OBJC_GC__
	[[NSGarbageCollector defaultCollector] enableCollectorForPointer:originalC];
#endif
	[paths addObject:path];
	[xmlDocuments addObject:xmlDocument];
    
    [self parseFile:[path fileSystemRepresentation]];
    
	return	YES;
}


- (BOOL)isBridgeSupportLoaded:(NSString*)path
{
	NSUInteger idx = [self bridgeSupportIndexForString:path];
	return	idx == NSNotFound ? NO : YES;
}

//
// bridgeSupportIndexForString
//	given 'AppKit', return index of '/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKitFull.bridgesupport'
//
- (NSUInteger)bridgeSupportIndexForString:(NSString*)string
{
	int i, l = [paths count];
	for (i=0; i<l; i++)
	{
		NSString* path = [paths objectAtIndex:i];
		NSRange range = [path rangeOfString:string];

		if (range.location != NSNotFound)	return	range.location;		
	}
	return	NSNotFound;
}

- (NSString*)queryName:(NSString*)name
{
	return [hash valueForKey:name];
}
- (NSString*)queryName:(NSString*)name type:(NSString*)type
{
	id v = [self queryName:name];
	if (!v)	return	nil;
	
	char* c = (char*)[v UTF8String];
	// Skip tag start
	c++;
	char* c0 = c;
	for (; *c && *c != ' '; c++);
	id extractedType = [[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding];
	[extractedType autorelease];
//	NSLog(@"extractedType=%@", extractedType);
	
	if (![extractedType isEqualToString:type])	return	nil;
	return	v;
}

- (JSBridgeType*) typeForName:(NSString*)name {
    return [ghash objectForKey:name];
}

#define BUFFSIZE 8192

- (void)parseFile:(const char *)xmlFile
{
    FILE *in;
    int done = 0; /* used in the xml parsing loop below */
    
    char        buffer[BUFFSIZE];
    if((in = fopen(xmlFile, "r")) == NULL)
    {   
        NSLog(@"Can't open xml file");
        return;
    }
    
    XML_Parser parser = XML_ParserCreate(NULL);
    
    XML_SetUserData(parser, self);
    XML_SetElementHandler(parser, startElementHandler, endElementHandler);
    
    XML_SetCharacterDataHandler(parser, characterDataHandler);
    
    while (!done)
    {
        int len;
        
        len = fread(buffer, 1, BUFFSIZE, in);
        if (ferror(in))
        {
            printf("XML Read error\n");
            exit(-1);
        }
        done = feof(in);
        
        if (! XML_Parse(parser, buffer, len, done))
        {
            NSLog(@"parse error: %s line %d", XML_ErrorString(XML_GetErrorCode(parser)), XML_GetCurrentLineNumber(parser));
        }
    }
    
    XML_ParserFree(parser);
}

- (void)startElement:(const char *)elementName :(const char **)atts {
    if (strcmp("constant", elementName) == 0) {
        
        JSBridgeType *bt = [[[JSBridgeType alloc] init] autorelease];
        
        bt.type = JSBridgeTypeConstant;
        
        NSString *name = [NSString stringWithUTF8String:atts[1]];
        bt.ctype = [NSString stringWithUTF8String:atts[3]];
        bt.name = name;
        
        [ghash setObject:bt forKey:name];
    }
    else if (strcmp("enum", elementName) == 0) {
        
        JSBridgeType *bt = [[[JSBridgeType alloc] init] autorelease];
        
        bt.type = JSBridgeTypeEnum;
        
        NSString *name = [NSString stringWithUTF8String:atts[1]];
        
        bt.evalue = [[NSString stringWithUTF8String:atts[3]] integerValue];
        bt.name = name;
        
        [ghash setObject:bt forKey:name];
    }
    else if (strcmp("function", elementName) == 0) {
        currentBridgeType = [[[JSBridgeType alloc] init] autorelease];
        currentBridgeType.type = JSBridgeTypeFunction;
        currentBridgeType.name = [NSString stringWithUTF8String:atts[1]];
    }
    else if (((strcmp("arg", elementName) == 0) || (strcmp("retval", elementName) == 0)) && currentBridgeType) {
        if (!currentBridgeType.args) {
            currentBridgeType.args = [NSMutableArray array];
        }
        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        while (*atts) {
            NSString *name = [NSString stringWithUTF8String:atts[0]];
            NSString *val  = [NSString stringWithUTF8String:atts[1]];
            [d setValue:val forKey:name];
            atts += 2;
        }
        
        if (strcmp("arg", elementName) == 0) {
            [(id)currentBridgeType.args addObject:[NSDictionary dictionaryWithDictionary:d]];
        }
        else {
            currentBridgeType.retval = [NSDictionary dictionaryWithDictionary:d];
        }
    }
    
}
- (void)endElement:(const char *)elementName {
    //debug(@"end element: %s", elementName);
    
    if (strcmp("function", elementName) == 0 && currentBridgeType) {
        
        [ghash setObject:currentBridgeType forKey:currentBridgeType.name];
        
        currentBridgeType = 0x00; // don't need this anymore.
    }
}
- (void)characterData:(const char *)data :(int)length {
    
}

static void startElementHandler(void *userData, const char *name, const char **atts) {
    [(id)userData startElement:name :atts];
}

static void endElementHandler(void *userData, const char *name) {
    [(id)userData endElement:name];
}

static void characterDataHandler(void *userData, const char *s, int len) {
    [(id)userData characterData:s :len];
}


@end

NSString *JSBridgeTypeConstant = @"const";
NSString *JSBridgeTypeEnum = @"enum";
NSString *JSBridgeTypeFunction = @"function";

@implementation JSBridgeType

@synthesize type=_type;
@synthesize name=_name;
@synthesize ctype=_ctype;
@synthesize evalue=_evalue;
@synthesize args=_args;
@synthesize retval=_retval;

@end



