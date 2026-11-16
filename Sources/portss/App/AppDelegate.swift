import AppKit
import PortssCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            let storage = try PortStorage()
            self.statusBarController = StatusBarController(storage: storage)
        } catch {
            DialogPresenter.shared.showError(title: "Initialization Error", message: error.localizedDescription)
            NSApp.terminate(nil)
        }
    }
}
