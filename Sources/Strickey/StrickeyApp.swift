import AppKit
import StrickeyCore

@main
struct StrickeyApp {
    @MainActor
    static func main() {
        // Checks real audio graph startup without requesting input permissions or changing settings.
        if CommandLine.arguments.contains("--smoke-test") {
            let audio = SoundEngine()
            do {
                audio.volume = 0
                try audio.play(profile: .tactile, key: .regular)
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.15))
                audio.shutdown()
                print("Strickey audio smoke test passed.")
            } catch {
                FileHandle.standardError.write(Data("Audio smoke test failed: \(error.localizedDescription)\n".utf8))
                exit(1)
            }
            return
        }
        let app = NSApplication.shared
        app.setActivationPolicy(CommandLine.arguments.contains("--preview-window") ? .regular : .accessory)
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
