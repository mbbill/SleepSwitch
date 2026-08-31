import Foundation

/// Says "this ban is ours, and we are still here to clear it".
///
/// Behind a protocol so `SleepMode` can be tested without touching the real filesystem.
protocol BanLeaseWriting {
    func renew()
    func clear()
}

/// A file whose modification time is the whole signal, which keeps the reconcile agent
/// down to a single `stat`.
///
/// The in-process handlers cannot cover SIGKILL, a force quit or a panic, so without this
/// the ban would stay armed with nothing left to clear it — and with the battery guard
/// gone as well, since that lives in the same process. A stale lease means the app died
/// holding the ban; a missing one means the ban was never ours to touch.
struct FileBanLease: BanLeaseWriting {
    static let directory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("SleepSwitch", isDirectory: true)

    static let url = directory.appendingPathComponent("ban.lease")

    func renew() {
        let manager = FileManager.default
        try? manager.createDirectory(at: Self.directory, withIntermediateDirectories: true)

        if manager.fileExists(atPath: Self.url.path) {
            try? manager.setAttributes([.modificationDate: Date()], ofItemAtPath: Self.url.path)
        } else {
            manager.createFile(atPath: Self.url.path, contents: nil)
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: Self.url)
    }
}
