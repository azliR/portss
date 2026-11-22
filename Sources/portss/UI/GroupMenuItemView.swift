import AppKit

@MainActor
final class GroupMenuItemView: NSView {
    private let titleLabel = NSTextField(labelWithString: "")
    private let chevronImageView = NSImageView()
    private var isRenderedHighlighted = false

    override var allowsVibrancy: Bool {
        return true
    }

    init(groupName: String) {
        super.init(frame: NSRect(x: 0, y: 0, width: 220, height: 22))

        self.autoresizingMask = [.width]
        setupViewHierarchy(groupName: groupName)
        setupConstraints()
        applyColors(isHighlighted: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy(groupName: String) {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.stringValue = groupName
        titleLabel.font = NSFont.menuFont(ofSize: 0)
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.drawsBackground = false
        titleLabel.isBezeled = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        addSubview(titleLabel)

        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: NSFont.menuFont(ofSize: 0).pointSize - 2, weight: .semibold)
        chevronImageView.image = NSImage(systemSymbolName: "chevron.right", accessibilityDescription: "Submenu")?
            .withSymbolConfiguration(symbolConfiguration)
        chevronImageView.imageScaling = .scaleNone
        addSubview(chevronImageView)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevronImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            chevronImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            chevronImageView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
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

    private func applyColors(isHighlighted: Bool) {
        isRenderedHighlighted = isHighlighted
        titleLabel.textColor = isHighlighted ? NSColor.selectedMenuItemTextColor : NSColor.controlTextColor
        chevronImageView.contentTintColor = isHighlighted
            ? NSColor.selectedMenuItemTextColor
            : NSColor.secondaryLabelColor
    }
}
