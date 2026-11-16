import Testing
import Foundation
@testable import PortssCore

struct PortItemTests {
    @Test func testValidItemCreation() throws {
        let item = try PortItem(key: "web", value: "9400")
        #expect(item.key == "web")
        #expect(item.value == "9400")
    }

    @Test func testExact24CharacterFields() throws {
        let max24Key = String(repeating: "k", count: 24)
        let max24Value = String(repeating: "v", count: 24)
        let item = try PortItem(key: max24Key, value: max24Value)
        #expect(item.key.count == 24)
        #expect(item.value.count == 24)
    }

    @Test func testExceedingKeyLengthFails() {
        let invalidKey = String(repeating: "k", count: 25)
        #expect(throws: ValidationError.self) {
            _ = try PortItem(key: invalidKey, value: "9400")
        }
    }

    @Test func testExceedingValueLengthFails() {
        let invalidValue = String(repeating: "9", count: 25)
        #expect(throws: ValidationError.self) {
            _ = try PortItem(key: "web", value: invalidValue)
        }
    }

    @Test func testEmptyKeyFails() {
        #expect(throws: ValidationError.self) {
            _ = try PortItem(key: "   ", value: "9400")
        }
    }

    @Test func testEmptyValueFails() {
        #expect(throws: ValidationError.self) {
            _ = try PortItem(key: "web", value: "   ")
        }
    }
}
