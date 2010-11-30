#import <Cocoa/Cocoa.h>
#import "JSTListener.h"
#import "JSTalk.h"

BOOL JSCErrorHandlerExitOnError = YES;

@interface JSCErrorHandler : NSObject {
    
}
@end

@implementation JSCErrorHandler

- (void)JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url {
    
    printf("Error line %d, %s\n", (int)lineNumber, [[error description] UTF8String]);
    
    if (JSCErrorHandlerExitOnError) {
        exit(1);
    }
}


@end


void runREPL(JSTalk *t) {
    
    // thanks http://tlrobinson.net/blog/2008/10/10/command-line-interpreter-and-repl-for-jscocoa/ !
    
    JSCErrorHandlerExitOnError = NO;
    
    while (1) {
        char buffer[1024];
        
        printf("js> ");
        
        if (fgets(buffer, 1024, stdin) == NULL) {
            exit(0);
        }
        
        NSString *s = [[NSString alloc] initWithUTF8String:buffer];
        
        id o = [t executeString:s];
        
        if (o) {
            printf("%s\n", [[o description] UTF8String]);
        }
        
        [s release];
    
    }
    
    
}


int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    JSCErrorHandler *eh = [[[JSCErrorHandler alloc] init] autorelease];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    
    JSCocoaController *jsController = [t jsController];
    jsController.delegate = eh;
    
    if (argc < 2) {
        runREPL(t);
        exit(0);
    }
    
    
    NSString *arg = [NSString stringWithUTF8String:argv[1]];
    NSString *s = [NSString stringWithContentsOfFile:arg encoding:NSUTF8StringEncoding error:nil];
    
    if (!s) {
        printf("usage: %s <path to file>\n", argv[0]);
        exit(0);
    }
    
    [t.env setObject:[NSURL fileURLWithPath:arg] forKey:@"scriptURL"];
    
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
