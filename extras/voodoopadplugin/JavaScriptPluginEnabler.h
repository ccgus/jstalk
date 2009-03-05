//
//  SketchPageController.h
//  SketchPage
//
//  Created by August Mueller on 4/21/08.
//  Copyright 2008 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <VPPlugin/VPPlugin.h>

@interface JavaScriptPluginEnabler :  VPPlugin <VPEventRunner>  {
    NSMutableDictionary *_scriptsData;
    
    NSTextView *_nonRetainedCurrentTextView;
    
}


@property (retain) NSMutableDictionary *scriptsData;

- (NSString*) scriptsDir;

- (void) registerScript:(NSString*)scriptPath;

@end
