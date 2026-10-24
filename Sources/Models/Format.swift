import Foundation

public enum FormatCategory: String, CaseIterable, Codable {
    case image = "Images"
    case audio = "Audio"
    case video = "Video"
    case document = "Documents"
    case subtitle = "Subtitles"
    case archive = "Archives"
}

public struct FileFormatInfo: Identifiable, Hashable {
    public var id: String { rawValue }
    public let rawValue: String
    public let displayName: String
    public let category: FormatCategory
    public let extensions: [String]
    public let mimeType: String

    public init(rawValue: String, displayName: String, category: FormatCategory, extensions: [String], mimeType: String) {
        self.rawValue = rawValue
        self.displayName = displayName
        self.category = category
        self.extensions = extensions
        self.mimeType = mimeType
    }
}

public enum AureloFormat: String, CaseIterable, Codable, Identifiable {
    // 9 Images
    case jpg, png, webp, heic, tiff, svg, avif, bmp, gif
    // 8 Audio
    case mp3, m4a, wav, flac, ogg, opus, aiff, wma
    // 6 Video
    case mp4, mov, mkv, webm, avi, wmv
    // 17 Documents & Spreadsheets
    case pdf, docx, pages, ppt, pptx, txt, md, rtf, rtfd, textClipping, html, epub, xlsx, xls, ods, csv, tsv
    // 2 Subtitles
    case srt, vtt
    // 4 Archives
    case zip, tar, gzip, rar

    public var id: String { rawValue }

    public var info: FileFormatInfo {
        switch self {
        case .jpg: return FileFormatInfo(rawValue: "jpg", displayName: "JPEG Image", category: .image, extensions: ["jpg", "jpeg"], mimeType: "image/jpeg")
        case .png: return FileFormatInfo(rawValue: "png", displayName: "PNG Image", category: .image, extensions: ["png"], mimeType: "image/png")
        case .webp: return FileFormatInfo(rawValue: "webp", displayName: "WebP Image", category: .image, extensions: ["webp"], mimeType: "image/webp")
        case .heic: return FileFormatInfo(rawValue: "heic", displayName: "Apple HEIC", category: .image, extensions: ["heic", "heif"], mimeType: "image/heic")
        case .tiff: return FileFormatInfo(rawValue: "tiff", displayName: "TIFF Image", category: .image, extensions: ["tiff", "tif"], mimeType: "image/tiff")
        case .svg: return FileFormatInfo(rawValue: "svg", displayName: "SVG Vector", category: .image, extensions: ["svg"], mimeType: "image/svg+xml")
        case .avif: return FileFormatInfo(rawValue: "avif", displayName: "AVIF Image", category: .image, extensions: ["avif"], mimeType: "image/avif")
        case .bmp: return FileFormatInfo(rawValue: "bmp", displayName: "Bitmap Image", category: .image, extensions: ["bmp"], mimeType: "image/bmp")
        case .gif: return FileFormatInfo(rawValue: "gif", displayName: "GIF Animation", category: .image, extensions: ["gif"], mimeType: "image/gif")

        case .mp3: return FileFormatInfo(rawValue: "mp3", displayName: "MP3 Audio", category: .audio, extensions: ["mp3"], mimeType: "audio/mpeg")
        case .m4a: return FileFormatInfo(rawValue: "m4a", displayName: "M4A AAC Audio", category: .audio, extensions: ["m4a"], mimeType: "audio/mp4")
        case .wav: return FileFormatInfo(rawValue: "wav", displayName: "WAV PCM Audio", category: .audio, extensions: ["wav"], mimeType: "audio/wav")
        case .flac: return FileFormatInfo(rawValue: "flac", displayName: "FLAC Lossless", category: .audio, extensions: ["flac"], mimeType: "audio/flac")
        case .ogg: return FileFormatInfo(rawValue: "ogg", displayName: "Ogg Vorbis", category: .audio, extensions: ["ogg", "oga"], mimeType: "audio/ogg")
        case .opus: return FileFormatInfo(rawValue: "opus", displayName: "Opus Audio", category: .audio, extensions: ["opus"], mimeType: "audio/opus")
        case .aiff: return FileFormatInfo(rawValue: "aiff", displayName: "AIFF Audio", category: .audio, extensions: ["aiff", "aif"], mimeType: "audio/aiff")
        case .wma: return FileFormatInfo(rawValue: "wma", displayName: "Windows Media Audio", category: .audio, extensions: ["wma"], mimeType: "audio/x-ms-wma")

        case .mp4: return FileFormatInfo(rawValue: "mp4", displayName: "MP4 Video", category: .video, extensions: ["mp4", "m4v"], mimeType: "video/mp4")
        case .mov: return FileFormatInfo(rawValue: "mov", displayName: "QuickTime Movie", category: .video, extensions: ["mov"], mimeType: "video/quicktime")
        case .mkv: return FileFormatInfo(rawValue: "mkv", displayName: "Matroska Video", category: .video, extensions: ["mkv"], mimeType: "video/x-matroska")
        case .webm: return FileFormatInfo(rawValue: "webm", displayName: "WebM Video", category: .video, extensions: ["webm"], mimeType: "video/webm")
        case .avi: return FileFormatInfo(rawValue: "avi", displayName: "AVI Video", category: .video, extensions: ["avi"], mimeType: "video/x-msvideo")
        case .wmv: return FileFormatInfo(rawValue: "wmv", displayName: "WMV Video", category: .video, extensions: ["wmv"], mimeType: "video/x-ms-wmv")

        case .pdf: return FileFormatInfo(rawValue: "pdf", displayName: "PDF Document", category: .document, extensions: ["pdf"], mimeType: "application/pdf")
        case .docx: return FileFormatInfo(rawValue: "docx", displayName: "Word Document", category: .document, extensions: ["docx"], mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")
        case .pages: return FileFormatInfo(rawValue: "pages", displayName: "Apple Pages", category: .document, extensions: ["pages"], mimeType: "application/x-iwork-pages-sffpages")
        case .ppt: return FileFormatInfo(rawValue: "ppt", displayName: "PowerPoint 97-2003", category: .document, extensions: ["ppt"], mimeType: "application/vnd.ms-powerpoint")
        case .pptx: return FileFormatInfo(rawValue: "pptx", displayName: "PowerPoint Presentation", category: .document, extensions: ["pptx"], mimeType: "application/vnd.openxmlformats-officedocument.presentationml.presentation")
        case .txt: return FileFormatInfo(rawValue: "txt", displayName: "Plain Text", category: .document, extensions: ["txt"], mimeType: "text/plain")
        case .md: return FileFormatInfo(rawValue: "md", displayName: "Markdown", category: .document, extensions: ["md", "markdown"], mimeType: "text/markdown")
        case .rtf: return FileFormatInfo(rawValue: "rtf", displayName: "Rich Text Format", category: .document, extensions: ["rtf"], mimeType: "application/rtf")
        case .rtfd: return FileFormatInfo(rawValue: "rtfd", displayName: "RTF Directory", category: .document, extensions: ["rtfd"], mimeType: "application/x-rtfd")
        case .textClipping: return FileFormatInfo(rawValue: "textClipping", displayName: "macOS Text Clipping", category: .document, extensions: ["textClipping"], mimeType: "application/x-textclipping")
        case .html: return FileFormatInfo(rawValue: "html", displayName: "HTML Webpage", category: .document, extensions: ["html", "htm"], mimeType: "text/html")
        case .epub: return FileFormatInfo(rawValue: "epub", displayName: "EPUB eBook", category: .document, extensions: ["epub"], mimeType: "application/epub+zip")
        case .xlsx: return FileFormatInfo(rawValue: "xlsx", displayName: "Excel Spreadsheet", category: .document, extensions: ["xlsx"], mimeType: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
        case .xls: return FileFormatInfo(rawValue: "xls", displayName: "Excel 97-2003", category: .document, extensions: ["xls"], mimeType: "application/vnd.ms-excel")
        case .ods: return FileFormatInfo(rawValue: "ods", displayName: "OpenDocument Sheet", category: .document, extensions: ["ods"], mimeType: "application/vnd.oasis.opendocument.spreadsheet")
        case .csv: return FileFormatInfo(rawValue: "csv", displayName: "CSV Table", category: .document, extensions: ["csv"], mimeType: "text/csv")
        case .tsv: return FileFormatInfo(rawValue: "tsv", displayName: "TSV Table", category: .document, extensions: ["tsv"], mimeType: "text/tab-separated-values")

        case .srt: return FileFormatInfo(rawValue: "srt", displayName: "SubRip Subtitles", category: .subtitle, extensions: ["srt"], mimeType: "application/x-subrip")
        case .vtt: return FileFormatInfo(rawValue: "vtt", displayName: "WebVTT Subtitles", category: .subtitle, extensions: ["vtt"], mimeType: "text/vtt")

        case .zip: return FileFormatInfo(rawValue: "zip", displayName: "ZIP Archive", category: .archive, extensions: ["zip"], mimeType: "application/zip")
        case .tar: return FileFormatInfo(rawValue: "tar", displayName: "TAR Archive", category: .archive, extensions: ["tar"], mimeType: "application/x-tar")
        case .gzip: return FileFormatInfo(rawValue: "gzip", displayName: "GZIP Archive", category: .archive, extensions: ["gz", "gzip"], mimeType: "application/gzip")
        case .rar: return FileFormatInfo(rawValue: "rar", displayName: "RAR Archive", category: .archive, extensions: ["rar"], mimeType: "application/vnd.rar")
        }
    }

    public static func detect(url: URL) -> AureloFormat? {
        let ext = url.pathExtension.lowercased()
        for f in allCases {
            if f.info.extensions.contains(ext) {
                return f
            }
        }
        return nil
    }
}
