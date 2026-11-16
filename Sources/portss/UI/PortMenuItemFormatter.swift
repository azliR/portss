import AppKit
import PortssCore

@MainActor
final class PortMenuItemFormatter {
    private let keyFont = NSFont.systemFont(ofSize: 13, weight: .medium)
    private let valueFont = NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .regular)
    private let minimumColumnSpacing: CGFloat = 36.0
    private let minimumTabLocation: CGFloat = 200.0

    func calculateTabLocation(for items: [PortItem]) -> CGFloat {
        guard !items.isEmpty else {
            return minimumTabLocation
        }

        var maximumKeyWidth: CGFloat = 0.0
        var maximumValueWidth: CGFloat = 0.0

        for item in items {
            let keySize = (item.key as NSString).size(withAttributes: [.font: keyFont])
            let valueSize = (item.value as NSString).size(withAttributes: [.font: valueFont])

            if keySize.width > maximumKeyWidth {
                maximumKeyWidth = keySize.width
            }
            if valueSize.width > maximumValueWidth {
                maximumValueWidth = valueSize.width
            }
        }

        let calculatedWidth = maximumKeyWidth + minimumColumnSpacing + maximumValueWidth
        return max(minimumTabLocation, calculatedWidth)
    }

    func format(item: PortItem, tabLocation: CGFloat) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.tabStops = [
            NSTextTab(textAlignment: .right, location: tabLocation, options: [:])
        ]

        let attributedTitle = NSMutableAttributedString()

        let keyAttributes: [NSAttributedString.Key: Any] = [
            .font: keyFont,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]
        let keyAttributedString = NSAttributedString(string: item.key, attributes: keyAttributes)
        attributedTitle.append(keyAttributedString)

        let tabAttributedString = NSAttributedString(string: "\t", attributes: [.paragraphStyle: paragraphStyle])
        attributedTitle.append(tabAttributedString)

        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: NSColor.secondaryLabelColor,
            .paragraphStyle: paragraphStyle
        ]
        let valueAttributedString = NSAttributedString(string: item.value, attributes: valueAttributes)
        attributedTitle.append(valueAttributedString)

        return attributedTitle
    }
}
