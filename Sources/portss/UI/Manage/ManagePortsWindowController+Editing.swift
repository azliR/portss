import AppKit
import PortssCore

extension ManagePortsWindowController: NSTextFieldDelegate {
    func beginEditingSelectedRow() {
        let row = outlineView.selectedRow
        guard row >= 0 else {
            return
        }
        beginEditing(row: row, column: 0)
    }

    func beginEditing(row: Int, column: Int) {
        guard let cellView = outlineView.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView,
              let textField = cellView.textField,
              textField.isEditable,
              textField.currentEditor() == nil else {
            return
        }

        outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        outlineView.editColumn(column, row: row, with: nil, select: true)
    }

    func insertDraftPort() {
        discardDrafts()

        let targetGroupId = selectedNode?.groupId
        let draftNode = ManagePortsNode(kind: .draftPort(groupId: targetGroupId))

        if let groupNode = rootNodes.first(where: { $0.isGroup && $0.groupId == targetGroupId && targetGroupId != nil }),
           let groupId = targetGroupId {
            groupNode.children.append(draftNode)
            expandedGroupIds.insert(groupId)
        } else {
            let firstGroupIndex = rootNodes.firstIndex(where: \.isGroup) ?? rootNodes.count
            rootNodes.insert(draftNode, at: firstGroupIndex)
        }

        reloadOutlinePreservingExpansion()
        beginEditing(row: outlineView.row(forItem: draftNode), column: 0)
    }

    func insertDraftGroup() {
        discardDrafts()

        let draftNode = ManagePortsNode(kind: .draftGroup)
        rootNodes.append(draftNode)
        reloadOutlinePreservingExpansion()
        beginEditing(row: outlineView.row(forItem: draftNode), column: 0)
    }

    func removeSelectedNode() {
        guard let node = selectedNode else {
            NSSound.beep()
            return
        }

        if node.isDraft {
            discardDrafts()
            return
        }

        do {
            switch node.kind {
            case .port:
                guard let location = node.portLocation else {
                    return
                }
                try storage.removeItem(location: location)
            case .group(let group):
                guard confirmGroupRemoval(group) else {
                    return
                }
                try storage.deleteGroup(groupId: group.id)
            case .draftGroup, .draftPort:
                return
            }
            showHint()
            reloadFromStorage(selecting: nil)
        } catch {
            report(error)
            reloadFromStorage(selecting: nil)
        }
    }

    private func confirmGroupRemoval(_ group: PortGroup) -> Bool {
        guard !group.items.isEmpty else {
            return true
        }

        return DialogPresenter.shared.showConfirmation(
            title: "Remove Group",
            message: "Remove '\(group.name)' and its \(group.items.count) port(s)?",
            confirmButtonTitle: "Remove"
        )
    }

    func discardDrafts() {
        let hasDraft = rootNodes.contains { $0.isDraft || $0.children.contains(where: \.isDraft) }
        guard hasDraft else {
            return
        }

        rootNodes.removeAll(where: \.isDraft)
        for node in rootNodes {
            node.children.removeAll(where: \.isDraft)
        }
        reloadOutlinePreservingExpansion()
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let fieldEditor = notification.userInfo?["NSFieldEditor"] as? NSText,
              fieldEditor.string.count > Self.maximumCharacterCount else {
            return
        }

        NSSound.beep()
        fieldEditor.string = String(fieldEditor.string.prefix(Self.maximumCharacterCount))
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        let row = outlineView.row(for: control)
        let column = outlineView.column(for: control)
        guard row >= 0, column >= 0, let node = outlineView.item(atRow: row) as? ManagePortsNode else {
            return false
        }

        let text = textView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        let isNameColumn = outlineView.tableColumns[column].identifier == ColumnIdentifier.name

        if node.isDraft {
            return handleDraftCommand(commandSelector, node: node, row: row, isNameColumn: isNameColumn, text: text)
        }

        switch commandSelector {
        case #selector(NSResponder.cancelOperation(_:)):
            isCancellingEdit = true
            window?.makeFirstResponder(outlineView)
            return true
        case #selector(NSResponder.insertTab(_:)), #selector(NSResponder.insertBacktab(_:)):
            window?.makeFirstResponder(outlineView)
            return true
        default:
            return false
        }
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard !isHandlingDraftNavigation, let textField = notification.object as? NSTextField else {
            return
        }

        let row = outlineView.row(for: textField)
        let column = outlineView.column(for: textField)
        let wasCancelled = isCancellingEdit
        isCancellingEdit = false

        guard row >= 0, column >= 0, let node = outlineView.item(atRow: row) as? ManagePortsNode else {
            return
        }

        let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let isNameColumn = outlineView.tableColumns[column].identifier == ColumnIdentifier.name

        if node.isDraft {
            storeDraftText(text, in: node, isNameColumn: isNameColumn)
            DispatchQueue.main.async { [weak self] in
                self?.finishDraftAfterFocusLoss(node)
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.commitEdit(node: node, text: text, isNameColumn: isNameColumn, wasCancelled: wasCancelled)
        }
    }

    private func commitEdit(node: ManagePortsNode, text: String, isNameColumn: Bool, wasCancelled: Bool) {
        switch node.kind {
        case .draftGroup, .draftPort:
            return
        case .group(let group):
            guard !wasCancelled, text != group.name else {
                reloadOutlinePreservingExpansion()
                return
            }
            perform(selecting: .group(group.id)) {
                try storage.renameGroup(groupId: group.id, newName: text)
            }
        case .port(let item, _):
            let newKey = isNameColumn ? text : item.key
            let newValue = isNameColumn ? item.value : text
            guard !wasCancelled, newKey != item.key || newValue != item.value, let location = node.portLocation else {
                reloadOutlinePreservingExpansion()
                return
            }
            perform(selecting: .port(item.id)) {
                try storage.updateItemFields(location: location, newKey: newKey, newValue: newValue)
            }
        }
    }

    private func perform(selecting target: SelectionTarget, operation: () throws -> Void) {
        do {
            try operation()
            showHint()
            reloadFromStorage(selecting: target)
        } catch {
            report(error)
            reloadFromStorage(selecting: target)
        }
    }
}
