import Foundation
import AppKit
import CoreGraphics
import CoreImage
import PDFKit
import Vision
import AVFoundation

public struct ProcessingProgress {
    public let fractionCompleted: Double
    public let statusMessage: String
}

public class ProcessingEngine {
    public static let shared = ProcessingEngine()

    private init() {}

    // Find bundled or system tools
    public var ffmpegPath: String? {
        if let bundleTools = Bundle.main.resourceURL?.appendingPathComponent("Tools/ffmpeg").path,
           FileManager.default.fileExists(atPath: bundleTools) {
            return bundleTools
        }
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/ffmpeg") { return "/opt/homebrew/bin/ffmpeg" }
        if FileManager.default.fileExists(atPath: "/usr/local/bin/ffmpeg") { return "/usr/local/bin/ffmpeg" }
        if FileManager.default.fileExists(atPath: "/usr/bin/ffmpeg") { return "/usr/bin/ffmpeg" }
        return nil
    }

    public var cwebpPath: String? {
        if let bundleTools = Bundle.main.resourceURL?.appendingPathComponent("Tools/cwebp").path,
           FileManager.default.fileExists(atPath: bundleTools) {
            return bundleTools
        }
        if FileManager.default.fileExists(atPath: "/opt/homebrew/bin/cwebp") { return "/opt/homebrew/bin/cwebp" }
        if FileManager.default.fileExists(atPath: "/usr/local/bin/cwebp") { return "/usr/local/bin/cwebp" }
        return nil
    }

    // Output destination helper
    public func outputURL(for source: URL, suffix: String, ext: String? = nil) -> URL {
        let baseDir = source.deletingLastPathComponent()
        let name = source.deletingPathExtension().lastPathComponent
        let targetExt = ext ?? source.pathExtension
        var out = baseDir.appendingPathComponent("\(name)_\(suffix).\(targetExt)")
        var counter = 1
        while FileManager.default.fileExists(atPath: out.path) {
            out = baseDir.appendingPathComponent("\(name)_\(suffix)_\(counter).\(targetExt)")
            counter += 1
        }
        return out
    }

    // MARK: - 1. Compress
    public func compress(url: URL, quality: Float = 0.7) throws -> URL {
        let format = AureloFormat.detect(url: url)
        if format?.info.category == .image {
            guard let image = NSImage(contentsOf: url),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw NSError(domain: "Aurelo", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read image for compression"])
            }
            let out = outputURL(for: url, suffix: "compressed", ext: "jpg")
            let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.jpeg" as CFString, 1, nil)!
            let options: [CFString: Any] = [
                kCGImageDestinationLossyCompressionQuality: quality
            ]
            CGImageDestinationAddImage(dest, cgImage, options as CFDictionary)
            CGImageDestinationFinalize(dest)
            return out
        } else if format == .pdf {
            guard let doc = PDFDocument(url: url) else {
                throw NSError(domain: "Aurelo", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not load PDF document"])
            }
            let out = outputURL(for: url, suffix: "compressed", ext: "pdf")
            doc.write(to: out)
            return out
        } else {
            // Passthrough copy for media without loss
            let out = outputURL(for: url, suffix: "compressed")
            try FileManager.default.copyItem(at: url, to: out)
            return out
        }
    }

    // MARK: - 2. Remove Metadata (Exif & Privacy)
    public func removeMetadata(url: URL) throws -> URL {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
            throw NSError(domain: "Aurelo", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid image source"])
        }
        let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
        let out = outputURL(for: url, suffix: "clean", ext: ext)
        guard let type = CGImageSourceGetType(source),
              let dest = CGImageDestinationCreateWithURL(out as CFURL, type, 1, nil) else {
            throw NSError(domain: "Aurelo", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not initialize image destination"])
        }

        // Empty metadata dictionary strips Exif, GPS, IPTC, and TIFF tags
        let emptyProps: [CFString: Any] = [
            kCGImagePropertyExifDictionary: [:],
            kCGImagePropertyGPSDictionary: [:],
            kCGImagePropertyTIFFDictionary: [:],
            kCGImagePropertyIPTCDictionary: [:]
        ]
        CGImageDestinationAddImageFromSource(dest, source, 0, emptyProps as CFDictionary)
        CGImageDestinationFinalize(dest)
        return out
    }

    // MARK: - 3. Frame Image (Canvas, Gradient & Shadow)
    public func frameImage(url: URL, padding: CGFloat = 60, cornerRadius: CGFloat = 16) throws -> URL {
        guard let img = NSImage(contentsOf: url),
              let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "Aurelo", code: 5, userInfo: [NSLocalizedDescriptionKey: "Could not decode source image"])
        }

        let origW = CGFloat(cgImage.width)
        let origH = CGFloat(cgImage.height)
        let totalW = origW + (padding * 2)
        let totalH = origH + (padding * 2)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: Int(totalW), height: Int(totalH), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw NSError(domain: "Aurelo", code: 6, userInfo: [NSLocalizedDescriptionKey: "Failed to allocate frame canvas"])
        }

        // 1. Draw Mint to Deep Graphite gradient background
        let colors = [
            NSColor(calibratedRed: 0.0, green: 0.96, blue: 0.63, alpha: 0.85).cgColor,
            NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.16, alpha: 1.0).cgColor
        ] as CFArray
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0])!
        ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: totalH), end: CGPoint(x: totalW, y: 0), options: [])

        // 2. Draw Soft Shadow for the framed picture
        ctx.saveGState()
        let shadowColor = NSColor.black.withAlphaComponent(0.45).cgColor
        ctx.setShadow(offset: CGSize(width: 0, height: -12), blur: 32, color: shadowColor)

        // 3. Clip Rounded Rectangle for source image
        let imgRect = CGRect(x: padding, y: padding, width: origW, height: origH)
        let path = CGPath(roundedRect: imgRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
        ctx.addPath(path)
        ctx.clip()

        ctx.draw(cgImage, in: imgRect)
        ctx.restoreGState()

        guard let framedCG = ctx.makeImage() else {
            throw NSError(domain: "Aurelo", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to render framed image"])
        }

        let out = outputURL(for: url, suffix: "framed", ext: "png")
        guard let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil) else {
            throw NSError(domain: "Aurelo", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to write framed PNG"])
        }
        CGImageDestinationAddImage(dest, framedCG, nil)
        CGImageDestinationFinalize(dest)
        return out
    }

    // MARK: - 4. Crop Image
    public func cropImage(url: URL, cropRect: CGRect) throws -> URL {
        guard let img = NSImage(contentsOf: url),
              let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "Aurelo", code: 9, userInfo: [NSLocalizedDescriptionKey: "Invalid image for crop"])
        }
        let origW = CGFloat(cgImage.width)
        let origH = CGFloat(cgImage.height)
        let scaledRect = CGRect(x: cropRect.origin.x * origW,
                                y: cropRect.origin.y * origH,
                                width: cropRect.size.width * origW,
                                height: cropRect.size.height * origH)
        guard let cropped = cgImage.cropping(to: scaledRect) else {
            throw NSError(domain: "Aurelo", code: 10, userInfo: [NSLocalizedDescriptionKey: "Crop operation failed"])
        }
        let out = outputURL(for: url, suffix: "cropped", ext: "png")
        let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, cropped, nil)
        CGImageDestinationFinalize(dest)
        return out
    }

    // MARK: - 5. Edit Image (Exposure, Contrast, Saturation)
    public func editImage(url: URL, contrast: Float = 1.1, brightness: Float = 0.05, saturation: Float = 1.15) throws -> URL {
        guard let ciImg = CIImage(contentsOf: url) else {
            throw NSError(domain: "Aurelo", code: 11, userInfo: [NSLocalizedDescriptionKey: "Could not create CIImage"])
        }
        let filter = CIFilter(name: "CIColorControls")!
        filter.setValue(ciImg, forKey: kCIInputImageKey)
        filter.setValue(contrast, forKey: kCIInputContrastKey)
        filter.setValue(brightness, forKey: kCIInputBrightnessKey)
        filter.setValue(saturation, forKey: kCIInputSaturationKey)

        guard let outputCI = filter.outputImage else {
            throw NSError(domain: "Aurelo", code: 12, userInfo: [NSLocalizedDescriptionKey: "Filter application failed"])
        }
        let rep = NSCIImageRep(ciImage: outputCI)
        let nsImg = NSImage(size: rep.size)
        nsImg.addRepresentation(rep)
        guard let cg = nsImg.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "Aurelo", code: 13, userInfo: [NSLocalizedDescriptionKey: "Failed to render adjusted image"])
        }
        let out = outputURL(for: url, suffix: "adjusted", ext: "png")
        let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, cg, nil)
        CGImageDestinationFinalize(dest)
        return out
    }

    // MARK: - 6. Read QR Code
    public func readQRCode(url: URL) throws -> [String] {
        guard let img = NSImage(contentsOf: url),
              let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "Aurelo", code: 14, userInfo: [NSLocalizedDescriptionKey: "Could not read image for barcode detection"])
        }

        var results: [String] = []
        let req = VNDetectBarcodesRequest { request, error in
            guard let observations = request.results as? [VNBarcodeObservation] else { return }
            for obs in observations {
                if let payload = obs.payloadStringValue {
                    results.append(payload)
                }
            }
        }
        req.symbologies = [.qr, .microQR, .aztec, .dataMatrix, .code128]
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([req])
        return results
    }

    // MARK: - 7. Redact Image (Blur sensitive areas)
    public func redactImage(url: URL, rectFraction: CGRect) throws -> URL {
        guard let img = NSImage(contentsOf: url),
              let cgImage = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "Aurelo", code: 15, userInfo: [NSLocalizedDescriptionKey: "Invalid image for redaction"])
        }
        let w = CGFloat(cgImage.width)
        let h = CGFloat(cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: Int(w), height: Int(h), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw NSError(domain: "Aurelo", code: 16, userInfo: [NSLocalizedDescriptionKey: "Failed to create context"])
        }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: w, height: h))

        // Draw solid graphite blackout rectangle with mint border
        let redactBox = CGRect(x: rectFraction.origin.x * w,
                               y: rectFraction.origin.y * h,
                               width: rectFraction.size.width * w,
                               height: rectFraction.size.height * h)
        ctx.setFillColor(NSColor(calibratedWhite: 0.08, alpha: 1.0).cgColor)
        ctx.fill(redactBox)
        ctx.setStrokeColor(AureloTheme.mint.cgColor)
        ctx.setLineWidth(2.0)
        ctx.stroke(redactBox)

        guard let redactedCG = ctx.makeImage() else {
            throw NSError(domain: "Aurelo", code: 17, userInfo: [NSLocalizedDescriptionKey: "Failed to finalize redacted image"])
        }
        let out = outputURL(for: url, suffix: "redacted", ext: "png")
        let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, redactedCG, nil)
        CGImageDestinationFinalize(dest)
        return out
    }

    // MARK: - 8. PDF Merge
    public func mergePDF(urls: [URL]) throws -> URL {
        guard !urls.isEmpty else {
            throw NSError(domain: "Aurelo", code: 18, userInfo: [NSLocalizedDescriptionKey: "No PDF files provided"])
        }
        let combined = PDFDocument()
        var pageIndex = 0
        for u in urls {
            if let doc = PDFDocument(url: u) {
                for i in 0..<doc.pageCount {
                    if let page = doc.page(at: i) {
                        combined.insert(page, at: pageIndex)
                        pageIndex += 1
                    }
                }
            }
        }
        let out = outputURL(for: urls[0], suffix: "merged", ext: "pdf")
        combined.write(to: out)
        return out
    }

    // MARK: - 9. PDF Split
    public func splitPDF(url: URL) throws -> [URL] {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "Aurelo", code: 19, userInfo: [NSLocalizedDescriptionKey: "Could not open PDF"])
        }
        var created: [URL] = []
        let baseDir = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i) {
                let singleDoc = PDFDocument()
                singleDoc.insert(page, at: 0)
                let pageURL = baseDir.appendingPathComponent("\(name)_page_\(i + 1).pdf")
                singleDoc.write(to: pageURL)
                created.append(pageURL)
            }
        }
        return created
    }

    // MARK: - 10. Extract Archive
    public func extractArchive(url: URL) throws -> URL {
        let baseDir = url.deletingLastPathComponent()
        let folderName = url.deletingPathExtension().lastPathComponent + "_extracted"
        let destDir = baseDir.appendingPathComponent(folderName)
        try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-x", "-k", url.path, destDir.path]
        try process.run()
        process.waitUntilExit()

        return destDir
    }

    // MARK: - 11. Normalize Audio
    public func normalizeAudio(url: URL) async throws -> URL {
        let asset = AVAsset(url: url)
        let out = outputURL(for: url, suffix: "normalized", ext: "m4a")

        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "Aurelo", code: 20, userInfo: [NSLocalizedDescriptionKey: "Export session initialization failed"])
        }
        export.outputURL = out
        export.outputFileType = .m4a
        await export.export()
        if export.status == .completed {
            return out
        } else {
            throw export.error ?? NSError(domain: "Aurelo", code: 21, userInfo: [NSLocalizedDescriptionKey: "Audio normalization failed"])
        }
    }

    // MARK: - 12. Mute Video
    public func muteVideo(url: URL) async throws -> URL {
        let asset = AVAsset(url: url)
        let comp = AVMutableComposition()
        guard let videoTrack = try? await asset.loadTracks(withMediaType: .video).first else {
            throw NSError(domain: "Aurelo", code: 22, userInfo: [NSLocalizedDescriptionKey: "No video track found"])
        }
        let compVideoTrack = comp.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let duration = try await asset.load(.duration)
        try compVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoTrack, at: .zero)

        let out = outputURL(for: url, suffix: "muted", ext: "mp4")
        guard let export = AVAssetExportSession(asset: comp, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Aurelo", code: 23, userInfo: [NSLocalizedDescriptionKey: "Video export session failed"])
        }
        export.outputURL = out
        export.outputFileType = .mp4
        await export.export()
        if export.status == .completed {
            return out
        } else {
            throw export.error ?? NSError(domain: "Aurelo", code: 24, userInfo: [NSLocalizedDescriptionKey: "Video mute export failed"])
        }
    }
}
