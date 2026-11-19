import AppKit
import YcradioCore

@MainActor
final class StatusItemController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let player: RadioPlayer
    private let nowPlaying: NowPlayingClient
    private let popup = TrackPopup()
    private let menu = NSMenu()
    private var longPressWork: DispatchWorkItem?
    private var longPressFired = false
    private var monitor: Any?

    private static let longPressDelay: TimeInterval = 0.45

    init?(player: RadioPlayer, nowPlaying: NowPlayingClient) {
        self.player = player
        self.nowPlaying = nowPlaying
        guard let button = statusItem.button else { return nil }

        button.target = self
        button.action = #selector(handleClick(_:))
        // A status button only sends its action for one event type, so the
        // press is observed separately from the release.
        button.sendAction(on: .leftMouseUp)
        button.imageScaling = .scaleProportionallyDown

        monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self, event.window === self.statusItem.button?.window else { return event }
            if event.type == .rightMouseDown {
                self.showMenu()
            } else {
                self.startLongPress()
            }
            return event
        }

        menu.addItem(NSMenuItem(title: "Quit Ycradio",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: "q"))

        update(player.state)
    }

    func update(_ state: PlayerState) {
        guard let button = statusItem.button else { return }
        let image = NSImage(systemSymbolName: state.symbolName, accessibilityDescription: state.accessibilityLabel)
        image?.isTemplate = true
        button.image = image
        updateLabels()
    }

    /// The track feed changes independently of the player state.
    func updateTrack() {
        updateLabels()
    }

    private func updateLabels() {
        guard let button = statusItem.button else { return }
        let state = player.state.accessibilityLabel
        let track = player.state == .paused ? nil : nowPlaying.nowPlaying?.displayName
        button.toolTip = ["Ycradio — \(state)", track].compactMap { $0 }.joined(separator: "\n")
        button.setAccessibilityLabel(["Ycradio", state, track].compactMap { $0 }.joined(separator: ", "))
    }

    private func startLongPress() {
        longPressWork?.cancel()
        longPressFired = false
        let work = DispatchWorkItem { [weak self] in
            // A release outside the button sends no action; don't treat it as a hold.
            guard let self, NSEvent.pressedMouseButtons & 0x1 != 0 else { return }
            self.longPressFired = true
            self.showTrack()
        }
        longPressWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.longPressDelay, execute: work)
    }

    @objc private func handleClick(_ sender: NSStatusBarButton) {
        longPressWork?.cancel()
        longPressWork = nil
        guard !longPressFired else {
            longPressFired = false
            return
        }
        player.toggle()
    }

    private func showMenu() {
        longPressWork?.cancel()
        guard let button = statusItem.button else { return }
        NSApp.activate(ignoringOtherApps: true)
        menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
    }

    private func showTrack() {
        let fallback = player.state == .paused ? "Not playing" : "No track info yet"
        popup.show(nowPlaying.nowPlaying?.displayName ?? fallback, near: statusItem.button)
    }
}
