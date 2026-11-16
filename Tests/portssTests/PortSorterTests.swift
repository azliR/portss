import Testing
import Foundation
@testable import PortssCore

struct PortSorterTests {
    @Test func testSortByKey() throws {
        let itemA = try PortItem(key: "alpha", value: "3000")
        let itemB = try PortItem(key: "beta", value: "2000")
        let itemC = try PortItem(key: "charlie", value: "1000")

        let unsorted = [itemC, itemA, itemB]
        let sorted = PortSorter.sort(items: unsorted, by: .key)

        #expect(sorted.map(\.key) == ["alpha", "beta", "charlie"])
    }

    @Test func testSortByValueNumeric() throws {
        let itemLow = try PortItem(key: "http", value: "80")
        let itemMid = try PortItem(key: "dev", value: "3000")
        let itemHigh = try PortItem(key: "api", value: "9400")

        let unsorted = [itemHigh, itemLow, itemMid]
        let sorted = PortSorter.sort(items: unsorted, by: .value)

        #expect(sorted.map(\.value) == ["80", "3000", "9400"])
    }

    @Test func testSortByCreated() throws {
        let now = Date()
        let olderDate = now.addingTimeInterval(-100)
        let middleDate = now.addingTimeInterval(-50)
        let newestDate = now

        let itemOld = try PortItem(key: "old", value: "1", createdAt: olderDate)
        let itemMid = try PortItem(key: "mid", value: "2", createdAt: middleDate)
        let itemNew = try PortItem(key: "new", value: "3", createdAt: newestDate)

        let unsorted = [itemOld, itemNew, itemMid]
        let sorted = PortSorter.sort(items: unsorted, by: .created)

        #expect(sorted.map(\.key) == ["new", "mid", "old"])
    }

    @Test func testSortByUpdated() throws {
        let now = Date()
        let olderDate = now.addingTimeInterval(-100)
        let newestDate = now

        let item1 = try PortItem(key: "item1", value: "1", updatedAt: olderDate)
        let item2 = try PortItem(key: "item2", value: "2", updatedAt: newestDate)

        let unsorted = [item1, item2]
        let sorted = PortSorter.sort(items: unsorted, by: .updated)

        #expect(sorted.map(\.key) == ["item2", "item1"])
    }
}
