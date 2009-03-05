from Foundation import *
from AppKit import *
import time

def application(appName):
    appPath = NSWorkspace.sharedWorkspace().fullPathForApplication_(appName);
    
    if (not appPath):
        print("Could not find application '" + appName + "'")
        return None
    
    
    appBundle = NSBundle.bundleWithPath_(appPath)
    bundleId  = appBundle.bundleIdentifier()
    
    
    NSWorkspace.sharedWorkspace().launchAppWithBundleIdentifier_options_additionalEventParamDescriptor_launchIdentifier_(bundleId, NSWorkspaceLaunchWithoutActivation | NSWorkspaceLaunchAsync, None, None)
    
    port = bundleId + ".JSTalk"
    
    conn = None
    tries = 0
    
    while ((conn is None) and (tries < 10)):
        conn = NSConnection.connectionWithRegisteredName_host_(port, None)
        tries = tries + 1;
        
        if (not conn):
            time.sleep(1)
    
    if (not conn):
        print("Could not find a JSTalk connection to " + appName)
        return None
    
    return conn.rootProxy()
        

def proxyForApp(appName):
    return application(appName)