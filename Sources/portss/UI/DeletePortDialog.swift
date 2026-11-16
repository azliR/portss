import AppKit
import PortssCore

struct DeletableTarget: Sendable {
    let groupId: UUID
    let itemId: UUID?
    let displayTitle: String
}

@MainActor
final class DeletePortDialog {
    func prompt(groups: [PortGroup]) -> DeletableTarget? {
        var targets: [DeletableTarget] = []

        for group in groups {
            for item in group.items {
                targets.append(
                    DeletableTarget(
                        groupId: group.id,
                        itemId: item.id,
                        displayTitle: "[\(group.name)] \(item.key): \(item.value)"
                    )
                )
            }
            targets.append(
                DeletableTarget(
                    groupId: group.id,
                    itemId: nil,
                    displayTitle: "Whole Group: \(group.name)"
                )
            )
        }

        guard !targets.isEmpty else {
            DialogPresenter.shared.showError(title: "Nothing to Delete", message: "There are currently no ports or groups saved.")
            return nil
        }

        let alert = NSAlert()
        alert.messageText = "Delete Port or Group"
        alert.informativeText = "Select an item or group to delete:"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")

        let popupButton = NSPopUpButton(frame: NSRect(x: 0, y: 0, width: 280, height: 26), pullsDown: false)
        for target in targets {
            popupButton.addItem(withTitle: target.displayTitle)
        }

        alert.accessoryView = popupButton

        NSApp.activate(ignoringOtherApps: true)
        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else {
            return nil
        }

        let selectedIndex = popupButton.indexOfSelectedItem
        guard selectedIndex >= 0 && selectedIndex < targets.count else {
            return nil
        }

        return targets[selectedIndex]
    }
}
