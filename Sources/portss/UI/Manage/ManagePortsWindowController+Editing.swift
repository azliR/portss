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
              textField.isEditable else {
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

    private func discardDrafts() {
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
        guard commandSelector == #selector(NSResponder.cancelOperation(_:)) else {
            return false
        }

        isCancellingEdit = true
        window?.makeFirstResponder(outlineView)
        return true
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
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

        DispatchQueue.main.async { [weak self] in
            self?.commitEdit(node: node, text: text, isNameColumn: isNameColumn, wasCancelled: wasCancelled)
        }
    }

    private func commitEdit(node: ManagePortsNode, text: String, isNameColumn: Bool, wasCancelled: Bool) {
        switch node.kind {
        case .draftGroup:
            commitDraftGroup(name: text, wasCancelled: wasCancelled)
        case .draftPort(let groupId):
            commitDraftPort(node: node, groupId: groupId, text: text, isNameColumn: isNameColumn, wasCancelled: wasCancelled)
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

    private func commitDraftGroup(name: String, wasCancelled: Bool) {
        guard !wasCancelled, !name.isEmpty else {
            discardDrafts()
            return
        }

        do {
            let groupId = try storage.createGroup(name: name)
            expandedGroupIds.insert(groupId)
            showHint()
            reloadFromStorage(selecting: .group(groupId))
        } catch {
            report(error)
            reopenDraft(column: 0)
        }
    }

    private func commitDraftPort(node: ManagePortsNode, groupId: UUID?, text: String, isNameColumn: Bool, wasCancelled: Bool) {
        guard !wasCancelled else {
            discardDrafts()
            return
        }

        if isNameColumn {
            guard !text.isEmpty else {
                discardDrafts()
                return
            }
            node.draftKey = text
            reopenDraft(column: 1)
            return
        }

        do {
            let itemId = try storage.addItem(groupId: groupId, key: node.draftKey, value: text)
            showHint()
            reloadFromStorage(selecting: .port(itemId))
        } catch {
            report(error)
            reopenDraft(column: error.isKeyError ? 0 : 1)
        }
    }

    private func reopenDraft(column: Int) {
        let allNodes = rootNodes + rootNodes.flatMap(\.children)
        guard let draftNode = allNodes.first(where: \.isDraft) else {
            return
        }

        outlineView.reloadItem(draftNode)
        beginEditing(row: outlineView.row(forItem: draftNode), column: column)
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

private extension Error {
    var isKeyError: Bool {
        guard let validationError = self as? ValidationError else {
            return false
        }

        switch validationError {
        case .duplicateKey:
            return true
        case .emptyField(let field), .exceedsMaxLength(let field, _, _):
            return field == "key"
        case .itemNotFound, .groupNotFound, .duplicateGroupName:
            return false
        }
    }
}
