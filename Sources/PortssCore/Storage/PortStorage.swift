import Foundation

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

    public func loadGroups() throws -> [PortGroup] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw StorageError.fileReadFailed(path: fileURL.path, underlyingError: error)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode([PortGroup].self, from: data)
        } catch {
            throw StorageError.decodingFailed(underlyingError: error)
        }
    }

    public func saveGroups(_ groups: [PortGroup]) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data: Data
        do {
            data = try encoder.encode(groups)
        } catch {
            throw StorageError.encodingFailed(underlyingError: error)
        }

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw StorageError.fileWriteFailed(path: fileURL.path, underlyingError: error)
        }
    }

    public func addOrUpdateItem(groupName: String, key: String, value: String) throws {
        var groups = try loadGroups()
        let newItem = try PortItem(key: key, value: value)

        if let groupIndex = groups.firstIndex(where: { $0.name.caseInsensitiveCompare(groupName) == .orderedSame }) {
            var group = groups[groupIndex]
            if let existingItemIndex = group.items.firstIndex(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }) {
                group.items[existingItemIndex] = newItem
            } else {
                group.items.append(newItem)
            }
            groups[groupIndex] = group
        } else {
            let newGroup = try PortGroup(name: groupName, items: [newItem])
            groups.append(newGroup)
        }

        try saveGroups(groups)
    }

    public func deleteItem(groupId: UUID, itemId: UUID) throws {
        var groups = try loadGroups()
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else {
            throw ValidationError.groupNotFound(groupName: groupId.uuidString)
        }

        var group = groups[groupIndex]
        guard let itemIndex = group.items.firstIndex(where: { $0.id == itemId }) else {
            throw ValidationError.itemNotFound(key: itemId.uuidString)
        }

        group.items.remove(at: itemIndex)
        if group.items.isEmpty {
            groups.remove(at: groupIndex)
        } else {
            groups[groupIndex] = group
        }

        try saveGroups(groups)
    }

    public func deleteGroup(groupId: UUID) throws {
        var groups = try loadGroups()
        guard let groupIndex = groups.firstIndex(where: { $0.id == groupId }) else {
            throw ValidationError.groupNotFound(groupName: groupId.uuidString)
        }

        groups.remove(at: groupIndex)
        try saveGroups(groups)
    }
}
