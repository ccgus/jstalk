#import <Cocoa/Cocoa.h>

// pass in -DDEBUG to gcc in development builds to see some output when you 
// don't feel like using a debugger.

#ifdef DEBUG
//#define debug(...) NSLog(__VA_ARGS__)
#else
#define debug(...)
#endif

enum {
    ACBitmapLayer = 1,
    ACShapeLayer = 2,
    ACGroupLayer = 3,
};

enum {
    ACRectangleGraphic = 1,
    ACOvalGraphic = 2,
    ACLineGraphic = 3,
    ACTextGraphic = 4,
    ACImageGraphic = 5,
    ACBezierGraphic = 6,
};

#define ACPLUGIN_SUPPORT 1

// forward decl.
@protocol ACBitmapTool;
@protocol ACImageIOProvider;
@protocol ACImageFilter;
@protocol ACLayer;

@protocol ACPluginManager

- (BOOL)addFilterMenuTitle:(NSString*)menuTitle
        withSuperMenuTitle:(NSString*)superMenuTitle
                    target:(id)target
                    action:(SEL)selector
             keyEquivalent:(NSString*)keyEquivalent
 keyEquivalentModifierMask:(NSUInteger)mask
                userObject:(id)userObject;

- (BOOL)addActionMenuTitle:(NSString*)menuTitle
        withSuperMenuTitle:(NSString*)superMenuTitle
                    target:(id)target
                    action:(SEL)selector
             keyEquivalent:(NSString*)keyEquivalent
 keyEquivalentModifierMask:(NSUInteger)mask
                userObject:(id)userObject;


- (void)registerIOProviderForReading:(id<ACImageIOProvider>)provider forUTI:(NSString*)uti;
- (void)registerIOProviderForWriting:(id<ACImageIOProvider>)provider forUTI:(NSString*)uti;
- (void)registerFilterName:(NSString*)filterName constructor:(Class<ACImageFilter>)filterClass;
@end



@interface NSApplication (ACPluginManagerAdditions)
- (id<ACPluginManager>)sharedPluginManager;
@end

@protocol ACPlugin 

/*
 This will create an instance of our plugin.  You really shouldn't need to
 worry about this at all.
 */
+ (id)plugin;

/*
 This gets called right before the plugin manager registers your plugin.
 I'm honestly not sure what you would use it for, but it seemed like a good
 idea at the time.
 */
- (void)willRegister:(id<ACPluginManager>)thePluginManager;

/*
 didRegister is called right after your plugin is all ready to go.
 */
- (void)didRegister;

/*
 Can we handle shape layers?  If yes, then our action is handed the layer instead of a CIImage
 
 return [NSNumber numberWithBool:YES]; 
 
 NSNumber is used to be friendly with scripting languages.
 */
- (NSNumber*)worksOnShapeLayers:(id)userObject;


/*
 How about a more general type of "do you work on this type of layer" question:
 
 return [NSNumber numberWithBool:YES];
 
 NSNumber is used to be friendly with scripting languages.
 
 Added in version 3.5
 
 */
- (NSNumber*)validateForLayer:(id<ACLayer>)layer;

@end



@protocol ACLayer <NSObject>
/* There are currently three types of layers.  "Bitmap" layers which contain pixels,
 and "Shape" layers which contain Text.  And then Group layers, which is a group of layers.
 
 And maybe other things eventually.
 
 Check out the ACLayerType enum for the constants to tell which is which.
 */
- (int)layerType;


// grab a CIImage representation of the layer.
- (CIImage*)CIImage;

@property (assign) BOOL visible;
@property (assign) float opacity;
@property (assign) CGBlendMode compositingMode; // aka, also the blend mode.
@property (retain, nonatomic) NSString *layerName;

@end



@protocol ACShapeLayer <ACLayer>

- (NSArray *)selectedGraphics;
- (NSArray *)graphics;

- (id)addRectangleWithBounds:(NSRect)bounds;
- (id)addOvalWithBounds:(NSRect)bounds;
- (id)addTextWithBounds:(NSRect)bounds;

@end

@protocol ACBitmapLayer <ACLayer>

// set a CIImage on the layer, to be a "preview".  Make sure to set it to nil when you are
// done with whatever it is you are doing.
- (void)setPreviewCIImage:(CIImage*)img;

// apply a ciimage to the layer.
- (void)applyCIImageFromFilter:(CIImage*)img;

// EXPERIMENTAL new in 1.1 
// get a CGBitmapContext that we can draw on.
- (CGContextRef)drawableContext;

// EXPERIMENTAL new in 1.1 
// commit the changes we made to the context, for undo support
- (void)commitFrameOfDrawableContext:(NSRect)r;

// EXPERIMENTAL new in 1.1 
// find out where on our layer the current mouse event is pointing to
- (NSPoint)layerPointFromEvent:(NSEvent*)theEvent;

// EXPERIMENTAL new in 1.1 
// tell the layer it needs to be updated
- (void)setNeedsDisplayInRect:(NSRect)invalidRect;


// what the origin of the bottom left corner of the layer is.  It's a silly name, which is why I've added setFrameOrigin: and frameOrigin below.
@property (assign) NSPoint drawDelta;


// same as drawDelta, but with a better name.
- (void)setFrameOrigin:(NSPoint)newOrigin;
- (NSPoint)frameOrigin;


@end

@protocol ACGroupLayer <ACLayer>

- (NSArray *)layers;

- (void)addLayer:(id<ACLayer>)l atIndex:(NSInteger)idx;

- (id<ACBitmapLayer>)insertCGImage:(CGImageRef)img atIndex:(NSUInteger)idx withName:(NSString*)layerName;

@end

@protocol ACGraphic <NSObject>

- (int)graphicType;

- (void)setDrawsFill:(BOOL)flag;
- (BOOL)drawsFill;

- (void)setFillColor:(NSColor *)fillColor;
- (NSColor *)fillColor;

- (void)setDrawsStroke:(BOOL)flag;
- (BOOL)drawsStroke;

- (void)setStrokeColor:(NSColor *)strokeColor;
- (NSColor *)strokeColor;

- (void)setStrokeLineWidth:(CGFloat)width;
- (CGFloat)strokeLineWidth;

- (NSRect)bounds;

- (BOOL)hasCornerRadius;
- (void)setHasCornerRadius:(BOOL)flag;

- (CGFloat)cornerRadius;
- (void)setCornerRadius:(CGFloat)newCornerRadius;

- (BOOL)hasShadow;
- (void)setHasShadow:(BOOL)flag;

- (CGFloat)shadowBlurRadius;
- (void)setShadowBlurRadius:(CGFloat)newShadowBlurRadius;

- (NSSize)shadowOffset;
- (void)setShadowOffset:(NSSize)newShadowOffset;

- (NSBezierPath *)bezierPath;

- (int)graphicType;

@end

@protocol ACDocument <NSObject> // this inherits from NSDocument

// grab an array of layers in the document.
- (NSArray*)layers;

// grab the current layer.
- (id<ACLayer>)currentLayer;

// crop to the given rect.
- (void)cropToRect:(NSRect)cropRect;

// start cropping with the given bounds.
- (void)beginCroppingWithRect:(NSRect)cropBounds;

// scale the image to the given size.
- (void)scaleImageToSize:(NSSize)newSize;

- (void)scaleImageToHeight:(CGFloat)newHeight;
- (void)scaleImageToWidth:(CGFloat)newWidth;

// resize the image to the given size.
- (void)resizeImageToSize:(NSSize)newSize;

// find the size of the canvas
- (NSSize)canvasSize;
- (void)setCanvasSize:(NSSize)s;
- (void)setCanvasSize:(NSSize)newSize usingAnchor:(NSString *)anchor;

// new in 2.0

// returns the base group, which contains all the base layers.
- (id<ACGroupLayer>)baseGroup;


- (NSSize)dpi;
- (void)setDpi:(NSSize)newDpi;


- (CGColorSpaceRef)colorSpace;
- (void)setColorSpace:(CGColorSpaceRef)newColorSpace;


// new in 2.2:
- (void)askToCommitCurrentAccessory;

@end

@protocol ACToolPalette <NSObject> 

- (NSColor *)frontColor;
- (void)setFrontColor:(NSColor *)newFrontColor;

- (NSColor *)backColor;
- (void)setBackColor:(NSColor *)newBackColor;

@end




// EXPERIMENTAL new in 1.1
// UI taken out in 2.0 - do you want this?  Write to support@flyingmeat.com if so.
@protocol ACBitmapTool  <NSObject> 
- (void)mouseDown:(NSEvent*)theEvent onCanvas:(NSView*)canvas toLayer:(id<ACBitmapLayer>)layer;
- (NSCursor*)toolCursorAtScale:(CGFloat)scale;
- (NSString *)toolName;
- (NSView*)toolPaletteView;
@end


@protocol ACImageIOProvider  <NSObject> 

- (BOOL)writeDocument:(id<ACDocument>)document toURL:(NSURL *)absoluteURL ofType:(NSString *)type forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError;

- (BOOL)readImageForDocument:(id<ACDocument>)document fromURL:(NSURL *)absoluteURL ofType:(NSString *)type error:(NSError **)outError;

@end


@protocol ACUtilities <NSObject> 

- (BOOL)crushPNGData:(NSData*)pngData toPath:(NSString*)path;

@end

@interface NSApplication (AcornAdditions)

- (id<ACToolPalette>)toolPalette;
- (id<ACUtilities>)utilitiesHelper;

@end


@protocol ACFilterWindowController <NSObject>
- (void)setNeedsToUpdateImageForFilterController:(id<ACImageFilter>)controller;
@end

@protocol ACImageFilter <NSObject>
+ (id<ACImageFilter>)imageFilterWithName:(NSString*)name;
+ (id<ACImageFilter>)imageFilterWithName:(NSString*)name parameters:(NSDictionary*)params;
+ (BOOL)isLayerStyle;
+ (NSString*)localizedNameForFilterName:(NSString*)filterName;
- (NSString*)localizedName;
- (NSString*)name;
- (id<ACImageFilter>)copy;
- (NSDictionary*)parametersForSaving;
- (BOOL)isEnabled;
- (void)setIsEnabled:(BOOL)enabled;
- (CIImage*)outputImage;
- (void)setInputImage:(CIImage*)image;
- (NSViewController*)viewController;
- (void)unloadViewController;
- (void)assignFilterWindowController:(id<ACFilterWindowController>)filterWindowController; // don't retain this guy!
- (CGFloat)updateExpansion;
@end





/*
 CTGradient is in Acorn, it's just got a different name- "TSGradient".
 For more info on CTGradient, visit here:
 http://blog.oofn.net/2006/01/15/gradients-in-cocoa/
 
 You can use it like so:
 id fade = [NSClassFromString(@"TSGradient") gradientWithBeginningColor:[NSColor clearColor] endingColor:[NSColor blackColor]];
 */
@interface NSObject (TSGradientTrustMeItsThere)
+ (id)gradientWithBeginningColor:(NSColor *)begin endingColor:(NSColor *)end;
- (void)fillRect:(NSRect)rect angle:(CGFloat)angle;
@end

@interface CIImage (PXNSImageAdditions)
- (NSImage *)NSImageFromRect:(CGRect)r;
- (NSImage *)NSImage;
@end

@interface NSImage (PXNSImageAdditions)
- (CIImage *)CIImage;
@end

@interface NSDocumentController (ACNSDocumentControllerAdditions)
- (id)makeUntitledDocumentWithData:(NSData*)data;
@end




