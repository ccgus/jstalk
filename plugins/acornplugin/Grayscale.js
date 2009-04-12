

function main(image) {
    
    var color   = [CIColor colorWithRed:0.5 green:0.5 blue:0.5]
    var filter  = [CIFilter filterWithName:"CIColorMonochrome"]
    
    [filter setDefaults]
    [filter setValue:image forKey:'inputImage']
    [filter setValue:color forKey:'inputColor']
    [filter setValue:1 forKey:'inputIntensity']
    
    return [filter valueForKey:'outputImage']
}

