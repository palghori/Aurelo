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

    // MARK: - 13. Create PDF from Images & Media
    public func createPDF(from urls: [URL]) throws -> URL {
        guard !urls.isEmpty else {
            throw NSError(domain: "Aurelo", code: 25, userInfo: [NSLocalizedDescriptionKey: "No files provided for PDF creation"])
        }
        let pdfDoc = PDFDocument()
        var pageIndex = 0

        for url in urls {
            let ext = url.pathExtension.lowercased()

            if ["jpg", "jpeg", "png", "webp", "heic", "tiff", "tif", "bmp", "avif", "gif"].contains(ext) {
                // Image → PDF page
                guard let image = NSImage(contentsOf: url) else { continue }
                if let pdfPage = PDFPage(image: image) {
                    pdfDoc.insert(pdfPage, at: pageIndex)
                    pageIndex += 1
                }
            } else if ext == "pdf" {
                // Existing PDF → append all its pages
                if let existingPDF = PDFDocument(url: url) {
                    for i in 0..<existingPDF.pageCount {
                        if let page = existingPDF.page(at: i) {
                            pdfDoc.insert(page, at: pageIndex)
                            pageIndex += 1
                        }
                    }
                }
            } else if ["txt", "md"].contains(ext) {
                // Text file → render as PDF page (US Letter: 612x792 pt)
                if let text = try? String(contentsOf: url, encoding: .utf8) {
                    let textView = NSTextView(frame: NSRect(x: 0, y: 0, width: 612, height: 792))
                    textView.string = text
                    textView.font = NSFont.systemFont(ofSize: 12)
                    textView.textColor = .black
                    textView.backgroundColor = .white
                    textView.layoutManager?.ensureLayout(for: textView.textContainer!)
                    let pdfData = textView.dataWithPDF(inside: textView.bounds)
                    if let textPDF = PDFDocument(data: pdfData) {
                        for i in 0..<textPDF.pageCount {
                            if let page = textPDF.page(at: i) {
                                pdfDoc.insert(page, at: pageIndex)
                                pageIndex += 1
                            }
                        }
                    }
                }
            }
        }

        guard pageIndex > 0 else {
            throw NSError(domain: "Aurelo", code: 26, userInfo: [NSLocalizedDescriptionKey: "No valid pages could be created from the selected files"])
        }

        let out = outputURL(for: urls[0], suffix: "created", ext: "pdf")
        pdfDoc.write(to: out)
        return out
    }

    // MARK: - 14. Video Snapshots (Still Frames)
    public func videoSnapshots(url: URL, count: Int = 1) async throws -> [URL] {
        let asset = AVAsset(url: url)
        let duration = try await asset.load(.duration)
        let totalSeconds = CMTimeGetSeconds(duration)
        guard totalSeconds > 0 else {
            throw NSError(domain: "Aurelo", code: 27, userInfo: [NSLocalizedDescriptionKey: "Invalid video duration"])
        }

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        var createdURLs: [URL] = []
        let timestamps: [Double] = count == 1 ? [min(1.0, totalSeconds / 2.0)] : (1...count).map { totalSeconds * Double($0) / Double(count + 1) }

        for (idx, sec) in timestamps.enumerated() {
            let time = CMTime(seconds: sec, preferredTimescale: 600)
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let suffix = count == 1 ? "snapshot" : "snapshot_\(idx + 1)"
            let out = outputURL(for: url, suffix: suffix, ext: "png")
            guard let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil) else { continue }
            CGImageDestinationAddImage(dest, cgImage, nil)
            CGImageDestinationFinalize(dest)
            createdURLs.append(out)
        }
        return createdURLs
    }

    // MARK: - 15. Concatenate Videos (Join)
    public func joinVideos(urls: [URL]) async throws -> URL {
        guard urls.count > 1 else {
            throw NSError(domain: "Aurelo", code: 28, userInfo: [NSLocalizedDescriptionKey: "Select at least 2 videos to concatenate"])
        }
        let composition = AVMutableComposition()
        guard let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            throw NSError(domain: "Aurelo", code: 29, userInfo: [NSLocalizedDescriptionKey: "Could not create composition video track"])
        }
        var compAudioTrack: AVMutableCompositionTrack? = nil

        var currentTime = CMTime.zero
        for u in urls {
            let asset = AVAsset(url: u)
            let duration = try await asset.load(.duration)
            if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
                try compVideoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: videoTrack, at: currentTime)
            }
            if let audioTrack = try await asset.loadTracks(withMediaType: .audio).first {
                if compAudioTrack == nil {
                    compAudioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
                }
                try compAudioTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: duration), of: audioTrack, at: currentTime)
            }
            currentTime = CMTimeAdd(currentTime, duration)
        }

        let out = outputURL(for: urls[0], suffix: "joined", ext: "mp4")
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Aurelo", code: 30, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize video join export"])
        }
        export.outputURL = out
        export.outputFileType = .mp4
        await export.export()
        if export.status == .completed {
            return out
        } else {
            throw export.error ?? NSError(domain: "Aurelo", code: 31, userInfo: [NSLocalizedDescriptionKey: "Video join failed"])
        }
    }

    // MARK: - 16. Trim Video
    public func trimVideo(url: URL, start: Double = 0.0, duration: Double = 15.0) async throws -> URL {
        let asset = AVAsset(url: url)
        let totalDuration = try await asset.load(.duration)
        let totalSecs = CMTimeGetSeconds(totalDuration)
        let actualStart = min(max(0, start), totalSecs)
        let actualDur = min(duration, max(0.1, totalSecs - actualStart))

        let out = outputURL(for: url, suffix: "trimmed", ext: "mp4")
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Aurelo", code: 32, userInfo: [NSLocalizedDescriptionKey: "Export initialization failed"])
        }
        export.outputURL = out
        export.outputFileType = .mp4
        export.timeRange = CMTimeRange(start: CMTime(seconds: actualStart, preferredTimescale: 600),
                                       duration: CMTime(seconds: actualDur, preferredTimescale: 600))
        await export.export()
        if export.status == .completed {
            return out
        } else {
            throw export.error ?? NSError(domain: "Aurelo", code: 33, userInfo: [NSLocalizedDescriptionKey: "Trim video failed"])
        }
    }

    // MARK: - 17. Trim Audio
    public func trimAudio(url: URL, start: Double = 0.0, duration: Double = 30.0) async throws -> URL {
        let asset = AVAsset(url: url)
        let totalDuration = try await asset.load(.duration)
        let totalSecs = CMTimeGetSeconds(totalDuration)
        let actualStart = min(max(0, start), totalSecs)
        let actualDur = min(duration, max(0.1, totalSecs - actualStart))

        let out = outputURL(for: url, suffix: "trimmed", ext: "m4a")
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "Aurelo", code: 34, userInfo: [NSLocalizedDescriptionKey: "Audio trim export initialization failed"])
        }
        export.outputURL = out
        export.outputFileType = .m4a
        export.timeRange = CMTimeRange(start: CMTime(seconds: actualStart, preferredTimescale: 600),
                                       duration: CMTime(seconds: actualDur, preferredTimescale: 600))
        await export.export()
        if export.status == .completed {
            return out
        } else {
            throw export.error ?? NSError(domain: "Aurelo", code: 35, userInfo: [NSLocalizedDescriptionKey: "Audio trim failed"])
        }
    }

    // MARK: - 18. Adjust Video Speed
    public func changeVideoSpeed(url: URL, speed: Double = 2.0) async throws -> URL {
        let asset = AVAsset(url: url)
        let originalDuration = try await asset.load(.duration)
        let composition = AVMutableComposition()

        if let videoTrack = try await asset.loadTracks(withMediaType: .video).first {
            let compVideoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compVideoTrack?.insertTimeRange(CMTimeRange(start: .zero, duration: originalDuration), of: videoTrack, at: .zero)
            let scaledDuration = CMTimeMultiplyByFloat64(originalDuration, multiplier: 1.0 / speed)
            compVideoTrack?.scaleTimeRange(CMTimeRange(start: .zero, duration: originalDuration), toDuration: scaledDuration)
        }

        let speedLabel = speed >= 1.0 ? "\(Int(speed))x" : "\(speed)x"
        let out = outputURL(for: url, suffix: "speed_\(speedLabel)", ext: "mp4")
        guard let export = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "Aurelo", code: 36, userInfo: [NSLocalizedDescriptionKey: "Speed export failed to initialize"])
        }
        export.outputURL = out
        export.outputFileType = .mp4
        await export.export()
        if export.status == .completed {
            return out
        } else {
            throw export.error ?? NSError(domain: "Aurelo", code: 37, userInfo: [NSLocalizedDescriptionKey: "Video speed adjustment failed"])
        }
    }

    // MARK: - 19. Compress Video
    public func compressVideo(url: URL) async throws -> URL {
        let asset = AVAsset(url: url)
        let out = outputURL(for: url, suffix: "compressed", ext: "mp4")
        guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
            throw NSError(domain: "Aurelo", code: 38, userInfo: [NSLocalizedDescriptionKey: "Video compression export failed"])
        }
        export.outputURL = out
        export.outputFileType = .mp4
        await export.export()
        if export.status == .completed {
            return out
        } else {
            throw export.error ?? NSError(domain: "Aurelo", code: 39, userInfo: [NSLocalizedDescriptionKey: "Video compression failed"])
        }
    }

    // MARK: - 20. Photo Collage (Grid)
    public func createCollage(urls: [URL]) throws -> URL {
        guard !urls.isEmpty else {
            throw NSError(domain: "Aurelo", code: 40, userInfo: [NSLocalizedDescriptionKey: "Select at least 2 images for a collage"])
        }
        let images = urls.compactMap { NSImage(contentsOf: $0) }
        guard images.count >= 2 else {
            throw NSError(domain: "Aurelo", code: 41, userInfo: [NSLocalizedDescriptionKey: "Failed to load image files for collage"])
        }

        let canvasSize: CGFloat = 2048
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: Int(canvasSize), height: Int(canvasSize), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw NSError(domain: "Aurelo", code: 42, userInfo: [NSLocalizedDescriptionKey: "Failed to create collage canvas"])
        }

        ctx.setFillColor(NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.16, alpha: 1.0).cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))

        let padding: CGFloat = 24
        let innerSize = canvasSize - (padding * 2)

        let count = min(images.count, 4)
        var rects: [CGRect] = []
        if count == 2 {
            let w = (innerSize - padding) / 2
            rects.append(CGRect(x: padding, y: padding, width: w, height: innerSize))
            rects.append(CGRect(x: padding + w + padding, y: padding, width: w, height: innerSize))
        } else if count == 3 {
            let w = (innerSize - padding) / 2
            let h = (innerSize - padding) / 2
            rects.append(CGRect(x: padding, y: padding, width: w, height: innerSize))
            rects.append(CGRect(x: padding + w + padding, y: padding + h + padding, width: w, height: h))
            rects.append(CGRect(x: padding + w + padding, y: padding, width: w, height: h))
        } else {
            let cell = (innerSize - padding) / 2
            rects.append(CGRect(x: padding, y: padding + cell + padding, width: cell, height: cell))
            rects.append(CGRect(x: padding + cell + padding, y: padding + cell + padding, width: cell, height: cell))
            rects.append(CGRect(x: padding, y: padding, width: cell, height: cell))
            rects.append(CGRect(x: padding + cell + padding, y: padding, width: cell, height: cell))
        }

        for (i, rect) in rects.enumerated() {
            guard let cg = images[i].cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            ctx.saveGState()
            let clipPath = CGPath(roundedRect: rect, cornerWidth: 16, cornerHeight: 16, transform: nil)
            ctx.addPath(clipPath)
            ctx.clip()

            let imgW = CGFloat(cg.width)
            let imgH = CGFloat(cg.height)
            let scale = max(rect.width / imgW, rect.height / imgH)
            let drawW = imgW * scale
            let drawH = imgH * scale
            let drawX = rect.midX - (drawW / 2)
            let drawY = rect.midY - (drawH / 2)
            ctx.draw(cg, in: CGRect(x: drawX, y: drawY, width: drawW, height: drawH))
            ctx.restoreGState()

            ctx.saveGState()
            ctx.addPath(clipPath)
            ctx.setStrokeColor(AureloTheme.mint.withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(2)
            ctx.strokePath()
            ctx.restoreGState()
        }

        guard let collageCG = ctx.makeImage() else {
            throw NSError(domain: "Aurelo", code: 43, userInfo: [NSLocalizedDescriptionKey: "Failed to render collage image"])
        }

        let out = outputURL(for: urls[0], suffix: "collage", ext: "png")
        guard let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil) else {
            throw NSError(domain: "Aurelo", code: 44, userInfo: [NSLocalizedDescriptionKey: "Failed to initialize destination for collage"])
        }
        CGImageDestinationAddImage(dest, collageCG, nil)
        CGImageDestinationFinalize(dest)
        return out
    }

    // MARK: - 21. OCR & Text Extraction (Apple Vision Neural Engine)
    public func extractTextOCR(url: URL) throws -> URL {
        var recognizedLines: [String] = []
        let ext = url.pathExtension.lowercased()

        func performOCR(cgImage: CGImage) {
            let request = VNRecognizeTextRequest { req, _ in
                guard let observations = req.results as? [VNRecognizedTextObservation] else { return }
                for obs in observations {
                    if let candidate = obs.topCandidates(1).first {
                        recognizedLines.append(candidate.string)
                    }
                }
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])
        }

        if ext == "pdf", let doc = PDFDocument(url: url) {
            for i in 0..<doc.pageCount {
                if let page = doc.page(at: i) {
                    let pageRect = page.bounds(for: .mediaBox)
                    let renderer = NSImage(size: pageRect.size)
                    renderer.lockFocus()
                    if let ctx = NSGraphicsContext.current?.cgContext {
                        page.draw(with: .mediaBox, to: ctx)
                    }
                    renderer.unlockFocus()
                    if let cg = renderer.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                        recognizedLines.append("--- PAGE \(i + 1) ---")
                        performOCR(cgImage: cg)
                    }
                }
            }
        } else if let img = NSImage(contentsOf: url),
                  let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            performOCR(cgImage: cg)
        } else {
            throw NSError(domain: "Aurelo", code: 45, userInfo: [NSLocalizedDescriptionKey: "Unsupported format for OCR"])
        }

        let fullText = recognizedLines.joined(separator: "\n")
        let out = outputURL(for: url, suffix: "ocr", ext: "txt")
        try fullText.write(to: out, atomically: true, encoding: .utf8)
        return out
    }

    // MARK: - 22. PDF to High-Res Images
    public func pdfToImages(url: URL) throws -> [URL] {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "Aurelo", code: 46, userInfo: [NSLocalizedDescriptionKey: "Could not open PDF"])
        }
        var createdURLs: [URL] = []
        let baseDir = url.deletingLastPathComponent()
        let name = url.deletingPathExtension().lastPathComponent

        for i in 0..<doc.pageCount {
            guard let page = doc.page(at: i) else { continue }
            let rect = page.bounds(for: .mediaBox)
            let img = NSImage(size: rect.size)
            img.lockFocus()
            if let ctx = NSGraphicsContext.current?.cgContext {
                page.draw(with: .mediaBox, to: ctx)
            }
            img.unlockFocus()

            guard let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else { continue }
            let pageURL = baseDir.appendingPathComponent("\(name)_page_\(i + 1).png")
            guard let dest = CGImageDestinationCreateWithURL(pageURL as CFURL, "public.png" as CFString, 1, nil) else { continue }
            CGImageDestinationAddImage(dest, cg, nil)
            CGImageDestinationFinalize(dest)
            createdURLs.append(pageURL)
        }
        return createdURLs
    }

    // MARK: - 23. Organize / Rotate PDF
    public func organizePDF(url: URL, rotateAngle: Int = 90) throws -> URL {
        guard let doc = PDFDocument(url: url) else {
            throw NSError(domain: "Aurelo", code: 47, userInfo: [NSLocalizedDescriptionKey: "Could not open PDF"])
        }
        for i in 0..<doc.pageCount {
            if let page = doc.page(at: i) {
                page.rotation = (page.rotation + rotateAngle) % 360
            }
        }
        let out = outputURL(for: url, suffix: "rotated", ext: "pdf")
        doc.write(to: out)
        return out
    }

    // MARK: - 24. Annotate & Mark Image
    public func annotateImage(url: URL, watermarkText: String = "AURELO PRO") throws -> URL {
        guard let img = NSImage(contentsOf: url),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "Aurelo", code: 48, userInfo: [NSLocalizedDescriptionKey: "Invalid image for annotation"])
        }
        let w = CGFloat(cg.width)
        let h = CGFloat(cg.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil, width: Int(w), height: Int(h), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw NSError(domain: "Aurelo", code: 49, userInfo: [NSLocalizedDescriptionKey: "Context allocation failed"])
        }

        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        let badgeH: CGFloat = max(36, h * 0.06)
        let badgeW: CGFloat = badgeH * 4.5
        let badgeRect = CGRect(x: w - badgeW - 24, y: 24, width: badgeW, height: badgeH)

        ctx.setFillColor(NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.16, alpha: 0.85).cgColor)
        let pillPath = CGPath(roundedRect: badgeRect, cornerWidth: badgeH / 2, cornerHeight: badgeH / 2, transform: nil)
        ctx.addPath(pillPath)
        ctx.fillPath()

        ctx.addPath(pillPath)
        ctx.setStrokeColor(AureloTheme.mint.cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokePath()

        guard let annotatedCG = ctx.makeImage() else {
            throw NSError(domain: "Aurelo", code: 50, userInfo: [NSLocalizedDescriptionKey: "Failed to render annotated image"])
        }
        let out = outputURL(for: url, suffix: "annotated", ext: "png")
        let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)!
        CGImageDestinationAddImage(dest, annotatedCG, nil)
        CGImageDestinationFinalize(dest)
        return out
    }

    // MARK: - 25. Universal Format Converter
    public func convertFormat(url: URL, targetExt: String) throws -> URL {
        guard let img = NSImage(contentsOf: url),
              let cg = img.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw NSError(domain: "Aurelo", code: 51, userInfo: [NSLocalizedDescriptionKey: "Could not load image for conversion"])
        }
        let uti: CFString
        switch targetExt.lowercased() {
        case "png": uti = "public.png" as CFString
        case "jpg", "jpeg": uti = "public.jpeg" as CFString
        case "tiff", "tif": uti = "public.tiff" as CFString
        case "bmp": uti = "com.microsoft.bmp" as CFString
        default: uti = "public.png" as CFString
        }
        let out = outputURL(for: url, suffix: "converted", ext: targetExt.lowercased())
        guard let dest = CGImageDestinationCreateWithURL(out as CFURL, uti, 1, nil) else {
            throw NSError(domain: "Aurelo", code: 52, userInfo: [NSLocalizedDescriptionKey: "Unsupported target format"])
        }
        CGImageDestinationAddImage(dest, cg, nil)
        CGImageDestinationFinalize(dest)
        return out
    }
}
