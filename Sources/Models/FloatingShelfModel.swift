import Foundation
import AppKit

public struct FloatingItem: Identifiable, Hashable {
    public let id: UUID
    public let url: URL
    public let name: String
    public let sizeString: String
    public let format: AureloFormat?
    public var thumbnail: NSImage?

    public init(url: URL) {
        self.id = UUID()
        self.url = url
        self.name = url.lastPathComponent
        self.format = AureloFormat.detect(url: url)

        let attr = (try? FileManager.default.attributesOfItem(atPath: url.path)) ?? [:]
        let bytes = (attr[.size] as? Int64) ?? 0
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        self.sizeString = formatter.string(fromByteCount: bytes)
        self.thumbnail = NSWorkspace.shared.icon(forFile: url.path)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FloatingItem, rhs: FloatingItem) -> Bool {
        lhs.id == rhs.id
    }
}

public class FloatingShelfModel: ObservableObject {
    public static let shared = FloatingShelfModel()

    @Published public var items: [FloatingItem] = []
    @Published public var isVisible: Bool = true
    @Published public var selectedItemIDs: Set<UUID> = []

    private init() {}

    public func add(urls: [URL]) {
        for u in urls {
            if !items.contains(where: { $0.url.path == u.path }) {
                items.append(FloatingItem(url: u))
            }
        }
    }

    public func remove(id: UUID) {
        items.removeAll { $0.id == id }
        selectedItemIDs.remove(id)
    }

    public func clear() {
        items.removeAll()
        selectedItemIDs.removeAll()
    }

    public func openTerminal(for item: FloatingItem) {
        let dir = item.url.deletingLastPathComponent().path
        let script = "tell application \"Terminal\" to do script \"cd \(dir.replacingOccurrences(of: "\"", with: "\\\""))\""
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
        }
    }

    public func copyPath(for item: FloatingItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.url.path, forType: .string)
    }

    public func shareAirDrop(items: [FloatingItem], from view: NSView) {
        let urls = items.map { $0.url }
        let picker = NSSharingServicePicker(items: urls)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
}
