import Testing
import Foundation
@testable import PortssCore

struct LaunchAtLoginManagerTests {
    private func createTemporaryPlistURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return tempDir.appendingPathComponent("test.plist")
    }

    @Test func testRegisterAndUnregisterLaunchAgent() throws {
        let plistURL = createTemporaryPlistURL()
        defer {
            try? FileManager.default.removeItem(at: plistURL.deletingLastPathComponent())
        }

        #expect(!LaunchAtLoginManager.isEnabled(at: plistURL))

        try LaunchAtLoginManager.register(appPath: "/Applications/portss.app", customPlistURL: plistURL)
        #expect(LaunchAtLoginManager.isEnabled(at: plistURL))

        let content = try String(contentsOf: plistURL, encoding: .utf8)
        #expect(content.contains("com.local.portss"))
        #expect(content.contains("/Applications/portss.app"))
        #expect(content.contains("<key>RunAtLoad</key>"))

        try LaunchAtLoginManager.unregister(customPlistURL: plistURL)
        #expect(!LaunchAtLoginManager.isEnabled(at: plistURL))
    }

    @Test func testSetLaunchAtLoginToggle() throws {
        let plistURL = createTemporaryPlistURL()
        defer {
            try? FileManager.default.removeItem(at: plistURL.deletingLastPathComponent())
        }

        try LaunchAtLoginManager.setLaunchAtLogin(enabled: true, appPath: "/Applications/portss.app", customPlistURL: plistURL)
        #expect(LaunchAtLoginManager.isEnabled(at: plistURL))

        try LaunchAtLoginManager.setLaunchAtLogin(enabled: false, appPath: "/Applications/portss.app", customPlistURL: plistURL)
        #expect(!LaunchAtLoginManager.isEnabled(at: plistURL))
    }
}
