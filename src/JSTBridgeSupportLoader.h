#if !TARGET_IPHONE_SIMULATOR && !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>
#endif

#import "JSTBridgedObject.h"

@interface JSTBridgeSupportLoader : NSObject <NSXMLParserDelegate> {
    
    NSMutableArray          *_paths;
    NSMutableArray          *_xmlDocuments;

    NSMutableDictionary     *_hash;
    NSMutableDictionary     *_variadicSelectors;
    NSMutableDictionary     *_variadicFunctions;
    
    
    NSMutableDictionary     *_symbolLookup;
    JSTBridgedObject        *_currentBridgeObject;
    JSTBridgedObject        *_currentBridgeClass;
}

+ (id)sharedController;

- (BOOL)loadBridgeSupport:(NSString*)path;
- (BOOL)isBridgeSupportLoaded:(NSString*)path;
- (NSUInteger)bridgeSupportIndexForString:(NSString*)string;

- (NSMutableDictionary*)variadicSelectors;
- (NSMutableDictionary*)variadicFunctions;

- (NSString*)queryName:(NSString*)name;
- (NSString*)queryName:(NSString*)name type:(NSString*)type;

- (NSArray*)keys;

@end
