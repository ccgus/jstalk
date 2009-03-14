//
//  JSTNSStringExtras.m
//  samplejstalkextra
//
//  Created by August Mueller on 3/14/09.
//  Copyright 2009 Flying Meat Inc. All rights reserved.
//

#import "JSTNSStringExtras.h"

// http://discuss.fogcreek.com/techinterview/default.asp?cmd=show&ixPost=2077
void JSTStrReverse3(unichar* str, int len);

/* Definition of the recurs_string() function */

void JSTStrReverse3(unichar* str, int len) {
    int i, j;
    unichar temp;
    i = j = temp = 0;
    
    for (i=0, j = len - 1; i <= j; i++, j--) {
        temp = str[i];
        str[i] = str[j];
        str[j] = temp;
    }
}

@implementation NSString (JSTNSStringExtras)

- (NSString*) reversedString {
    
    unichar *uString = malloc(([self length] * sizeof(unichar)) + 1);
    
    [self getCharacters:uString];
    
    JSTStrReverse3(uString, [self length]);
    
    NSString *s = [NSString stringWithCharacters:uString length:[self length]];
    
    free(uString);
    
    return s;
}

@end
