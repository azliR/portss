import Foundation

public enum StorageError: LocalizedError {
    case directoryResolutionFailed
    case directoryCreationFailed(underlyingError: Error)
    case fileReadFailed(path: String, underlyingError: Error)
    case fileWriteFailed(path: String, underlyingError: Error)
    case encodingFailed(underlyingError: Error)
    case decodingFailed(underlyingError: Error)

    public var errorDescription: String? {
        switch self {
        case .directoryResolutionFailed:
            return "Unable to locate the Application Support directory on macOS."
        case .directoryCreationFailed(let underlyingError):
            return "Failed to create application storage directory: \(underlyingError.localizedDescription)"
        case .fileReadFailed(let path, let underlyingError):
            return "Failed to read storage file at \(path): \(underlyingError.localizedDescription)"
        case .fileWriteFailed(let path, let underlyingError):
            return "Failed to write storage file at \(path): \(underlyingError.localizedDescription)"
        case .encodingFailed(let underlyingError):
            return "Failed to serialize port configuration into JSON: \(underlyingError.localizedDescription)"
        case .decodingFailed(let underlyingError):
            return "Failed to parse port configuration file. Data may be corrupted: \(underlyingError.localizedDescription)"
        }
    }
}
