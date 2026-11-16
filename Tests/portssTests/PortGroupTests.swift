import Testing
import Foundation
@testable import PortssCore

struct PortGroupTests {
    @Test func testValidGroupCreation() throws {
        let item = try PortItem(key: "web", value: "9400")
        let group = try PortGroup(name: "App A", items: [item])
        #expect(group.name == "App A")
        #expect(group.items.count == 1)
        #expect(group.items.first?.key == "web")
    }

    @Test func testExact24CharacterGroupName() throws {
        let max24Name = String(repeating: "g", count: 24)
        let group = try PortGroup(name: max24Name)
        #expect(group.name.count == 24)
        #expect(group.items.isEmpty)
    }

    @Test func testExceedingGroupNameFails() {
        let invalidName = String(repeating: "g", count: 25)
        #expect(throws: ValidationError.self) {
            _ = try PortGroup(name: invalidName)
        }
    }

    @Test func testEmptyGroupNameFails() {
        #expect(throws: ValidationError.self) {
            _ = try PortGroup(name: "   ")
        }
    }
}
