import AppKit

final class ManagePortsOutlineView: NSOutlineView {
    var onDeleteKey: (() -> Void)?
    var onReturnKey: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 51, 117:
            guard let onDeleteKey = onDeleteKey else {
                return super.keyDown(with: event)
            }
            onDeleteKey()
        case 36, 76:
            guard let onReturnKey = onReturnKey else {
                return super.keyDown(with: event)
            }
            onReturnKey()
        default:
            super.keyDown(with: event)
        }
    }
}
