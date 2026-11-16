import Foundation

public enum PortSortOption: String, CaseIterable, Codable, Sendable {
    case created
    case updated
    case key
    case value

    public var displayName: String {
        switch self {
        case .created:
            return "Created"
        case .updated:
            return "Updated"
        case .key:
            return "Key (A-Z)"
        case .value:
            return "Value (Port)"
        }
    }
}
