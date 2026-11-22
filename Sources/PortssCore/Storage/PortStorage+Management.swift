import Foundation

extension PortStorage {
    @discardableResult
    public func createGroup(name: String) throws -> UUID {
        var store = try loadStore()
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        try ensureGroupNameIsUnique(trimmedName, in: store, excludingGroupId: nil)

        let group = try PortGroup(name: trimmedName)
        store.groups.append(group)
        try saveStore(store)
        return group.id
    }

    public func renameGroup(groupId: UUID, newName: String) throws {
        var store = try loadStore()
        let groupIndex = try indexOfGroup(groupId, in: store)
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        try ensureGroupNameIsUnique(trimmedName, in: store, excludingGroupId: groupId)

        let existingGroup = store.groups[groupIndex]
        store.groups[groupIndex] = try PortGroup(id: existingGroup.id, name: trimmedName, items: existingGroup.items)
        try saveStore(store)
    }

    @discardableResult
    public func addItem(groupId: UUID?, key: String, value: String) throws -> UUID {
        var store = try loadStore()
        let item = try PortItem(
            key: key.trimmingCharacters(in: .whitespacesAndNewlines),
            value: value.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        try insert(item, intoGroupId: groupId, store: &store)
        try saveStore(store)
        return item.id
    }

    public func updateItemFields(location: PortItemSourceLocation, newKey: String, newValue: String) throws {
        var store = try loadStore()
        let originalItem = try removeItem(at: location, from: &store)
        let updatedItem = try PortItem(
            id: originalItem.id,
            key: newKey.trimmingCharacters(in: .whitespacesAndNewlines),
            value: newValue.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: originalItem.createdAt,
            updatedAt: Date()
        )

        try insert(updatedItem, intoGroupId: location.groupId, store: &store)
        try saveStore(store)
    }

    public func moveItem(location: PortItemSourceLocation, toGroupId targetGroupId: UUID?) throws {
        guard location.groupId != targetGroupId else {
            return
        }

        var store = try loadStore()
        let item = try removeItem(at: location, from: &store)
        try insert(item, intoGroupId: targetGroupId, store: &store)
        try saveStore(store)
    }

    public func removeItem(location: PortItemSourceLocation) throws {
        var store = try loadStore()
        _ = try removeItem(at: location, from: &store)
        try saveStore(store)
    }

    private func removeItem(at location: PortItemSourceLocation, from store: inout PortStore) throws -> PortItem {
        switch location {
        case .standalone(let itemId):
            guard let itemIndex = store.standaloneItems.firstIndex(where: { $0.id == itemId }) else {
                throw ValidationError.itemNotFound(key: itemId.uuidString)
            }
            return store.standaloneItems.remove(at: itemIndex)

        case .group(let groupId, let itemId):
            let groupIndex = try indexOfGroup(groupId, in: store)
            guard let itemIndex = store.groups[groupIndex].items.firstIndex(where: { $0.id == itemId }) else {
                throw ValidationError.itemNotFound(key: itemId.uuidString)
            }
            return store.groups[groupIndex].items.remove(at: itemIndex)
        }
    }

    private func insert(_ item: PortItem, intoGroupId groupId: UUID?, store: inout PortStore) throws {
        guard let groupId = groupId else {
            try ensureKeyIsUnique(item.key, in: store.standaloneItems)
            store.standaloneItems.append(item)
            return
        }

        let groupIndex = try indexOfGroup(groupId, in: store)
        try ensureKeyIsUnique(item.key, in: store.groups[groupIndex].items)
        store.groups[groupIndex].items.append(item)
    }

    private func indexOfGroup(_ groupId: UUID, in store: PortStore) throws -> Int {
        guard let groupIndex = store.groups.firstIndex(where: { $0.id == groupId }) else {
            throw ValidationError.groupNotFound(groupName: groupId.uuidString)
        }
        return groupIndex
    }

    private func ensureKeyIsUnique(_ key: String, in items: [PortItem]) throws {
        let hasDuplicate = items.contains { $0.key.caseInsensitiveCompare(key) == .orderedSame }
        guard !hasDuplicate else {
            throw ValidationError.duplicateKey(key: key)
        }
    }

    private func ensureGroupNameIsUnique(_ name: String, in store: PortStore, excludingGroupId: UUID?) throws {
        let hasDuplicate = store.groups.contains {
            $0.id != excludingGroupId && $0.name.caseInsensitiveCompare(name) == .orderedSame
        }
        guard !hasDuplicate else {
            throw ValidationError.duplicateGroupName(groupName: name)
        }
    }
}

extension PortItemSourceLocation {
    public var groupId: UUID? {
        switch self {
        case .standalone:
            return nil
        case .group(let groupId, _):
            return groupId
        }
    }

    public var itemId: UUID {
        switch self {
        case .standalone(let itemId):
            return itemId
        case .group(_, let itemId):
            return itemId
        }
    }
}
