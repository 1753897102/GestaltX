// SPDX-License-Identifier: GPL-3.0-only
struct AdvancedUnlockSequence {
    private(set) var taps = 0
    mutating func tap() -> Bool {
        guard taps < 10 else { return false }
        taps += 1
        return taps == 10
    }
    mutating func reset() { taps = 0 }
}
