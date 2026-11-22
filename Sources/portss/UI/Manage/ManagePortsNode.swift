import Foundation
import PortssCore

@MainActor
final class ManagePortsNode {
    enum Kind {
        case group(PortGroup)
        case port(PortItem, groupId: UUID?)
        case draftGroup
        case draftPort(groupId: UUID?)
    }

    let kind: Kind
    var children: [ManagePortsNode]
    var draftKey = ""

    init(kind: Kind, children: [ManagePortsNode] = []) {
        self.kind = kind
        self.children = children
    }

    var isGroup: Bool {
        switch kind {
        case .group, .draftGroup:
            return true
        case .port, .draftPort:
            return false
        }
    }

    var isDraft: Bool {
        switch kind {
        case .draftGroup, .draftPort:
            return true
        case .group, .port:
            return false
        }
    }

    var groupId: UUID? {
        switch kind {
        case .group(let group):
            return group.id
        case .port(_, let groupId), .draftPort(let groupId):
            return groupId
        case .draftGroup:
            return nil
        }
    }

    var portLocation: PortItemSourceLocation? {
        guard case .port(let item, let groupId) = kind else {
            return nil
        }
        guard let groupId = groupId else {
            return .standalone(itemId: item.id)
        }
        return .group(groupId: groupId, itemId: item.id)
    }

    var nameText: String {
        switch kind {
        case .group(let group):
            return group.name
        case .port(let item, _):
            return item.key
        case .draftGroup, .draftPort:
            return draftKey
        }
    }

    var valueText: String {
        switch kind {
        case .group(let group):
            return group.items.count == 1 ? "1 port" : "\(group.items.count) ports"
        case .port(let item, _):
            return item.value
        case .draftGroup, .draftPort:
            return ""
        }
    }

    static func buildTree(from store: PortStore) -> [ManagePortsNode] {
        let standaloneNodes = sortedByKey(store.standaloneItems).map {
            ManagePortsNode(kind: .port($0, groupId: nil))
        }

        let groupNodes = store.groups
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { group in
                ManagePortsNode(
                    kind: .group(group),
                    children: sortedByKey(group.items).map { ManagePortsNode(kind: .port($0, groupId: group.id)) }
                )
            }

        return standaloneNodes + groupNodes
    }

    private static func sortedByKey(_ items: [PortItem]) -> [PortItem] {
        return items.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }
    }
}
