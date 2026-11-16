import AppKit
import PortssCore

struct EditablePortEntry: Sendable {
    let sourceLocation: PortItemSourceLocation
    let currentGroupName: String?
    let currentKey: String
    let currentValue: String
    let displayTitle: String
}

struct EditPortOutput: Sendable {
    let sourceLocation: PortItemSourceLocation
    let newGroupName: String?
    let newKey: String
    let newValue: String
}

@MainActor
final class EditPortDialog: NSObject, NSTextFieldDelegate {
    private let maximumCharacterCount = 24
    private var entries: [EditablePortEntry] = []

    private let popupButton = NSPopUpButton(frame: NSRect(x: 0, y: 166, width: 280, height: 26), pullsDown: false)
    private let groupField = ShortcutTextField(frame: NSRect(x: 0, y: 110, width: 280, height: 24))
    private let keyField = ShortcutTextField(frame: NSRect(x: 0, y: 58, width: 280, height: 24))
    private let valueField = ShortcutTextField(frame: NSRect(x: 0, y: 6, width: 280, height: 24))

    func prompt(store: PortStore) -> EditPortOutput? {
        buildEntries(from: store)

        guard !entries.isEmpty else {
            DialogPresenter.shared.showError(title: "Nothing to Edit", message: "There are currently no ports saved to edit.")
            return nil
        }

        let alert = NSAlert()
        alert.messageText = "Edit Port"
        alert.informativeText = "Select a port to edit, update its details, and click Save."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 216))

        let selectLabel = NSTextField(labelWithString: "Select Port to Edit:")
        selectLabel.frame = NSRect(x: 0, y: 194, width: 280, height: 18)

        popupButton.removeAllItems()
        for entry in entries {
            popupButton.addItem(withTitle: entry.displayTitle)
        }
        popupButton.target = self
        popupButton.action = #selector(handlePopupSelectionChanged)

        let groupLabel = NSTextField(labelWithString: "Group (Optional):")
        groupLabel.frame = NSRect(x: 0, y: 136, width: 280, height: 18)
        groupField.placeholderString = "Optional (e.g. App A)"
        groupField.delegate = self

        let keyLabel = NSTextField(labelWithString: "Key:")
        keyLabel.frame = NSRect(x: 0, y: 84, width: 280, height: 18)
        keyField.placeholderString = "e.g. web"
        keyField.delegate = self

        let valueLabel = NSTextField(labelWithString: "Value (Port):")
        valueLabel.frame = NSRect(x: 0, y: 32, width: 280, height: 18)
        valueField.placeholderString = "e.g. 9400"
        valueField.delegate = self

        containerView.addSubview(selectLabel)
        containerView.addSubview(popupButton)
        containerView.addSubview(groupLabel)
        containerView.addSubview(groupField)
        containerView.addSubview(keyLabel)
        containerView.addSubview(keyField)
        containerView.addSubview(valueLabel)
        containerView.addSubview(valueField)

        alert.accessoryView = containerView
        populateFieldsForIndex(0)
        alert.window.initialFirstResponder = keyField

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return nil
        }

        let selectedIndex = popupButton.indexOfSelectedItem
        guard selectedIndex >= 0 && selectedIndex < entries.count else {
            return nil
        }

        let selectedEntry = entries[selectedIndex]
        let rawGroup = groupField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let newGroupName = rawGroup.isEmpty ? nil : rawGroup
        let newKey = keyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let newValue = valueField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        return EditPortOutput(
            sourceLocation: selectedEntry.sourceLocation,
            newGroupName: newGroupName,
            newKey: newKey,
            newValue: newValue
        )
    }

    private func buildEntries(from store: PortStore) {
        entries = []

        for item in store.standaloneItems {
            entries.append(
                EditablePortEntry(
                    sourceLocation: .standalone(itemId: item.id),
                    currentGroupName: nil,
                    currentKey: item.key,
                    currentValue: item.value,
                    displayTitle: "\(item.key): \(item.value)"
                )
            )
        }

        for group in store.groups {
            for item in group.items {
                entries.append(
                    EditablePortEntry(
                        sourceLocation: .group(groupId: group.id, itemId: item.id),
                        currentGroupName: group.name,
                        currentKey: item.key,
                        currentValue: item.value,
                        displayTitle: "[\(group.name)] \(item.key): \(item.value)"
                    )
                )
            }
        }
    }

    @objc private func handlePopupSelectionChanged() {
        let index = popupButton.indexOfSelectedItem
        populateFieldsForIndex(index)
    }

    private func populateFieldsForIndex(_ index: Int) {
        guard index >= 0 && index < entries.count else {
            return
        }

        let entry = entries[index]
        groupField.stringValue = entry.currentGroupName ?? ""
        keyField.stringValue = entry.currentKey
        valueField.stringValue = entry.currentValue
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
