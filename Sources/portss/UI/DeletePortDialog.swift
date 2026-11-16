import AppKit
import PortssCore

enum DeleteActionKind: Sendable {
    case standaloneItem(itemId: UUID)
    case groupItem(groupId: UUID, itemId: UUID)
    case group(groupId: UUID)
}

struct DeletableTarget: Sendable {
    let action: DeleteActionKind
    let displayTitle: String
}

@MainActor
final class DeletePortDialog {
    func prompt(store: PortStore) -> DeletableTarget? {
        var targets: [DeletableTarget] = []

        for item in store.standaloneItems {
            targets.append(
                DeletableTarget(
                    action: .standaloneItem(itemId: item.id),
                    displayTitle: "\(item.key): \(item.value)"
                )
            )
        }

        for group in store.groups {
            for item in group.items {
                targets.append(
                    DeletableTarget(
                        action: .groupItem(groupId: group.id, itemId: item.id),
                        displayTitle: "[\(group.name)] \(item.key): \(item.value)"
                    )
                )
            }
            targets.append(
                DeletableTarget(
                    action: .group(groupId: group.id),
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
