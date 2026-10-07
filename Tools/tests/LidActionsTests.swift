import Foundation

func runLidActionsTests() {
    Test.section("LidActions: display sleep and optional sound")
    for awake in [false, true] {
        for closed in [false, true] {
            for sounds in [false, true] {
                var displayRequests = 0
                var soundEvents: [Bool] = []
                LidActions.handle(closed: closed, awake: awake, soundsEnabled: sounds,
                                  playSound: { soundEvents.append($0) },
                                  sleepDisplay: { displayRequests += 1 })
                let context = "awake=\(awake), closed=\(closed), sounds=\(sounds)"
                Test.expect(displayRequests == (awake && closed ? 1 : 0),
                            "display request: \(context)")
                Test.expect(soundEvents == (awake && sounds ? [closed] : []),
                            "sound event: \(context)")
            }
        }
    }
}
