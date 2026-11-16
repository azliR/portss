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

    public func addOrUpdateItem(groupName: String?, key: String, value: String) throws {
        var store = try loadStore()
        let newItem = try PortItem(key: key, value: value)
        let trimmedGroupName = groupName?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let validGroupName = trimmedGroupName, !validGroupName.isEmpty {
            if let groupIndex = store.groups.firstIndex(where: { $0.name.caseInsensitiveCompare(validGroupName) == .orderedSame }) {
                var group = store.groups[groupIndex]
                if let existingItemIndex = group.items.firstIndex(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }) {
                    group.items[existingItemIndex] = newItem
                } else {
                    group.items.append(newItem)
                }
                store.groups[groupIndex] = group
            } else {
                let newGroup = try PortGroup(name: validGroupName, items: [newItem])
                store.groups.append(newGroup)
            }
        } else {
            if let existingIndex = store.standaloneItems.firstIndex(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }) {
                store.standaloneItems[existingIndex] = newItem
            } else {
                store.standaloneItems.append(newItem)
            }
        }

        try saveStore(store)
    }

    public func updateItem(sourceLocation: PortItemSourceLocation, newGroupName: String?, newKey: String, newValue: String) throws {
        var store = try loadStore()
        let updatedItem = try PortItem(key: newKey, value: newValue)

        switch sourceLocation {
        case .standalone(let itemId):
            guard let itemIndex = store.standaloneItems.firstIndex(where: { $0.id == itemId }) else {
                throw ValidationError.itemNotFound(key: itemId.uuidString)
            }
            store.standaloneItems.remove(at: itemIndex)

        case .group(let groupId, let itemId):
            guard let groupIndex = store.groups.firstIndex(where: { $0.id == groupId }) else {
                throw ValidationError.groupNotFound(groupName: groupId.uuidString)
            }
            var group = store.groups[groupIndex]
            guard let itemIndex = group.items.firstIndex(where: { $0.id == itemId }) else {
                throw ValidationError.itemNotFound(key: itemId.uuidString)
            }
            group.items.remove(at: itemIndex)
            if group.items.isEmpty {
                store.groups.remove(at: groupIndex)
            } else {
                store.groups[groupIndex] = group
            }
        }

        let trimmedGroupName = newGroupName?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let validGroupName = trimmedGroupName, !validGroupName.isEmpty {
            if let groupIndex = store.groups.firstIndex(where: { $0.name.caseInsensitiveCompare(validGroupName) == .orderedSame }) {
                var group = store.groups[groupIndex]
                if let existingItemIndex = group.items.firstIndex(where: { $0.key.caseInsensitiveCompare(newKey) == .orderedSame }) {
                    group.items[existingItemIndex] = updatedItem
                } else {
                    group.items.append(updatedItem)
                }
                store.groups[groupIndex] = group
            } else {
                let newGroup = try PortGroup(name: validGroupName, items: [updatedItem])
                store.groups.append(newGroup)
            }
        } else {
            if let existingIndex = store.standaloneItems.firstIndex(where: { $0.key.caseInsensitiveCompare(newKey) == .orderedSame }) {
                store.standaloneItems[existingIndex] = updatedItem
            } else {
                store.standaloneItems.append(updatedItem)
            }
        }

        try saveStore(store)
    }

    public func deleteStandaloneItem(itemId: UUID) throws {
        var store = try loadStore()
        guard let itemIndex = store.standaloneItems.firstIndex(where: { $0.id == itemId }) else {
            throw ValidationError.itemNotFound(key: itemId.uuidString)
        }

        store.standaloneItems.remove(at: itemIndex)
        try saveStore(store)
    }

    public func deleteGroupItem(groupId: UUID, itemId: UUID) throws {
        var store = try loadStore()
        guard let groupIndex = store.groups.firstIndex(where: { $0.id == groupId }) else {
            throw ValidationError.groupNotFound(groupName: groupId.uuidString)
        }

        var group = store.groups[groupIndex]
        guard let itemIndex = group.items.firstIndex(where: { $0.id == itemId }) else {
            throw ValidationError.itemNotFound(key: itemId.uuidString)
        }

        group.items.remove(at: itemIndex)
        if group.items.isEmpty {
            store.groups.remove(at: groupIndex)
        } else {
            store.groups[groupIndex] = group
        }

        try saveStore(store)
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
