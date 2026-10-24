# Aurelo — Pro Mac File Utility & Studio

<div align="center">
  <img src="Resources/AppIcon.icns" width="128" height="128" alt="Aurelo Icon" />
  <h3>The Unlimited Native macOS File Utility</h3>
  <p><strong>Created and Developed by PAL GHORI</strong></p>
  <p>27 Pro Tools • 46 Format Decoders • 6 Quick Actions • 100% Free & Unlimited</p>
</div>

---

## ✦ Overview

**Aurelo** is an ultra-fast, native macOS utility built from the ground up for Apple Silicon (M1, M2, M3, and M4 Macs). It provides a sleek, modern desktop workspace, a persistent translucent floating shelf, and a comprehensive suite of 27 high-speed file manipulation tools covering images, audio, video, PDF documents, archives, and privacy redacting.

Unlike restricted utilities, **Aurelo is completely free with zero limits**—no task quotas, no subscriptions, and no paywalls.

---

## ✨ Features

### 1. 27 Professional File Tools
* **Image Studio (6)**: Lossless & Lossy Image Compression, Color & Exposure Adjustments, Annotation & Marker Tools, Gradient Canvas Framing with Soft Shadows, Aspect-Ratio Cropping, Photo Collages.
* **Audio Suite (5)**: Broadcast Loudness Normalization (RMS/Peak), Waveform Trimming, Channel Remixing (Stereo/Mono/Volume), Audio-to-Video generation with cover artwork, Audio Bleep/Mute Censor.
* **Video Studio (8)**: Audio Strip (Mute), Precision Timeline Trim, Video Box & Aspect Cropping (9:16, 1:1, custom), Variable Speed Adjustment (0.25x–4x), Clip Concatenation, Full-Resolution Snapshot Extraction, Video Slicing & Splitting, Video Redaction.
* **PDF Toolkit (4)**: Page Splitting, Visual Page Organizer & Reorder, Document/Image to PDF Creator, Multi-PDF Merging.
* **Privacy & Meta (4)**: Exif/GPS/IPTC/XMP Metadata Wiper, Image Face & Rectangle Blur, Video Timestamp Redaction, Audio Censor.
* **Extract & Vision (2)**: Instant Archive Extraction (ZIP, TAR, GZ, RAR), Barcode & QR Code Vision Detector.

### 2. 46 Supported Format Decoders
Aurelo natively recognizes, converts, and processes 46 format identifiers:
* **Images (9)**: `.jpg`, `.png`, `.webp`, `.heic`, `.tiff`, `.svg`, `.avif`, `.bmp`, `.gif`
* **Audio (8)**: `.mp3`, `.m4a`, `.wav`, `.flac`, `.ogg`, `.opus`, `.aiff`, `.wma`
* **Video (6)**: `.mp4`, `.mov`, `.mkv`, `.webm`, `.avi`, `.wmv`
* **Documents (17)**: `.pdf`, `.docx`, `.pages`, `.ppt`, `.pptx`, `.txt`, `.md`, `.rtf`, `.rtfd`, `.textClipping`, `.html`, `.epub`, `.xlsx`, `.xls`, `.ods`, `.csv`, `.tsv`
* **Subtitles (2)**: `.srt`, `.vtt`
* **Archives (4)**: `.zip`, `.tar`, `.gzip`, `.rar`

### 3. Persistent Floating Desktop Shelf
* A translucent glass HUD tray (`NSPanel`) that floats over your desktop.
* Collect files from Finder, stage them for batch operations, and drag them directly into Slack, Photoshop, Final Cut, or Mail.
* One-click contextual actions: **AirDrop**, **Open in Terminal**, **Copy Path**, and **QuickLook Preview**.

### 4. Modern Graphite & Mint Design System
* Designed around an obsidian dark glass palette (`#121316`) paired with electric mint emerald accents (`#00F5A0` / `#10B981`).
* Instant real-time fuzzy search across all tools and formats.
* Smooth micro-animations and Apple Silicon hardware acceleration.

---

## 🚀 Getting Started

### Prerequisites
* macOS 13.0 (Ventura) or newer
* Apple Silicon Mac (M1 / M2 / M3 / M4)
* Swift 5.9+ / Command Line Tools (`xcode-select --install`)

### Building from Source
Clone the repository and run the build script:

```bash
git clone https://github.com/palghori/Aurelo.git
cd Aurelo
./build.sh
```

This compiles a native ARM64 Mach-O executable and packages the application bundle into `build/Aurelo.app`.

### Launching the App
```bash
open build/Aurelo.app
```

### Interactive Web UI Showcase
To explore the Graphite & Mint UI prototype and simulate tool workflows in your browser:
```bash
open preview.html
```

---

## 🛠 Architecture & Tech Stack

```
Aurelo/
├── Sources/
│   ├── main.swift                 # Entry point & runtime lifecycle
│   ├── AureloApp.swift            # Menu bar status item & app delegate
│   ├── Theme.swift                # Graphite & Mint design tokens
│   ├── Models/
│   │   ├── FileTool.swift         # The 27 tool definitions & categories
│   │   ├── Format.swift           # The 46 format decoders & metadata
│   │   ├── FileAction.swift       # 6 quick desktop actions
│   │   └── FloatingShelfModel.swift # Shelf tray state & item collection
│   ├── Views/
│   │   ├── MainWindowView.swift   # Studio workspace & tool cards grid
│   │   └── FloatingShelfWindow.swift # Floating glass desktop tray
│   └── Engine/
│       └── ProcessingEngine.swift # AVFoundation, CoreImage, PDFKit & Vision
├── Resources/                     # App icon & bundled engine binaries
├── build.sh                       # One-click native compilation script
└── preview.html                   # Interactive web preview & documentation
```

* **Core Graphics & Core Image**: Real-time image processing, adjustments, filtering, and framing.
* **AVFoundation**: Audio loudness normalization, waveform generation, video timeline trimming, and stream muxing.
* **PDFKit**: Document page extraction, reordering, merging, and compression.
* **Vision**: Neural barcode and QR code detection.

---

## 👤 Author

**PAL GHORI**  
*Creator and Lead Developer of Aurelo*

---

## 📄 License

This project is licensed under the MIT License — feel free to use, modify, and distribute.
