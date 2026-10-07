import Foundation

/// Keep display sleep independent of the optional lid sound.
enum LidActions {
    static func handle(closed: Bool, awake: Bool, soundsEnabled: Bool,
                       playSound: (Bool) -> Void, sleepDisplay: () -> Void) {
        guard awake else { return }
        if soundsEnabled { playSound(closed) }
        // Existing behavior: lid events only play the optional sound.
    }
}

/// Ask macOS to sleep the displays without changing brightness or system sleep settings.
/// `pmset displaysleepnow` affects external displays too, just like a manual invocation.
final class DisplaySleep {
    private var process: Process?

    func request() {
        guard process == nil else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["displaysleepnow"]
        task.terminationHandler = { [weak self] finished in
            let status = finished.terminationStatus
            DispatchQueue.main.async {
                self?.process = nil
                if status != 0 {
                    NSLog("SleepSwitch: display sleep request failed (exit %d)", status)
                }
            }
        }
        process = task
        do {
            try task.run()
        } catch {
            process = nil
            NSLog("SleepSwitch: could not request display sleep: %@", error.localizedDescription)
        }
    }
}
