// Created by Patrick Geiller on 21/12/08.
// Modified by Gus Mueller

#import "JSTBridgeSupportLoader.h"

@interface JSTBridgeSupportLoader ()
- (BOOL)oldloadBridgeSupport:(NSString*)path;
@end


@implementation JSTBridgeSupportLoader

+ (id)sharedController {

    static id singleton;
    
    @synchronized(self) {
        if (!singleton) {
            singleton = [[JSTBridgeSupportLoader alloc] init];
        }
    }
    
    return singleton;
}

- (id)init {
    
	self = [super init];
	if ((self != nil)) {
        
        _paths              = [[NSMutableArray alloc] init];
        _xmlDocuments       = [[NSMutableArray alloc] init];
        _hash               = [[NSMutableDictionary alloc] init];
        _variadicSelectors  = [[NSMutableDictionary alloc] init];
        _variadicFunctions  = [[NSMutableDictionary alloc] init];
        _symbolLookup       = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)dealloc {
    
    [_variadicFunctions release];
    [_variadicSelectors release];
    [_hash release];
    [_paths release];
    [_xmlDocuments release];
    [_symbolLookup release];

    [super dealloc];
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    //[_currentBridgeObject release];
    _currentBridgeObject = 0x00;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)tagName namespaceURI:(NSString *)nsURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)atts {
    
    JSTRuntimeInfo *nextObject = 0x00;
    
    if ([tagName isEqualToString:@"struct"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setObjectType:JSTStruct];
    }
    else if ([tagName isEqualToString:@"constant"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setObjectType:JSTConstant];
        [nextObject setDeclaredType:[atts objectForKey:@"declared_type"]];
    }
    else if ([tagName isEqualToString:@"enum"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setObjectType:JSTEnum];
        [nextObject setEnumValue:[[atts objectForKey:@"value"] intValue]]; // enums are always ints, not longs in 64 bit.
    }
    else if ([tagName isEqualToString:@"function"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setObjectType:JSTFunction];
    }
    else if ([tagName isEqualToString:@"class"]) {
        
        // well, appkit + foundation both have stuff for NSString... yay additions!
        nextObject = [_symbolLookup objectForKey:[atts objectForKey:@"name"]];
        nextObject = nextObject ? [nextObject retain] : [[JSTRuntimeInfo alloc] init];
        
        [nextObject setObjectType:JSTClass];
        _currentBridgeClass = nextObject;
    }
    else if (_currentBridgeClass && [tagName isEqualToString:@"method"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setObjectType:JSTMethod];
        [nextObject setMethodSelector:[atts objectForKey:@"selector"]];
        
        if ([[atts objectForKey:@"class_method"] boolValue]) {
            [_currentBridgeClass addClassMethod:nextObject];
        }
        else {
            [_currentBridgeClass addInstanceMethod:nextObject];
        }
    }
    else if ([_currentBridgeObject objectType] == JSTStruct && [tagName isEqualToString:@"field"]) {
        [_currentBridgeObject addStructField:[atts objectForKey:@"name"]];
    }
    else if ([_currentBridgeObject objectType] == JSTFunction && ([tagName isEqualToString:@"arg"] || [tagName isEqualToString:@"retval"])) {
        
        JSTRuntimeInfo *arg = [[JSTRuntimeInfo alloc] init];
        [arg setDeclaredType:[atts objectForKey:@"declared_type"]];
        [arg grabTypeFromAttributes:atts];
        
        if ([tagName isEqualToString:@"arg"]){
            [_currentBridgeObject addArgument:arg];
        }
        else {
            [_currentBridgeObject setReturnValue:arg];
        }
        
        [arg release];
    }
    // is it an arg or a ret for a method on a class?
    else if (_currentBridgeClass && [_currentBridgeObject objectType] == JSTMethod && ([tagName isEqualToString:@"arg"] || [tagName isEqualToString:@"retval"])) {
        
        JSTRuntimeInfo *arg = [[JSTRuntimeInfo alloc] init];
        [arg setDeclaredType:[atts objectForKey:@"declared_type"]];
        [arg grabTypeFromAttributes:atts];
        
        if ([tagName isEqualToString:@"arg"]){
            [_currentBridgeObject addArgument:arg];
        }
        else {
            [_currentBridgeObject setReturnValue:arg];
        }
        
        [arg release];
    }
    
    
    
    if (nextObject) {
        
        [nextObject grabTypeFromAttributes:atts];
        
        [nextObject setSymbolName:[atts objectForKey:@"name"]];
        
        _currentBridgeObject = nextObject;
        
        if ([nextObject objectType] == JSTStruct || [nextObject objectType] == JSTConstant ||
            [nextObject objectType] == JSTEnum   || [nextObject objectType] == JSTFunction ||
            [nextObject objectType] == JSTClass) {
            
            //debug(@"Adding: %@ - %@", [nextObject name], [nextObject type]);
            
            JSTAssert([nextObject symbolName]);
            [_symbolLookup setObject:nextObject forKey:[nextObject symbolName]];
            
        }
        
        [nextObject release];
        
        
        
    }
    
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)tagName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    if (_currentBridgeClass && [tagName isEqualToString:@"class"]) {
        _currentBridgeClass = 0x00;
    }
}

- (BOOL)loadBridgeSupportAtPath:(NSString*)path {
    
    NSXMLParser *parser = [[[NSXMLParser alloc] initWithContentsOfURL:[NSURL fileURLWithPath:path]] autorelease];
    
    if (!parser) {
        NSLog(@"Could not load the bridge support at '%@'", path);
        return NO;
    }
    
    BOOL success;
    
    @synchronized(self) {
        [parser setDelegate:self];
        success = [parser parse];
    }
    
    if (!success) {
        
        NSLog(@"Could not load the bridge support at '%@'", path);
        
        NSError *err;
        if ((err = [parser parserError])) {
            NSLog(@"Error: %@", err);
        }
        return NO;
    }
    
    return [self oldloadBridgeSupport:path];
}

- (JSTRuntimeInfo*)runtimeInfoForSymbol:(NSString*)symbol {
    return [_symbolLookup objectForKey:symbol];
}


//
// Load a bridgeSupport file into a hash as { name : xmlTagString } 
//
- (BOOL)oldloadBridgeSupport:(NSString*)path
{
    NSError*    error = nil;
    /*
        Adhoc parser
            NSXMLDocument is too slow
            loading xml document as string then querying on-demand is too slow
            can't get CFXMLParserRef to work
            don't wan't to delve into expat
            -> ad hoc : load file, build a hash of { name : xmlTagString }
    */
    NSString* xmlDocument = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (error)    return    NSLog(@"loadBridgeSupport : %@", error), NO;

    char* c = (char*)[xmlDocument UTF8String];
#ifdef __OBJC_GC__
    char* originalC = c;
    [[NSGarbageCollector defaultCollector] disableCollectorForPointer:originalC];
#endif

//    double t0 = CFAbsoluteTimeGetCurrent();
    // Start parsing
    for (; *c; c++)
    {
        if (*c == '<')
        {
            char startTagChar = c[1];
            if (startTagChar == 0)    return    NO;

            // 'co'    constant
            // 'cl'    class
            // 'e'    enum
            // 'fu'    function
            // 'st'    struct
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
                    if (*c == '<')            foundOpenTag = YES;
                    else    
                    if (*c == '/')
                    {
                        if (!foundOpenTag)
                        {
                            if(c[1] == '>')    foundEndTag = YES, c++;
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
                    else
                    // Variadic parsing
                    if (c[0] == 'v' && c[1] == 'a' && c[2] == 'r')
                    {
                        if (strncmp(c, "variadic", 8) == 0)
                        {
                            // Skip back to tag start
                            c0 = c;
                            for (; *c0 != '<'; c0--);

                            // Tag name starts with 'm' : variadic method
                            // <method variadic='true' selector='alertWithMessageText:defaultButton:alternateButton:otherButton:informativeTextWithFormat:' class_method='true'>
                            if (c0[1] == 'm')
                            {
                                c = c0;
                                id variadicMethodName = nil;
                                // Extract selector name
                                for (; *c != '>'; c++)
                                {
                                    if (c[0] == ' ' && c[1] == 's' && c[2] == 'e' && c[3] == 'l')
                                    {
                                        for (; *c && *c != '\''; c++);
                                        c++;
                                        c0 = c;
                                        for (; *c && *c != '\''; c++);
                                        variadicMethodName = [[[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding] autorelease];
                                    }
                                }
                                [_variadicSelectors setValue:[NSNumber numberWithBool:YES] forKey:variadicMethodName];
                                
                            }
                            else {
                                [_variadicFunctions setValue:[NSNumber numberWithBool:YES] forKey:name];
                            }
                        }
                    }
                }
                
                c0 = tagStart;
                id value = [[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding];
    
                [_hash setValue:value forKey:name];
                [value release];
                [name release];
            }
        }
    }
    
#ifdef __OBJC_GC__
    [[NSGarbageCollector defaultCollector] enableCollectorForPointer:originalC];
#endif
    
    [_paths addObject:path];
    [_xmlDocuments addObject:xmlDocument];

    return YES;
}


- (BOOL)isBridgeSupportLoaded:(NSString*)path {
    
    NSUInteger idx = [self bridgeSupportIndexForString:path];
    
    return idx == NSNotFound ? NO : YES;
}

//
// bridgeSupportIndexForString
//    given 'AppKit', return index of '/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/BridgeSupport/AppKitFull.bridgesupport'
//
- (NSUInteger)bridgeSupportIndexForString:(NSString*)string {
    
    NSUInteger i, l = [_paths count];
    for (i=0; i<l; i++) {
        NSString* path = [_paths objectAtIndex:i];
        NSRange range  = [path rangeOfString:string];
        
        if (range.location != NSNotFound) {
            return range.location;
        } 
    }
    
    return NSNotFound;
}

- (NSMutableDictionary*)variadicSelectors {
    return _variadicSelectors;
}

- (NSMutableDictionary*)variadicFunctions {
    return _variadicFunctions;
}

- (NSArray*)keys {
    
    [_hash removeObjectForKey:@"NSProxy"];
    [_hash removeObjectForKey:@"NSProtocolChecker"];
    [_hash removeObjectForKey:@"NSDistantObject"];
    
    return [_hash allKeys];
}

- (NSString*)queryName:(NSString*)name {
    return [_hash valueForKey:name];
}

- (NSString*)queryName:(NSString*)name type:(NSString*)type {
    
    id v = [self queryName:name];
    if (!v) {
        return nil;
    }
    
    char* c = (char*)[v UTF8String];
    // Skip tag start
    c++;
    char* c0 = c;
    for (; *c && *c != ' '; c++);
    
    NSString* extractedType = [[[NSString alloc] initWithBytes:c0 length:c-c0 encoding:NSUTF8StringEncoding] autorelease];
    
    if (![extractedType isEqualToString:type]) {
        return nil;
    }
    
    return v;
}

@end
