import AppKit
import PortssCore

@MainActor
final class PortMenuItemView: NSView {
    private let portItem: PortItem
    private let onCopy: () -> Void

    private let highlightContainerView = NSView()
    private let keyLabel = NSTextField(labelWithString: "")
    private let valueLabel = NSTextField(labelWithString: "")
    private var trackingAreaRef: NSTrackingArea?

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy() {
        wantsLayer = true

        highlightContainerView.translatesAutoresizingMaskIntoConstraints = false
        highlightContainerView.wantsLayer = true
        highlightContainerView.layer?.cornerRadius = 4.0
        highlightContainerView.layer?.backgroundColor = NSColor.clear.cgColor
        addSubview(highlightContainerView)

        let standardMenuFont = NSFont.menuFont(ofSize: 0)

        keyLabel.translatesAutoresizingMaskIntoConstraints = false
        keyLabel.stringValue = portItem.key
        keyLabel.font = standardMenuFont
        keyLabel.textColor = NSColor.controlTextColor
        keyLabel.lineBreakMode = .byTruncatingTail
        keyLabel.drawsBackground = false
        keyLabel.isBezeled = false
        keyLabel.isEditable = false
        keyLabel.isSelectable = false
        addSubview(keyLabel)

        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.stringValue = portItem.value
        valueLabel.font = NSFont.monospacedDigitSystemFont(ofSize: standardMenuFont.pointSize, weight: .regular)
        valueLabel.textColor = NSColor.secondaryLabelColor
        valueLabel.alignment = .right
        valueLabel.drawsBackground = false
        valueLabel.isBezeled = false
        valueLabel.isEditable = false
        valueLabel.isSelectable = false
        addSubview(valueLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            highlightContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            highlightContainerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),
            highlightContainerView.topAnchor.constraint(equalTo: topAnchor, constant: 1),
            highlightContainerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -1),

            keyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            keyLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: keyLabel.trailingAnchor, constant: 16)
        ])
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let existing = trackingAreaRef {
            removeTrackingArea(existing)
        }

        let options: NSTrackingArea.Options = [.mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let newTrackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(newTrackingArea)
        self.trackingAreaRef = newTrackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        setHoverState(isHovered: true)
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        setHoverState(isHovered: false)
    }

    override func mouseUp(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        guard bounds.contains(location) else {
            return
        }

        onCopy()
        enclosingMenuItem?.menu?.cancelTracking()
    }

    private func setHoverState(isHovered: Bool) {
        if isHovered {
            highlightContainerView.layer?.backgroundColor = NSColor.selectedContentBackgroundColor.cgColor
            keyLabel.textColor = NSColor.selectedMenuItemTextColor
            valueLabel.textColor = NSColor.selectedMenuItemTextColor.withAlphaComponent(0.85)
        } else {
            highlightContainerView.layer?.backgroundColor = NSColor.clear.cgColor
            keyLabel.textColor = NSColor.controlTextColor
            valueLabel.textColor = NSColor.secondaryLabelColor
        }
    }
}
