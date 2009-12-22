/* MVMailBundle.h created by dave on Wed 08-Sep-1999 */

#import <Cocoa/Cocoa.h>

#ifdef SNOW_LEOPARD

@interface MVMailBundle : NSObject
{
}

+ (id)allBundles;
+ (id)composeAccessoryViewOwners;
+ (void)registerBundle;
+ (id)sharedInstance;
+ (BOOL)hasPreferencesPanel;
+ (id)preferencesOwnerClassName;
+ (id)preferencesPanelName;
+ (BOOL)hasComposeAccessoryViewOwner;
+ (id)composeAccessoryViewOwnerClassName;
- (void)dealloc;
- (void)_registerBundleForNotifications;

@end

#elif defined(LEOPARD)

@interface MVMailBundle : NSObject
{
}

+ (id)allBundles;
+ (id)composeAccessoryViewOwners;
+ (void)registerBundle;
+ (id)sharedInstance;
+ (BOOL)hasPreferencesPanel;
+ (id)preferencesOwnerClassName;
+ (id)preferencesPanelName;
+ (BOOL)hasComposeAccessoryViewOwner;
+ (id)composeAccessoryViewOwnerClassName;
- (void)dealloc;
- (void)_registerBundleForNotifications;

@end

#elif defined(TIGER)

@interface MVMailBundle : NSObject
{
}

+ (id)allBundles;
+ (id)composeAccessoryViewOwners;
+ (void)registerBundle;
+ (id)sharedInstance;
+ (BOOL)hasPreferencesPanel;
+ (id)preferencesOwnerClassName;
+ (id)preferencesPanelName;
+ (BOOL)hasComposeAccessoryViewOwner;
+ (id)composeAccessoryViewOwnerClassName;
- (void)dealloc;
- (void)_registerBundleForNotifications;

@end

#else

@interface MVMailBundle:NSObject
{
}

+ allBundles;
+ composeAccessoryViewOwners;
+ (void)registerBundle; // Must be called to force registering preferences
+ sharedInstance;
+ (BOOL)hasPreferencesPanel;
+ preferencesOwnerClassName;
+ preferencesPanelName;
+ (BOOL)hasComposeAccessoryViewOwner;
+ composeAccessoryViewOwnerClassName;
- (void)dealloc;
- (void)_registerBundleForNotifications;

@end

#endif

// The following methods are called if implemented:
//- (MessageBody *) bodyWillBeEncoded:(MessageBody *)body forMessage:(Message *)message;
//- (MessageBody *) bodyWasEncoded:(MessageBody *)body forMessage:(Message *)message;
//- (NSData *) bodyWillBeDecoded:(NSData *)bodyData forMessage:(Message *)message;
//- (MessageBody *) bodyWasDecoded:(MessageBody *)body forMessage:(Message *)message; // Comes before messageWillBeDisplayedInView: and bodyData is not nil!
//- (MessageBody *) bodyWillBeForwarded:(MessageBody *)body forMessage:(Message *)message;
//- (void) messageWillBeDisplayedInView:(NSNotification *)notification;
// with MessageKey = displayed message in userInfo
// and MessageViewKey = view used for display

