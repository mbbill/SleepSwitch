import Foundation

runLidActionsTests()
runPowerAssertionsTests()
runSleepModeTests()
runBatteryGuardTests()
runUpdaterTests()

if CommandLine.arguments.contains("--network") {
    runUpdaterNetworkTests()
}

Test.finish()
