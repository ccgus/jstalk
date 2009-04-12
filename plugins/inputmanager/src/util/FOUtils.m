//
//  FOUtils.m
//  flyopts
//
//  Created by August Mueller on 11/20/05.
//  Copyright 2005 Flying Meat Inc.. All rights reserved.
//

#import "FOUtils.h"


// thank you http://cocoadev.com/index.pl?MethodSwizzling

#import <objc/objc-class.h>

void MethodSwizzle(Class aClass, SEL orig_sel, SEL alt_sel) {
    Method orig_method = nil, alt_method = nil;
    
    // First, look for the methods
    orig_method = class_getInstanceMethod(aClass, orig_sel);
    alt_method = class_getInstanceMethod(aClass, alt_sel);
    
    // If both are found, swizzle them
    if ((orig_method != nil) && (alt_method != nil)) {
        char *temp1;
        IMP temp2;
        
        temp1 = orig_method->method_types;
        orig_method->method_types = alt_method->method_types;
        alt_method->method_types = temp1;
        
        temp2 = orig_method->method_imp;
        orig_method->method_imp = alt_method->method_imp;
        alt_method->method_imp = temp2;
    }
}

NSString *appicationSupportFolder(NSString *appName, NSString *subFolder) {
    NSArray *paths;
    
    NSFileManager *fm = [NSFileManager defaultManager]; 
    NSString *path = nil;
    
    paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES); 
    
    if ([paths count] > 0) { 
        
        NSString *appSupport    = [[paths objectAtIndex:0] 
                                    stringByAppendingPathComponent:@"Application Support"];
        NSString *appNameSupport = [appSupport stringByAppendingPathComponent:appName];
        NSDictionary *attributes = [NSDictionary dictionary];
        
        BOOL isDir;
        if (!([fm fileExistsAtPath:appNameSupport isDirectory:&isDir] && isDir)) {
            
            if (![fm createDirectoryAtPath:appNameSupport attributes:attributes]) {
                NSLog(@"could not create the directory '%@'", appNameSupport);
                return nil;
            }
        }
        
        if (!subFolder) {
            return appNameSupport;
        }
        
        subFolder   = [appNameSupport stringByAppendingPathComponent:subFolder];
        
        if (!([fm fileExistsAtPath:subFolder isDirectory:&isDir] && isDir)) {
            if (![fm createDirectoryAtPath:subFolder attributes:attributes]) {
                NSLog(@"could not create the directory '%@'", subFolder);
                return nil;
            }
        }
        
        path = subFolder;
    }
    
    return path;
}

BOOL isTextEdit() {
    return [@"com.apple.TextEdit" isEqualToString:[[NSBundle mainBundle] bundleIdentifier]];
}
