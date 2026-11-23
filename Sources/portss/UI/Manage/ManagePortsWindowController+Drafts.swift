import AppKit
import PortssCore

extension ManagePortsWindowController {
    func handleDraftCommand(
        _ commandSelector: Selector,
        node: ManagePortsNode,
        row: Int,
        isNameColumn: Bool,
        text: String
    ) -> Bool {
        switch commandSelector {
        case #selector(NSResponder.cancelOperation(_:)):
            endEditingSilently()
            discardDrafts()
            return true

        case #selector(NSResponder.insertNewline(_:)), #selector(NSResponder.insertTab(_:)):
            storeDraftText(text, in: node, isNameColumn: isNameColumn)
            advanceDraft(node, row: row, isNameColumn: isNameColumn)
            return true

        case #selector(NSResponder.insertBacktab(_:)):
            storeDraftText(text, in: node, isNameColumn: isNameColumn)
            if case .draftPort = node.kind, !isNameColumn {
                moveDraftEditing(row: row, column: 0)
            }
            return true

        default:
            return false
        }
    }

    func storeDraftText(_ text: String, in node: ManagePortsNode, isNameColumn: Bool) {
        if isNameColumn {
            node.draftKey = text
        } else {
            node.draftValue = text
        }
    }

    func finishDraftAfterFocusLoss(_ node: ManagePortsNode) {
        switch node.kind {
        case .draftGroup:
            guard !node.draftKey.isEmpty else {
                discardDrafts()
                return
            }
            saveDraftGroup(node)
        case .draftPort(let groupId):
            guard !node.draftKey.isEmpty, !node.draftValue.isEmpty else {
                discardDrafts()
                return
            }
            saveDraftPort(node, groupId: groupId)
        case .group, .port:
            return
        }
    }

    private func advanceDraft(_ node: ManagePortsNode, row: Int, isNameColumn: Bool) {
        switch node.kind {
        case .draftGroup:
            saveDraftGroup(node)
        case .draftPort(let groupId):
            guard isNameColumn else {
                saveDraftPort(node, groupId: groupId)
                return
            }
            guard !node.draftKey.isEmpty else {
                report(ValidationError.emptyField(field: "key"))
                return
            }
            moveDraftEditing(row: row, column: 1)
        case .group, .port:
            return
        }
    }

    private func saveDraftGroup(_ node: ManagePortsNode) {
        do {
            let groupId = try storage.createGroup(name: node.draftKey)
            expandedGroupIds.insert(groupId)
            endEditingSilently()
            showHint()
            reloadFromStorage(selecting: .group(groupId))
        } catch {
            report(error)
        }
    }

    private func saveDraftPort(_ node: ManagePortsNode, groupId: UUID?) {
        do {
            let itemId = try storage.addItem(groupId: groupId, key: node.draftKey, value: node.draftValue)
            endEditingSilently()
            showHint()
            reloadFromStorage(selecting: .port(itemId))
        } catch {
            report(error)
            focusDraftField(for: error, node: node)
        }
    }

    private func focusDraftField(for error: Error, node: ManagePortsNode) {
        let row = outlineView.row(forItem: node)
        guard row >= 0 else {
            return
        }

        let column = error.isKeyValidationError ? 0 : 1
        moveDraftEditing(row: row, column: column)
    }

    private func moveDraftEditing(row: Int, column: Int) {
        endEditingSilently()
        beginEditing(row: row, column: column)
    }

    private func endEditingSilently() {
        isHandlingDraftNavigation = true
        window?.makeFirstResponder(outlineView)
        isHandlingDraftNavigation = false
    }
}

private extension Error {
    var isKeyValidationError: Bool {
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
