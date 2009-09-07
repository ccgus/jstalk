//
//  main.m
//  JSTalk
//
//  Created by August Mueller on 1/14/09.
//  Copyright Flying Meat Inc 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
#ifdef __LP64__
    printf("__LP64__!\n");
    
    printf("%ld\n", sizeof(NSRect));
    
#endif

    return NSApplicationMain(argc, (const char **) argv);
}

