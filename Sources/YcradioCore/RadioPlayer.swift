import AVFoundation

@MainActor
public final class RadioPlayer {
    nonisolated public static let streamURL = URL(string: "https://ycradio.stream.publicradio.org/ycradio.aac")!

    public var onChange: ((PlayerState) -> Void)?
    public private(set) var state: PlayerState = .paused {
        didSet {
            guard state != oldValue else { return }
            onChange?(state)
        }
    }

    private let url: URL
    private let player = AVPlayer()
    private var wantsPlay = false
    private var timeControlObservation: NSKeyValueObservation?
    private var itemObservation: NSKeyValueObservation?

    public init(url: URL = RadioPlayer.streamURL) {
        self.url = url
        player.automaticallyWaitsToMinimizeStalling = true

        timeControlObservation = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            let status = player.timeControlStatus
            Task { @MainActor in self?.apply(status) }
        }
    }

    public func toggle() {
        wantsPlay ? pause() : play()
    }

    public func play() {
        guard !wantsPlay else { return }
        wantsPlay = true
        state = .buffering
        // Always connect again: a live stream resumed from a paused item
        // replays from wherever it stopped instead of the live edge.
        loadItem()
        player.play()
    }

    public func pause() {
        wantsPlay = false
        player.pause()
        state = .paused
    }

    private func loadItem() {
        let item = AVPlayerItem(url: url)
        itemObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .failed else { return }
            Task { @MainActor in self?.retryAfterFailure() }
        }
        player.replaceCurrentItem(with: item)
    }

    private func retryAfterFailure() {
        guard wantsPlay else { return }
        state = .buffering
        Task {
            try? await Task.sleep(for: .seconds(3))
            guard wantsPlay else { return }
            loadItem()
            player.play()
        }
    }

    private func apply(_ status: AVPlayer.TimeControlStatus) {
        guard wantsPlay else {
            state = .paused
            return
        }
        let newState = PlayerState(status)
        // While playing is requested AVPlayer reports `.paused` until the first
        // samples arrive; that is buffering, not a stopped player.
        state = newState == .paused ? .buffering : newState
    }
}
