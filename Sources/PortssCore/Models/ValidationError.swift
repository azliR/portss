import Foundation

public enum ValidationError: LocalizedError, Equatable {
    case exceedsMaxLength(field: String, maxLength: Int, actualLength: Int)
    case emptyField(field: String)
    case groupNotFound(groupName: String)
    case itemNotFound(key: String)
    case duplicateKey(key: String)
    case duplicateGroupName(groupName: String)

    public var errorDescription: String? {
        switch self {
        case .duplicateKey(let key):
            return "A port with key '\(key)' already exists in this location."
        case .duplicateGroupName(let groupName):
            return "A group named '\(groupName)' already exists."
        case .exceedsMaxLength(let field, let maxLength, let actualLength):
            return "Field '\(field)' exceeds maximum length of \(maxLength) characters (current: \(actualLength))."
        case .emptyField(let field):
            return "Field '\(field)' cannot be empty."
        case .groupNotFound(let groupName):
            return "Group '\(groupName)' was not found."
        case .itemNotFound(let key):
            return "Item with key '\(key)' was not found."
        }
    }
}
