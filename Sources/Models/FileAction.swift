import Foundation
import AppKit

public enum FileActionType: String, CaseIterable, Identifiable {
    case airDrop = "airDrop"
    case float = "float"
    case copy = "copy"
    case move = "move"
    case copyPath = "copyPath"
    case openTerminal = "openTerminal"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .airDrop: return "AirDrop"
        case .float: return "Float Tray"
        case .copy: return "Copy File"
        case .move: return "Move File"
        case .copyPath: return "Copy Path"
        case .openTerminal: return "Open in Terminal"
        }
    }

    public var iconName: String {
        switch self {
        case .airDrop: return "airplayaudio"
        case .float: return "paperclip"
        case .copy: return "doc.on.doc"
        case .move: return "folder"
        case .copyPath: return "link"
        case .openTerminal: return "terminal"
        }
    }

    public var description: String {
        switch self {
        case .airDrop: return "Send immediately via AirDrop"
        case .float: return "Pin to floating translucent shelf"
        case .copy: return "Copy to macOS clipboard"
        case .move: return "Move to target directory"
        case .copyPath: return "Copy full path string to clipboard"
        case .openTerminal: return "Open directory in Terminal"
        }
    }
}
