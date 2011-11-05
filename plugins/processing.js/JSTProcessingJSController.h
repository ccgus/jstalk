#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

@interface JSTProcessingJSController : NSWindowController {
    IBOutlet WebView *webView;
}

+ (id)processingControllerWithName:(NSString*)name;

- (void)processFileAtURL:(NSURL*)scriptURL;

@end

@interface NSDocument (ProcessingExtras)

@end
