import MediaPlayer
import YcradioCore

/// Routes the hardware/system media keys to the radio and keeps the system
/// "Now Playing" info alive so macOS sends those keys here.
@MainActor
final class MediaKeyHandler {
    private var info: [String: Any] = [
        MPNowPlayingInfoPropertyIsLiveStream: true,
        MPMediaItemPropertyArtist: "YourClassical MPR",
    ]

    func install(player: RadioPlayer) {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { _ in
            Task { @MainActor in player.play() }
            return .success
        }
        center.pauseCommand.addTarget { _ in
            Task { @MainActor in player.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { _ in
            Task { @MainActor in player.toggle() }
            return .success
        }

        center.playCommand.isEnabled = true
        center.pauseCommand.isEnabled = true
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = false
        center.previousTrackCommand.isEnabled = false
    }

    func update(_ state: PlayerState) {
        info[MPNowPlayingInfoPropertyPlaybackRate] = state == .paused ? 0.0 : 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        MPNowPlayingInfoCenter.default().playbackState = state == .paused ? .paused : .playing
    }

    func update(title: String) {
        info[MPMediaItemPropertyTitle] = title
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
