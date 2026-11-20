import Foundation

public struct NowPlaying: Equatable, Sendable {
    public let title: String
    public let composer: String?

    public init(title: String, composer: String?) {
        self.title = title
        self.composer = composer
    }

    public var displayName: String {
        guard let composer, !composer.isEmpty else { return title }
        return "\(composer) — \(title)"
    }

    /// Pulls the current play out of a `nowplayingv2` websocket message:
    /// `{"data": {"plays": [{"song": {"title": ..., "composer": ...}}]}}`
    public init?(message data: Data) {
        struct Message: Decodable {
            let data: Payload?

            struct Payload: Decodable {
                let plays: [Play]
            }

            struct Play: Decodable {
                let song: Song
            }

            struct Song: Decodable {
                let title: String
                let composer: String?
            }
        }

        guard let message = try? JSONDecoder().decode(Message.self, from: data),
              let song = message.data?.plays.first?.song,
              !song.title.isEmpty
        else { return nil }

        self.init(title: song.title, composer: song.composer)
    }

    public init?(message: String) {
        self.init(message: Data(message.utf8))
    }
}

/// The station's own now-playing feed (the one yourclassical.org uses).
@MainActor
public final class NowPlayingClient {
    public private(set) var nowPlaying: NowPlaying?
    public var onChange: ((NowPlaying) -> Void)?

    private var stream: RadioStream
    private var socket: URLSessionWebSocketTask?
    private var task: Task<Void, Never>?

    public init(stream: RadioStream = .saved()) {
        self.stream = stream
    }

    private var url: URL {
        URL(string: "wss://nowplayingv2.publicradio.org/playlist/\(stream.id)/v2")!
    }

    /// Follows the player's stream: reconnects the feed if it is running.
    public func select(_ stream: RadioStream) {
        guard stream != self.stream else { return }
        let wasRunning = task != nil
        stop()
        self.stream = stream
        nowPlaying = nil
        if wasRunning { start() }
    }

    public func start() {
        guard task == nil else { return }
        task = Task { [weak self] in
            while let self, !Task.isCancelled {
                let socket = URLSession.shared.webSocketTask(with: self.url)
                self.socket = socket
                socket.resume()
                do {
                    while !Task.isCancelled {
                        let message = try await socket.receive()
                        let data: Data? = switch message {
                        case .string(let text): Data(text.utf8)
                        case .data(let data): data
                        @unknown default: nil
                        }
                        if let data, let nowPlaying = NowPlaying(message: data) {
                            self.apply(nowPlaying)
                        }
                    }
                } catch {
                    // Connection lost or cancelled; reconnect below.
                }
                socket.cancel(with: .goingAway, reason: nil)
                self.socket = nil
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }

    public func stop() {
        task?.cancel()
        task = nil
        socket?.cancel(with: .goingAway, reason: nil)
        socket = nil
    }

    private func apply(_ newValue: NowPlaying) {
        guard newValue != nowPlaying else { return }
        nowPlaying = newValue
        onChange?(newValue)
    }
}
