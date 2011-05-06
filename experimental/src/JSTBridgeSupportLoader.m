// Created by Patrick Geiller on 21/12/08.
// Modified by Gus Mueller

#import "JSTBridgeSupportLoader.h"
#import <dlfcn.h>

@interface JSTBridgeSupportLoader ()
//- (BOOL)oldloadBridgeSupport:(NSString*)path;
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
        [nextObject setJSTType:JSTTypeStruct];
    }
    else if ([tagName isEqualToString:@"constant"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setJSTType:JSTTypeConstant];
        [nextObject setDeclaredType:[atts objectForKey:@"declared_type"]];
    }
    else if ([tagName isEqualToString:@"enum"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setJSTType:JSTTypeEnum];
        [nextObject grabEnumValueFromAttributes:atts];
    }
    else if ([tagName isEqualToString:@"function"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setJSTType:JSTTypeFunction];
        [nextObject setIsVariadic:[[atts objectForKey:@"variadic"] isEqualToString:@"true"]];
    }
    else if ([tagName isEqualToString:@"class"]) {
        
        // well, appkit + foundation both have stuff for NSString... yay additions!
        nextObject = [_symbolLookup objectForKey:[atts objectForKey:@"name"]];
        nextObject = nextObject ? [nextObject retain] : [[JSTRuntimeInfo alloc] init];
        
        [nextObject setJSTType:JSTTypeClass];
        _currentBridgeClass = nextObject;
    }
    else if (_currentBridgeClass && [tagName isEqualToString:@"method"]) {
        nextObject = [[JSTRuntimeInfo alloc] init];
        [nextObject setJSTType:JSTTypeMethod];
        [nextObject setMethodSelector:[atts objectForKey:@"selector"]];
        
        if ([[atts objectForKey:@"class_method"] boolValue]) {
            [_currentBridgeClass addClassMethod:nextObject];
        }
        else {
            [_currentBridgeClass addInstanceMethod:nextObject];
        }
    }
    else if ([_currentBridgeObject jstType] == JSTTypeStruct && [tagName isEqualToString:@"field"]) {
        [_currentBridgeObject addStructField:[atts objectForKey:@"name"]];
    }
    else if ([_currentBridgeObject jstType] == JSTTypeFunction && ([tagName isEqualToString:@"arg"] || [tagName isEqualToString:@"retval"])) {
        
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
    else if (_currentBridgeClass && [_currentBridgeObject jstType] == JSTTypeMethod && ([tagName isEqualToString:@"arg"] || [tagName isEqualToString:@"retval"])) {
        
        //debug(@"adding %@ for %@", tagName, [_currentBridgeObject methodSelector]);
        
        JSTRuntimeInfo *arg = [[JSTRuntimeInfo alloc] init];
        [arg setDeclaredType:[atts objectForKey:@"declared_type"]];
        [arg grabTypeFromAttributes:atts];
        
        if ([tagName isEqualToString:@"arg"]){
            [_currentBridgeObject addArgument:arg];
        }
        else {
            [_currentBridgeObject setReturnValue:arg];
        }
        
        /*
        if ([[_currentBridgeObject methodSelector] isEqualToString:@"testClassBoolValue"]) {
            debug(@"returnValue         : '%@'", [_currentBridgeObject returnValue]);
            debug(@"_currentBridgeObject: '%@'", _currentBridgeObject);
            debug(@"typeEncoding:         '%@'", [[_currentBridgeObject returnValue] typeEncoding]);
        }
        */
        
        [arg release];
    }
    
    
    
    if (nextObject) {
        
        [nextObject grabTypeFromAttributes:atts];
        
        [nextObject setSymbolName:[atts objectForKey:@"name"]];
        
        _currentBridgeObject = nextObject;
        
        if ([nextObject jstType] == JSTTypeStruct || [nextObject jstType] == JSTTypeConstant ||
            [nextObject jstType] == JSTTypeEnum   || [nextObject jstType] == JSTTypeFunction ||
            [nextObject jstType] == JSTTypeClass) {
            
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

- (BOOL)loadFrameworkAtPath:(NSString*)frameworkPath {
    
    NSString *name = [[frameworkPath lastPathComponent] stringByDeletingPathExtension];
    
    NSString *path = [NSString stringWithFormat:@"%@/Resources/BridgeSupport/%@Full.bridgeSupport", frameworkPath, name];
    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        path = [NSString stringWithFormat:@"%@/Resources/BridgeSupport/%@.bridgeSupport", frameworkPath, name];
    }
    
    // Return YES if already loaded
    if ([[JSTBridgeSupportLoader sharedController] isBridgeSupportLoaded:path]) {
        return YES;
    }
    
    [self loadBridgeSupportAtPath:path];
    
    [[NSBundle bundleWithPath:frameworkPath] load];
    
    NSString *dylibPath = [NSString stringWithFormat:@"%@/Resources/BridgeSupport/%@.dylib", frameworkPath, name];
    if ([[NSFileManager defaultManager] fileExistsAtPath:dylibPath]) {
        dlopen([dylibPath UTF8String], RTLD_LAZY);
    }
    
    return YES;
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
    
    [_paths addObject:path];
    
    return YES;
}

+ (JSTRuntimeInfo*)runtimeInfoForSymbol:(NSString*)symbol {
    return [[self sharedController] runtimeInfoForSymbol:symbol];
}

- (JSTRuntimeInfo*)runtimeInfoForSymbol:(NSString*)symbol {
    return [_symbolLookup objectForKey:symbol];
}



- (BOOL)isBridgeSupportLoaded:(NSString*)path {
    return [_paths containsObject:path];
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
