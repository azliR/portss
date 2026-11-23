import AppKit
import PortssCore

@MainActor
final class ManagePortsWindowController: NSWindowController {
    enum ColumnIdentifier {
        static let name = NSUserInterfaceItemIdentifier("name")
        static let value = NSUserInterfaceItemIdentifier("value")
    }

    enum SelectionTarget {
        case group(UUID)
        case port(UUID)
    }

    static let portRowPasteboardType = NSPasteboard.PasteboardType("com.local.portss.port-row")
    static let maximumCharacterCount = 24

    let storage: PortStorage
    let outlineView = ManagePortsOutlineView()
    private let statusLabel = NSTextField(labelWithString: "")

    var rootNodes: [ManagePortsNode] = []
    var expandedGroupIds: Set<UUID> = []
    var hasLoadedOnce = false
    var isReloading = false
    var isCancellingEdit = false
    var isHandlingDraftNavigation = false
    var draggedNode: ManagePortsNode?

    init(storage: PortStorage) {
        self.storage = storage

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 440),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Manage Ports"
        window.minSize = NSSize(width: 360, height: 280)
        window.isReleasedWhenClosed = false
        super.init(window: window)

        setupContent(in: window)
        window.center()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present() {
        reloadFromStorage(selecting: nil)
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(outlineView)
    }

    private func setupContent(in window: NSWindow) {
        let contentView = NSView()
        window.contentView = contentView

        configureOutlineView()

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        contentView.addSubview(scrollView)

        let buttonBar = makeButtonBar()
        contentView.addSubview(buttonBar)

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        contentView.addSubview(statusLabel)
        showHint()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            buttonBar.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 10),
            buttonBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            buttonBar.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -12),

            statusLabel.topAnchor.constraint(equalTo: buttonBar.bottomAnchor, constant: 8),
            statusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            statusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -14),
            statusLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    private func configureOutlineView() {
        let nameColumn = NSTableColumn(identifier: ColumnIdentifier.name)
        nameColumn.title = "Name"
        nameColumn.minWidth = 160
        nameColumn.resizingMask = .autoresizingMask

        let valueColumn = NSTableColumn(identifier: ColumnIdentifier.value)
        valueColumn.title = "Port"
        valueColumn.width = 140
        valueColumn.minWidth = 90
        valueColumn.resizingMask = .userResizingMask

        outlineView.addTableColumn(nameColumn)
        outlineView.addTableColumn(valueColumn)
        outlineView.outlineTableColumn = nameColumn
        outlineView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        outlineView.style = .inset
        outlineView.rowHeight = 24
        outlineView.usesAlternatingRowBackgroundColors = false
        outlineView.autosaveExpandedItems = false
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.target = self
        outlineView.doubleAction = #selector(handleDoubleClick)
        outlineView.registerForDraggedTypes([Self.portRowPasteboardType])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
        outlineView.onDeleteKey = { [weak self] in self?.removeSelectedNode() }
        outlineView.onReturnKey = { [weak self] in self?.beginEditingSelectedRow() }
    }

    private func makeButtonBar() -> NSStackView {
        let addPortButton = NSButton(title: "Add Port", target: self, action: #selector(handleAddPort))
        let addGroupButton = NSButton(title: "Add Group", target: self, action: #selector(handleAddGroup))
        let removeButton = NSButton(title: "Remove", target: self, action: #selector(handleRemove))

        let stackView = NSStackView(views: [addPortButton, addGroupButton, removeButton])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .horizontal
        stackView.spacing = 8
        return stackView
    }

    func reloadFromStorage(selecting target: SelectionTarget?) {
        let store: PortStore
        do {
            store = try storage.loadStore()
        } catch {
            DialogPresenter.shared.showError(title: "Data Loading Error", message: error.localizedDescription)
            return
        }

        rootNodes = ManagePortsNode.buildTree(from: store)
        if !hasLoadedOnce {
            expandedGroupIds = Set(store.groups.map(\.id))
            hasLoadedOnce = true
        }

        reloadOutlinePreservingExpansion()
        select(target)
    }

    func reloadOutlinePreservingExpansion() {
        isReloading = true
        outlineView.reloadData()
        for node in rootNodes where node.isGroup {
            guard let groupId = node.groupId, expandedGroupIds.contains(groupId) else {
                continue
            }
            outlineView.expandItem(node)
        }
        isReloading = false
    }

    private func select(_ target: SelectionTarget?) {
        guard let target = target, let node = findNode(matching: target) else {
            return
        }

        let row = outlineView.row(forItem: node)
        guard row >= 0 else {
            return
        }

        outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        outlineView.scrollRowToVisible(row)
    }

    private func findNode(matching target: SelectionTarget) -> ManagePortsNode? {
        let allNodes = rootNodes + rootNodes.flatMap(\.children)
        return allNodes.first { node in
            switch (target, node.kind) {
            case (.group(let targetId), .group(let group)):
                return group.id == targetId
            case (.port(let targetId), .port(let item, _)):
                return item.id == targetId
            default:
                return false
            }
        }
    }

    var selectedNode: ManagePortsNode? {
        let row = outlineView.selectedRow
        guard row >= 0 else {
            return nil
        }
        return outlineView.item(atRow: row) as? ManagePortsNode
    }

    func showHint() {
        statusLabel.textColor = NSColor.secondaryLabelColor
        statusLabel.stringValue = "Double-click or press Return to edit. Drag ports between groups."
    }

    func report(_ error: Error) {
        guard error is ValidationError else {
            DialogPresenter.shared.showError(title: "Save Failed", message: error.localizedDescription)
            return
        }

        NSSound.beep()
        statusLabel.textColor = NSColor.systemRed
        statusLabel.stringValue = error.localizedDescription
    }

    @objc private func handleDoubleClick() {
        let row = outlineView.clickedRow
        let column = outlineView.clickedColumn
        guard row >= 0 else {
            return
        }

        beginEditing(row: row, column: max(column, 0))
    }

    @objc private func handleAddPort() {
        insertDraftPort()
    }

    @objc private func handleAddGroup() {
        insertDraftGroup()
    }

    @objc private func handleRemove() {
        removeSelectedNode()
    }
}
