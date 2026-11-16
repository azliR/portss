import AppKit

final class ShortcutTextField: NSTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown else {
            return super.performKeyEquivalent(with: event)
        }

        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard let characters = event.charactersIgnoringModifiers else {
            return super.performKeyEquivalent(with: event)
        }

        if flags == .command {
            switch characters {
            case "a":
                return NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: self)
            case "c":
                return NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: self)
            case "v":
                return NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: self)
            case "x":
                return NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: self)
            case "z":
                return NSApp.sendAction(Selector(("undo:")), to: nil, from: self)
            default:
                break
            }
        }

        if flags == [.command, .shift] && characters.lowercased() == "z" {
            return NSApp.sendAction(Selector(("redo:")), to: nil, from: self)
        }

        return super.performKeyEquivalent(with: event)
    }
}
