import Foundation
import IOKit
import IOKit.pwr_mgt

/// Holds the IOKit assertions that block system idle sleep while allowing display sleep.
///
/// This is the safe half of the app: assertions belong to the process, so they disappear
/// the moment it dies. Nothing can get stuck the way a system setting can.
final class PowerAssertions {
    private var systemAssertion: IOPMAssertionID = 0

    private(set) var holdsSystem = false

    /// Keep background work running without overriding the display idle timer.
    func apply(active: Bool) {
        setSystem(active)
    }

    func releaseAll() {
        apply(active: false)
    }

    private func setSystem(_ wanted: Bool) {
        guard wanted != holdsSystem else { return }
        if wanted {
            // Assertion names stay ASCII: `pmset -g assertions` prints them verbatim.
            guard let id = create(kIOPMAssertionTypePreventUserIdleSystemSleep,
                                  reason: "SleepSwitch: no idle sleep") else { return }
            systemAssertion = id
            holdsSystem = true
        } else {
            IOPMAssertionRelease(systemAssertion)
            systemAssertion = 0
            holdsSystem = false
        }
    }

    private func create(_ type: String, reason: String) -> IOPMAssertionID? {
        var id: IOPMAssertionID = 0
        let result = IOPMAssertionCreateWithName(
            type as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &id
        )
        return result == kIOReturnSuccess ? id : nil
    }
}
