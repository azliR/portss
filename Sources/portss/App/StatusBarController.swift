import AppKit
import PortssCore

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let storage: PortStorage
    private let addPortDialog: AddPortDialog
    private let deletePortDialog: DeletePortDialog

    init(storage: PortStorage) {
        self.storage = storage
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.addPortDialog = AddPortDialog()
        self.deletePortDialog = DeletePortDialog()
        super.init()

        setupStatusItem()
        rebuildMenu()
    }

    private func setupStatusItem() {
        guard let button = statusItem.button else {
            DialogPresenter.shared.showError(title: "Status Bar Error", message: "Failed to initialize menu bar button.")
            return
        }

        if let symbolImage = NSImage(systemSymbolName: "network", accessibilityDescription: "portss") {
            symbolImage.isTemplate = true
            button.image = symbolImage
        } else {
            button.title = "portss"
        }
    }

    func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self

        let store: PortStore
        do {
            store = try storage.loadStore()
        } catch {
            DialogPresenter.shared.showError(title: "Data Loading Error", message: error.localizedDescription)
            store = PortStore()
        }

        if store.isEmpty {
            let emptyItem = NSMenuItem(title: "No ports saved yet", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            populateStore(store, into: menu)
        }

        menu.addItem(NSMenuItem.separator())

        let addItem = NSMenuItem(title: "Add Port...", action: #selector(handleAddPort), keyEquivalent: "")
        addItem.target = self
        menu.addItem(addItem)

        let deleteItem = NSMenuItem(title: "Delete Port...", action: #selector(handleDeletePort), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)

        menu.addItem(NSMenuItem.separator())

        let openConfigFileItem = NSMenuItem(title: "Open ports.json", action: #selector(handleOpenConfigFile), keyEquivalent: "")
        openConfigFileItem.target = self
        menu.addItem(openConfigFileItem)

        let quitItem = NSMenuItem(title: "Quit portss", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func populateStore(_ store: PortStore, into menu: NSMenu) {
        for item in store.standaloneItems {
            let itemMenu = createPortMenuItem(item: item)
            menu.addItem(itemMenu)
        }

        if !store.standaloneItems.isEmpty && !store.groups.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        for group in store.groups {
            let groupMenuItem = NSMenuItem(title: group.name, action: nil, keyEquivalent: "")
            let groupSubmenu = NSMenu(title: group.name)

            if group.items.isEmpty {
                let emptyItem = NSMenuItem(title: "(empty)", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                groupSubmenu.addItem(emptyItem)
            } else {
                for item in group.items {
                    let itemMenu = createPortMenuItem(item: item)
                    groupSubmenu.addItem(itemMenu)
                }
            }

            groupMenuItem.submenu = groupSubmenu
            menu.addItem(groupMenuItem)
        }
    }

    private func createPortMenuItem(item: PortItem) -> NSMenuItem {
        let title = "\(item.key): \(item.value)"
        let menuItem = NSMenuItem(title: title, action: #selector(handleCopyPortValue(_:)), keyEquivalent: "")
        menuItem.target = self
        menuItem.representedObject = item.value
        menuItem.toolTip = "Click to copy '\(item.value)' to clipboard"
        return menuItem
    }

    @objc private func handleCopyPortValue(_ sender: NSMenuItem) {
        guard let portValue = sender.representedObject as? String else {
            DialogPresenter.shared.showError(title: "Clipboard Error", message: "Port value is missing.")
            return
        }

        ClipboardManager.shared.copyToClipboard(text: portValue)
        NSSound.beep()
    }

    @objc private func handleAddPort() {
        guard let input = addPortDialog.prompt() else {
            return
        }

        do {
            try storage.addOrUpdateItem(groupName: input.groupName, key: input.key, value: input.value)
            rebuildMenu()
        } catch {
            DialogPresenter.shared.showError(title: "Save Failed", message: error.localizedDescription)
        }
    }

    @objc private func handleDeletePort() {
        let store: PortStore
        do {
            store = try storage.loadStore()
        } catch {
            DialogPresenter.shared.showError(title: "Data Loading Error", message: error.localizedDescription)
            return
        }

        guard let target = deletePortDialog.prompt(store: store) else {
            return
        }

        let isConfirmed = DialogPresenter.shared.showConfirmation(
            title: "Confirm Deletion",
            message: "Are you sure you want to delete '\(target.displayTitle)'?",
            confirmButtonTitle: "Delete"
        )

        guard isConfirmed else {
            return
        }

        do {
            switch target.action {
            case .standaloneItem(let itemId):
                try storage.deleteStandaloneItem(itemId: itemId)
            case .groupItem(let groupId, let itemId):
                try storage.deleteGroupItem(groupId: groupId, itemId: itemId)
            case .group(let groupId):
                try storage.deleteGroup(groupId: groupId)
            }
            rebuildMenu()
        } catch {
            DialogPresenter.shared.showError(title: "Deletion Failed", message: error.localizedDescription)
        }
    }

    @objc private func handleOpenConfigFile() {
        let fileURL = storage.storageFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            do {
                try storage.saveStore(PortStore())
            } catch {
                DialogPresenter.shared.showError(title: "File Error", message: error.localizedDescription)
                return
            }
            NSWorkspace.shared.open(fileURL)
            return
        }

        NSWorkspace.shared.open(fileURL)
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }
}
