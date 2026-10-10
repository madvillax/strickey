import Foundation

/// Bundled, recorded Cherry MX keystrokes. Loading happens once, before typing playback.
public enum SoundLibrary {
    public static let sampleRate = 44_100.0
    public static let variantCount = 4

    public enum LoadingError: Error, LocalizedError {
        case missingRecording(String)
        case invalidWave
        case unsupportedFormat

        public var errorDescription: String? {
            switch self {
            case .missingRecording(let name): "Missing Cherry MX recording: \(name)"
            case .invalidWave: "The Cherry MX recording is damaged."
            case .unsupportedFormat: "The recording must be mono 44.1 kHz, 16-bit PCM WAV."
            }
        }
    }

    public static func load(profile: SwitchProfile, key: KeyKind, variant: Int) throws -> [Float] {
        guard (0..<variantCount).contains(variant) else { throw LoadingError.invalidWave }
        let category: String
        switch key {
        case .regular: category = "regular-\(variant)"
        case .space: category = "space"
        case .enter: category = "enter"
        case .delete: category = "delete"
        }
        let name = "\(profile.recordingPrefix)-\(category)"
        let bundle: Bundle
        if Bundle.main.bundleURL.pathExtension == "app" {
            guard let url = Bundle.main.url(forResource: "Strickey_StrickeyCore", withExtension: "bundle"),
                  let packaged = Bundle(url: url) else {
                throw LoadingError.missingRecording("Strickey_StrickeyCore.bundle")
            }
            bundle = packaged
        } else {
            bundle = Bundle.module
        }
        guard let url = bundle.url(forResource: name, withExtension: "wav", subdirectory: "CherryMX") else {
            throw LoadingError.missingRecording(name)
        }
        return try decode(Data(contentsOf: url))
    }

    /// Reject malformed/truncated assets rather than silently falling back to synthetic effects.
    public static func decode(_ data: Data) throws -> [Float] {
        let bytes = [UInt8](data)
        func tag(_ offset: Int) -> String {
            String(bytes: bytes[offset..<offset + 4], encoding: .ascii) ?? ""
        }
        func number(_ offset: Int, _ count: Int) -> Int {
            (0..<count).reduce(0) { $0 | (Int(bytes[offset + $1]) << ($1 * 8)) }
        }
        guard bytes.count >= 12, tag(0) == "RIFF", tag(8) == "WAVE",
              number(4, 4) + 8 == bytes.count else { throw LoadingError.invalidWave }
        var offset = 12
        var validFormat = false
        var audioRange: Range<Int>?
        while offset + 8 <= bytes.count {
            let kind = tag(offset)
            let length = number(offset + 4, 4)
            let start = offset + 8
            guard length <= bytes.count - start else { throw LoadingError.invalidWave }
            if kind == "fmt " {
                guard length >= 16 else { throw LoadingError.invalidWave }
                guard number(start, 2) == 1, number(start + 2, 2) == 1,
                      number(start + 4, 4) == Int(sampleRate), number(start + 8, 4) == 88_200,
                      number(start + 12, 2) == 2, number(start + 14, 2) == 16 else {
                    throw LoadingError.unsupportedFormat
                }
                validFormat = true
            } else if kind == "data" {
                guard length > 0, length.isMultiple(of: 2) else { throw LoadingError.invalidWave }
                audioRange = start..<start + length
            }
            offset = start + length + (length % 2)
        }
        guard validFormat, let audioRange, offset == bytes.count else { throw LoadingError.invalidWave }
        return stride(from: audioRange.lowerBound, to: audioRange.upperBound, by: 2).map {
            let bits = UInt16(bytes[$0]) | (UInt16(bytes[$0 + 1]) << 8)
            return Float(Int16(bitPattern: bits)) / 32_768
        }
    }
}
