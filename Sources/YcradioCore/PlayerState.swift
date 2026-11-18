import AVFoundation

public enum PlayerState: Equatable, Sendable {
    case paused
    case buffering
    case playing

    public init(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing: self = .playing
        case .waitingToPlayAtSpecifiedRate: self = .buffering
        case .paused: self = .paused
        @unknown default: self = .paused
        }
    }

    /// SF Symbol for the status item.
    public var symbolName: String {
        switch self {
        case .playing: "play.fill"
        case .buffering: "hourglass"
        case .paused: "pause.fill"
        }
    }

    public var accessibilityLabel: String {
        switch self {
        case .playing: "Playing"
        case .buffering: "Buffering"
        case .paused: "Paused"
        }
    }
}
