import AppKit
import PortssCore

extension ManagePortsWindowController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let node = item as? ManagePortsNode else {
            return rootNodes.count
        }
        return node.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let node = item as? ManagePortsNode else {
            return rootNodes[index]
        }
        return node.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? ManagePortsNode else {
            return false
        }
        return node.isGroup && !node.children.isEmpty
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? ManagePortsNode, let tableColumn = tableColumn else {
            return nil
        }

        let isNameColumn = tableColumn.identifier == ColumnIdentifier.name
        let cellView = dequeueCellView(identifier: tableColumn.identifier)
        guard let textField = cellView.textField else {
            return cellView
        }

        textField.stringValue = isNameColumn ? node.nameText : node.valueText
        textField.isEditable = isCellEditable(node: node, isNameColumn: isNameColumn)
        textField.placeholderString = placeholder(for: node, isNameColumn: isNameColumn)

        if isNameColumn {
            textField.font = node.isGroup
                ? NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold)
                : NSFont.systemFont(ofSize: NSFont.systemFontSize)
            textField.textColor = NSColor.labelColor
        } else {
            textField.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
            textField.textColor = node.isGroup ? NSColor.tertiaryLabelColor : NSColor.secondaryLabelColor
        }

        return cellView
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
        guard !isReloading, let groupId = expansionGroupId(from: notification) else {
            return
        }
        expandedGroupIds.insert(groupId)
    }

    func outlineViewItemDidCollapse(_ notification: Notification) {
        guard !isReloading, let groupId = expansionGroupId(from: notification) else {
            return
        }
        expandedGroupIds.remove(groupId)
    }

    private func expansionGroupId(from notification: Notification) -> UUID? {
        let node = notification.userInfo?["NSObject"] as? ManagePortsNode
        return node?.groupId
    }

    private func dequeueCellView(identifier: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        if let reusedView = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView {
            return reusedView
        }

        let cellView = NSTableCellView()
        cellView.identifier = identifier

        let textField = NSTextField(string: "")
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isBordered = false
        textField.drawsBackground = false
        textField.lineBreakMode = .byTruncatingTail
        textField.cell?.usesSingleLineMode = true
        textField.delegate = self
        if identifier == ColumnIdentifier.value {
            textField.alignment = .right
        }

        cellView.addSubview(textField)
        cellView.textField = textField

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: cellView.leadingAnchor, constant: 2),
            textField.trailingAnchor.constraint(equalTo: cellView.trailingAnchor, constant: -2),
            textField.centerYAnchor.constraint(equalTo: cellView.centerYAnchor)
        ])

        return cellView
    }

    private func isCellEditable(node: ManagePortsNode, isNameColumn: Bool) -> Bool {
        switch node.kind {
        case .group, .draftGroup:
            return isNameColumn
        case .port, .draftPort:
            return true
        }
    }

    private func placeholder(for node: ManagePortsNode, isNameColumn: Bool) -> String? {
        switch node.kind {
        case .draftGroup:
            return isNameColumn ? "Group name" : nil
        case .draftPort:
            return isNameColumn ? "Key (e.g. web)" : "Port"
        case .group, .port:
            return nil
        }
    }
}
