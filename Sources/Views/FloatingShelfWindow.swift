import AppKit

public class FloatingShelfWindow: NSPanel {
    public static let shared = FloatingShelfWindow()

    private var hostingView: NSView?
    private var isPinned: Bool = true

    private init() {
        super.init(
            contentRect: NSRect(x: 100, y: 100, width: 340, height: 420),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        setupContent()
    }

    private func setupContent() {
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = AureloTheme.radiusTray
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderColor = AureloTheme.borderFocus.cgColor
        visualEffect.layer?.borderWidth = 1.0

        let shelfView = ShelfContentView()
        shelfView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(shelfView)

        NSLayoutConstraint.activate([
            shelfView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            shelfView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            shelfView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            shelfView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor)
        ])

        self.contentView = visualEffect
    }
}

public class ShelfContentView: NSView {
    private let titleLabel = NSTextField(labelWithString: "Aurelo Shelf")
    private let badgeLabel = NSTextField(labelWithString: "0 files")
    private let clearButton = NSButton()
    private let tableView = NSTableView()
    private let scrollView = NSScrollView()
    private let dropPrompt = NSTextField(labelWithString: "Drop files here to float")

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        setupUI()
        NotificationCenter.default.addObserver(self, selector: #selector(shelfUpdated), name: NSNotification.Name("AureloShelfChanged"), object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        // Header Mint Dot
        let mintDot = NSView()
        mintDot.wantsLayer = true
        mintDot.layer?.backgroundColor = AureloTheme.mint.cgColor
        mintDot.layer?.cornerRadius = 4.0
        mintDot.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mintDot)

        // Title
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        titleLabel.textColor = AureloTheme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Badge
        badgeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium)
        badgeLabel.textColor = AureloTheme.mint
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(badgeLabel)

        // Clear button
        clearButton.title = "Clear"
        clearButton.bezelStyle = .inline
        clearButton.target = self
        clearButton.action = #selector(clearShelf)
        clearButton.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(clearButton)

        // Drop Prompt
        dropPrompt.font = NSFont.systemFont(ofSize: 12, weight: .regular)
        dropPrompt.textColor = AureloTheme.textMuted
        dropPrompt.alignment = .center
        dropPrompt.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dropPrompt)

        // Scroll View & Table View
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = true
        scrollView.documentView = tableView

        let col = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("itemCol"))
        col.title = "Files"
        tableView.addTableColumn(col)
        tableView.headerView = nil
        tableView.backgroundColor = .clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 44
        addSubview(scrollView)

        NSLayoutConstraint.activate([
            mintDot.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            mintDot.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            mintDot.widthAnchor.constraint(equalToConstant: 8),
            mintDot.heightAnchor.constraint(equalToConstant: 8),

            titleLabel.leadingAnchor.constraint(equalTo: mintDot.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: mintDot.centerYAnchor),

            badgeLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            badgeLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            clearButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),

            dropPrompt.centerXAnchor.constraint(equalTo: centerXAnchor),
            dropPrompt.centerYAnchor.constraint(equalTo: centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])

        refreshBadge()
    }

    @objc private func clearShelf() {
        FloatingShelfModel.shared.clear()
        shelfUpdated()
    }

    @objc private func shelfUpdated() {
        tableView.reloadData()
        refreshBadge()
    }

    private func refreshBadge() {
        let count = FloatingShelfModel.shared.items.count
        badgeLabel.stringValue = "\(count) file\(count == 1 ? "" : "s")"
        dropPrompt.isHidden = count > 0
    }

    // Drag and drop destination
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let items = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        FloatingShelfModel.shared.add(urls: items)
        shelfUpdated()
        return true
    }
}

extension ShelfContentView: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return FloatingShelfModel.shared.items.count
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let items = FloatingShelfModel.shared.items
        guard row < items.count else { return nil }
        let item = items[row]

        let cell = NSView()
        cell.wantsLayer = true
        cell.layer?.cornerRadius = 8
        cell.layer?.backgroundColor = AureloTheme.surface.cgColor

        let iconView = NSImageView(image: item.thumbnail ?? NSImage())
        iconView.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(iconView)

        let nameLabel = NSTextField(labelWithString: item.name)
        nameLabel.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        nameLabel.textColor = AureloTheme.textPrimary
        nameLabel.lineBreakMode = .byTruncatingMiddle
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(nameLabel)

        let sizeLabel = NSTextField(labelWithString: item.sizeString)
        sizeLabel.font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        sizeLabel.textColor = AureloTheme.textSecondary
        sizeLabel.translatesAutoresizingMaskIntoConstraints = false
        cell.addSubview(sizeLabel)

        let termBtn = NSButton()
        termBtn.title = "Terminal"
        termBtn.bezelStyle = .inline
        termBtn.font = NSFont.systemFont(ofSize: 9, weight: .medium)
        termBtn.translatesAutoresizingMaskIntoConstraints = false
        termBtn.target = self
        termBtn.action = #selector(openTerminalAction(_:))
        termBtn.tag = row
        cell.addSubview(termBtn)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 8),
            iconView.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 28),
            iconView.heightAnchor.constraint(equalToConstant: 28),

            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            nameLabel.topAnchor.constraint(equalTo: cell.topAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: termBtn.leadingAnchor, constant: -8),

            sizeLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            sizeLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),

            termBtn.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -8),
            termBtn.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])

        return cell
    }

    @objc private func openTerminalAction(_ sender: NSButton) {
        let items = FloatingShelfModel.shared.items
        if sender.tag < items.count {
            FloatingShelfModel.shared.openTerminal(for: items[sender.tag])
        }
    }
}
