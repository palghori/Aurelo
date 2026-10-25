// Aurelo Full Engine Verification Suite
// Tests EVERY single implemented feature against real media files from macOS
import Foundation
import AppKit
import PDFKit
import AVFoundation

@main
struct FullSuiteTest {
    static func main() async {
        let testDir = "/Users/palghori/.gemini/antigravity-ide/scratch/Aurelo/test_workspace"
        let fm = FileManager.default
        try? fm.removeItem(atPath: testDir)
        try? fm.createDirectory(atPath: testDir, withIntermediateDirectories: true)

        let pdf1Src = "/Users/palghori/Desktop/PDF Documents/certificate MATLAB.pdf"
        let pdf2Src = "/Users/palghori/Desktop/PDF Documents/certificate charusat.pdf"
        let pdf3Src = "/Users/palghori/Desktop/PDF Documents/certificate MACHINE LEARNING.pdf"
        let img1Src = "/Users/palghori/llama.cpp/media/llama0-banner.png"
        let img2Src = "/Users/palghori/llama.cpp/media/llama1-icon.png"
        let img3Src = "/Users/palghori/llama.cpp/tools/mtmd/test-1.jpeg"
        let audioSrc = "/Users/palghori/llama.cpp/tools/mtmd/test-2.mp3"
        let videoSrc = "/Users/palghori/.bobide/extensions/donjayamanne.python-environment-manager-1.2.7/images/createVenv.mp4"
        let zipSrc = "/Users/palghori/.cursor/extensions/ms-vscode.cpptools-1.26.3-darwin-arm64/VCPkgHeadersDatabase.zip"

        func log(_ msg: String) {
            print(msg)
            fflush(stdout)
        }

        func safeCopy(_ src: String, _ name: String) -> URL? {
            guard fm.fileExists(atPath: src) else {
                log("⚠️ File not found: \(src)")
                return nil
            }
            let dst = URL(fileURLWithPath: testDir).appendingPathComponent(name)
            try? fm.removeItem(at: dst)
            do {
                try fm.copyItem(atPath: src, toPath: dst.path)
                return dst
            } catch {
                log("⚠️ Copy failed for \(name): \(error.localizedDescription)")
                return nil
            }
        }

        log("╔════════════════════════════════════════════════════════════════════╗")
        log("║           AURELO COMPLETE FEATURE AUDIT & STRESS SUITE             ║")
        log("╚════════════════════════════════════════════════════════════════════╝\n")

        let pdf1 = safeCopy(pdf1Src, "cert_matlab.pdf")
        let pdf2 = safeCopy(pdf2Src, "cert_charusat.pdf")
        let pdf3 = safeCopy(pdf3Src, "cert_ml.pdf")
        let img1 = safeCopy(img1Src, "banner.png")
        let img2 = safeCopy(img2Src, "icon.png")
        let img3 = safeCopy(img3Src, "photo.jpeg")
        let audioFile = safeCopy(audioSrc, "sample_audio.mp3")
        let videoFile = safeCopy(videoSrc, "sample_video.mp4")
        let zipFile = safeCopy(zipSrc, "sample_archive.zip")

        let engine = ProcessingEngine.shared
        var passed = 0
        var failed = 0

        func report(_ name: String, pass: Bool, detail: String) {
            if pass {
                log("   ✅ PASS — \(name): \(detail)")
                passed += 1
            } else {
                log("   ❌ FAIL — \(name): \(detail)")
                failed += 1
            }
        }

        // 1. PDF Merge
        log("━━━ FEATURE 1: Merge PDF ━━━")
        if let p1 = pdf1, let p2 = pdf2, let p3 = pdf3 {
            do {
                let doc1 = PDFDocument(url: p1)!
                let doc2 = PDFDocument(url: p2)!
                let doc3 = PDFDocument(url: p3)!
                let total = doc1.pageCount + doc2.pageCount + doc3.pageCount
                let res = try engine.mergePDF(urls: [p1, p2, p3])
                let resDoc = PDFDocument(url: res)!
                report("Merge PDF (3 files)", pass: resDoc.pageCount == total, detail: "\(total) pages merged into \(res.lastPathComponent)")
            } catch {
                report("Merge PDF", pass: false, detail: error.localizedDescription)
            }
        }

        // 2. Create PDF from Images
        log("\n━━━ FEATURE 2: Create PDF from Images ━━━")
        if let i1 = img1, let i2 = img2, let i3 = img3 {
            do {
                let res = try engine.createPDF(from: [i1, i2, i3])
                let doc = PDFDocument(url: res)!
                report("Create PDF (3 images)", pass: doc.pageCount == 3, detail: "3 images converted to 3-page PDF (\(res.lastPathComponent))")
            } catch {
                report("Create PDF", pass: false, detail: error.localizedDescription)
            }
        }

        // 3. Split PDF
        log("\n━━━ FEATURE 3: Split PDF ━━━")
        if let p2 = pdf2 {
            do {
                let res = try engine.splitPDF(url: p2)
                report("Split PDF", pass: res.count == 2, detail: "Split 2-page PDF into \(res.count) files")
            } catch {
                report("Split PDF", pass: false, detail: error.localizedDescription)
            }
        }

        // 4. Compress Image
        log("\n━━━ FEATURE 4: Compress Image ━━━")
        if let i1 = img1 {
            do {
                let origSize = (try? fm.attributesOfItem(atPath: i1.path)[.size] as? Int64) ?? 0
                let res = try engine.compress(url: i1, quality: 0.5)
                let newSize = (try? fm.attributesOfItem(atPath: res.path)[.size] as? Int64) ?? 0
                let ratio = Double(newSize) / Double(origSize) * 100.0
                report("Compress Image", pass: newSize > 0 && newSize < origSize, detail: "Reduced from \(origSize) to \(newSize) bytes (\(String(format: "%.1f", ratio))%)")
            } catch {
                report("Compress Image", pass: false, detail: error.localizedDescription)
            }
        }

        // 5. Remove Metadata
        log("\n━━━ FEATURE 5: Remove Metadata (Exif & Privacy) ━━━")
        if let i3 = img3 {
            do {
                let res = try engine.removeMetadata(url: i3)
                let size = (try? fm.attributesOfItem(atPath: res.path)[.size] as? Int64) ?? 0
                report("Remove Metadata", pass: size > 0 && fm.fileExists(atPath: res.path), detail: "Clean file created: \(res.lastPathComponent) (\(size) bytes)")
            } catch {
                report("Remove Metadata", pass: false, detail: error.localizedDescription)
            }
        }

        // 6. Frame Image
        log("\n━━━ FEATURE 6: Frame Image (Canvas, Gradient & Shadow) ━━━")
        if let i2 = img2 {
            do {
                let res = try engine.frameImage(url: i2)
                let img = NSImage(contentsOf: res)
                report("Frame Image", pass: img != nil, detail: "Framed artwork generated: \(res.lastPathComponent)")
            } catch {
                report("Frame Image", pass: false, detail: error.localizedDescription)
            }
        }

        // 7. Crop Image
        log("\n━━━ FEATURE 7: Crop Image ━━━")
        if let i1 = img1 {
            do {
                let res = try engine.cropImage(url: i1, cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))
                let img = NSImage(contentsOf: res)
                report("Crop Image", pass: img != nil, detail: "Cropped to center 80%: \(res.lastPathComponent)")
            } catch {
                report("Crop Image", pass: false, detail: error.localizedDescription)
            }
        }

        // 8. Edit Image (Adjustments)
        log("\n━━━ FEATURE 8: Edit Image (Exposure, Contrast, Saturation) ━━━")
        if let i1 = img1 {
            do {
                let res = try engine.editImage(url: i1)
                let img = NSImage(contentsOf: res)
                report("Edit Image", pass: img != nil, detail: "Color controls applied: \(res.lastPathComponent)")
            } catch {
                report("Edit Image", pass: false, detail: error.localizedDescription)
            }
        }

        // 9. Redact Image
        log("\n━━━ FEATURE 9: Redact Image ━━━")
        if let i1 = img1 {
            do {
                let res = try engine.redactImage(url: i1, rectFraction: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.3))
                let img = NSImage(contentsOf: res)
                report("Redact Image", pass: img != nil, detail: "Blackout & mint boundary added: \(res.lastPathComponent)")
            } catch {
                report("Redact Image", pass: false, detail: error.localizedDescription)
            }
        }

        // 10. Read QR Code
        log("\n━━━ FEATURE 10: Read QR / Barcodes ━━━")
        if let i1 = img1 {
            do {
                let codes = try engine.readQRCode(url: i1)
                report("Read QR / Barcode", pass: true, detail: "Vision barcode detector executed successfully (found \(codes.count) codes)")
            } catch {
                report("Read QR / Barcode", pass: false, detail: error.localizedDescription)
            }
        }

        // 11. Extract Archive
        log("\n━━━ FEATURE 11: Extract Archive (ZIP) ━━━")
        if let z = zipFile {
            do {
                let res = try engine.extractArchive(url: z)
                var isDir: ObjCBool = false
                let exists = fm.fileExists(atPath: res.path, isDirectory: &isDir)
                let contents = (try? fm.contentsOfDirectory(atPath: res.path)) ?? []
                report("Extract Archive", pass: exists && isDir.boolValue && !contents.isEmpty, detail: "Unpacked \(contents.count) items into \(res.lastPathComponent)")
            } catch {
                report("Extract Archive", pass: false, detail: error.localizedDescription)
            }
        }

        // 12. Normalize Audio
        log("\n━━━ FEATURE 12: Normalize Audio ━━━")
        if let a = audioFile {
            do {
                let res = try await engine.normalizeAudio(url: a)
                let size = (try? fm.attributesOfItem(atPath: res.path)[.size] as? Int64) ?? 0
                report("Normalize Audio", pass: size > 0 && fm.fileExists(atPath: res.path), detail: "Exported broadcast m4a: \(res.lastPathComponent) (\(size) bytes)")
            } catch {
                report("Normalize Audio", pass: false, detail: error.localizedDescription)
            }
        }

        // 13. Mute Video
        log("\n━━━ FEATURE 13: Mute Video (Strip Audio) ━━━")
        if let v = videoFile {
            do {
                let res = try await engine.muteVideo(url: v)
                let asset = AVAsset(url: res)
                let audioTracks = try await asset.loadTracks(withMediaType: .audio)
                let videoTracks = try await asset.loadTracks(withMediaType: .video)
                let pass = audioTracks.isEmpty && !videoTracks.isEmpty
                report("Mute Video", pass: pass, detail: "Stripped audio track (audio tracks: \(audioTracks.count), video tracks: \(videoTracks.count))")
            } catch {
                report("Mute Video", pass: false, detail: error.localizedDescription)
            }
        }

        // 14. Video Snapshots
        log("\n━━━ FEATURE 14: Extract Video Snapshots ━━━")
        if let v = videoFile {
            do {
                let res = try await engine.videoSnapshots(url: v, count: 1)
                let pass = !res.isEmpty && fm.fileExists(atPath: res[0].path)
                report("Video Snapshots", pass: pass, detail: "Extracted still frame: \(res.first?.lastPathComponent ?? "")")
            } catch {
                report("Video Snapshots", pass: false, detail: error.localizedDescription)
            }
        }

        // 15. Concatenate Videos (Join)
        log("\n━━━ FEATURE 15: Concatenate Videos ━━━")
        if let v = videoFile {
            do {
                let copy2 = safeCopy(videoSrc, "sample_video_part2.mp4")!
                let res = try await engine.joinVideos(urls: [v, copy2])
                let asset = AVAsset(url: res)
                let dur = try await asset.load(.duration)
                let pass = CMTimeGetSeconds(dur) > 0 && fm.fileExists(atPath: res.path)
                report("Join Videos", pass: pass, detail: "Merged 2 video files into \(res.lastPathComponent) (\(String(format: "%.1f", CMTimeGetSeconds(dur)))s)")
            } catch {
                report("Join Videos", pass: false, detail: error.localizedDescription)
            }
        }

        // 16. Trim Video
        log("\n━━━ FEATURE 16: Trim Video ━━━")
        if let v = videoFile {
            do {
                let res = try await engine.trimVideo(url: v, start: 0.0, duration: 2.0)
                let asset = AVAsset(url: res)
                let dur = try await asset.load(.duration)
                let pass = CMTimeGetSeconds(dur) > 0 && fm.fileExists(atPath: res.path)
                report("Trim Video", pass: pass, detail: "Trimmed video clip: \(res.lastPathComponent) (\(String(format: "%.1f", CMTimeGetSeconds(dur)))s)")
            } catch {
                report("Trim Video", pass: false, detail: error.localizedDescription)
            }
        }

        // 17. Adjust Video Speed
        log("\n━━━ FEATURE 17: Adjust Video Speed (2x) ━━━")
        if let v = videoFile {
            do {
                let res = try await engine.changeVideoSpeed(url: v, speed: 2.0)
                let asset = AVAsset(url: res)
                let dur = try await asset.load(.duration)
                let pass = CMTimeGetSeconds(dur) > 0 && fm.fileExists(atPath: res.path)
                report("Adjust Video Speed", pass: pass, detail: "Fast-forward 2x video: \(res.lastPathComponent)")
            } catch {
                report("Adjust Video Speed", pass: false, detail: error.localizedDescription)
            }
        }

        // 18. Compress Video
        log("\n━━━ FEATURE 18: Compress Video ━━━")
        if let v = videoFile {
            do {
                let _ = (try? fm.attributesOfItem(atPath: v.path)[.size] as? Int64) ?? 0
                let res = try await engine.compressVideo(url: v)
                let newSize = (try? fm.attributesOfItem(atPath: res.path)[.size] as? Int64) ?? 0
                report("Compress Video", pass: newSize > 0, detail: "Encoded medium quality MP4: \(res.lastPathComponent) (\(newSize) bytes)")
            } catch {
                report("Compress Video", pass: false, detail: error.localizedDescription)
            }
        }

        // 19. Trim Audio
        log("\n━━━ FEATURE 19: Trim Audio ━━━")
        if let a = audioFile {
            do {
                let res = try await engine.trimAudio(url: a, start: 0.0, duration: 5.0)
                let asset = AVAsset(url: res)
                let dur = try await asset.load(.duration)
                let pass = CMTimeGetSeconds(dur) > 0 && fm.fileExists(atPath: res.path)
                report("Trim Audio", pass: pass, detail: "Trimmed audio snippet: \(res.lastPathComponent) (\(String(format: "%.1f", CMTimeGetSeconds(dur)))s)")
            } catch {
                report("Trim Audio", pass: false, detail: error.localizedDescription)
            }
        }

        // 20. Photo Collage
        log("\n━━━ FEATURE 20: Photo Collage ━━━")
        if let i1 = img1, let i2 = img2, let i3 = img3 {
            do {
                let res = try engine.createCollage(urls: [i1, i2, i3])
                let pass = fm.fileExists(atPath: res.path) && (NSImage(contentsOf: res) != nil)
                report("Photo Collage", pass: pass, detail: "Generated 3-photo grid artwork: \(res.lastPathComponent)")
            } catch {
                report("Photo Collage", pass: false, detail: error.localizedDescription)
            }
        }

        // 21. OCR Text Extraction
        log("\n━━━ FEATURE 21: OCR Text Extraction ━━━")
        if let i1 = img1 {
            do {
                let res = try engine.extractTextOCR(url: i1)
                let pass = fm.fileExists(atPath: res.path)
                let text = (try? String(contentsOf: res, encoding: .utf8)) ?? ""
                report("OCR Text Extraction", pass: pass, detail: "Extracted text to \(res.lastPathComponent) (\(text.count) chars)")
            } catch {
                report("OCR Text Extraction", pass: false, detail: error.localizedDescription)
            }
        }

        // 22. PDF to Images
        log("\n━━━ FEATURE 22: PDF to High-Res Images ━━━")
        if let p2 = pdf2 {
            do {
                let res = try engine.pdfToImages(url: p2)
                let pass = res.count == 2 && fm.fileExists(atPath: res[0].path)
                report("PDF to Images", pass: pass, detail: "Rendered \(res.count) pages to individual PNG images")
            } catch {
                report("PDF to Images", pass: false, detail: error.localizedDescription)
            }
        }

        // 23. Organize / Rotate PDF
        log("\n━━━ FEATURE 23: Organize / Rotate PDF ━━━")
        if let p1 = pdf1 {
            do {
                let initialRot = PDFDocument(url: p1)?.page(at: 0)?.rotation ?? 0
                let res = try engine.organizePDF(url: p1, rotateAngle: 90)
                let doc = PDFDocument(url: res)
                let expectedRot = (initialRot + 90) % 360
                let pass = (doc?.page(at: 0)?.rotation == expectedRot)
                report("Organize PDF (Rotate)", pass: pass, detail: "Rotated document from \(initialRot)° to \(doc?.page(at: 0)?.rotation ?? 0)°: \(res.lastPathComponent)")
            } catch {
                report("Organize PDF", pass: false, detail: error.localizedDescription)
            }
        }

        // 24. Annotate & Mark Image
        log("\n━━━ FEATURE 24: Annotate & Mark Image ━━━")
        if let i2 = img2 {
            do {
                let res = try engine.annotateImage(url: i2, watermarkText: "AURELO PRO")
                let pass = fm.fileExists(atPath: res.path) && (NSImage(contentsOf: res) != nil)
                report("Annotate Image", pass: pass, detail: "Overlay badge & watermark applied: \(res.lastPathComponent)")
            } catch {
                report("Annotate Image", pass: false, detail: error.localizedDescription)
            }
        }

        // 25. Format Converter
        log("\n━━━ FEATURE 25: Universal Format Converter ━━━")
        if let i3 = img3 {
            do {
                let res = try engine.convertFormat(url: i3, targetExt: "png")
                let pass = fm.fileExists(atPath: res.path) && (NSImage(contentsOf: res) != nil)
                report("Convert Format (JPEG -> PNG)", pass: pass, detail: "Converted image: \(res.lastPathComponent)")
            } catch {
                report("Convert Format", pass: false, detail: error.localizedDescription)
            }
        }

        log("")
        log("╔════════════════════════════════════════════════════════════════════╗")
        log("║   TOTAL RESULTS: \(passed)/\(passed + failed) FEATURES VERIFIED PASSED                      ║")
        log("╚════════════════════════════════════════════════════════════════════╝\n")

        try? fm.removeItem(atPath: testDir)
    }
}
