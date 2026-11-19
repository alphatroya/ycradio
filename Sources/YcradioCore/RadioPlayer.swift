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
    /// How long a paused item is kept so a quick resume plays the buffer
    /// instead of reconnecting to the live edge.
    private let pauseGrace: Duration
    let player = AVPlayer()
    private var wantsPlay = false
    private var resumeFromBuffer = false
    private var pauseGraceTask: Task<Void, Never>?
    private var timeControlObservation: NSKeyValueObservation?
    private var itemObservation: NSKeyValueObservation?

    public init(url: URL = RadioPlayer.streamURL, pauseGrace: Duration = .seconds(15)) {
        self.url = url
        self.pauseGrace = pauseGrace
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
        if resumeFromBuffer, player.currentItem?.status == .readyToPlay {
            // Still inside the pause timebox: play the kept buffer from where
            // it stopped, which is instant compared to a fresh connection.
            resumeFromBuffer = false
            pauseGraceTask?.cancel()
            player.play()
        } else {
            // Always connect again: a live stream resumed from a paused item
            // replays from wherever it stopped instead of the live edge.
            loadItem()
            player.play()
        }
    }

    public func pause() {
        guard wantsPlay else { return }
        wantsPlay = false
        player.pause()
        state = .paused
        resumeFromBuffer = true
        pauseGraceTask?.cancel()
        pauseGraceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.pauseGrace)
            guard !Task.isCancelled else { return }
            self.dropPausedItem()
        }
    }

    /// After the timebox, release the paused item so the next play reconnects
    /// at the live edge.
    private func dropPausedItem() {
        guard !wantsPlay else { return }
        resumeFromBuffer = false
        player.replaceCurrentItem(with: nil)
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
