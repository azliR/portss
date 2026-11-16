import AppKit

struct AddPortInput: Sendable {
    let groupName: String
    let key: String
    let value: String
}

@MainActor
final class AddPortDialog: NSObject, NSTextFieldDelegate {
    private let maximumCharacterCount = 24

    func prompt(prefilledGroupName: String? = nil) -> AddPortInput? {
        let alert = NSAlert()
        alert.messageText = "Add Port"
        alert.informativeText = "Enter group, key, and value (maximum 24 characters each)."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 160))

        let groupLabel = NSTextField(labelWithString: "Group:")
        groupLabel.frame = NSRect(x: 0, y: 136, width: 280, height: 18)
        let groupField = NSTextField(frame: NSRect(x: 0, y: 110, width: 280, height: 24))
        groupField.placeholderString = "e.g. App A"
        groupField.delegate = self
        if let prefilledGroupName = prefilledGroupName {
            groupField.stringValue = prefilledGroupName
        }

        let keyLabel = NSTextField(labelWithString: "Key:")
        keyLabel.frame = NSRect(x: 0, y: 84, width: 280, height: 18)
        let keyField = NSTextField(frame: NSRect(x: 0, y: 58, width: 280, height: 24))
        keyField.placeholderString = "e.g. web"
        keyField.delegate = self

        let valueLabel = NSTextField(labelWithString: "Value (Port):")
        valueLabel.frame = NSRect(x: 0, y: 32, width: 280, height: 18)
        let valueField = NSTextField(frame: NSRect(x: 0, y: 6, width: 280, height: 24))
        valueField.placeholderString = "e.g. 9400"
        valueField.delegate = self

        containerView.addSubview(groupLabel)
        containerView.addSubview(groupField)
        containerView.addSubview(keyLabel)
        containerView.addSubview(keyField)
        containerView.addSubview(valueLabel)
        containerView.addSubview(valueField)

        alert.accessoryView = containerView
        alert.window.initialFirstResponder = groupField.stringValue.isEmpty ? groupField : keyField

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return nil
        }

        let rawGroup = groupField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawKey = keyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawValue = valueField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        return AddPortInput(groupName: rawGroup, key: rawKey, value: rawValue)
    }

    func controlTextDidChange(_ notification: Notification) {
        guard let textField = notification.object as? NSTextField else {
            return
        }
        guard textField.stringValue.count > maximumCharacterCount else {
            return
        }

        textField.stringValue = String(textField.stringValue.prefix(maximumCharacterCount))
    }
}
