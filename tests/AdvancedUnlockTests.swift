@main struct AdvancedUnlockTests {
    static func main() {
        var sequence = AdvancedUnlockSequence()
        for _ in 0..<9 { precondition(!sequence.tap()) }
        precondition(sequence.tap())
        precondition(!sequence.tap())
        sequence.reset()
        for _ in 0..<9 { precondition(!sequence.tap()) }
        precondition(sequence.tap())
        print("PASS: ten version taps, single unlock, and reset.")
    }
}
