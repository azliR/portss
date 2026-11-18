import Foundation

public final class LaunchAtLoginManager: Sendable {
    private static let label = "com.local.portss"

    public static var defaultPlistURL: URL {
        return FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents", isDirectory: true)
            .appendingPathComponent("\(label).plist")
    }

    public static func isEnabled(at customPlistURL: URL? = nil) -> Bool {
        let fileURL = customPlistURL ?? defaultPlistURL
        return FileManager.default.fileExists(atPath: fileURL.path)
    }

    public static func register(
        appPath: String = "/Applications/portss.app",
        customPlistURL: URL? = nil
    ) throws {
        let fileURL = customPlistURL ?? defaultPlistURL
        let directoryURL = fileURL.deletingLastPathComponent()

        if !FileManager.default.fileExists(atPath: directoryURL.path) {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>
            <key>ProgramArguments</key>
            <array>
                <string>/usr/bin/open</string>
                <string>-a</string>
                <string>\(appPath)</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
        </dict>
        </plist>
        """

        try plistContent.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    public static func unregister(customPlistURL: URL? = nil) throws {
        let fileURL = customPlistURL ?? defaultPlistURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }

        try FileManager.default.removeItem(at: fileURL)
    }

    public static func setLaunchAtLogin(
        enabled: Bool,
        appPath: String = "/Applications/portss.app",
        customPlistURL: URL? = nil
    ) throws {
        if enabled {
            try register(appPath: appPath, customPlistURL: customPlistURL)
        } else {
            try unregister(customPlistURL: customPlistURL)
        }
    }
}
