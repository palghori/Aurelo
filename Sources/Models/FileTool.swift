import Foundation

public enum ToolCategory: String, CaseIterable, Identifiable {
    case image = "Image Studio"
    case audio = "Audio Suite"
    case video = "Video Studio"
    case pdf = "PDF Toolkit"
    case privacy = "Privacy & Meta"
    case utilities = "Extract & Vision"

    public var id: String { rawValue }
}

public enum FileToolType: String, CaseIterable, Identifiable {
    // Media/Doc Compression
    case compress = "compress"
    // Privacy
    case removeMetadata = "removeMetadata"
    case redactImage = "redactImage"
    case redactVideo = "redactVideo"
    case redactAudio = "redactAudio"
    // Image
    case editImage = "editImage"
    case annotateImage = "annotateImage"
    case frameImage = "frameImage"
    case cropImage = "cropImage"
    case createCollage = "createCollage"
    // Audio
    case normalizeAudio = "normalizeAudio"
    case trimAudio = "trimAudio"
    case audioChannels = "audioChannels"
    case audioToVideo = "audioToVideo"
    // Video
    case muteVideo = "muteVideo"
    case trimVideo = "trimVideo"
    case cropVideo = "cropVideo"
    case changeVideoSpeed = "changeVideoSpeed"
    case joinVideos = "joinVideos"
    case videoSnapshots = "videoSnapshots"
    case splitVideo = "splitVideo"
    // PDF
    case splitPDF = "splitPDF"
    case organizePDF = "organizePDF"
    case createPDF = "createPDF"
    case mergePDF = "mergePDF"
    // Archive & Vision
    case extractArchive = "extractArchive"
    case readQRCode = "readQRCode"
    case extractText = "extractText"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .compress: return "Compress File"
        case .removeMetadata: return "Strip Exif & Privacy"
        case .redactImage: return "Redact / Blur Image"
        case .redactVideo: return "Redact Video Timestamps"
        case .redactAudio: return "Bleep / Mute Audio"
        case .editImage: return "Image Adjustments"
        case .annotateImage: return "Annotate & Mark"
        case .frameImage: return "Frame Canvas & Shadow"
        case .cropImage: return "Crop Image"
        case .createCollage: return "Photo Collage"
        case .normalizeAudio: return "Normalize Loudness"
        case .trimAudio: return "Trim Audio Clip"
        case .audioChannels: return "Audio Channels (Stereo/Mono)"
        case .audioToVideo: return "Audio to Video (Artwork)"
        case .muteVideo: return "Strip Audio Track"
        case .trimVideo: return "Trim Video Timeline"
        case .cropVideo: return "Crop Video Box"
        case .changeVideoSpeed: return "Adjust Video Speed"
        case .joinVideos: return "Concatenate Videos"
        case .videoSnapshots: return "Extract Snapshots"
        case .splitVideo: return "Split Video Segments"
        case .splitPDF: return "Split PDF Pages"
        case .organizePDF: return "Organize & Reorder PDF"
        case .createPDF: return "Create PDF from Media"
        case .mergePDF: return "Merge PDF Documents"
        case .extractArchive: return "Extract ZIP / Archive"
        case .readQRCode: return "Detect & Read QR Codes"
        case .extractText: return "OCR Text Extraction"
        }
    }

    public var category: ToolCategory {
        switch self {
        case .compress, .editImage, .annotateImage, .frameImage, .cropImage, .createCollage:
            return .image
        case .normalizeAudio, .trimAudio, .audioChannels:
            return .audio
        case .muteVideo, .trimVideo, .cropVideo, .changeVideoSpeed, .joinVideos, .videoSnapshots, .splitVideo, .audioToVideo:
            return .video
        case .splitPDF, .organizePDF, .createPDF, .mergePDF:
            return .pdf
        case .removeMetadata, .redactImage, .redactVideo, .redactAudio:
            return .privacy
        case .extractArchive, .readQRCode, .extractText:
            return .utilities
        }
    }

    public var iconName: String {
        switch self {
        case .compress: return "arrow.down.right.and.arrow.up.left"
        case .removeMetadata: return "lock.shield.fill"
        case .redactImage: return "eye.slash.fill"
        case .redactVideo: return "video.slash.fill"
        case .redactAudio: return "speaker.slash.fill"
        case .editImage: return "slider.horizontal.3"
        case .annotateImage: return "pencil.tip.crop.circle"
        case .frameImage: return "photo.artframe"
        case .cropImage: return "crop"
        case .createCollage: return "square.grid.2x2.fill"
        case .normalizeAudio: return "waveform.badge.magnifyingglass"
        case .trimAudio: return "timeline.selection"
        case .audioChannels: return "tuningfork"
        case .audioToVideo: return "music.note.tv"
        case .muteVideo: return "speaker.slash"
        case .trimVideo: return "film"
        case .cropVideo: return "crop.rotate"
        case .changeVideoSpeed: return "gauge.with.needle"
        case .joinVideos: return "plus.rectangle.on.rectangle"
        case .videoSnapshots: return "camera.metering.matrix"
        case .splitVideo: return "scissors"
        case .splitPDF: return "doc.badge.arrow.up"
        case .organizePDF: return "square.stack.3d.up"
        case .createPDF: return "doc.fill.badge.plus"
        case .mergePDF: return "doc.on.doc.fill"
        case .extractArchive: return "archivebox.fill"
        case .readQRCode: return "qrcode.viewfinder"
        case .extractText: return "text.viewfinder"
        }
    }

    public var shortDescription: String {
        switch self {
        case .compress: return "Smart compression for images, videos & documents."
        case .removeMetadata: return "Completely wipe GPS, camera, and author Exif tags."
        case .redactImage: return "Blur or blackout sensitive rectangles or detected faces."
        case .redactVideo: return "Pixelate or blackout selected time ranges."
        case .redactAudio: return "Insert censor bleeps or silence over timestamps."
        case .editImage: return "Tweak exposure, contrast, saturation and sharpness."
        case .annotateImage: return "Draw shapes, arrows, captions and callouts."
        case .frameImage: return "Wrap screenshots in gradient cards with shadows."
        case .cropImage: return "Quickly crop images to fixed or freeform dimensions."
        case .createCollage: return "Combine multiple photos into balanced grid layouts."
        case .normalizeAudio: return "Level inconsistent volume peaks to standard broadcast RMS."
        case .trimAudio: return "Snip start/end boundaries with precision waveform."
        case .audioChannels: return "Remix stereo to mono or isolate left/right tracks."
        case .audioToVideo: return "Turn podcast audio into an MP4 video with cover artwork."
        case .muteVideo: return "Remove all audio streams from video files."
        case .trimVideo: return "Cut video to exact start and end timestamps."
        case .cropVideo: return "Crop video canvas to vertical 9:16, 1:1 or custom box."
        case .changeVideoSpeed: return "Speed up or slow down video footage from 0.25x to 4x."
        case .joinVideos: return "Stitch multiple video segments into a single file."
        case .videoSnapshots: return "Capture full-resolution still frames from video."
        case .splitVideo: return "Slice long video into parts by size or duration."
        case .splitPDF: return "Extract every page or specific ranges into PDFs."
        case .organizePDF: return "Visual drag-and-drop page reorder, rotate and delete."
        case .createPDF: return "Combine loose images or documents into a clean PDF."
        case .mergePDF: return "Stack multiple PDFs into a single continuous file."
        case .extractArchive: return "Instantly unpack ZIP, TAR, GZ, and RAR archives."
        case .readQRCode: return "Detect barcodes and QR codes from images or screenshots."
        case .extractText: return "Extract all text from images or scanned PDFs with Apple Neural Engine."
        }
    }

    public var supportedExtensions: [String] {
        switch self {
        case .compress:
            return ["jpg", "jpeg", "png", "webp", "pdf", "mp4", "mov"]
        case .removeMetadata, .editImage, .annotateImage, .frameImage, .cropImage, .redactImage:
            return ["jpg", "jpeg", "png", "webp", "heic", "tiff", "avif", "bmp"]
        case .createCollage:
            return ["jpg", "jpeg", "png", "webp", "heic"]
        case .normalizeAudio, .trimAudio, .audioChannels, .redactAudio:
            return ["mp3", "m4a", "wav", "flac", "ogg", "aiff"]
        case .audioToVideo:
            return ["mp3", "m4a", "wav", "flac"]
        case .muteVideo, .trimVideo, .cropVideo, .changeVideoSpeed, .joinVideos, .videoSnapshots, .splitVideo, .redactVideo:
            return ["mp4", "mov", "mkv", "webm", "avi"]
        case .splitPDF, .organizePDF, .mergePDF:
            return ["pdf"]
        case .createPDF:
            return ["jpg", "jpeg", "png", "webp", "heic", "txt", "md"]
        case .extractArchive:
            return ["zip", "tar", "gz", "gzip", "rar"]
        case .readQRCode:
            return ["jpg", "jpeg", "png", "webp", "heic", "tiff"]
        case .extractText:
            return ["jpg", "jpeg", "png", "webp", "heic", "tiff", "pdf"]
        }
    }
}
