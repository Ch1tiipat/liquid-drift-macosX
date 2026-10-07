import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Writes uncompressed TIFF images of about 1, 10 and 50 MB into the scratch folder: plain colour, and random
/// noise. Preview copies images as PNG, which shrinks plain colour to a few KB; noise keeps the copy large.
enum Images {
    /// Square edge in pixels for RGBA8 data of about the given number of megabytes.
    static let sizes: [(name: String, edge: Int)] = [("1mb", 512), ("10mb", 1620), ("50mb", 3620)]

    static func write(into scratch: String) -> Bool {
        for (name, edge) in sizes + sizes.map({ ("noise-" + $0.name, $0.edge) }) {
            guard let image = plainImage(edge: edge, noise: name.hasPrefix("noise-")) else { Log.line("could not draw \(name)"); return false }
            let url = URL(fileURLWithPath: scratch).appendingPathComponent("s005-\(name).tiff")
            guard let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.tiff.identifier as CFString, 1, nil) else {
                Log.line("could not create \(name)"); return false
            }
            // Compression 1 = none, so the file size follows the pixel count.
            let props = [kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFCompression: 1]] as CFDictionary
            CGImageDestinationAddImage(dest, image, props)
            guard CGImageDestinationFinalize(dest) else { Log.line("could not write \(name)"); return false }
            let bytes = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? NSNumber)?.intValue ?? 0
            Log.line("wrote s005-\(name).tiff: \(edge)x\(edge) px, \(bytes) bytes")
        }
        return true
    }

    private static func plainImage(edge: Int, noise: Bool) -> CGImage? {
        guard let ctx = CGContext(data: nil, width: edge, height: edge, bitsPerComponent: 8, bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        ctx.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: edge, height: edge))
        if noise, let pixels = ctx.data {
            // Random colour channels, opaque alpha, so PNG cannot compress the copy much.
            arc4random_buf(pixels, ctx.bytesPerRow * edge)
            let bytes = pixels.assumingMemoryBound(to: UInt8.self)
            for i in stride(from: 3, to: ctx.bytesPerRow * edge, by: 4) { bytes[i] = 255 }
        }
        return ctx.makeImage()
    }
}
