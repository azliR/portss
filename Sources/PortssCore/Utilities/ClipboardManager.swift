import AppKit

@MainActor
public final class ClipboardManager {
    public static let shared = ClipboardManager()

    private init() {}

    public func copyToClipboard(text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}
