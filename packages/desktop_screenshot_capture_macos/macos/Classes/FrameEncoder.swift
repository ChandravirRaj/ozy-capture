import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum FrameEncoder {
  static func encode(image: CGImage, format: String, quality: Int, outputPath: String) throws -> Int {
    let url = URL(fileURLWithPath: outputPath)
    let directory = url.deletingLastPathComponent()
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    } catch {
      throw CapturePluginError.directoryCreationFailed
    }

    guard let destination = CGImageDestinationCreateWithURL(
      url as CFURL,
      format == "png" ? UTType.png.identifier as CFString : UTType.jpeg.identifier as CFString,
      1,
      nil
    ) else {
      throw CapturePluginError.encodingFailed("Could not create image destination")
    }

    let options: [CFString: Any]
    if format == "png" {
      options = [:]
    } else {
      options = [kCGImageDestinationLossyCompressionQuality: NSNumber(value: Double(quality) / 100.0)]
    }

    CGImageDestinationAddImage(destination, image, options as CFDictionary)
    if !CGImageDestinationFinalize(destination) {
      throw CapturePluginError.encodingFailed("Image destination finalize failed")
    }

    let attributes = try FileManager.default.attributesOfItem(atPath: outputPath)
    return attributes[.size] as? Int ?? 0
  }
}
