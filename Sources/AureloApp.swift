import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        setupStatusItem()

        // Display Main Studio Window
        MainWindowController.shared.showWindow(nil)
        MainWindowController.shared.window?.center()
        MainWindowController.shared.window?.makeKeyAndOrderFront(nil)

        // Show Floating Shelf Window
        FloatingShelfWindow.shared.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            if let img = NSImage(systemSymbolName: "circle.hexagongrid.circle.fill", accessibilityDescription: "Aurelo") {
                button.image = img
                button.contentTintColor = AureloTheme.mint
            } else {
                button.title = "✦ Aurelo"
            }
        }

        let menu = NSMenu()

        let headerItem = NSMenuItem(title: "Aurelo Studio — Unlimited", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        menu.addItem(NSMenuItem.separator())

        let openStudioItem = NSMenuItem(title: "Open Aurelo Studio...", action: #selector(openStudio), keyEquivalent: "o")
        openStudioItem.target = self
        menu.addItem(openStudioItem)

        let toggleShelfItem = NSMenuItem(title: "Toggle Floating Shelf", action: #selector(toggleShelf), keyEquivalent: "s")
        toggleShelfItem.target = self
        menu.addItem(toggleShelfItem)

        let clearShelfItem = NSMenuItem(title: "Clear Floating Shelf", action: #selector(clearShelf), keyEquivalent: "")
        clearShelfItem.target = self
        menu.addItem(clearShelfItem)

        menu.addItem(NSMenuItem.separator())

        let formatsItem = NSMenuItem(title: "Supported Formats (46 Formats)...", action: #selector(showFormats), keyEquivalent: "")
        formatsItem.target = self
        menu.addItem(formatsItem)

        let statusText = NSMenuItem(title: "License: Unlimited Free (No Limits)", action: nil, keyEquivalent: "")
        statusText.isEnabled = false
        menu.addItem(statusText)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit Aurelo", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusMenu = menu
        statusItem?.menu = menu
    }

    @objc private func openStudio() {
        MainWindowController.shared.showWindow(nil)
        MainWindowController.shared.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func toggleShelf() {
        let shelf = FloatingShelfWindow.shared
        if shelf.isVisible {
            shelf.orderOut(nil)
        } else {
            shelf.makeKeyAndOrderFront(nil)
        }
    }

    @objc private func clearShelf() {
        FloatingShelfModel.shared.clear()
        NotificationCenter.default.post(name: NSNotification.Name("AureloShelfChanged"), object: nil)
    }

    @objc private func showFormats() {
        let alert = NSAlert()
        alert.messageText = "Aurelo Format Compatibility Matrix"
        alert.informativeText = """
        Aurelo natively supports 46 file formats across 6 domains:

        • Images (9): JPG, PNG, WebP, HEIC, TIFF, SVG, AVIF, BMP, GIF
        • Audio (8): MP3, M4A, WAV, FLAC, OGG, Opus, AIFF, WMA
        • Video (6): MP4, MOV, MKV, WebM, AVI, WMV
        • Documents (17): PDF, DOCX, Pages, PPT, PPTX, TXT, MD, RTF, RTFD, TextClipping, HTML, EPUB, XLSX, XLS, ODS, CSV, TSV
        • Subtitles (2): SRT, VTT
        • Archives (4): ZIP, TAR, GZIP, RAR

        Engine: Native macOS AVFoundation + CoreImage + PDFKit + Vision + CoreGraphics.
        Usage Limit: Unlimited Free Forever.
        """
        alert.runModal()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            MainWindowController.shared.showWindow(nil)
        }
        return true
    }
}
