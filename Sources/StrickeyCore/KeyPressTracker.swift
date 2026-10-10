/// Holds only currently depressed physical keys. Cleared on pause, sleep, or secure input.
public struct KeyPressTracker: Sendable {
    private var heldKeys: Set<UInt16> = []

    public init() {}

    public mutating func keyDown(_ keyCode: UInt16, isRepeat: Bool, isShortcut: Bool) -> KeyKind? {
        guard !isRepeat, !isShortcut, heldKeys.insert(keyCode).inserted else { return nil }
        return KeyKind(keyCode: keyCode)
    }

    public mutating func keyUp(_ keyCode: UInt16) -> KeyKind? {
        guard heldKeys.remove(keyCode) != nil else { return nil }
        return KeyKind(keyCode: keyCode)
    }

    public mutating func reset() { heldKeys.removeAll(keepingCapacity: true) }
}
