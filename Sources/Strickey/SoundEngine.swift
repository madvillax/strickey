import AVFoundation
import StrickeyCore

@MainActor
final class SoundEngine {
    private struct SampleID: Hashable {
        let profile: SwitchProfile
        let key: KeyKind
        let variant: Int
    }
    private let engine = AVAudioEngine()
    private let format = AVAudioFormat(standardFormatWithSampleRate: SoundLibrary.sampleRate, channels: 1)!
    private var players: [AVAudioPlayerNode] = []
    private var samples: [SampleID: AVAudioPCMBuffer] = [:]
    private var nextVoice = 0
    private var nextVariant = 0
    private var configurationObserver: NSObjectProtocol?
    private var loadingError: Error?
    var volume: Float = 0.5 { didSet { engine.mainMixerNode.outputVolume = volume } }

    init() {
        // A fixed voice pool bounds work and memory while allowing overlapping keystrokes.
        for _ in 0..<24 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            players.append(player)
        }
        engine.mainMixerNode.outputVolume = volume
        do {
            for profile in SwitchProfile.allCases {
                for key in KeyKind.allCases {
                    for variant in 0..<SoundLibrary.variantCount {
                        let values = try SoundLibrary.load(profile: profile, key: key, variant: variant)
                        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(values.count))!
                        buffer.frameLength = buffer.frameCapacity
                        values.withUnsafeBufferPointer { source in
                            buffer.floatChannelData![0].update(from: source.baseAddress!, count: values.count)
                        }
                        samples[SampleID(profile: profile, key: key, variant: variant)] = buffer
                    }
                }
            }
        } catch {
            loadingError = error
            samples.removeAll()
        }
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.stop() }
        }
    }

    func start() throws {
        guard !engine.isRunning else { return }
        engine.prepare()
        try engine.start()
    }

    func play(profile: SwitchProfile, key: KeyKind) throws {
        if let loadingError { throw loadingError }
        try start()
        let id = SampleID(profile: profile, key: key, variant: nextVariant)
        guard let buffer = samples[id] else { throw SoundLibrary.LoadingError.invalidWave }
        nextVariant = (nextVariant + 1) % SoundLibrary.variantCount
        let player = players[nextVoice]
        nextVoice = (nextVoice + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer)
        player.play()
    }

    func stop() {
        players.forEach { $0.stop() }
        engine.stop()
    }

    func shutdown() {
        stop()
        if let configurationObserver { NotificationCenter.default.removeObserver(configurationObserver) }
        configurationObserver = nil
    }
}
