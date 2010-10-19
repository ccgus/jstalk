#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif

#import "JSTRuntimeInfo.h"

@interface JSTBridgeSupportLoader : NSObject <NSXMLParserDelegate> {
    
    NSMutableArray          *_paths;

    NSMutableDictionary     *_hash;
    NSMutableDictionary     *_variadicSelectors;
    NSMutableDictionary     *_variadicFunctions;
    
    
    NSMutableDictionary     *_symbolLookup;
    JSTRuntimeInfo        *_currentBridgeObject;
    JSTRuntimeInfo        *_currentBridgeClass;
}

+ (id)sharedController;

- (BOOL)loadFrameworkAtPath:(NSString*)frameworkPath;
- (BOOL)loadBridgeSupportAtPath:(NSString*)path;
- (BOOL)isBridgeSupportLoaded:(NSString*)path;

+ (JSTRuntimeInfo*)runtimeInfoForSymbol:(NSString*)symbol;
- (JSTRuntimeInfo*)runtimeInfoForSymbol:(NSString*)symbol;

- (NSMutableDictionary*)variadicSelectors;
- (NSMutableDictionary*)variadicFunctions;

- (NSString*)queryName:(NSString*)name;
- (NSString*)queryName:(NSString*)name type:(NSString*)type;

- (NSArray*)keys;

@end
