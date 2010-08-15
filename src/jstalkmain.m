#import <Cocoa/Cocoa.h>
#import "JSTListener.h"
#import "JSTalk.h"


@interface JSCErrorHandler : NSObject {
    
}
@end

@implementation JSCErrorHandler

- (void) JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url {
    
    NSLog(@"Error line %d, %@", (int)lineNumber, error);
    
    exit(1);
}


@end



int main(int argc, char *argv[]) {
    
    if (argc < 2) {
        printf("usage: %s <path to file>\n", argv[0]);
        return 1;
    }
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString *s = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
    
    JSCErrorHandler *eh = [[[JSCErrorHandler alloc] init] autorelease];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    
    JSCocoaController *jsController = [t jsController];
    jsController.delegate = eh;
    
    [t.env setObject:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]] forKey:@"scriptURL"];
    
    if ([s hasPrefix:@"#!"]) {
        
        NSRange r = [s rangeOfString:@"\n"];
        
        if (r.location != NSNotFound) {
            s = [s substringFromIndex:r.location];
        }
    }
    
    [t executeString:s];
    
    [pool release];
    
    return 0;
}
