import Foundation

/// Installs the launch agent that clears a ban the app died holding.
///
/// A user agent rather than a root daemon: it needs no privilege of its own, since it
/// clears the ban through the same narrow sudo rule the app uses. Registering it costs no
/// password either, which is why the app can do it at launch rather than the installer.
enum ReconcileAgent {
    static let label = "com.ganin.sleepswitch.reconcile"

    /// Every minute, and once at login — the two moments a crash can be noticed.
    private static let interval = 60

    private static var plistURL: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LaunchAgents/\(label).plist")
    }

    static func install() {
        guard let script = Bundle.main.url(forResource: "reconcile", withExtension: "sh") else {
            return
        }
        let plist: [String: Any] = [
            "Label": label,
            "ProgramArguments": ["/bin/bash", script.path],
            "RunAtLoad": true,
            "StartInterval": interval,
        ]
        guard let data = try? PropertyListSerialization.data(fromPropertyList: plist,
                                                             format: .xml, options: 0) else {
            return
        }

        // Rewrite only on a real change: the app path moves with an upgrade, but most
        // launches have nothing to say.
        let existing = try? Data(contentsOf: plistURL)
        if existing != data {
            try? FileManager.default.createDirectory(at: plistURL.deletingLastPathComponent(),
                                                     withIntermediateDirectories: true)
            try? data.write(to: plistURL)
        }

        let domain = "gui/\(getuid())"
        launchctl(["bootout", "\(domain)/\(label)"])       // no-op when not loaded
        launchctl(["bootstrap", domain, plistURL.path])
    }

    static func remove() {
        launchctl(["bootout", "gui/\(getuid())/\(label)"])
        try? FileManager.default.removeItem(at: plistURL)
    }

    @discardableResult
    private static func launchctl(_ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice

        do { try process.run() } catch { return false }
        process.waitUntilExit()
        return process.terminationStatus == 0
    }
}
