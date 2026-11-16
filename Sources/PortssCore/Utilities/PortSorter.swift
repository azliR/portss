import Foundation

public final class PortSorter {
    public static func sort(items: [PortItem], by option: PortSortOption) -> [PortItem] {
        switch option {
        case .created:
            return items.sorted { $0.createdAt > $1.createdAt }

        case .updated:
            return items.sorted { $0.updatedAt > $1.updatedAt }

        case .key:
            return items.sorted { $0.key.localizedStandardCompare($1.key) == .orderedAscending }

        case .value:
            return items.sorted { firstItem, secondItem in
                if let firstNumber = Int(firstItem.value), let secondNumber = Int(secondItem.value) {
                    if firstNumber != secondNumber {
                        return firstNumber < secondNumber
                    }
                }
                return firstItem.value.localizedStandardCompare(secondItem.value) == .orderedAscending
            }
        }
    }
}
