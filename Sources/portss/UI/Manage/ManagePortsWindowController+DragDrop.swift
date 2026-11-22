import AppKit
import PortssCore

extension ManagePortsWindowController {
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let node = item as? ManagePortsNode, node.portLocation != nil else {
            return nil
        }

        draggedNode = node
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(node.nameText, forType: Self.portRowPasteboardType)
        return pasteboardItem
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        draggingSession session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        draggedNode = nil
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        validateDrop info: NSDraggingInfo,
        proposedItem item: Any?,
        proposedChildIndex index: Int
    ) -> NSDragOperation {
        guard let draggedNode = draggedNode else {
            return []
        }

        let targetNode = dropTargetGroupNode(for: item)
        guard targetNode?.isDraft != true, targetNode?.groupId != draggedNode.groupId else {
            return []
        }

        outlineView.setDropItem(targetNode, dropChildIndex: NSOutlineViewDropOnItemIndex)
        return .move
    }

    func outlineView(
        _ outlineView: NSOutlineView,
        acceptDrop info: NSDraggingInfo,
        item: Any?,
        childIndex index: Int
    ) -> Bool {
        guard let draggedNode = draggedNode,
              case .port(let draggedItem, _) = draggedNode.kind,
              let location = draggedNode.portLocation else {
            return false
        }

        let targetGroupId = dropTargetGroupNode(for: item)?.groupId
        do {
            try storage.moveItem(location: location, toGroupId: targetGroupId)
            if let targetGroupId = targetGroupId {
                expandedGroupIds.insert(targetGroupId)
            }
            showHint()
            reloadFromStorage(selecting: .port(draggedItem.id))
            return true
        } catch {
            report(error)
            reloadFromStorage(selecting: .port(draggedItem.id))
            return false
        }
    }

    private func dropTargetGroupNode(for proposedItem: Any?) -> ManagePortsNode? {
        guard let node = proposedItem as? ManagePortsNode else {
            return nil
        }

        if node.isGroup {
            return node
        }

        return outlineView.parent(forItem: node) as? ManagePortsNode
    }
}
