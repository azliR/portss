import Foundation

public struct PortItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var key: String
    public var value: String

    public init(id: UUID = UUID(), key: String, value: String) throws {
        guard key.count <= 24 else {
            throw ValidationError.exceedsMaxLength(field: "key", maxLength: 24, actualLength: key.count)
        }
        guard value.count <= 24 else {
            throw ValidationError.exceedsMaxLength(field: "value", maxLength: 24, actualLength: value.count)
        }
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyField(field: "key")
        }
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyField(field: "value")
        }

        self.id = id
        self.key = key
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = (try? container.decode(UUID.self, forKey: .id)) ?? UUID()
        self.key = try container.decode(String.self, forKey: .key)
        self.value = try container.decode(String.self, forKey: .value)

        guard key.count <= 24 else {
            throw ValidationError.exceedsMaxLength(field: "key", maxLength: 24, actualLength: key.count)
        }
        guard value.count <= 24 else {
            throw ValidationError.exceedsMaxLength(field: "value", maxLength: 24, actualLength: value.count)
        }
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyField(field: "key")
        }
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyField(field: "value")
        }
    }
}
