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

    @Test func testAddStandaloneItemWithNilGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: nil, key: "web", value: "3000")

        let store = try storage.loadStore()
        #expect(store.standaloneItems.count == 1)
        #expect(store.standaloneItems.first?.key == "web")
        #expect(store.standaloneItems.first?.value == "3000")
        #expect(store.groups.isEmpty)
    }

    @Test func testAddStandaloneItemWithEmptyGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "   ", key: "api", value: "8000")

        let store = try storage.loadStore()
        #expect(store.standaloneItems.count == 1)
        #expect(store.standaloneItems.first?.key == "api")
        #expect(store.groups.isEmpty)
    }

    @Test func testAddGroupedItem() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9400")

        let store = try storage.loadStore()
        #expect(store.standaloneItems.isEmpty)
        #expect(store.groups.count == 1)
        #expect(store.groups.first?.name == "App A")
        #expect(store.groups.first?.items.count == 1)
        #expect(store.groups.first?.items.first?.key == "web")
        #expect(store.groups.first?.items.first?.value == "9400")
    }

    @Test func testUpdateExistingStandaloneItem() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: nil, key: "web", value: "3000")
        try storage.addOrUpdateItem(groupName: nil, key: "web", value: "3001")

        let store = try storage.loadStore()
        #expect(store.standaloneItems.count == 1)
        #expect(store.standaloneItems.first?.value == "3001")
    }

    @Test func testUpdateItemRenamingAndMovingToGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: nil, key: "web", value: "3000")
        let initialStore = try storage.loadStore()
        let itemId = try #require(initialStore.standaloneItems.first?.id)

        try storage.updateItem(
            sourceLocation: .standalone(itemId: itemId),
            newGroupName: "Backend",
            newKey: "api-server",
            newValue: "8080"
        )

        let updatedStore = try storage.loadStore()
        #expect(updatedStore.standaloneItems.isEmpty)
        #expect(updatedStore.groups.count == 1)
        #expect(updatedStore.groups.first?.name == "Backend")
        #expect(updatedStore.groups.first?.items.count == 1)
        #expect(updatedStore.groups.first?.items.first?.key == "api-server")
        #expect(updatedStore.groups.first?.items.first?.value == "8080")
    }

    @Test func testUpdateGroupedItemToStandalone() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "Frontend", key: "ui", value: "3000")
        let initialStore = try storage.loadStore()
        let groupId = try #require(initialStore.groups.first?.id)
        let itemId = try #require(initialStore.groups.first?.items.first?.id)

        try storage.updateItem(
            sourceLocation: .group(groupId: groupId, itemId: itemId),
            newGroupName: nil,
            newKey: "standalone-ui",
            newValue: "3005"
        )

        let updatedStore = try storage.loadStore()
        #expect(updatedStore.groups.isEmpty)
        #expect(updatedStore.standaloneItems.count == 1)
        #expect(updatedStore.standaloneItems.first?.key == "standalone-ui")
        #expect(updatedStore.standaloneItems.first?.value == "3005")
    }

    @Test func testDeleteStandaloneItem() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: nil, key: "web", value: "3000")
        let store = try storage.loadStore()
        let itemId = try #require(store.standaloneItems.first?.id)

        try storage.deleteStandaloneItem(itemId: itemId)

        let updatedStore = try storage.loadStore()
        #expect(updatedStore.standaloneItems.isEmpty)
    }

    @Test func testDeleteGroupItemRemovesGroupWhenEmpty() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9400")
        let store = try storage.loadStore()
        let groupId = try #require(store.groups.first?.id)
        let itemId = try #require(store.groups.first?.items.first?.id)

        try storage.deleteGroupItem(groupId: groupId, itemId: itemId)

        let updatedStore = try storage.loadStore()
        #expect(updatedStore.groups.isEmpty)
    }

    @Test func testDeleteGroupRemovesEntireGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9400")
        try storage.addOrUpdateItem(groupName: "App B", key: "api", value: "8080")

        let store = try storage.loadStore()
        let groupToDelete = try #require(store.groups.first(where: { $0.name == "App A" }))

        try storage.deleteGroup(groupId: groupToDelete.id)

        let remainingStore = try storage.loadStore()
        #expect(remainingStore.groups.count == 1)
        #expect(remainingStore.groups.first?.name == "App B")
    }
}
