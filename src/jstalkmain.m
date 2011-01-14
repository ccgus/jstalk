#import <Cocoa/Cocoa.h>
#import "JSTListener.h"
#import "JSTalk.h"


@interface JSCErrorHandler : NSObject {
    
}
@end

@implementation JSCErrorHandler
/*
- (void)JSCocoa:(JSCocoaController*)controller hadError:(NSString*)error onLineNumber:(NSInteger)lineNumber atSourceURL:(id)url {
    
    NSLog(@"Error line %d, %@", (int)lineNumber, error);
    
    exit(1);
}
*/


@end

void JSValuePrint(JSContextRef ctx,
                  JSValueRef value,
                  JSValueRef *exception)
{
    JSStringRef string = JSValueToStringCopy(ctx, value, exception);
    size_t length = JSStringGetLength(string);
    
    char *buffer = malloc(length+1);
    JSStringGetUTF8CString(string, buffer, length+1);
    JSStringRelease(string);
    
    puts(buffer);
    
    free(buffer);
}

void runREPL(void) {
    
    printf("Note: we do not currently support objc style stuff in the REPL\n");
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    JSContextRef ctx = [[t bridge] jsContext];
    
    // http://tlrobinson.net/blog/2008/10/10/command-line-interpreter-and-repl-for-jscocoa/
    while (1)
    {
        char buffer[1024];
        
        printf("js> ");
        
        if (fgets(buffer, 1024, stdin) == NULL) {
            exit(0);
        }
        
        
        JSStringRef script = JSStringCreateWithUTF8CString(buffer);
        JSValueRef exception = NULL;
        
        if (JSCheckScriptSyntax(ctx, script, 0, 0, &exception) && !exception)
        {
            JSValueRef value = JSEvaluateScript(ctx, script, 0, 0, 0, &exception);
            
            if (exception) {
                JSValuePrint(ctx, exception, NULL);
            }
            
            if (value && !JSValueIsUndefined(ctx, value)) {
                JSValuePrint(ctx, value, &exception);
            }
                
        }
        else
        {
            printf("Syntax error\n");
        }
        
        JSStringRelease(script);
    }
    
    [pool release];
    
}


int main(int argc, char *argv[]) {
    
    if (argc < 2) {
        printf("usage: %s <path to file>\n", argv[0]);
        return 1;
    }
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    NSString *arg = [NSString stringWithUTF8String:argv[1]];
    
    if ([arg isEqualToString:@"-e"]) {
        
        runREPL();
        
        exit(0);
    }
    
    
    NSString *s = [NSString stringWithContentsOfFile:arg encoding:NSUTF8StringEncoding error:nil];
    
    //JSCErrorHandler *eh = [[[JSCErrorHandler alloc] init] autorelease];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    
    #warning add this delegate back in
    
    //JSCocoaController *jsController = [t jsController];
    //jsController.delegate = eh;
    
    [t.env setObject:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]] forKey:@"scriptURL"];
    [t.env setObject:[[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]] URLByDeletingLastPathComponent] forKey:@"scriptDirectoryURL"];
    
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
