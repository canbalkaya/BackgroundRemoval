//
//  backgroundRemoval.swift
//  backgroundRemoval
//
//  Created by Ezaldeen on 17/03/2022.
//

#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif
import CoreML
import Vision

public struct BackgroundRemoval {
    public init() {
    }
    
    #if canImport(UIKit)
    ///@param uploadedImage of the input image
    ///@param filterSharpness tha sharpness of filter if needed (recommeneded)
    ///@param maskOnly pass true if you want the mask onl, not the output image
    
    public func removeBackground(image: UIImage, maskOnly: Bool = false) -> UIImage {
        
        let w = image.size.width
        let h = image.size.height

        /// determine whether width or height is greater
        let longer = max(w, h)
        /// create a Square size box
        let sz = CGSize(width: longer, height: longer)

        /// call scaling function to scale the image to the Square dimensions, using "aspect fit"
        let scaledImage = image.scaled(to: sz, scalingMode: .aspectFit)

        /// resize image to 320 * 320 before sending it to the model
        let resize =  scaledImage.resizeImage(width: 320, height: 320)
        
        /// init model and get result
        let model = try? LaLabsu2netp.init()
        let result = try? model?.prediction(in_0: buffer(from: resize)!)
        let out = UIImage(pixelBuffer: result!.out_p1)
        
        /// scale the image again to the longest dimension in the input image,
        let scaledOut = out!.scaled(to: sz, scalingMode: .aspectFit)
                
        // please pass this to the output image if you need to see the masked image
        let finalResult = scaledImage.maskImage(withMask: scaledOut.invertedImage()!)

        return maskOnly ? scaledOut : finalResult
    }
    #else
    ///@param uploadedImage of the input image
    ///@param filterSharpness tha sharpness of filter if needed (recommeneded)
    ///@param maskOnly pass true if you want the mask onl, not the output image
    
    public func removeBackground(image: NSImage, maskOnly: Bool = false) -> NSImage {
        
        let w = image.size.width
        let h = image.size.height

        /// determine whether width or height is greater
        let longer = max(w, h)
        /// create a Square size box
        let sz = CGSize(width: longer, height: longer)

        /// call scaling function to scale the image to the Square dimensions, using "aspect fit"
        let scaledImage = image.scaled(to: sz, scalingMode: .aspectFit)

        /// resize image to 320 * 320 before sending it to the model
        let resize =  scaledImage.resizeImage(width: 320, height: 320)
        
        /// init model and get result
        let model = try? LaLabsu2netp.init()
        let result = try? model?.prediction(in_0: buffer(from: resize)!)
        let out = NSImage(pixelBuffer: result!.out_p1)
        
        /// scale the image again to the longest dimension in the input image,
        let scaledOut = out!.scaled(to: sz, scalingMode: .aspectFit).imageRotatedByDegreess(degrees: 180).flipHorizontally()
                
        // please pass this to the output image if you need to see the masked image
        let finalResult = scaledImage.maskImage(withMask: scaledOut.invertedImage()!)

        return maskOnly ? scaledOut : finalResult
    }
    #endif
    
    #if canImport(UIKit)
    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }
    #else
    func buffer(from image: NSImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }

        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context!, flipped: false)
        image.draw(in: NSRect(x: 0, y: 0, width: image.size.width, height: image.size.height), from: .zero, operation: .copy, fraction: 1.0)
        NSGraphicsContext.restoreGraphicsState()

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
    #endif
}
