import AppKit
import Carbon
import Combine
import CoreGraphics
import OSLog
import ServiceManagement
import StrickeyCore

@MainActor
final class AppModel: ObservableObject {
    private static let logger = Logger(subsystem: "app.strickey.mac", category: "keyboard-listener")
    enum ListeningStatus: Equatable {
        case needsPermission, listening, paused, secureInput, sleeping, unavailable

        var title: String {
            switch self {
            case .needsPermission: "Typing access is blocked by macOS"
            case .listening: "Listening for keystrokes"
            case .paused: "Sounds are paused"
            case .secureInput: "Secure input is active"
            case .sleeping: "Mac is asleep"
            case .unavailable: "Keyboard listener unavailable"
            }
        }
    }

    private let defaults: UserDefaults
    private let monitor = KeyboardMonitor()
    private let audio = SoundEngine()
    private var timer: Timer?
    private var previewTask: Task<Void, Never>?
    private var sleeping = false
    private var reportedStatus: ListeningStatus?

    @Published var enabled: Bool {
        didSet {
            defaults.set(enabled, forKey: "soundsEnabled")
            previewTask?.cancel()
            refresh()
        }
    }
    @Published var profile: SwitchProfile {
        didSet { defaults.set(profile.rawValue, forKey: "switchProfile") }
    }
    @Published var volume: Double {
        didSet {
            defaults.set(volume, forKey: "volume")
            applyVolume()
        }
    }
    @Published var ignoreShortcuts: Bool {
        didSet {
            defaults.set(ignoreShortcuts, forKey: "ignoreShortcuts")
            monitor.ignoreShortcuts = ignoreShortcuts
        }
    }
    @Published private(set) var status: ListeningStatus = .needsPermission
    @Published private(set) var permissionGranted = false
    @Published private(set) var launchAtLogin = false
    @Published private(set) var loginNeedsApproval = false
    @Published private(set) var previewing = false
    @Published private(set) var typingDetected = false
    @Published private(set) var outputDeviceName = SystemAudioOutput.name
    @Published var errorMessage: String?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            "soundsEnabled": true, "switchProfile": "tactile", "volume": 1.0,
            "ignoreShortcuts": true,
        ])
        enabled = defaults.bool(forKey: "soundsEnabled")
        profile = SwitchProfile(rawValue: defaults.string(forKey: "switchProfile") ?? "") ?? .tactile
        // Preserve the effective gain of the old full-Mac-volume mode on upgrade.
        if defaults.bool(forKey: "useSystemVolume") {
            defaults.set(1.0, forKey: "volume")
        }
        defaults.removeObject(forKey: "useSystemVolume")
        let savedVolume = defaults.double(forKey: "volume")
        volume = savedVolume.isFinite ? min(1, max(0, savedVolume)) : 1.0
        ignoreShortcuts = defaults.bool(forKey: "ignoreShortcuts")
        applyVolume()
        monitor.ignoreShortcuts = ignoreShortcuts
        monitor.onKey = { [weak self] key, release in
            guard let self, self.enabled, !release else { return }
            if self.play(key: key), !self.typingDetected {
                self.typingDetected = true
            }
        }
    }

    func start() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        timer?.tolerance = 0.5
    }

    func refresh() {
        let outputName = SystemAudioOutput.name
        if outputDeviceName != outputName { outputDeviceName = outputName }
        let granted = CGPreflightListenEventAccess()
        if permissionGranted != granted { permissionGranted = granted }
        let loginStatus = SMAppService.mainApp.status
        let registered = loginStatus == .enabled || loginStatus == .requiresApproval
        if launchAtLogin != registered { launchAtLogin = registered }
        if loginNeedsApproval != (loginStatus == .requiresApproval) {
            loginNeedsApproval = loginStatus == .requiresApproval
        }

        let next: ListeningStatus
        if sleeping {
            monitor.stop()
            next = .sleeping
        } else if !enabled {
            monitor.stop()
            if !previewing { audio.stop() }
            next = .paused
        } else if !granted {
            monitor.stop()
            if !previewing { audio.stop() }
            next = .needsPermission
        } else if IsSecureEventInputEnabled() {
            monitor.stop()
            if !previewing { audio.stop() }
            next = .secureInput
        } else {
            next = monitor.start() ? .listening : .unavailable
        }
        if next != .listening, typingDetected { typingDetected = false }
        if status != next { status = next }
        if reportedStatus != next {
            Self.logger.notice("Listener status: \(next.title, privacy: .public); input access: \(granted, privacy: .public); sounds enabled: \(self.enabled, privacy: .public)")
            reportedStatus = next
        }
    }

    private func applyVolume() {
        // AVAudioEngine follows the default output device; macOS applies its volume downstream.
        // App gain scales keyboard sounds; the normal Mac volume still applies downstream.
        audio.volume = Float(min(1, max(0, volume)))
    }

    func requestPermission() {
        _ = CGRequestListenEventAccess()
        refresh()
        if !permissionGranted { openInputSettings() }
    }

    func openInputSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") else { return }
        NSWorkspace.shared.open(url)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            errorMessage = nil
        } catch {
            errorMessage = "Could not update launch at login: \(error.localizedDescription)"
        }
        refresh()
    }

    func openLoginSettings() { SMAppService.openSystemSettingsLoginItems() }

    func preview() {
        previewTask?.cancel()
        previewing = true
        previewTask = Task { [weak self] in
            guard let self else { return }
            defer {
                self.previewing = false
                self.refresh()
            }
            for key in [KeyKind.regular, .regular, .space, .regular, .enter] {
                guard !Task.isCancelled else { return }
                self.play(key: key)
                do { try await Task.sleep(for: .milliseconds(250)) } catch { return }
            }
        }
    }

    @discardableResult
    private func play(key: KeyKind) -> Bool {
        do {
            try audio.play(profile: profile, key: key)
            return true
        } catch {
            if errorMessage == nil { errorMessage = "Audio is unavailable: \(error.localizedDescription)" }
            return false
        }
    }

    func sleep() {
        sleeping = true
        previewTask?.cancel()
        monitor.stop()
        audio.stop()
        refresh()
    }

    func wake() {
        sleeping = false
        refresh()
    }

    func shutdown() {
        timer?.invalidate()
        timer = nil
        previewTask?.cancel()
        monitor.stop()
        audio.shutdown()
    }
}
