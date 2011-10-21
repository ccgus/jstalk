#import <Cocoa/Cocoa.h>
#import "JSTListener.h"
#import "JSTalk.h"
#import "JSTPreprocessor.h"

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

void testPreprocess(NSString *shouldLookLike, NSString *processMe) {
    
}

void testScriptAtPath(NSString *pathToScript) {
    
    
    NSString *s = [NSString stringWithContentsOfFile:pathToScript encoding:NSUTF8StringEncoding error:nil];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    
    [[t env] setObject:[NSURL fileURLWithPath:pathToScript] forKey:@"scriptURL"];
    [[t env] setObject:[[NSURL fileURLWithPath:pathToScript] URLByDeletingLastPathComponent] forKey:@"scriptDirectoryURL"];
    
    [t executeString:s];
    
    exit(0);
}

void testPreprocessAtPath(NSString *pathToScript) {
    NSLog(@"Testing %@", pathToScript);
    
    NSString *bp = [[pathToScript stringByDeletingPathExtension] stringByAppendingPathExtension:@"jstpc"];
    NSString *a = [NSString stringWithContentsOfFile:pathToScript encoding:NSUTF8StringEncoding error:nil];
    NSString *b = [NSString stringWithContentsOfFile:bp encoding:NSUTF8StringEncoding error:nil];
    
    NSString *r = [JSTPreprocessor preprocessCode:a];
    
    b = [b stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    r = [r stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![b isEqualToString:r]) {
        NSLog(@"Bad preprocess for %@", pathToScript);
        [[r dataUsingEncoding:NSUTF8StringEncoding] writeToFile:@"/private/tmp/jstb.jstalk" atomically:YES];
        NSString *cmd = [NSString stringWithFormat:@"/usr/bin/diff %@ /private/tmp/jstb.jstalk", bp];
        NSLog(@"%@", cmd);
        system([cmd UTF8String]);
        exit(123);
    }
}

int testFolder(NSString *folder) {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    BOOL isDir;
    if (!([fm fileExistsAtPath:folder isDirectory:&isDir] && isDir)) {
        printf("The test path given does not exist or is not a folder\n");
        return 1;
    }
    
    NSError *err = 0x00;
    NSArray *ar = [fm subpathsOfDirectoryAtPath:folder error:&err];
    if (!ar) {
        NSLog(@"Error loading %@: %@", folder, err);
        return 1;
    }
    
    
    for (NSString *sd in ar) {
        
        if (![[sd pathExtension] isEqualToString:@"jstalk"]) {
            continue;
        }
        
        else if ([sd hasPrefix:@"testPreprocess"]) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            testPreprocessAtPath([folder stringByAppendingPathComponent:sd]);
            [pool release];
        }
        else if ([sd hasPrefix:@"test"]) {
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            testScriptAtPath([folder stringByAppendingPathComponent:sd]);
            [pool release];
        }
    }
    
    return 0;
}

int main(int argc, char *argv[]) {
    
    if (argc < 2) {
        printf("usage: %s <path to file>\n", argv[0]);
        return 1;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *arg = [NSString stringWithUTF8String:argv[1]];
    
    if ([arg isEqualToString:@"-e"]) {
        runREPL();
        exit(0);
    }
    
    if ([arg isEqualToString:@"-t"]) {
        if (argc < 3) {
            printf("-t requires a path to a test folder\n");
            return 1;
        }
        
        NSString *arg2 = [NSString stringWithUTF8String:argv[2]];
        
        exit(testFolder(arg2));
    }
    
    NSString *s = [NSString stringWithContentsOfFile:arg encoding:NSUTF8StringEncoding error:nil];
    
    //JSCErrorHandler *eh = [[[JSCErrorHandler alloc] init] autorelease];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    
    #warning add this delegate back in
    
    //JSCocoaController *jsController = [t jsController];
    //jsController.delegate = eh;
    
    [[t env] setObject:[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]] forKey:@"scriptURL"];
    [[t env] setObject:[[NSURL fileURLWithPath:[NSString stringWithUTF8String:argv[1]]] URLByDeletingLastPathComponent] forKey:@"scriptDirectoryURL"];
    
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
