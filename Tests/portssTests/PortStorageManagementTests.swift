import Testing
import Foundation
@testable import PortssCore

struct PortStorageManagementTests {
    private func createTemporaryStorage() throws -> (PortStorage, URL) {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = temporaryDirectory.appendingPathComponent("test_ports.json")
        let storage = try PortStorage(customFileURL: fileURL)
        return (storage, temporaryDirectory)
    }

    @Test func testCreateEmptyGroupPersists() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let groupId = try storage.createGroup(name: "  SSH  ")

        let store = try storage.loadStore()
        #expect(store.groups.count == 1)
        #expect(store.groups.first?.id == groupId)
        #expect(store.groups.first?.name == "SSH")
        #expect(store.groups.first?.items.isEmpty == true)
    }

    @Test func testCreateGroupRejectsDuplicateName() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.createGroup(name: "SSH")

        #expect(throws: ValidationError.duplicateGroupName(groupName: "ssh")) {
            try storage.createGroup(name: "ssh")
        }
    }

    @Test func testRenameGroupKeepsItems() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let groupId = try storage.createGroup(name: "SSH")
        try storage.addItem(groupId: groupId, key: "moots", value: "22")
        try storage.renameGroup(groupId: groupId, newName: "Servers")

        let store = try storage.loadStore()
        #expect(store.groups.first?.name == "Servers")
        #expect(store.groups.first?.items.first?.key == "moots")
    }

    @Test func testAddItemRejectsDuplicateKeyInSameLocation() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addItem(groupId: nil, key: "web", value: "3000")

        #expect(throws: ValidationError.duplicateKey(key: "WEB")) {
            try storage.addItem(groupId: nil, key: "WEB", value: "4000")
        }
    }

    @Test func testUpdateItemFieldsKeepsIdentityAndCreatedAt() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let itemId = try storage.addItem(groupId: nil, key: "web", value: "3000")
        let originalItem = try #require(try storage.loadStore().standaloneItems.first)

        try storage.updateItemFields(location: .standalone(itemId: itemId), newKey: "api", newValue: "4000")

        let updatedItem = try #require(try storage.loadStore().standaloneItems.first)
        #expect(updatedItem.id == itemId)
        #expect(updatedItem.key == "api")
        #expect(updatedItem.value == "4000")
        #expect(updatedItem.createdAt == originalItem.createdAt)
    }

    @Test func testUpdateItemFieldsRejectsCollisionWithSibling() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addItem(groupId: nil, key: "web", value: "3000")
        let apiId = try storage.addItem(groupId: nil, key: "api", value: "4000")

        #expect(throws: ValidationError.duplicateKey(key: "web")) {
            try storage.updateItemFields(location: .standalone(itemId: apiId), newKey: "web", newValue: "4000")
        }
        #expect(try storage.loadStore().standaloneItems.count == 2)
    }

    @Test func testMoveItemBetweenGroupsKeepsEmptySourceGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let sourceGroupId = try storage.createGroup(name: "Source")
        let targetGroupId = try storage.createGroup(name: "Target")
        let itemId = try storage.addItem(groupId: sourceGroupId, key: "web", value: "3000")

        try storage.moveItem(location: .group(groupId: sourceGroupId, itemId: itemId), toGroupId: targetGroupId)

        let store = try storage.loadStore()
        let sourceGroup = try #require(store.groups.first { $0.id == sourceGroupId })
        let targetGroup = try #require(store.groups.first { $0.id == targetGroupId })
        #expect(sourceGroup.items.isEmpty)
        #expect(targetGroup.items.first?.id == itemId)
    }

    @Test func testMoveItemToStandalone() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let groupId = try storage.createGroup(name: "SSH")
        let itemId = try storage.addItem(groupId: groupId, key: "web", value: "3000")

        try storage.moveItem(location: .group(groupId: groupId, itemId: itemId), toGroupId: nil)

        let store = try storage.loadStore()
        #expect(store.standaloneItems.first?.id == itemId)
        #expect(store.groups.first?.items.isEmpty == true)
    }

    @Test func testRemoveItemKeepsEmptyGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let groupId = try storage.createGroup(name: "SSH")
        let itemId = try storage.addItem(groupId: groupId, key: "web", value: "3000")

        try storage.removeItem(location: .group(groupId: groupId, itemId: itemId))

        let store = try storage.loadStore()
        #expect(store.groups.count == 1)
        #expect(store.groups.first?.items.isEmpty == true)
    }
}
