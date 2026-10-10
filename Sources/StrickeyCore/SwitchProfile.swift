import Foundation

public enum SwitchProfile: String, CaseIterable, Identifiable, Sendable {
    case linear, tactile, clicky

    public var id: String { rawValue }
    public var name: String {
        switch self {
        case .linear: "MX Red"
        case .tactile: "MX Brown"
        case .clicky: "MX Blue"
        }
    }
    public var subtitle: String {
        switch self {
        case .linear: "Cherry MX Red · linear · PBT keycaps"
        case .tactile: "Cherry MX Brown · tactile · PBT keycaps"
        case .clicky: "Cherry MX Blue · clicky · PBT keycaps"
        }
    }

    public var recordingPrefix: String {
        switch self {
        case .linear: "red"
        case .tactile: "brown"
        case .clicky: "blue"
        }
    }
    public var symbol: String {
        switch self {
        case .linear: "waveform.path"
        case .tactile: "waveform.path.ecg"
        case .clicky: "bolt.fill"
        }
    }
}

/// These are physical key categories, never characters or typed text.
public enum KeyKind: Int, CaseIterable, Sendable {
    case regular, space, enter, delete

    public init(keyCode: UInt16) {
        switch keyCode {
        case 49: self = .space
        case 36, 76: self = .enter
        case 51, 117: self = .delete
        default: self = .regular
        }
    }
}
