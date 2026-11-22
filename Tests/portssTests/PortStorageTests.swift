import Testing
import Foundation
@testable import PortssCore

struct PortStorageTests {
    private func createTemporaryStorage() throws -> (PortStorage, URL) {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let fileURL = temporaryDirectory.appendingPathComponent("test_ports.json")
        let storage = try PortStorage(customFileURL: fileURL)
        return (storage, temporaryDirectory)
    }

    @Test func testEmptyStorageReturnsEmptyStore() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let store = try storage.loadStore()
        #expect(store.isEmpty)
        #expect(store.standaloneItems.isEmpty)
        #expect(store.groups.isEmpty)
    }

    @Test func testAddStandaloneItem() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addItem(groupId: nil, key: " web ", value: "3000")

        let store = try storage.loadStore()
        #expect(store.standaloneItems.count == 1)
        #expect(store.standaloneItems.first?.key == "web")
        #expect(store.standaloneItems.first?.value == "3000")
        #expect(store.groups.isEmpty)
    }

    @Test func testAddGroupedItem() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let groupId = try storage.createGroup(name: "App A")
        try storage.addItem(groupId: groupId, key: "web", value: "9400")

        let store = try storage.loadStore()
        #expect(store.standaloneItems.isEmpty)
        #expect(store.groups.count == 1)
        #expect(store.groups.first?.name == "App A")
        #expect(store.groups.first?.items.first?.key == "web")
        #expect(store.groups.first?.items.first?.value == "9400")
    }

    @Test func testAddItemToMissingGroupFails() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let missingGroupId = UUID()
        #expect(throws: ValidationError.groupNotFound(groupName: missingGroupId.uuidString)) {
            try storage.addItem(groupId: missingGroupId, key: "web", value: "9400")
        }
    }

    @Test func testRemoveStandaloneItem() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let itemId = try storage.addItem(groupId: nil, key: "web", value: "3000")
        try storage.removeItem(location: .standalone(itemId: itemId))

        #expect(try storage.loadStore().standaloneItems.isEmpty)
    }

    @Test func testDeleteGroupRemovesEntireGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let groupToDeleteId = try storage.createGroup(name: "App A")
        try storage.addItem(groupId: groupToDeleteId, key: "web", value: "9400")
        let remainingGroupId = try storage.createGroup(name: "App B")
        try storage.addItem(groupId: remainingGroupId, key: "api", value: "8080")

        try storage.deleteGroup(groupId: groupToDeleteId)

        let remainingStore = try storage.loadStore()
        #expect(remainingStore.groups.count == 1)
        #expect(remainingStore.groups.first?.id == remainingGroupId)
    }
}
