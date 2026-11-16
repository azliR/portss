import Foundation

public struct PortStore: Codable, Equatable, Sendable {
    public var standaloneItems: [PortItem]
    public var groups: [PortGroup]

    public init(standaloneItems: [PortItem] = [], groups: [PortGroup] = []) {
        self.standaloneItems = standaloneItems
        self.groups = groups
    }

    public var isEmpty: Bool {
        return standaloneItems.isEmpty && groups.isEmpty
    }

    public init(from decoder: Decoder) throws {
        if let container = try? decoder.container(keyedBy: CodingKeys.self) {
            self.standaloneItems = (try? container.decode([PortItem].self, forKey: .standaloneItems)) ?? []
            self.groups = (try? container.decode([PortGroup].self, forKey: .groups)) ?? []
            return
        }

        let singleContainer = try decoder.singleValueContainer()
        if let decodedGroups = try? singleContainer.decode([PortGroup].self) {
            self.standaloneItems = []
            self.groups = decodedGroups
            return
        }

        self.standaloneItems = []
        self.groups = []
    }
}
