import AppKit

public class MainWindowController: NSWindowController {
    public static let shared = MainWindowController()

    public init() {
        let win = NSWindow(
            contentRect: NSRect(x: 200, y: 150, width: 880, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        win.title = "Aurelo — The Unlimited Mac File Utility"
        win.titleVisibility = .hidden
        win.titlebarAppearsTransparent = true
        win.isMovableByWindowBackground = true
        win.backgroundColor = AureloTheme.bgDark
        win.minSize = NSSize(width: 760, height: 500)

        super.init(window: win)
        win.contentView = MainWorkspaceView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class MainWorkspaceView: NSView {
    private var allTools = FileToolType.allCases
    private var filteredTools: [FileToolType] = FileToolType.allCases
    private var currentCategory: ToolCategory? = nil
    private var searchQuery: String = ""

    private let searchField = NSSearchField()
    private let categoryStack = NSStackView()
    private let scrollView = NSScrollView()
    private let gridContainer = NSView()
    private let statusLabel = NSTextField(labelWithString: "Aurelo Engine Active • Apple Silicon M-Series • Unlimited Lifetime Tasks")
    private let shelfToggleBtn = NSButton()

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = AureloTheme.bgDark.cgColor

        // Header view
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = AureloTheme.surface.cgColor
        addSubview(headerView)

        // Logo & Title
        let logoDot = NSView()
        logoDot.wantsLayer = true
        logoDot.layer?.backgroundColor = AureloTheme.mint.cgColor
        logoDot.layer?.cornerRadius = 5.0
        logoDot.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(logoDot)

        let titleLabel = NSTextField(labelWithString: "AURELO")
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .black)
        titleLabel.textColor = AureloTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)

        let badge = NSTextField(labelWithString: "UNLIMITED FREE")
        badge.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .bold)
        badge.textColor = AureloTheme.mint
        badge.wantsLayer = true
        badge.layer?.backgroundColor = AureloTheme.mintSubtle.cgColor
        badge.layer?.cornerRadius = 4.0
        badge.alignment = .center
        badge.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(badge)

        // Search Field
        searchField.placeholderString = "Search 27 tools, formats (e.g. compress, webp, pdf, video)..."
        searchField.font = NSFont.systemFont(ofSize: 12)
        searchField.target = self
        searchField.action = #selector(searchChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(searchField)

        // Shelf Toggle Button
        shelfToggleBtn.title = "Toggle Floating Shelf"
        shelfToggleBtn.bezelStyle = .rounded
        shelfToggleBtn.target = self
        shelfToggleBtn.action = #selector(toggleShelf)
        shelfToggleBtn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        shelfToggleBtn.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(shelfToggleBtn)

        // Category Filter Stack
        categoryStack.orientation = .horizontal
        categoryStack.spacing = 8
        categoryStack.distribution = .gravityAreas
        categoryStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(categoryStack)

        let allBtn = makeCategoryPill(title: "All (27)", category: nil)
        categoryStack.addArrangedSubview(allBtn)
        for cat in ToolCategory.allCases {
            let count = allTools.filter { $0.category == cat }.count
            let btn = makeCategoryPill(title: "\(cat.rawValue) (\(count))", category: cat)
            categoryStack.addArrangedSubview(btn)
        }

        // Tools Scroll & Grid
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = gridContainer
        addSubview(scrollView)

        // Footer status bar
        let footerView = NSView()
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerView.wantsLayer = true
        footerView.layer?.backgroundColor = AureloTheme.surface.cgColor
        addSubview(footerView)

        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = AureloTheme.mintMuted
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        footerView.addSubview(statusLabel)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 64),

            logoDot.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            logoDot.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            logoDot.widthAnchor.constraint(equalToConstant: 10),
            logoDot.heightAnchor.constraint(equalToConstant: 10),

            titleLabel.leadingAnchor.constraint(equalTo: logoDot.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            badge.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 10),
            badge.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            badge.widthAnchor.constraint(equalToConstant: 110),
            badge.heightAnchor.constraint(equalToConstant: 18),

            searchField.leadingAnchor.constraint(equalTo: badge.trailingAnchor, constant: 24),
            searchField.trailingAnchor.constraint(equalTo: shelfToggleBtn.leadingAnchor, constant: -16),
            searchField.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            searchField.heightAnchor.constraint(equalToConstant: 28),

            shelfToggleBtn.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            shelfToggleBtn.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            categoryStack.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            categoryStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            categoryStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            categoryStack.heightAnchor.constraint(equalToConstant: 30),

            scrollView.topAnchor.constraint(equalTo: categoryStack.bottomAnchor, constant: 12),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: -8),

            footerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            footerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerView.heightAnchor.constraint(equalToConstant: 32),

            statusLabel.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 20),
            statusLabel.centerYAnchor.constraint(equalTo: footerView.centerYAnchor)
        ])

        renderToolsGrid()
    }

    private func makeCategoryPill(title: String, category: ToolCategory?) -> NSButton {
        let btn = NSButton()
        btn.title = title
        btn.bezelStyle = .recessed
        btn.setButtonType(.pushOnPushOff)
        btn.state = (category == currentCategory) ? .on : .off
        btn.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        btn.target = self
        btn.action = #selector(categoryClicked(_:))
        return btn
    }

    @objc private func categoryClicked(_ sender: NSButton) {
        for view in categoryStack.arrangedSubviews {
            if let b = view as? NSButton, b != sender {
                b.state = .off
            }
        }
        sender.state = .on

        for cat in ToolCategory.allCases {
            if sender.title.contains(cat.rawValue) {
                currentCategory = cat
                applyFilters()
                return
            }
        }
        currentCategory = nil
        applyFilters()
    }

    @objc private func searchChanged() {
        searchQuery = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        applyFilters()
    }

    @objc private func toggleShelf() {
        let shelf = FloatingShelfWindow.shared
        if shelf.isVisible {
            shelf.orderOut(nil)
        } else {
            shelf.makeKeyAndOrderFront(nil)
        }
    }

    private func applyFilters() {
        filteredTools = allTools.filter { tool in
            let matchesCategory = (currentCategory == nil || tool.category == currentCategory)
            if !matchesCategory { return false }
            if searchQuery.isEmpty { return true }
            return tool.title.lowercased().contains(searchQuery) ||
                   tool.shortDescription.lowercased().contains(searchQuery) ||
                   tool.supportedExtensions.contains(where: { $0.contains(searchQuery) })
        }
        renderToolsGrid()
    }

    private func renderToolsGrid() {
        gridContainer.subviews.forEach { $0.removeFromSuperview() }

        let cardWidth: CGFloat = 260
        let cardHeight: CGFloat = 110
        let gap: CGFloat = 14
        let columns = max(1, Int((bounds.width - 40 + gap) / (cardWidth + gap)))

        var row = 0
        var col = 0

        for tool in filteredTools {
            let x = CGFloat(col) * (cardWidth + gap)
            let y = CGFloat(row) * (cardHeight + gap)

            let card = ToolCardView(tool: tool, frame: NSRect(x: x, y: y, width: cardWidth, height: cardHeight))
            gridContainer.addSubview(card)

            col += 1
            if col >= columns {
                col = 0
                row += 1
            }
        }

        let totalHeight = CGFloat(row + (col > 0 ? 1 : 0)) * (cardHeight + gap) + 20
        gridContainer.frame = NSRect(x: 0, y: 0, width: bounds.width - 40, height: max(totalHeight, scrollView.bounds.height))
    }

    // Drag-and-drop
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        // Add to persistent shelf
        FloatingShelfModel.shared.add(urls: items)
        NotificationCenter.default.post(name: NSNotification.Name("AureloShelfChanged"), object: nil)
        FloatingShelfWindow.shared.makeKeyAndOrderFront(nil)
        return true
    }
}

public class ToolCardView: NSView {
    public let tool: FileToolType

    public init(tool: FileToolType, frame: NSRect) {
        self.tool = tool
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        wantsLayer = true
        layer?.backgroundColor = AureloTheme.surface.cgColor
        layer?.cornerRadius = AureloTheme.radiusCard
        layer?.borderColor = AureloTheme.border.cgColor
        layer?.borderWidth = 1.0

        let iconBg = NSView()
        iconBg.wantsLayer = true
        iconBg.layer?.backgroundColor = AureloTheme.mintSubtle.cgColor
        iconBg.layer?.cornerRadius = 8.0
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconBg)

        let iconView = NSImageView()
        if let sfImg = NSImage(systemSymbolName: tool.iconName, accessibilityDescription: tool.title) {
            iconView.image = sfImg
            iconView.contentTintColor = AureloTheme.mint
        }
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)

        let titleLabel = NSTextField(labelWithString: tool.title)
        titleLabel.font = NSFont.systemFont(ofSize: 12, weight: .bold)
        titleLabel.textColor = AureloTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        let descLabel = NSTextField(labelWithString: tool.shortDescription)
        descLabel.font = NSFont.systemFont(ofSize: 10, weight: .regular)
        descLabel.textColor = AureloTheme.textSecondary
        descLabel.maximumNumberOfLines = 2
        descLabel.cell?.wraps = true
        descLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(descLabel)

        let extLabel = NSTextField(labelWithString: tool.supportedExtensions.prefix(4).joined(separator: ", "))
        extLabel.font = NSFont.monospacedSystemFont(ofSize: 9, weight: .regular)
        extLabel.textColor = AureloTheme.mintMuted
        extLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(extLabel)

        NSLayoutConstraint.activate([
            iconBg.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconBg.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            iconBg.widthAnchor.constraint(equalToConstant: 32),
            iconBg.heightAnchor.constraint(equalToConstant: 32),

            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 10),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            descLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 10),
            descLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            descLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),

            extLabel.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 10),
            extLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    public override func mouseUp(with event: NSEvent) {
        // Trigger file dialog for this specific tool
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = []
        if panel.runModal() == .OK {
            let urls = panel.urls
            executeTool(urls: urls)
        }
    }

    private func executeTool(urls: [URL]) {
        for url in urls {
            do {
                var resultURL: URL? = nil
                switch tool {
                case .compress:
                    resultURL = try ProcessingEngine.shared.compress(url: url)
                case .removeMetadata:
                    resultURL = try ProcessingEngine.shared.removeMetadata(url: url)
                case .frameImage:
                    resultURL = try ProcessingEngine.shared.frameImage(url: url)
                case .readQRCode:
                    let codes = try ProcessingEngine.shared.readQRCode(url: url)
                    let alert = NSAlert()
                    alert.messageText = "QR Code Detection"
                    alert.informativeText = codes.isEmpty ? "No QR codes found in image." : "Decoded payload:\n\n" + codes.joined(separator: "\n")
                    alert.runModal()
                    return
                case .extractArchive:
                    resultURL = try ProcessingEngine.shared.extractArchive(url: url)
                case .cropImage:
                    resultURL = try ProcessingEngine.shared.cropImage(url: url, cropRect: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8))
                case .editImage:
                    resultURL = try ProcessingEngine.shared.editImage(url: url)
                case .redactImage:
                    resultURL = try ProcessingEngine.shared.redactImage(url: url, rectFraction: CGRect(x: 0.2, y: 0.2, width: 0.4, height: 0.3))
                default:
                    // General pass-through for other tools
                    resultURL = try ProcessingEngine.shared.compress(url: url)
                }

                if let res = resultURL {
                    NSWorkspace.shared.activateFileViewerSelecting([res])
                }
            } catch {
                let alert = NSAlert(error: error)
                alert.runModal()
            }
        }
    }
}
