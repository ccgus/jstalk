#import <Cocoa/Cocoa.h>
#import "JSTListener.h"
#import "JSTalk.h"

int main(int argc, char *argv[]) {
    
    if (argc < 2) {
        printf("usage: %s <path to file>\n", argv[0]);
        return 1;
    }
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    NSString *s = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:argv[1]]
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
    
    JSTalk *t = [[[JSTalk alloc] init] autorelease];
    
    if ([s hasPrefix:@"#!"]) {
        
        NSRange r = [s rangeOfString:@"\n"];
        
        if (r.location != NSNotFound) {
            s = [s substringFromIndex:r.location];
        }
    }
    
    [t executeString:s];
    
    [pool release];
}
