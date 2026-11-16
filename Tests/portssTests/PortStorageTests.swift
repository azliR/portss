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

    @Test func testEmptyStorageReturnsEmptyList() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let groups = try storage.loadGroups()
        #expect(groups.isEmpty)
    }

    @Test func testAddAndRetrieveItem() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9400")

        let groups = try storage.loadGroups()
        #expect(groups.count == 1)
        #expect(groups.first?.name == "App A")
        #expect(groups.first?.items.count == 1)
        #expect(groups.first?.items.first?.key == "web")
        #expect(groups.first?.items.first?.value == "9400")
    }

    @Test func testUpdateExistingItemValue() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9400")
        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9401")

        let groups = try storage.loadGroups()
        #expect(groups.count == 1)
        #expect(groups.first?.items.count == 1)
        #expect(groups.first?.items.first?.value == "9401")
    }

    @Test func testDeleteItemRemovesGroupWhenEmpty() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9400")
        let groups = try storage.loadGroups()
        let groupId = try #require(groups.first?.id)
        let itemId = try #require(groups.first?.items.first?.id)

        try storage.deleteItem(groupId: groupId, itemId: itemId)

        let updatedGroups = try storage.loadGroups()
        #expect(updatedGroups.isEmpty)
    }

    @Test func testDeleteGroupRemovesEntireGroup() throws {
        let (storage, tempDir) = try createTemporaryStorage()
        defer { try? FileManager.default.removeItem(at: tempDir) }

        try storage.addOrUpdateItem(groupName: "App A", key: "web", value: "9400")
        try storage.addOrUpdateItem(groupName: "App B", key: "api", value: "8080")

        let groups = try storage.loadGroups()
        let groupToDelete = try #require(groups.first(where: { $0.name == "App A" }))

        try storage.deleteGroup(groupId: groupToDelete.id)

        let remainingGroups = try storage.loadGroups()
        #expect(remainingGroups.count == 1)
        #expect(remainingGroups.first?.name == "App B")
    }
}
