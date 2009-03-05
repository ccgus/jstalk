
function main(image) {
    
    nsimg  = [image NSImage];
    extent = [image extent];
    
    xOffset = 5;
    yOffset = 35;
    curveHeight = 15;
    imageYOffset = 10;
    
    newSize = NSMakeSize(extent.size.width, extent.size.height + imageYOffset);
    
    newImage = [[[NSImage alloc] initWithSize:newSize] autorelease];
    
    [newImage lockFocus]
    
    // save the current state, so we don't have the shadow when
    // we draw the image below
    [NSGraphicsContext saveGraphicsState]
    
    shadow = [[[NSShadow alloc] init] autorelease];
    shadow.setShadowColor_(NSColor.blackColor().colorWithAlphaComponent_(.6))
    shadow.setShadowOffset_(NSMakeSize(0, -(yOffset + 5)))
    shadow.setShadowBlurRadius_(5)
    shadow.set()
    
    // make a curved path, at the bottom of our image.
    bezierPath = [NSBezierPath bezierPath]
    
    bezierPath.moveToPoint(NSMakePoint(xOffset, 40 + yOffset))
    bezierPath.lineToPoint(NSMakePoint(extent.size.width - xOffset, 40+ yOffset))
    bezierPath.lineToPoint(NSMakePoint(extent.size.width - xOffset, 10+ yOffset))
    
    bezierPath.curveToPoint_controlPoint1_controlPoint2_(NSMakePoint(newSize.width / 2, curveHeight + yOffset),
                                                         NSMakePoint(extent.size.width - xOffset, 10 + yOffset),
                                                         NSMakePoint(newSize.width *.75, curveHeight + yOffset))
    
    bezierPath.curveToPoint_controlPoint1_controlPoint2_(NSMakePoint(xOffset, 10 + yOffset),
                                                         NSMakePoint(newSize.width *.25, curveHeight + yOffset),
                                                         NSMakePoint(xOffset, 10 + yOffset))
    
    [bezierPath fill];
    
    // get rid of our shadow
    [NSGraphicsContext restoreGraphicsState];
    
    
    nsimg.drawAtPoint_fromRect_operation_fraction_(NSMakePoint(0, imageYOffset), NSMakeRect(0, 0, extent.size.width, extent.size.height), NSCompositeCopy, 1)
    
    // draw our border
    [[NSColor lightGrayColor] set];
    NSGraphicsContext.currentContext().setCompositingOperation_(NSCompositePlusDarker)
    NSBezierPath.bezierPathWithRect_(NSMakeRect(.5, imageYOffset + .5, extent.size.width - 1, extent.size.height - 1)).stroke()
    
    // we're done drawing to the image.
    [newImage unlockFocus]
    
    NSDocumentController.sharedDocumentController().newDocumentWithImageData_(newImage.TIFFRepresentation())
    
    return null;
    
}

