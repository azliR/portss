import AppKit
import PortssCore

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let storage: PortStorage
    private let addPortDialog: AddPortDialog
    private let editPortDialog: EditPortDialog
    private let deletePortDialog: DeletePortDialog
    private let sortOptionUserDefaultsKey = "portss_sort_option"

    init(storage: PortStorage) {
        self.storage = storage
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.addPortDialog = AddPortDialog()
        self.editPortDialog = EditPortDialog()
        self.deletePortDialog = DeletePortDialog()
        super.init()

        setupStatusItem()
        rebuildMenu()
    }

    private var currentSortOption: PortSortOption {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: sortOptionUserDefaultsKey),
                  let option = PortSortOption(rawValue: rawValue) else {
                return .created
            }
            return option
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: sortOptionUserDefaultsKey)
        }
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

        let editItem = NSMenuItem(title: "Edit Port...", action: #selector(handleEditPort), keyEquivalent: "")
        editItem.target = self
        menu.addItem(editItem)

        let deleteItem = NSMenuItem(title: "Delete Port...", action: #selector(handleDeletePort), keyEquivalent: "")
        deleteItem.target = self
        menu.addItem(deleteItem)

        menu.addItem(NSMenuItem.separator())

        let sortMenuItem = NSMenuItem(title: "Sort by", action: nil, keyEquivalent: "")
        let sortSubmenu = NSMenu(title: "Sort by")
        for option in PortSortOption.allCases {
            let item = NSMenuItem(title: option.displayName, action: #selector(handleSelectSortOption(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = option
            item.state = (option == currentSortOption) ? .on : .off
            sortSubmenu.addItem(item)
        }
        sortMenuItem.submenu = sortSubmenu
        menu.addItem(sortMenuItem)

        let launchAtLoginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(handleToggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchAtLoginItem.target = self
        launchAtLoginItem.state = LaunchAtLoginManager.isEnabled() ? .on : .off
        menu.addItem(launchAtLoginItem)

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
        let sortedStandaloneItems = PortSorter.sort(items: store.standaloneItems, by: currentSortOption)
        for item in sortedStandaloneItems {
            let itemMenu = createPortMenuItem(item: item)
            menu.addItem(itemMenu)
        }

        if !store.standaloneItems.isEmpty && !store.groups.isEmpty {
            menu.addItem(NSMenuItem.separator())
        }

        let sortedGroups = store.groups.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        for group in sortedGroups {
            let groupMenuItem = NSMenuItem(title: group.name, action: nil, keyEquivalent: "")
            let groupSubmenu = NSMenu(title: group.name)

            if group.items.isEmpty {
                let emptyItem = NSMenuItem(title: "(empty)", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                groupSubmenu.addItem(emptyItem)
            } else {
                let sortedGroupItems = PortSorter.sort(items: group.items, by: currentSortOption)
                for item in sortedGroupItems {
                    let itemMenu = createPortMenuItem(item: item)
                    groupSubmenu.addItem(itemMenu)
                }
            }

            groupMenuItem.submenu = groupSubmenu
            menu.addItem(groupMenuItem)
        }
    }

    private func createPortMenuItem(item: PortItem) -> NSMenuItem {
        let menuItem = NSMenuItem()
        let customView = PortMenuItemView(portItem: item) { [weak self] in
            self?.executeCopy(portValue: item.value)
        }
        menuItem.view = customView
        menuItem.representedObject = item.value
        menuItem.toolTip = "Click to copy '\(item.value)' to clipboard"
        return menuItem
    }

    private func executeCopy(portValue: String) {
        ClipboardManager.shared.copyToClipboard(text: portValue)
        NSSound.beep()
    }

    @objc private func handleSelectSortOption(_ sender: NSMenuItem) {
        guard let option = sender.representedObject as? PortSortOption else {
            return
        }

        currentSortOption = option
        rebuildMenu()
    }

    @objc private func handleToggleLaunchAtLogin() {
        let targetState = !LaunchAtLoginManager.isEnabled()
        do {
            try LaunchAtLoginManager.setLaunchAtLogin(enabled: targetState)
            rebuildMenu()
        } catch {
            DialogPresenter.shared.showError(
                title: "Launch at Login Error",
                message: "Failed to configure launch at login: \(error.localizedDescription)"
            )
        }
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

    @objc private func handleEditPort() {
        let store: PortStore
        do {
            store = try storage.loadStore()
        } catch {
            DialogPresenter.shared.showError(title: "Data Loading Error", message: error.localizedDescription)
            return
        }

        guard let output = editPortDialog.prompt(store: store) else {
            return
        }

        do {
            try storage.updateItem(
                sourceLocation: output.sourceLocation,
                newGroupName: output.newGroupName,
                newKey: output.newKey,
                newValue: output.newValue
            )
            rebuildMenu()
        } catch {
            DialogPresenter.shared.showError(title: "Update Failed", message: error.localizedDescription)
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
