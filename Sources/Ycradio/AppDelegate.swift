import AppKit
import YcradioCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let player = RadioPlayer()
    private let nowPlaying = NowPlayingClient()
    private let mediaKeys = MediaKeyHandler()
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let statusItem = StatusItemController(player: player, nowPlaying: nowPlaying) else { return }
        self.statusItem = statusItem

        mediaKeys.install(player: player)
        mediaKeys.update(player.state)

        nowPlaying.onChange = { [weak self] in
            self?.statusItem?.updateTrack()
            self?.mediaKeys.update(title: $0.displayName)
        }
        player.onChange = { [weak self] state in
            guard let self else { return }
            self.statusItem?.update(state)
            self.mediaKeys.update(state)
            if state == .paused {
                self.nowPlaying.stop()
            } else {
                self.nowPlaying.start()
            }
        }
    }
}
