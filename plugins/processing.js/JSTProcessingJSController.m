#import "JSTProcessingJSController.h"

#define debug NSLog

NSMutableDictionary *JSTProcessingJSControllers = 0x00;

@implementation JSTProcessingJSController

+ (void)load {
    
    if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"org.jstalk.JSTalkEditor"]) {
        NSMenu *mainMenu = [NSApp mainMenu];
        
        NSMenuItem *scriptMenuItem = [[mainMenu itemArray] objectAtIndex:4];
        
        NSMenuItem *item = [[scriptMenuItem submenu] addItemWithTitle:@"Run as Processing.js" action:@selector(JSTProcessingJSControllerRunProcessingJS:) keyEquivalent:@"p"];
        
        [item setKeyEquivalentModifierMask:NSControlKeyMask | NSCommandKeyMask];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];

    }
}

+ (id)processingControllerWithName:(NSString*)name {
    
    if (!JSTProcessingJSControllers) {
        JSTProcessingJSControllers = [[NSMutableDictionary dictionary] retain];
    }
    
    if ([JSTProcessingJSControllers objectForKey:name]) {
        return [JSTProcessingJSControllers objectForKey:name];
    }
    
    
    JSTProcessingJSController *whatever = [[[JSTProcessingJSController alloc] initWithWindowNibName:@"JSTProcessingJSControllerWindow"] autorelease];
    
    [JSTProcessingJSControllers setObject:whatever forKey:name];
    
    return whatever;
}

- (void)awakeFromNib {
    [webView setResourceLoadDelegate:self];
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
    NSBeep();
    NSLog(@"%@", error);
}

- (void)processFileAtURL:(NSURL*)scriptURL {
    
    [self setWindowFrameAutosaveName:[[scriptURL path] stringByAppendingString:@"-processing.js"]];
    
    if (![[self window] isVisible]) {
        //[[self window] setFrameAutosaveName:[scriptURL path]];
        [[self window] makeKeyAndOrderFront:self];
    }
    
    NSURL *processingScript = [[NSBundle bundleForClass:[self class]] URLForResource:@"processing" withExtension:@"js"];
    
    NSString *html = [NSString stringWithFormat:@"<!doctype html><html><head><script src=\"file://%@\"></script></head><body style=\"margin: 0px;\"><canvas data-processing-sources=\"file://%@\"></canvas></body></html>", [processingScript path], [scriptURL path]];
    
    [[webView mainFrame] loadHTMLString:html baseURL:0x00];
    
    [[self window] setTitle:[scriptURL lastPathComponent]];
}

@end

@implementation NSDocument (ProcessingExtras)

- (void)JSTProcessingJSControllerRunProcessingJS:(id)sender {
    
    [self saveDocument:sender];
    
    if (![self fileURL]) {
        [NSAlert alertWithMessageText:@"Please Save File" defaultButton:@"OK, I'll save it" alternateButton:0x00 otherButton:0x00 informativeTextWithFormat:@"Sorry, but you've got to save this file before you try and use it as processing script"];
        return;
    }
    
    JSTProcessingJSController *c = [JSTProcessingJSController processingControllerWithName:[[self fileURL] path]];
    
    [c processFileAtURL:[self fileURL]];
}

@end
