import Foundation
import IOKit.pwr_mgt

// Inspect the assertions registered with macOS, not the implementation's own flags.
func runPowerAssertionsTests() {
    Test.section("PowerAssertions: keep the system awake without keeping the display on")
    let assertions = PowerAssertions()
    defer { assertions.releaseAll() }

    func types() -> [String] {
        var raw: Unmanaged<CFDictionary>?
        let result = IOPMCopyAssertionsByProcess(&raw)
        Test.expect(result == kIOReturnSuccess, "macOS assertion inspection succeeds")
        guard let raw else {
            Test.expect(false, "macOS returns assertion data")
            return []
        }
        let byProcess = raw.takeRetainedValue() as NSDictionary
        let entries = byProcess[NSNumber(value: ProcessInfo.processInfo.processIdentifier)]
            as? [[String: Any]] ?? []
        return entries.compactMap { $0[kIOPMAssertionTypeKey] as? String }
    }

    assertions.apply(active: true)
    let active = types()
    Test.expect(active.contains(kIOPMAssertionTypePreventUserIdleSystemSleep),
                "active mode prevents system idle sleep")
    Test.expect(!active.contains(kIOPMAssertionTypePreventUserIdleDisplaySleep),
                "active mode permits display idle sleep")
    assertions.apply(active: true)
    Test.expect(types() == active, "repeated activation does not add assertions")
    assertions.releaseAll()
    assertions.releaseAll()
    let inactive = types()
    Test.expect(!inactive.contains(kIOPMAssertionTypePreventUserIdleSystemSleep),
                "release removes the system assertion")
    Test.expect(!inactive.contains(kIOPMAssertionTypePreventUserIdleDisplaySleep),
                "release leaves no display assertion")
}
