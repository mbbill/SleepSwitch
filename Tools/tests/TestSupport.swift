import Foundation

/// Minimal harness. The project has no test target — the suite is a plain executable
/// compiled from the sources, which keeps the build to `swiftc` and nothing else.
enum Test {
    private(set) static var failures = 0

    static func section(_ name: String) {
        print(name)
    }

    static func expect(_ condition: Bool, _ description: String) {
        if condition {
            print("  ok    \(description)")
        } else {
            print("  FAIL  \(description)")
            failures += 1
        }
    }

    static func finish() -> Never {
        print(failures == 0 ? "\nAll checks passed." : "\nFailures: \(failures)")
        exit(failures == 0 ? 0 : 1)
    }
}

/// Stand-in for the privileged half, so the state machine can be driven through paths the
/// real system cannot be talked into on demand — a declined password, a failing `pmset`.
final class FakeSleepBan: SleepBanControlling {
    var log: EventLog?
    var isActive = false

    /// What the next `set` should pretend to do.
    var response: Result<Void, SystemSleepBan.Failure> = .success(())

    /// Whether the quiet path (the sudo rule) works. False models a machine without it.
    var quietClearWorks = true

    private(set) var setCalls: [(on: Bool, allowPrompt: Bool)] = []
    private(set) var quietClears = 0

    func set(_ on: Bool, allowPrompt: Bool) -> Result<Void, SystemSleepBan.Failure> {
        setCalls.append((on, allowPrompt))
        log?.record(on ? "ban armed" : "ban cleared")
        if case .success = response { isActive = on }
        return response
    }

    func clearQuietly() {
        quietClears += 1
        if quietClearWorks { isActive = false }
    }
}

/// Records the order things happened in. Whether the claim is written before or after the
/// ban is the difference between a crash being recoverable and being invisible, so the
/// order is worth pinning down rather than trusting.
final class EventLog {
    private(set) var events: [String] = []
    func record(_ event: String) { events.append(event) }
}

/// Stand-in for the on-disk lease, so the state machine can be tested without writing
/// anything to a real Application Support folder.
final class FakeBanLease: BanLeaseWriting {
    private let log: EventLog?
    private(set) var exists = false
    private(set) var renewals = 0
    private(set) var clears = 0

    init(log: EventLog? = nil) { self.log = log }

    func renew() {
        exists = true
        renewals += 1
        log?.record("claim written")
    }

    func clear() {
        exists = false
        clears += 1
        log?.record("claim cleared")
    }
}
