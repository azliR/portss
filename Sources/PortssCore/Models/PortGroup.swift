import Foundation

public struct PortGroup: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var items: [PortItem]

    public init(id: UUID = UUID(), name: String, items: [PortItem] = []) throws {
        guard name.count <= 24 else {
            throw ValidationError.exceedsMaxLength(field: "group name", maxLength: 24, actualLength: name.count)
        }
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyField(field: "group name")
        }

        self.id = id
        self.name = name
        self.items = items
    }
}
