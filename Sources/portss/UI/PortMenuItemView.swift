import AppKit
import PortssCore

@MainActor
final class PortMenuItemView: NSView {
    private let portItem: PortItem
    private let onCopy: () -> Void

    private let keyLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private var isRenderedHighlighted = false

    override var allowsVibrancy: Bool {
        return true
    }

    init(portItem: PortItem, onCopy: @escaping () -> Void) {
        self.portItem = portItem
        self.onCopy = onCopy
        super.init(frame: NSRect(x: 0, y: 0, width: 220, height: 22))

        self.autoresizingMask = [.width]
        setupViewHierarchy()
        setupConstraints()
        applyColors(isHighlighted: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy() {
        let standardMenuFont = NSFont.menuFont(ofSize: 0)

        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.stringValue = portItem.key
        keyLabel.font = standardMenuFont
        keyLabel.lineBreakMode = .byTruncatingTail
        keyLabel.drawsBackground = false
        keyLabel.isBezeled = false
        keyLabel.isEditable = false
        keyLabel.isSelectable = false
        addSubview(keyLabel)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.stringValue = portItem.value
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: standardMenuFont.pointSize, weight: .regular)
        valueLabel.alignment = .right
        valueLabel.drawsBackground = false
        valueLabel.isBezeled = false
        valueLabel.isEditable = false
        valueLabel.isSelectable = false
        addSubview(valueLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            keyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: keyLabel.trailingAnchor, constant: 16)
        ])
    }

    override func draw(_ dirtyRect: NSRect) {
        let isHighlighted = enclosingMenuItem?.isHighlighted ?? false
        if isHighlighted != isRenderedHighlighted {
            applyColors(isHighlighted: isHighlighted)
        }

        guard isHighlighted else {
            return
        }

        let highlightRect = bounds.insetBy(dx: 4, dy: 1)
        NSColor.selectedContentBackgroundColor.setFill()
        NSBezierPath(roundedRect: highlightRect, xRadius: 4, yRadius: 4).fill()
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard bounds.contains(location) else {
            return
        }

        onCopy()
        enclosingMenuItem?.menu?.cancelTracking()
    }

    private func applyColors(isHighlighted: Bool) {
        isRenderedHighlighted = isHighlighted
        keyLabel.textColor = isHighlighted ? NSColor.selectedMenuItemTextColor : NSColor.controlTextColor
        valueLabel.textColor = isHighlighted
            ? NSColor.selectedMenuItemTextColor.withAlphaComponent(0.85)
            : NSColor.secondaryLabelColor
    }
}
