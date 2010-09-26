//
//  JSTUtil.h
//  jstalk
//
//  Created by August Mueller on 9/24/10.
//  Copyright 2010 Flying Meat Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "JSTBridge.h"
#include <ffi/ffi.h>

id JSTNSObjectFromValue(JSTBridge *bridge, JSValueRef value);
SEL JSTSelectorFromValue(JSTBridge *bridge, JSValueRef value);
ffi_type* JSTFFITypeForTypeEncoding(NSString *encoding);
int JSTSizeOfTypeEncoding(NSString *encoding);
NSString *JSTStringForFFIType(ffi_type* type);
ffi_type* JSTFFITypeForBridgeDeclaredType(NSString *type);
