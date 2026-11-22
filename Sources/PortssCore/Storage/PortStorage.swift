import Foundation

public enum PortItemSourceLocation: Sendable, Equatable {
    case standalone(itemId: UUID)
    case group(groupId: UUID, itemId: UUID)
}

public final class PortStorage {
    private let directoryURL: URL
    private let fileURL: URL

    public init(customFileURL: URL? = nil) throws {
        if let customFileURL = customFileURL {
            self.fileURL = customFileURL
            self.directoryURL = customFileURL.deletingLastPathComponent()
        } else {
            let applicationSupportDirectories = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            guard let applicationSupportDirectory = applicationSupportDirectories.first else {
                throw StorageError.directoryResolutionFailed
            }

            self.directoryURL = applicationSupportDirectory.appendingPathComponent("portss", isDirectory: true)
            self.fileURL = self.directoryURL.appendingPathComponent("ports.json")
        }

        try ensureStorageDirectoryExists()
    }

    public var storageFileURL: URL {
        return fileURL
    }

    private func ensureStorageDirectoryExists() throws {
        guard !FileManager.default.fileExists(atPath: directoryURL.path) else {
            return
        }

        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            throw StorageError.directoryCreationFailed(underlyingError: error)
        }
    }

    public func loadStore() throws -> PortStore {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return PortStore()
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw StorageError.fileReadFailed(path: fileURL.path, underlyingError: error)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(PortStore.self, from: data)
        } catch {
            throw StorageError.decodingFailed(underlyingError: error)
        }
    }

    public func saveStore(_ store: PortStore) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data: Data
        do {
            data = try encoder.encode(store)
        } catch {
            throw StorageError.encodingFailed(underlyingError: error)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw StorageError.fileWriteFailed(path: fileURL.path, underlyingError: error)
        }
    }

    public func deleteGroup(groupId: UUID) throws {
        var store = try loadStore()
        guard let groupIndex = store.groups.firstIndex(where: { $0.id == groupId }) else {
            throw ValidationError.groupNotFound(groupName: groupId.uuidString)
        }

        store.groups.remove(at: groupIndex)
        try saveStore(store)
    }
}
