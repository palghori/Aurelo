// Aurelo Engine Dry-Run Test
// Tests the critical fixed functionality: mergePDF, createPDF, splitPDF, compress
import Foundation
import AppKit
import PDFKit

@main
struct AureloTest {
    static func main() {
        // Test workspace
        let testDir = "/Users/palghori/.gemini/antigravity-ide/scratch/Aurelo/test_workspace"
        try? FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)

        // Copy test files to workspace to avoid touching originals
        let fm = FileManager.default
        let pdf1Src = "/Users/palghori/Desktop/PDF Documents/certificate MATLAB.pdf"
        let pdf2Src = "/Users/palghori/Desktop/PDF Documents/certificate charusat.pdf"
        let pdf3Src = "/Users/palghori/Desktop/PDF Documents/certificate MACHINE LEARNING.pdf"
        let img1Src = "/Users/palghori/llama.cpp/media/llama0-banner.png"
        let img2Src = "/Users/palghori/llama.cpp/media/llama1-icon.png"
        let img3Src = "/Users/palghori/llama.cpp/tools/mtmd/test-1.jpeg"

        let pdf1 = URL(fileURLWithPath: testDir).appendingPathComponent("test_cert_matlab.pdf")
        let pdf2 = URL(fileURLWithPath: testDir).appendingPathComponent("test_cert_charusat.pdf")
        let pdf3 = URL(fileURLWithPath: testDir).appendingPathComponent("test_cert_ml.pdf")
        let img1 = URL(fileURLWithPath: testDir).appendingPathComponent("test_llama_banner.png")
        let img2 = URL(fileURLWithPath: testDir).appendingPathComponent("test_llama_icon.png")
        let img3 = URL(fileURLWithPath: testDir).appendingPathComponent("test_llama_photo.jpeg")

        func safeCopy(_ src: String, _ dst: URL) {
            try? fm.removeItem(at: dst)
            try! fm.copyItem(atPath: src, toPath: dst.path)
        }
        safeCopy(pdf1Src, pdf1)
        safeCopy(pdf2Src, pdf2)
        safeCopy(pdf3Src, pdf3)
        safeCopy(img1Src, img1)
        safeCopy(img2Src, img2)
        safeCopy(img3Src, img3)

        let engine = ProcessingEngine.shared
        var passed = 0
        var failed = 0

        print("")
        print("╔══════════════════════════════════════════════════════════╗")
        print("║            AURELO ENGINE — DRY-RUN TEST SUITE           ║")
        print("╚══════════════════════════════════════════════════════════╝")
        print("")

        // ═══════════════════════════════════════════════════════════
        // TEST 1: Merge 3 PDFs into one
        // ═══════════════════════════════════════════════════════════
        print("━━━ TEST 1: Merge PDF (3 certificates) ━━━")
        do {
            let input1 = PDFDocument(url: pdf1)!
            let input2 = PDFDocument(url: pdf2)!
            let input3 = PDFDocument(url: pdf3)!
            let totalInputPages = input1.pageCount + input2.pageCount + input3.pageCount
            print("   Input:  3 PDF files")
            print("   Pages:  \(input1.pageCount) + \(input2.pageCount) + \(input3.pageCount) = \(totalInputPages) total input pages")

            let merged = try engine.mergePDF(urls: [pdf1, pdf2, pdf3])
            let mergedDoc = PDFDocument(url: merged)!
            let mergedSize = (try? fm.attributesOfItem(atPath: merged.path)[.size] as? Int64) ?? 0

            print("   Output: \(merged.lastPathComponent)")
            print("   Pages:  \(mergedDoc.pageCount) pages in merged PDF")
            print("   Size:   \(mergedSize) bytes")

            if mergedDoc.pageCount == totalInputPages {
                print("   ✅ PASS — Merged PDF has \(mergedDoc.pageCount) pages (matches \(totalInputPages) input pages)")
                passed += 1
            } else {
                print("   ❌ FAIL — Expected \(totalInputPages) pages, got \(mergedDoc.pageCount)")
                failed += 1
            }
        } catch {
            print("   ❌ FAIL — Error: \(error.localizedDescription)")
            failed += 1
        }

        print("")

        // ═══════════════════════════════════════════════════════════
        // TEST 2: Create PDF from 3 images
        // ═══════════════════════════════════════════════════════════
        print("━━━ TEST 2: Create PDF from 3 Images ━━━")
        do {
            print("   Input:  llama0-banner.png, llama1-icon.png, test-1.jpeg")

            let createdPDF = try engine.createPDF(from: [img1, img2, img3])
            let doc = PDFDocument(url: createdPDF)!
            let createdSize = (try? fm.attributesOfItem(atPath: createdPDF.path)[.size] as? Int64) ?? 0

            print("   Output: \(createdPDF.lastPathComponent)")
            print("   Pages:  \(doc.pageCount) pages in created PDF")
            print("   Size:   \(createdSize) bytes")

            if doc.pageCount == 3 {
                print("   ✅ PASS — Created PDF has 3 pages (one per image)")
                passed += 1
            } else {
                print("   ❌ FAIL — Expected 3 pages, got \(doc.pageCount)")
                failed += 1
            }
        } catch {
            print("   ❌ FAIL — Error: \(error.localizedDescription)")
            failed += 1
        }

        print("")

        // ═══════════════════════════════════════════════════════════
        // TEST 3: Create PDF from mixed (2 images + 1 PDF)
        // ═══════════════════════════════════════════════════════════
        print("━━━ TEST 3: Create PDF from Mixed (2 images + 1 PDF) ━━━")
        do {
            let pdfPagesBefore = PDFDocument(url: pdf1)!.pageCount
            print("   Input:  llama0-banner.png + llama1-icon.png + \(pdf1.lastPathComponent) (\(pdfPagesBefore) pages)")

            let mixedPDF = try engine.createPDF(from: [img1, img2, pdf1])
            let doc = PDFDocument(url: mixedPDF)!
            let expectedPages = 2 + pdfPagesBefore

            print("   Output: \(mixedPDF.lastPathComponent)")
            print("   Pages:  \(doc.pageCount) pages")

            if doc.pageCount == expectedPages {
                print("   ✅ PASS — Mixed PDF has \(expectedPages) pages (2 images + \(pdfPagesBefore) PDF pages)")
                passed += 1
            } else {
                print("   ❌ FAIL — Expected \(expectedPages) pages, got \(doc.pageCount)")
                failed += 1
            }
        } catch {
            print("   ❌ FAIL — Error: \(error.localizedDescription)")
            failed += 1
        }

        print("")

        // ═══════════════════════════════════════════════════════════
        // TEST 4: Split a multi-page PDF
        // ═══════════════════════════════════════════════════════════
        print("━━━ TEST 4: Split PDF (certificate MATLAB) ━━━")
        do {
            let inputDoc = PDFDocument(url: pdf1)!
            print("   Input:  \(pdf1.lastPathComponent) (\(inputDoc.pageCount) pages)")

            let splitPages = try engine.splitPDF(url: pdf1)

            print("   Output: \(splitPages.count) individual PDF files")
            for (_, pageURL) in splitPages.enumerated() {
                let pageDoc = PDFDocument(url: pageURL)!
                print("   • \(pageURL.lastPathComponent) — \(pageDoc.pageCount) page")
            }

            if splitPages.count == inputDoc.pageCount {
                print("   ✅ PASS — Split produced \(splitPages.count) files for \(inputDoc.pageCount) pages")
                passed += 1
            } else {
                print("   ❌ FAIL — Expected \(inputDoc.pageCount) files, got \(splitPages.count)")
                failed += 1
            }
        } catch {
            print("   ❌ FAIL — Error: \(error.localizedDescription)")
            failed += 1
        }

        print("")

        // ═══════════════════════════════════════════════════════════
        // TEST 5: Compress an image
        // ═══════════════════════════════════════════════════════════
        print("━━━ TEST 5: Compress Image (llama banner) ━━━")
        do {
            let originalSize = (try? fm.attributesOfItem(atPath: img1.path)[.size] as? Int64) ?? 0
            print("   Input:  \(img1.lastPathComponent) — \(originalSize) bytes")

            let compressed = try engine.compress(url: img1, quality: 0.5)
            let compressedSize = (try? fm.attributesOfItem(atPath: compressed.path)[.size] as? Int64) ?? 0

            print("   Output: \(compressed.lastPathComponent) — \(compressedSize) bytes")

            if compressedSize > 0 && fm.fileExists(atPath: compressed.path) {
                let ratio = Double(compressedSize) / Double(originalSize) * 100.0
                print("   ✅ PASS — Compressed to \(String(format: "%.1f", ratio))% of original size")
                passed += 1
            } else {
                print("   ❌ FAIL — Output file missing or empty")
                failed += 1
            }
        } catch {
            print("   ❌ FAIL — Error: \(error.localizedDescription)")
            failed += 1
        }

        print("")

        // ═══════════════════════════════════════════════════════════
        // TEST 6: Merge 2 PDFs (exact user scenario)
        // ═══════════════════════════════════════════════════════════
        print("━━━ TEST 6: Merge 2 PDFs (User's exact reported scenario) ━━━")
        do {
            let doc1 = PDFDocument(url: pdf1)!
            let doc2 = PDFDocument(url: pdf2)!
            let totalInput = doc1.pageCount + doc2.pageCount
            print("   Input:  \(pdf1.lastPathComponent) (\(doc1.pageCount)p) + \(pdf2.lastPathComponent) (\(doc2.pageCount)p)")

            let merged = try engine.mergePDF(urls: [pdf1, pdf2])
            let mergedDoc = PDFDocument(url: merged)!

            print("   Output: \(merged.lastPathComponent)")
            print("   Result: 1 PDF file with \(mergedDoc.pageCount) pages")

            if mergedDoc.pageCount == totalInput {
                print("   ✅ PASS — Got 1 merged PDF with \(mergedDoc.pageCount) pages (not 2 separate copies!)")
                passed += 1
            } else {
                print("   ❌ FAIL — Merge produced wrong result")
                failed += 1
            }
        } catch {
            print("   ❌ FAIL — Error: \(error.localizedDescription)")
            failed += 1
        }

        print("")

        // ═══════════════════════════════════════════════════════════
        // TEST 7: Verify output is DIFFERENT from input (anti-regression)
        // ═══════════════════════════════════════════════════════════
        print("━━━ TEST 7: Verify Merge Output ≠ Input (Anti-Regression) ━━━")
        do {
            let input1Data = try Data(contentsOf: pdf1)
            let input2Data = try Data(contentsOf: pdf2)

            let merged = try engine.mergePDF(urls: [pdf1, pdf2])
            let mergedData = try Data(contentsOf: merged)

            let mergedSize = mergedData.count
            let input1Size = input1Data.count
            let input2Size = input2Data.count

            print("   Input 1: \(input1Size) bytes")
            print("   Input 2: \(input2Size) bytes")
            print("   Merged:  \(mergedSize) bytes")

            if mergedData != input1Data && mergedData != input2Data && mergedSize > input1Size && mergedSize > input2Size {
                print("   ✅ PASS — Merged output is genuinely different from both inputs")
                print("            (merged \(mergedSize) > input1 \(input1Size) AND > input2 \(input2Size))")
                passed += 1
            } else {
                print("   ❌ FAIL — Output appears to be a copy of one of the inputs!")
                failed += 1
            }
        } catch {
            print("   ❌ FAIL — Error: \(error.localizedDescription)")
            failed += 1
        }

        print("")
        print("╔══════════════════════════════════════════════════════════╗")
        if failed == 0 {
            print("║  RESULTS: \(passed)/\(passed + failed) TESTS PASSED ✅                        ║")
        } else {
            print("║  RESULTS: \(passed) PASSED, \(failed) FAILED out of \(passed + failed) tests          ║")
        }
        print("╚══════════════════════════════════════════════════════════╝")
        print("")

        if failed > 0 {
            print("⚠️  Some tests failed! Review output above.")
        } else {
            print("🎉 All tests passed! Aurelo engine is working correctly.")
        }
        print("")
    }
}
