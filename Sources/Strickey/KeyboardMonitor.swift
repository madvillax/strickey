import Carbon
import CoreGraphics
import StrickeyCore

// The tap is attached exclusively to the main run loop; its callback never leaves that thread.
private let keyboardCallback: CGEventTapCallBack = { _, type, event, context in
    guard let context else { return Unmanaged.passUnretained(event) }
    let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
    // Pass value types across the isolation boundary, never the non-Sendable CGEvent.
    let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
    let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
    let shortcutModifier = !event.flags.intersection([.maskCommand, .maskControl]).isEmpty
    MainActor.assumeIsolated {
        monitor.receive(type: type, keyCode: keyCode, isRepeat: isRepeat, shortcutModifier: shortcutModifier)
    }
    return Unmanaged.passUnretained(event)
}

@MainActor
final class KeyboardMonitor {
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?
    private var tracker = KeyPressTracker()
    var onKey: ((KeyKind, Bool) -> Void)?
    var ignoreShortcuts = true
    var isRunning: Bool { tap.map { CGEvent.tapIsEnabled(tap: $0) } ?? false }

    @discardableResult
    func start() -> Bool {
        if isRunning { return true }
        stop()
        guard CGPreflightListenEventAccess() else { return false }
        let mask = (CGEventMask(1) << CGEventType.keyDown.rawValue)
            | (CGEventMask(1) << CGEventType.keyUp.rawValue)
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: keyboardCallback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            return false
        }
        self.tap = tap
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        return true
    }

    func stop() {
        if let tap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        source = nil
        tap = nil
        tracker.reset()
    }

    fileprivate func receive(type: CGEventType, keyCode: UInt16, isRepeat: Bool, shortcutModifier: Bool) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            tracker.reset()
            if let tap, CGPreflightListenEventAccess() { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        guard !IsSecureEventInputEnabled() else {
            tracker.reset()
            return
        }
        // Read only physical key code and repeat/modifier flags. Do not request Unicode text.
        if type == .keyDown {
            let shortcut = ignoreShortcuts && shortcutModifier
            if let key = tracker.keyDown(keyCode, isRepeat: isRepeat, isShortcut: shortcut) {
                onKey?(key, false)
            }
        } else if type == .keyUp, let key = tracker.keyUp(keyCode) {
            onKey?(key, true)
        }
    }
}
